-- ============================================================================
-- NSQC4 / Quests / Field / Settings / Init
-- Одна логика: регистрация кнопки «Настройки» на панели LEFT.
--
-- НЕ создаёт окно, НЕ регистрирует контент, НЕ реализует мышь окна.
-- Мышь окна — в UI/Window/API/Mouse/*:
--   W:SetupWindowMouse(win)          (497)
--   W:AddWindowMouseHandler(win, fn) (494)
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local W           = NSQC4.FieldWindow
    if not QuestsField or not W then return end

    local field = NSQC4.Field
    if not field then return end

    field:RegisterButton(
        "LEFT", 1, 1,
        "Interface\\Icons\\INV_Misc_Gear_01",
        function(button)
            if button ~= "LeftButton" then return end

            W:Register({
                id     = "settings",
                side   = "LEFT",
                width  = 260,
                height = "FIELD",
            })

            local win = W["settings"]
            if win and W.SetupWindowMouse then
                W:SetupWindowMouse(win)
            end

            W:Toggle("settings")
        end,
        {
            tooltip = "Настройки поля",
            color   = { 1, 0.82, 0, 1 },
            visible = 1,
        }
    )
end, 570)