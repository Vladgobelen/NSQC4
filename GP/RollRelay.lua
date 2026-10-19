-- ============================================================================
-- NSQC4 / GP / RollRelay
-- Ловит ВСЕ роллы в CHAT_MSG_SYSTEM и дублирует их в офицер-чат гильдии.
-- Только свои роллы (ник = UnitName("player")).
-- ============================================================================

NSQC4.RegisterModule("roll_relay", function()

    local DEDUP = 1.5
    local lastMsg, lastTime = nil, 0

    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    local function ParseRoll(msg)
        local name, n = msg:match("(%S+)%s+выбрасывает%s+(%d+)")
        if not name then
            name, n = msg:match("(%S+)%s+rolls%s+(%d+)")
        end
        if not name then return nil end
        local value = tonumber(n)
        if not value then return nil end
        return { name = name, value = value }
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_SYSTEM")

    f:SetScript("OnEvent", function(_, event, msg)
        if event ~= "CHAT_MSG_SYSTEM" then return end
        if not msg or msg == "" then return end

        local roll = ParseRoll(msg)
        if not roll then return end

        -- только свои роллы
        local me = ShortName(UnitName("player"))
        if not me or roll.name ~= me then return end

        local now = GetTime()
        if msg == lastMsg and (now - lastTime) < DEDUP then return end
        lastMsg, lastTime = msg, now

        SendChatMessage(msg, "OFFICER")
    end)

end, {
    label   = "Ролл в офицер-чат",
    tooltip = "Дублирует ваши /roll в офицерский чат гильдии.",
    order   = 60,
})