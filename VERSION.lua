NSQC4_VERSION = {
    major = 1,
    minor = 0,
    code  = "NSQC4",
}

local verFrame = CreateFrame("Frame")
verFrame:RegisterEvent("CHAT_MSG_ADDON")
verFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix == "NSQC4Vers" then
        SendAddonMessage("NSQC4_VER_RESP", NSQC4_VERSION.major .. ":" .. NSQC4_VERSION.minor, channel)
    end
end)