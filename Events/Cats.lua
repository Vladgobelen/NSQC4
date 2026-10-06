-- ============================================================================
-- NSQC4 / Events / Cats
-- Репортер: при смене цели отправляет GUID и имя цели в гильд-чат.
-- Модуль: events_cats.
-- ============================================================================

NSQC4.RegisterModule("events_cats", function()

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:SetScript("OnEvent", function()
        local guid = UnitGUID("target")
        if not guid then
            return
        end

        local name = UnitName("target") or "?"
        SendAddonMessage("itsCat " .. name, guid, "GUILD")
    end)

end)