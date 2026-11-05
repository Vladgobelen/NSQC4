-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Mouse
-- Абстрактный регистратор кликов мыши на клетке.
-- Ничего не знает ни о ландшафте, ни о существах, ни о хайлайте.
-- API: регистрация действия на конкретную кнопку мыши.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Регистрация клика на конкретную кнопку
    --   index  — номер клетки 1..100
    --   which  — "LeftButton" | "RightButton" | "MiddleButton" | ...
    --   fn     — function(btn, button, index) или nil (снять)
    -- ========================================================================
    function QuestsField:SetCellOnMouseClick(index, which, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        if not btn._mouseHandlers then
            btn._mouseHandlers = {}
        end

        if fn then
            btn._mouseHandlers[which] = fn
        else
            btn._mouseHandlers[which] = nil
        end

        btn:RegisterForClicks("AnyUp")
        btn:SetScript("OnClick", function(self2, button)
            local handler = self2._mouseHandlers and self2._mouseHandlers[button]
            if handler then
                handler(self2, button, index)
            end
        end)
    end

    -- ========================================================================
    -- Снятие клика
    --   index — номер клетки
    --   which — конкретная кнопка (nil = снять все)
    -- ========================================================================
    function QuestsField:ClearCellMouse(index, which)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        if not btn._mouseHandlers then return end

        if which then
            btn._mouseHandlers[which] = nil
        else
            btn._mouseHandlers = {}
        end

        -- Если обработчиков не осталось — снимаем OnClick
        local hasAny = false
        for _ in pairs(btn._mouseHandlers) do hasAny = true; break end
        if not hasAny then
            btn:SetScript("OnClick", nil)
            btn:RegisterForClicks()
        end
    end
end)