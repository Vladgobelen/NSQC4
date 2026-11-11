-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Mouse
-- Одна логика: регистрация обработчика мыши для кнопок панелей.
--
--   event "up"   → OnMouseUp()  (ReleaseTexture)
--   event "down" → HitPanelButton → LeftButton:   OnPanelButtonClick
--                                    MiddleButton: ToggleTooltipButton
--
-- НЕ рисует, НЕ создаёт, НЕ хит-тестит (это делают Draw / Hit / Click).
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local field = NSQC4.Field
    if not field then return end

    field:AddMouseHandler(function(x, y, button, event)
        -- Отпускание мыши — снять анимацию нажатия.
        -- Возвращаем false, чтобы другие обработчики (свитчеры) тоже
        -- могли снять свою анимацию.
        if event == "up" then
            field:OnMouseUp()
            return false
        end

        if event ~= "down" then return false end

        local rec = field.HitPanelButton and field:HitPanelButton(x, y)
        if rec then
            if button == "MiddleButton" then
                field:ToggleTooltipButton(rec)
            elseif button == "LeftButton" then
                field:OnPanelButtonClick(rec, button)
            end

            return true  -- событие поглощено
        end

        return false
    end)
end, 468)