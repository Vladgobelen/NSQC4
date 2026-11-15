-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Border / Visible
-- Одна логика: показ/скрытие линий сетки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- Скрывает или показывает все линии (v + h)
    function QuestsField:SetGridLinesVisible(show)
        local lines = self.gridLines
        if not lines then return end

        for _, tex in ipairs(lines.v) do
            if show then tex:Show() else tex:Hide() end
        end
        for _, tex in ipairs(lines.h) do
            if show then tex:Show() else tex:Hide() end
        end
    end

end, 342)