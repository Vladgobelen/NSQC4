-- ============================================================================
-- NSQC4 / Quests / Field / Core / Storage / Defaults
-- Одна логика: значения по умолчанию для поля.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- Дефолтные значения (если в NSDB ничего нет)
    QuestsField.StorageDefaults = {
        borderVisible = true,
        borderless    = false,
        cellSize      = nil,   -- nil = использовать DEFAULT_CELL из Const
        x             = nil,   -- nil = CENTER
        y             = nil,
    }

    -- Хелпер: получить дефолт по ключу
    function QuestsField:GetDefault(key)
        local d = self.StorageDefaults
        return d and d[key] or nil
    end

end, 291)