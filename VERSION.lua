NSQC4_VERSION = {
    major = 1,
    minor = 0,
    code  = "NSQC4",
}

NSQC4_LAST_VERSION = nil

function NSQC4_VER_RESP(channel, text, sender, prefix)
    local major, minor = text:match("^(%d+):(%d+)$")
    if major and minor then
        print("|cff00ff00[NSQC4]|r " .. sender .. " — версия " .. major .. "." .. minor)
    end
end

local verFrame = CreateFrame("Frame")
verFrame:RegisterEvent("CHAT_MSG_ADDON")
verFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix == "NSQC4Vers" then
        SendAddonMessage("NSQC4_VER_RESP", NSQC4_VERSION.major .. ":" .. NSQC4_VERSION.minor, channel)
    elseif prefix == "NSQC4_VER_RESP" then
        NSQC4_VER_RESP(channel, msg, sender, prefix)
    elseif prefix == "NSQC4LastVers" then
        local major, minor = msg:match("^(%d+):(%d+)$")
        if major and minor then
            NSQC4_LAST_VERSION = { major = tonumber(major), minor = tonumber(minor) }
            if NSQC4_LAST_VERSION.major ~= NSQC4_VERSION.major
            or NSQC4_LAST_VERSION.minor ~= NSQC4_VERSION.minor then
                SendChatMessage("Мой аддон устарел, нужно обновить", "OFFICER")
            else
                SendChatMessage("Версия аддона актуальна", "OFFICER")
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