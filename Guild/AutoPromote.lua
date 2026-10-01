local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("promote") then return end












NSQC4 = NSQC4 or {}
if not NSQC4.Settings.IsModuleEnabled("promote") then return end

-- ============================================================================
-- NSQC4 / Guild / AutoPromote
-- Команда: "-повысить [Ник]" в гильд-чате
-- Без ника — повышает всех "И.О. Констебля" без заметок (или с "0 X 0"),
--            с защитой от двойного повышения в одной сессии.
-- С ником — повышает указанного БЕЗ проверок и БЕЗ защиты (офицер знает, что делает).
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.promotedThisSession = NSQC4.promotedThisSession or {}

local PROMOTE_RANK = "и.о. констебля"

-- ============================================================================
-- Проверка офицерской заметки (только для массового режима)
-- ============================================================================
local function IsOfficerNoteEmpty(officerNote)
    if not officerNote or officerNote == "" then return true end
    local of1, of3 = string.match(officerNote, "^%s*(%S+)%s+%S+%s+(%S+)%s*$")
    if of1 and of3 and tonumber(of1) == 0 and tonumber(of3) == 0 then
        return true
    end
    return false
end

-- ============================================================================
-- Проверка существования игрока в гильдии
-- ============================================================================
local function PlayerExistsInGuild(nick)
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name == nick then return true end
    end
    return false
end

-- ============================================================================
-- КОРНЕВАЯ ФУНКЦИЯ
-- ============================================================================
function NSQC4.RunAutoPromote(words, sender, text, channel, prefix)
    if sender ~= UnitName("player") then return end
    if not IsInGuild() then return end

    local targetNick = words[2]
    if targetNick and targetNick ~= "" then
        targetNick = targetNick:match("^([^%-]+)") or targetNick
    end

    -- === РЕЖИМ 1: конкретный игрок (без проверок и защиты) ===
    if targetNick then
        if not PlayerExistsInGuild(targetNick) then
            print("|cffff8080[NSQC4]|r Игрок " .. targetNick .. " не найден в гильдии.")
            return
        end
        GuildPromote(targetNick)
        NSQC4.promotedThisSession[targetNick] = true
        SendChatMessage(string.format("[gPromote] %s — ПОВЫШЕН (вручную)", targetNick), "OFFICER")
        return
    end

    -- === РЕЖИМ 2: массовое повышение (с проверками и защитой) ===
    local promoted = 0
    local list = NSQC4.promotedThisSession

    for i = 1, GetNumGuildMembers() do
        local name, rankName, _, _, _, _, publicNote, officerNote = GetGuildRosterInfo(i)
        if name and rankName and rankName:lower() == PROMOTE_RANK then
            if not list[name] then
                if publicNote == "" and IsOfficerNoteEmpty(officerNote) then
                    GuildPromote(name)
                    list[name] = true
                    promoted = promoted + 1
                end
            end
        end
    end

    if promoted > 0 then
        SendChatMessage(string.format("[gPromote] Повышено: %d", promoted), "OFFICER")
    else
        print("|cff00ff00[NSQC4]|r Нет кандидатов на повышение.")
    end
end

-- ============================================================================
-- РЕГИСТРАЦИЯ ТРИГГЕРА
-- ============================================================================
NSQC4.ChatHandler:Register("GUILD:-повысить", {
    func = NSQC4.RunAutoPromote,
    stopOnMatch = true,
})








end -- конец функции настроек

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)