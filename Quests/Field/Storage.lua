-- ============================================================================
-- NSQC4 / Quests / Field / Storage
-- Хранилище nsDbc4.quests.field + API флага и шаблона заполнения.
-- Модуль: quests.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Гарантирует, что таблица существует
    -- ========================================================================
    function QuestsField:EnsureStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.field = nsDbc4.quests.field or {}
        return nsDbc4.quests.field
    end

    -- ========================================================================
    -- Загрузка из nsDbc4 → self
    -- ========================================================================
    function QuestsField:Load()
        local s = self:EnsureStorage()
        self.saved = {
            x             = s.x,
            y             = s.y,
            cellSize      = s.cellSize,
            borderVisible = s.borderVisible,
        }
    end

    -- ========================================================================
    -- Сохранение self → nsDbc4
    -- ========================================================================
    function QuestsField:Save()
        local s = self:EnsureStorage()

        if self.frame then
            s.x = self.frame:GetLeft()
            s.y = self.frame:GetBottom()
        end

        if self.cellSize then
            s.cellSize = self.cellSize
        end

        s.borderVisible = self.borderVisible and true or false
    end

    -- ========================================================================
    -- API: флаг «поле заполнено» — един на всё поле
    -- ========================================================================
    function QuestsField:IsFilled()
        local s = self:EnsureStorage()
        return s.filled and true or false
    end

    function QuestsField:SetFilled(v)
        local s = self:EnsureStorage()
        s.filled = v and true or false
    end

    -- ========================================================================
    -- API: шаблон заполнения поля
    -- ========================================================================
    function QuestsField:GetFillTemplate()
        local s = self:EnsureStorage()
        return s.template
    end

    function QuestsField:SetFillTemplate(tpl)
        local s = self:EnsureStorage()
        s.template = tpl
        return s.template
    end

end)