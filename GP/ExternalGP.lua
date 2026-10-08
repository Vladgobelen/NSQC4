-- ============================================================================
-- NSQC4 / GP / ExternalGP
-- Система обмена ГП не-гильдейских игроков.
-- Префиксы:
--   GetGPA   — запрос ГП (шлётся в GUILD)
--   showGPA  — ретрансляция запроса (в RAID)
--   hisGP    — ответ игрока на showGPA (в RAID)
--   enAlToGi — ретрансляция ответа (в GUILD)
--   ns_hisGP — прямой ответ (когда сервер сам нашёл ГП в гильдии)
-- Модуль: gp.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    local myName = UnitName("player") or ""
    local plainMe = myName:match("^(.-)-") or myName

    -- ========================================================================
    -- Сохранить ГП в кэш (с защитой от перезаписи нулём)
    -- ========================================================================
    local function SaveExternalGp(gpStr, nick)
        if not gpStr or not nick or nick == "" then return end

        local gp = tonumber(gpStr)
        if not gp then gp = 0 end

        local cleanNick = nick:match("^(.-)-") or nick

        if gpDb and gpDb.SetExternalGp then
            local oldGp = gpDb.GetExternalGp and gpDb:GetExternalGp(cleanNick) or nil
            if oldGp and oldGp ~= 0 and gp == 0 then
                return
            end
            gpDb:SetExternalGp(cleanNick, gp)
        end

        if gpDb and gpDb.UpdateGpEntry then
            gpDb:UpdateGpEntry(cleanNick, gp)
        end
    end

    -- ========================================================================
    -- 1. showGPA — если запрос про нас, отвечаем своим ГП в RAID
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:showgpa", {
        func = function(words, sender, text, channel, prefix)
            if sender == myName then return end

            local targetNick = text and text:match("^%s*(.-)%s*$")
            if not targetNick or targetNick == "" then return end

            local plainTarget = targetNick:match("^(.-)-") or targetNick
            if plainTarget ~= plainMe then return end

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
                            if #words2 >= 3 then
                                myGP = tonumber(words2[3]) or 0
                            end
                        end
                        break
                    end
                end
            end

            SendAddonMessage("hisGP " .. tostring(myGP), myName, "RAID")
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- 2. enAlToGi — сохраняем полученный ГП
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:enaltoi", {
        func = function(words, sender, text, channel, prefix)
            if sender == myName then return end

            local gp = prefix and prefix:match("^%S+%s+(.+)$")
            local nick = text and text:match("^%s*(.-)%s*$")
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- 3. ns_hisGP — прямой ответ сервера
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:ns_hisgp", {
        func = function(words, sender, text, channel, prefix)
            if sender == myName then return end

            local gp = prefix and prefix:match("^%S+%s+(.+)$")
            local nick = text and text:match("^%s*(.-)%s*$")
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

end)