NSQC4_VERSION = {
    major = 1,
    minor = 22,
    code  = "NSQC4",
}

NSQC4_LAST_VERSION = nil
local versionChecked = false

local myName = UnitName("player")

local verFrame = CreateFrame("Frame")
verFrame:RegisterEvent("CHAT_MSG_ADDON")
verFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix == "NSQC4Vers" then
        SendAddonMessage("NSQC4_VER_RESP", NSQC4_VERSION.major .. ":" .. NSQC4_VERSION.minor, channel)

    elseif prefix == "NSQC4LastVers" then
        local nick, major, minor = msg:match("^([^:]+):(%d+):(%d+)$")
        if nick and major and minor and nick == myName and not versionChecked then
            versionChecked = true
            NSQC4_LAST_VERSION = { major = tonumber(major), minor = tonumber(minor) }

            if NSQC4_LAST_VERSION.major ~= NSQC4_VERSION.major
            or NSQC4_LAST_VERSION.minor ~= NSQC4_VERSION.minor then
                SendChatMessage("Мой аддон устарел, нужно обновить", "OFFICER")
            else
                if NSQC4.Settings.IsModuleEnabled("version_officer") then
                    SendChatMessage("Версия аддона актуальна", "OFFICER")
                else
                    SendAddonMessage("ns_NSQC4_vers", "Версия аддона актуальна", "GUILD")
                end
            end
        end
    end
end)

local initTimer = CreateFrame("Frame")
local initElapsed = 0
initTimer:SetScript("OnUpdate", function(self, dt)
    initElapsed = initElapsed + dt
    if initElapsed >= 3 then
        self:SetScript("OnUpdate", nil)
        SendAddonMessage("NSQC4GiveMeVers", "", "GUILD")
    end
end)