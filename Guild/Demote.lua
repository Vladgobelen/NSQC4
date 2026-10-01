local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("demote") then return end















NSQC4 = NSQC4 or {}
if not NSQC4.Settings.IsModuleEnabled("demote") then return end

-- ============================================================================
-- NSQC4 / Guild / Demote
-- Команда: "-понизить <Ник>" в гильд-чате
-- Понижает указанного игрока. Без проверок — офицер знает, что делает.
-- Работает только с ником (общего режима нет).
-- ============================================================================

NSQC4 = NSQC4 or {}

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
function NSQC4.RunGuildDemote(words, sender, text, channel, prefix)
    if sender ~= UnitName("player") then return end
    if not IsInGuild() then return end

    local targetNick = words[2]
    if not targetNick or targetNick == "" then
        print("|cffff8080[NSQC4]|r Укажите ник: -понизить Ник")
        return
    end
    targetNick = targetNick:match("^([^%-]+)") or targetNick

    if not PlayerExistsInGuild(targetNick) then
        print("|cffff8080[NSQC4]|r Игрок " .. targetNick .. " не найден в гильдии.")
        return
    end

    GuildDemote(targetNick)
    SendChatMessage(string.format("[gDemote] %s — ПОНИЖЕН", targetNick), "OFFICER")
end

-- ============================================================================
-- РЕГИСТРАЦИЯ ТРИГГЕРА
-- ============================================================================
NSQC4.ChatHandler:Register("GUILD:-принизить", {
    func = NSQC4.RunGuildDemote,
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