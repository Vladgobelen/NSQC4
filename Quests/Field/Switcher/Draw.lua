-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Draw
-- Одна логика: отрисовка свитчеров панелей (RefreshSwitchers).
--
-- Видимость свитчера:
--   1 — всегда видима
--   2 — видима при видимой подложке (borderVisible = true)
--   3 — видима при невидимой подложке (borderVisible = false)
--
-- Дополнительно — скрывается, если на текущей панели стороны нет ни одной
-- кнопки (HasPanelButtons(side) == false).
--
-- НЕ создаёт текстуры (это делает Init.lua).
-- НЕ кликает, НЕ ловит мышь (это Click.lua и Mouse.lua).
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local FIRST_CELL = {
        TOP    = 91,
        RIGHT  = 100,
        LEFT   = 91,
        BOTTOM = 1,
    }

    -- ========================================================================
    -- RefreshSwitchers — пересчитать позиции и видимость всех 4 свитчеров.
    -- ========================================================================
    function QuestsField:RefreshSwitchers()
        local list = self._switchers
        if not list then return end

        local f = self.frame
        if not f then return end

        local bs = self:GetButtonSize()

        for _, rec in ipairs(list) do
            local side = rec.side
            local v    = (rec.settings and rec.settings.visible) or 1

            local visibleNow = true
            if v == 2 then
                visibleNow = (self.borderVisible == true)
            elseif v == 3 then
                visibleNow = (self.borderVisible == false)
            end

            -- Скрываем, если на текущей панели стороны нет кнопок
            if visibleNow and not self:HasPanelButtons(side) then
                visibleNow = false
            end

            if visibleNow then
                local cx, cy = self:PanelButtonXY(side, FIRST_CELL[side])
                if cx then
                    rec.texture:ClearAllPoints()
                    rec.texture:SetPoint("CENTER", f, "BOTTOMLEFT", cx, cy)

                    if not self:IsPressed(rec.texture) then
                        rec.texture:SetSize(bs, bs)
                    end
                    rec.texture:Show()
                else
                    rec.texture:Hide()
                end
            else
                rec.texture:Hide()
            end
        end
    end
end, 610)