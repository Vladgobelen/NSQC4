-- ============================================================================
-- NSQC4 / Guild / KickInactive
-- Команда: "-кик [Ник]" в гильд-чате
-- Без ника — кикает всех неактивных по критериям (звание + заметки + офлайн).
-- С ником — кикает указанного БЕЗ проверок (офицер знает, что делает).
-- ============================================================================

NSQC4 = NSQC4 or {}

-- Пороги дней офлайна: [макс.уровень] = требуемые_дни
local KICK_REQUIRED_DAYS = {
    [29] = 3, [39] = 3, [49] = 4, [59] = 5,
    [69] = 6, [79] = 7, [999] = 14,
}

-- Разрешённые звания для кика (в нижнем регистре)
local KICK_ALLOWED_RANKS = {
    ["и.о. констебля"] = true,
    ["мл. констебль"]  = true,
}

-- ============================================================================
-- Проверка: кикать ли игрока (только для массового режима)
-- ============================================================================
local function ShouldKick(rankName, level, publicNote, officerNote, days)
    if not KICK_ALLOWED_RANKS[rankName:lower()] then return false end
    if publicNote ~= "" then return false end

    if officerNote ~= "" then
        local of1, of3 = string.match(officerNote, "^%s*(%S+)%s+%S+%s+(%S+)%s*$")
        if not (of1 and of3 and tonumber(of1) == 0 and tonumber(of3) == 0) then
            return false
        end
    end

    local lvl = tonumber(level)
    if not lvl then return false end

    local required
    for maxLvl, daysReq in pairs(KICK_REQUIRED_DAYS) do
        if lvl <= maxLvl then required = daysReq; break end
    end
    if not required or days < required then return false end

    return true
end

-- ============================================================================
-- Проверка: есть ли игрок в гильдии
-- ============================================================================
local function PlayerExistsInGuild(nick)
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name == nick then return true end
    end
    return false
end

-- ============================================================================
-- Сбор кандидатов (только для массового режима)
-- ============================================================================
local function CollectCandidates()
    local list = {}
    for i = 1, GetNumGuildMembers() do
        local name, rankName, _, level, _, _, publicNote, officerNote = GetGuildRosterInfo(i)
        if name and rankName and level then
            local y, m, d = GetGuildRosterLastOnline(i)
            local days = (y or 0) * 365 + (m or 0) * 30 + (d or 0)
            if ShouldKick(rankName, level, publicNote, officerNote, days) then
                table.insert(list, {
                    name = name, rank = rankName, level = level, days = days,
                    publicNote = publicNote or "", officerNote = officerNote or "",
                })
            end
        end
    end
    return list
end

-- ============================================================================
-- Кик с тротлингом (для массового режима)
-- ============================================================================
local function StartKickSequence(candidates)
    local idx = 1
    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed < 0.1 then return end
        self.elapsed = 0

        local c = candidates[idx]
        if not c then
            self:SetScript("OnUpdate", nil)
            return
        end

        GuildUninvite(c.name)
        SendChatMessage(string.format(
            "[gKick] %s (%s, ур.%s, %s дн) Пуб:'%s' Оф:'%s' - КИКНУТ",
            c.name, c.rank, c.level, c.days, c.publicNote, c.officerNote
        ), "OFFICER")

        idx = idx + 1
    end)
end

-- ============================================================================
-- КОРНЕВАЯ ФУНКЦИЯ
-- ============================================================================
function NSQC4.RunGuildKick(words, sender, text, channel, prefix)
    if sender ~= UnitName("player") then return end
    if not IsInGuild() then return end

    local targetNick = words[2]
    if targetNick and targetNick ~= "" then
        targetNick = targetNick:match("^([^%-]+)") or targetNick
    end

    -- === РЕЖИМ 1: конкретный игрок ===
    if targetNick then
        if not PlayerExistsInGuild(targetNick) then
            print("|cffff8080[NSQC4]|r Игрок " .. targetNick .. " не найден в гильдии.")
            return
        end
        GuildUninvite(targetNick)
        SendChatMessage(string.format("[gKick] %s — КИКНУТ (вручную)", targetNick), "OFFICER")
        return
    end

    -- === РЕЖИМ 2: массовый кик ===
    if GetNumGuildMembers() == 0 then
        GuildRoster()
        local f = CreateFrame("Frame")
        f:RegisterEvent("GUILD_ROSTER_UPDATE")
        f:SetScript("OnEvent", function(self, _, isFullUpdate)
            self:UnregisterEvent("GUILD_ROSTER_UPDATE")
            if isFullUpdate then
                local list = CollectCandidates()
                if #list > 0 then StartKickSequence(list) end
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

-- ============================================================================
-- РЕГИСТРАЦИЯ ТРИГГЕРА
-- ============================================================================
NSQC4.ChatHandler:Register("GUILD:-кик", {
    func = NSQC4.RunGuildKick,
    stopOnMatch = true,
})