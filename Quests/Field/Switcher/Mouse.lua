-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Mouse
-- Одна логика: регистрация обработчика мыши для свитчеров панелей.
--
--   event "up"   → ничего не делаем (анимацию снимает Buttons/Mouse.lua
--                  через field:OnMouseUp() → ReleaseTexture)
--   event "down" → HitSwitcher → MiddleButton: ToggleTooltipSwitcher
--                               → LeftButton / RightButton:
--                                   PressTexture + OnSwitcherClick
--
-- НЕ рисует (это делает Draw.lua).
-- НЕ создаёт текстуры (это делает Init.lua).
-- НЕ хит-тестит (это делает Click.lua).
-- Анимация нажатия — через Press.lua (PressTexture / ReleaseTexture).
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local field = NSQC4.Field
    if not field then return end

    field:AddMouseHandler(function(x, y, button, event)
        -- Отпускание мыши — анимацию уже снял Buttons/Mouse.lua
        -- через field:OnMouseUp() → ReleaseTexture().
        -- Возвращаем false, чтобы не блокировать другие обработчики.
        if event == "up" then
            return false
        end

        if event ~= "down" then return false end

        local sw = field.HitSwitcher and field:HitSwitcher(x, y)
        if sw then
            if button == "MiddleButton" then
                field:ToggleTooltipSwitcher(sw)
            else
                field:PressTexture(sw.texture)
                field:OnSwitcherClick(sw, button)
            end

            return true  -- событие поглощено
        end

        return false
    end)
end, 620)