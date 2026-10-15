NSQC4 = NSQC4 or {}

local TARGET = "\208\159\208\187\208\176\209\135\32\208\178\209\139\209\129\208\190\208\186\208\190\209\128\208\190\208\182\208\180\208\181\208\189\208\189\209\139\209\133"

local TARGETS = {
    [TARGET] = true,
}

local PREFIX  = "nsWarning"
local CHANNEL = "GUILD"
local DEDUP   = 2
local REPEAT  = 30

local lastTime = 0
local seen = {}

NSQC4.RegisterModule("m1", function()

    local f = CreateFrame("Frame")
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    f:SetScript("OnEvent", function(_, event, unit, spellName, spellRank, spellId)
        if event ~= "UNIT_SPELLCAST_SUCCEEDED" then return end
        if not spellName then return end
        if not TARGETS[spellName] then return end

        if not UnitInRaid(unit) then return end

        local now = GetTime()
        if now - lastTime < DEDUP then return end
        lastTime = now

        local who = UnitName(unit)
        if not who then return end

        if seen[who] and (now - seen[who]) < REPEAT then return end
        seen[who] = now

        SendAddonMessage(PREFIX, who, CHANNEL)

        print(("|cffff8000NSQC4|r "..PREFIX.." \226\134\146 %s"):format(who))
    end)

    NSQC4.ChatHandler:Register("ADDON:"..PREFIX:lower(), {
        func = function(words, sender, text, channel, prefix)
            local who = text
            if not who or who == "" then who = sender or "?" end
            print(("|cffff0000[NSQC4 "..PREFIX.."]|r %s"):format(who))
        end,
        stopOnMatch = true,
    })

end)