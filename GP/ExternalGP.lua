-- ============================================================================
-- NSQC4 / GP / ExternalGP  (С ОТЛАДКОЙ)
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    local DEBUG = true

    local function D(...)
        if not DEBUG then return end
        local parts = {}
        for i = 1, select("#", ...) do
            parts[#parts+1] = tostring(select(i, ...))
        end
        local msg = "[EXTGP-DBG] " .. table.concat(parts, " ")
        print(msg)
        -- в офицерский тоже (закомментируй, если спамит)
        SendChatMessage(msg, "OFFICER")
    end

    local myName = UnitName("player") or ""
    local plainMe = myName:match("^(.-)-") or myName

    D("=== Module loaded ===")
    D("myName:", myName, "plainMe:", plainMe)

    -- ========================================================================
    -- Сохранить ГП в кэш
    -- ========================================================================
    local function SaveExternalGp(gpStr, nick)
        D("SaveExternalGp CALLED. gpStr=", tostring(gpStr), "nick=", tostring(nick))
        if not gpStr or not nick or nick == "" then
            D("  ABORT: empty gpStr or nick")
            return
        end

        local gp = tonumber(gpStr)
        if not gp then gp = 0 end

        local cleanNick = nick:match("^(.-)-") or nick
        D("  cleanNick=", cleanNick, "gp=", gp)

        if gpDb and gpDb.SetExternalGp then
            local oldGp = gpDb.GetExternalGp and gpDb:GetExternalGp(cleanNick) or nil
            D("  oldGp=", tostring(oldGp))

            if oldGp and oldGp ~= 0 and gp == 0 then
                D("  ABORT: не перезаписываем ненулевой на 0")
                return
            end
            gpDb:SetExternalGp(cleanNick, gp)
            D("  SetExternalGp OK")
        else
            D("  gpDb или SetExternalGp нет! gpDb=", type(gpDb))
        end

        if gpDb and gpDb.UpdateGpEntry then
            gpDb:UpdateGpEntry(cleanNick, gp)
            D("  UpdateGpEntry OK")
        end
    end

    -- ========================================================================
    -- 1. showGPA
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:showgpa", {
        func = function(words, sender, text, channel, prefix)
            D(">>> showGPA. sender=", sender, "text=", text, "prefix=", prefix)

            if sender == myName then
                D("  ABORT: это я сам")
                return
            end

            local targetNick = text and text:match("^%s*(.-)%s*$")
            if not targetNick or targetNick == "" then
                D("  ABORT: пустой targetNick")
                return
            end

            local plainTarget = targetNick:match("^(.-)-") or targetNick
            D("  plainTarget=", plainTarget, "plainMe=", plainMe)

            if plainTarget ~= plainMe then
                D("  ABORT: запрос не про меня")
                return
            end

            D("  ЗАПРОС ПРО МЕНЯ — читаю свой ГП из ростора")

            local myGP = 0
            for i = 1, GetNumGuildMembers(true) do
                local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
                if name then
                    local plainName = name:match("^(.-)-") or name
                    if plainName == plainMe then
                        if officerNote and officerNote ~= "" then
                            local words2 = {}
                            for word in officerNote:gmatch("%S+") do
                                table.insert(words2, word)
                            end
                            D("  officerNote words:", words2[1], words2[2], words2[3])
                            if #words2 >= 3 then
                                myGP = tonumber(words2[3]) or 0
                            end
                        end
                        break
                    end
                end
            end

            D("  Мой ГП =", myGP, "— отправляю hisGP в RAID")
            SendAddonMessage("hisGP " .. tostring(myGP), myName, "RAID")
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- 2. enAlToGi
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:enaltoi", {
        func = function(words, sender, text, channel, prefix)
            D(">>> enAlToGi. sender=", sender, "text=", text, "prefix=", prefix)
            if sender == myName then
                D("  ABORT: это я сам")
                return
            end

            local gp = prefix and prefix:match("^%S+%s+(.+)$")
            local nick = text and text:match("^%s*(.-)%s*$")
            D("  gp=", tostring(gp), "nick=", tostring(nick))
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- 3. ns_hisGP
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:ns_hisgp", {
        func = function(words, sender, text, channel, prefix)
            D(">>> ns_hisGP. sender=", sender, "text=", text, "prefix=", prefix)
            if sender == myName then
                D("  ABORT: это я сам")
                return
            end

            local gp = prefix and prefix:match("^%S+%s+(.+)$")
            local nick = text and text:match("^%s*(.-)%s*$")
            D("  gp=", tostring(gp), "nick=", tostring(nick))
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- Ручной вызов диагностики
    -- ========================================================================
    function NSQC4.GP_Debug()
        local function O(msg)
            SendChatMessage("[GP-DBG] " .. msg, "OFFICER")
        end

        O("=== GP DEBUG START ===")

        if not gpDb then
            O("gpDb = nil — окно ГП не создано")
            return
        end

        O("gpDb type: " .. type(gpDb))
        O("IsInRaid: " .. tostring(IsInRaid()))
        O("GetNumGroupMembers: " .. tostring(GetNumGroupMembers()))

        local cache = gpDb.external_gp_cache or {}
        local cacheCount = 0
        for _ in pairs(cache) do cacheCount = cacheCount + 1 end
        O("external_gp_cache: " .. cacheCount .. " записей")
        for nick, gp in pairs(cache) do
            O("  cache[" .. tostring(nick) .. "] = " .. tostring(gp))
        end

        local guildNames = {}
        local guildCount = 0
        for i = 1, GetNumGuildMembers(true) do
            local name = GetGuildRosterInfo(i)
            if name then
                local plain = name:match("^(.-)-") or name
                guildNames[plain] = true
                guildCount = guildCount + 1
            end
        end
        O("В гильдии: " .. guildCount .. " игроков")

        local nonGuild = {}
        for i = 1, GetNumGroupMembers() do
            local raidName = GetRaidRosterInfo(i)
            if raidName then
                local plain = raidName:match("^(.-)-") or raidName
                if not guildNames[plain] then
                    table.insert(nonGuild, plain)
                end
            end
        end

        O("Не из гильдии в рейде: " .. #nonGuild)
        for _, nick in ipairs(nonGuild) do
            local cached = cache[nick]
            O("  " .. nick .. " → cache=" .. tostring(cached))
        end

        if gpDb.gp_data then
            O("gp_data: " .. #gpDb.gp_data .. " строк")
            for i, e in ipairs(gpDb.gp_data) do
                if i > 15 then
                    O("  ... ещё " .. (#gpDb.gp_data - 15))
                    break
                end
                O(string.format("  %d. %s | gp=%s | isGuild=%s | ID=%s",
                    i, tostring(e.original_nick), tostring(e.gp),
                    tostring(e.isGuildMember), tostring(e.playerID)))
            end
        end

        O("Пробуем GetGPA для первого не-гильдейского...")
        if nonGuild[1] then
            SendAddonMessage("GetGPA", nonGuild[1], "GUILD")
            O("  Отправлен GetGPA для: " .. nonGuild[1])
        else
            O("  Нет не-гильдейских игроков в рейде")
        end

        O("=== GP DEBUG END ===")
    end

    D("=== Module READY ===")

end)