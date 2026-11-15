-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Border / Set
-- Одна логика: установка состояния "borderless".
--
-- 1) Меняет флаг self.borderless
-- 2) Скрывает/показывает линии (SetGridLinesVisible)
-- 3) Пересчитывает геометрию (ReflowCells)
-- 4) Сохраняет флаг в NSDB (SaveFlag)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:SetBorderless(v)
        self.borderless = v and true or false

        -- 1. Видимость линий
        if self.SetGridLinesVisible then
            self:SetGridLinesVisible(not self.borderless)
        end

        -- 2. Пересчёт геометрии (если frame уже создан)
        if self.frame and self.ReflowCells then
            self:ReflowCells()
        end

        -- 3. Сохранение флага
        if self.SaveFlag then
            self:SaveFlag("borderless", self.borderless)
        end
    end

end, 343)