-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Click
-- Одна логика: клик по свитчерам панелей + тултип по СКМ.
--
--   HitSwitcher(x, y)           -- хит-тест видимого свитчера
--   OnSwitcherClick(sw, button) -- ЛКМ: следующая панель, ПКМ: предыдущая
--   ToggleTooltipSwitcher(sw)   -- СКМ: показать/скрыть тултип
--
-- НЕ рисует (это делает Draw.lua).
-- НЕ создаёт текстуры (это делает Init.lua).
-- НЕ ловит мышь (это делает Mouse.lua).
-- Анимация нажатия — в Mouse.lua через Press.lua.
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
    -- HitSwitcher — попадание в видимый свитчер.
    -- x, y — координаты курсора в системе frame (BOTTOMLEFT = 0,0).
    -- ========================================================================
    function QuestsField:HitSwitcher(x, y)
        local list = self._switchers
        if not list then return nil end

        local bs = self:GetButtonSize()

        for _, rec in ipairs(list) do
            if rec.texture:IsShown() then
                local cx, cy = self:PanelButtonXY(rec.side, FIRST_CELL[rec.side])
                if cx and x >= cx - bs/2 and x <= cx + bs/2
                       and y >= cy - bs/2 and y <= cy + bs/2 then
                    return rec
                end
            end
        end

        return nil
    end

    -- ========================================================================
    -- OnSwitcherClick — переключение панели.
    --   ЛКМ — следующая панель (dir = +1)
    --   ПКМ — предыдущая панель (dir = -1)
    -- ========================================================================
    function QuestsField:OnSwitcherClick(sw, button)
        if not sw then return end

        if button == "LeftButton" then
            self:SwitchPanel(sw.side, 1)
        elseif button == "RightButton" then
            self:SwitchPanel(sw.side, -1)
        end

        if self.RefreshSwitchers  then self:RefreshSwitchers()  end
        if self.RefreshAllButtons then self:RefreshAllButtons() end
    end

    -- ========================================================================
    -- ToggleTooltipSwitcher — СКМ: показать/скрыть тултип свитчера.
    -- ========================================================================
    function QuestsField:ToggleTooltipSwitcher(sw)
        if not sw then return end

        if self._tooltipTarget == sw then
            self._tooltipTarget = nil
            GameTooltip:Hide()
            return
        end

        self._tooltipTarget = sw

        local tip = sw.settings and sw.settings.tooltip
        if tip and self.frame then
            GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end
end, 615)