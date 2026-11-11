-- ============================================================================
-- NSQC4 / Guild / KickInactive
-- ============================================================================

NSQC4.RegisterModule("kick", function()

    -- ---- Отладка ----------------------------------------------------------
    local function D(...)
        if NSQC4.Debug then
            NSQC4.Debug("[kick] " .. table.concat({...}, " "))
        else
            print("|cff80c0ff[kick]|r " .. table.concat({...}, " "))
        end
    end

    local KICK_REQUIRED_DAYS = {
        [29] = 3, [39] = 3, [49] = 4, [59] = 5,
        [69] = 6, [79] = 7, [999] = 14,
    }

    local KICK_ALLOWED_RANKS = {
        ["и.о. констебля"] = true,
        ["мл. констебль"]  = true,
    }

    -- ========================================================================
    local function ShouldKick(rankName, level, publicNote, officerNote, days)
        rankName    = rankName    or ""
        publicNote  = publicNote  or ""
        officerNote = officerNote or ""

        if not KICK_ALLOWED_RANKS[rankName:lower()] then
            D("skip rank:", rankName)
            return false
        end
        if publicNote ~= "" then
            D("skip pubnote:", publicNote)
            return false
        end

        if officerNote ~= "" then
            local of1, of3 = string.match(officerNote, "^%s*(%S+)%s+%S+%s+(%S+)%s*$")
            if not (of1 and of3 and tonumber(of1) == 0 and tonumber(of3) == 0) then
                D("skip ofnote:", officerNote)
                return false
            end
        end

        local lvl = tonumber(level)
        if not lvl then D("skip lvl:", tostring(level)); return false end

        local required
        for maxLvl, daysReq in pairs(KICK_REQUIRED_DAYS) do
            if lvl <= maxLvl then required = daysReq; break end
        end
        if not required then D("skip no-threshold lvl:", lvl); return false end
        if days < required then
            D("skip days:", days, "<", required, "(lvl", lvl .. ")")
            return false
        end

        D("MATCH rank=", rankName, "lvl=", lvl, "days=", days)
        return true
    end

    -- ========================================================================
    local function PlayerExistsInGuild(nick)
        local target = (nick or ""):lower()
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i)
            if name and name:lower() == target then
                D("found:", name, "==", nick)
                return true
            end
            if name and name:lower():match("^" .. target .. "%-") then
                D("found (base match):", name, "~", nick)
                return true
            end
        end
        D("NOT found:", nick)
        return false
    end

    -- ========================================================================
    local function CollectCandidates()
        local list, total, checked = {}, GetNumGuildMembers(), 0
        D("CollectCandidates: total members =", total)
        for i = 1, total do
            local name, rankName, _, level, _, _, publicNote, officerNote = GetGuildRosterInfo(i)
            if name and rankName and level then
                checked = checked + 1
                local y, m, d = GetGuildRosterLastOnline(i)
                local days = (y or 0) * 365 + (m or 0) * 30 + (d or 0)
                if ShouldKick(rankName, level, publicNote, officerNote, days) then
                    D("candidate:", name, "rank=", rankName, "lvl=", level, "days=", days)
                    table.insert(list, {
                        name = name, rank = rankName, level = level, days = days,
                        publicNote = publicNote or "", officerNote = officerNote or "",
                    })
                end
            else
                D("skip slot", i, "name=", tostring(name),
                  "rank=", tostring(rankName), "lvl=", tostring(level))
            end
        end
        D("CollectCandidates: checked=", checked, "candidates=", #list)
        return list
    end

    -- ========================================================================
    local function StartKickSequence(candidates)
        D("StartKickSequence: count =", #candidates)
        local idx = 1
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame:SetScript("OnUpdate", function(self, dt)
            self.elapsed = self.elapsed + dt
            if self.elapsed < 0.1 then return end
            self.elapsed = 0

            local c = candidates[idx]
            if not c then
                D("kick sequence done")
                self:SetScript("OnUpdate", nil)
                return
            end

            D("KICK:", c.name, "rank=", c.rank, "lvl=", c.level, "days=", c.days,
              "pub='" .. tostring(c.publicNote) .. "' of='" .. tostring(c.officerNote) .. "'")
            GuildUninvite(c.name)
            SendChatMessage(string.format(
                "[gKick] %s (%s, ур.%s, %s дн) Пуб:'%s' Оф:'%s' - КИКНУТ",
                c.name, c.rank, c.level, c.days, c.publicNote, c.officerNote
            ), "OFFICER")

            idx = idx + 1
        end)
    end

    -- ========================================================================
    function NSQC4.RunGuildKick(words, sender, text, channel, prefix)
        D("=== RunGuildKick ===")
        D("words=", tostring(words and #words), "sender=", tostring(sender),
          "text=", tostring(text), "channel=", tostring(channel), "prefix=", tostring(prefix))
        D("player=", tostring(UnitName("player")), "inGuild=", tostring(IsInGuild()))

        if sender ~= UnitName("player") then
            D("abort: sender mismatch")
            return
        end
        if not IsInGuild() then
            D("abort: not in guild")
            return
        end

        local targetNick = words and words[2]
        D("targetNick raw =", tostring(targetNick))
        if targetNick and targetNick ~= "" then
            targetNick = targetNick:match("^([^%-]+)") or targetNick
            D("targetNick clean =", targetNick)
        end

        -- === РЕЖИМ 1 ===
        if targetNick and targetNick ~= "" then
            D("mode: single ->", targetNick)
            if not PlayerExistsInGuild(targetNick) then
                print("|cffff8080[NSQC4]|r Игрок " .. targetNick .. " не найден в гильдии.")
                return
            end
            GuildUninvite(targetNick)
            SendChatMessage(string.format("[gKick] %s — КИКНУТ (вручную)", targetNick), "OFFICER")
            return
        end

        -- === РЕЖИМ 2 ===
        D("mode: mass")
        local memberCount = GetNumGuildMembers()
        D("GetNumGuildMembers =", memberCount)
        if memberCount == 0 then
            D("roster empty -> request GuildRoster()")
            GuildRoster()
            local f = CreateFrame("Frame")
            f:RegisterEvent("GUILD_ROSTER_UPDATE")
            f:SetScript("OnEvent", function(self, _, isFullUpdate)
                D("GUILD_ROSTER_UPDATE isFullUpdate=", tostring(isFullUpdate),
                  "members=", GetNumGuildMembers())
                self:UnregisterEvent("GUILD_ROSTER_UPDATE")
                if isFullUpdate then
                    local list = CollectCandidates()
                    if #list > 0 then
                        StartKickSequence(list)
                    else
                        print("|cff00ff00[NSQC4]|r Нет кандидатов на кик.")
                    end
                else
                    D("not full update, ignored")
                end
            end)
            return
        end

        local list = CollectCandidates()
        if #list > 0 then
            StartKickSequence(list)
        else
            print("|cff00ff00[NSQC4]|r Нет кандидатов на кик.")
        end
    end

    -- ========================================================================
    -- Обёртка триггера с логом входа
    -- ========================================================================
    NSQC4.ChatHandler:Register("GUILD:-кик", {
        func = function(words, sender, text, channel, prefix)
            D("TRIGGER fired | words=", tostring(words and table.concat(words, "|")),
              "sender=", tostring(sender), "channel=", tostring(channel),
              "prefix=", tostring(prefix))
            return NSQC4.RunGuildKick(words, sender, text, channel, prefix)
        end,
        stopOnMatch = true,
    })

    D("module 'kick' registered, trigger GUILD:-кик ready")

    NSQC4.SetModuleMeta("kick", {
        label   = "Кик неактивных",
        tooltip = "Команда «-кик [Ник]» в гильд-чате. Без ника — массовый кик неактивных по критериям (звание, заметки, офлайн).",
        order   = 100,
    })

end)