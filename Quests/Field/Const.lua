-- ============================================================================
-- NSQC4 / Quests / Field / Const
-- Одна логика: константы поля. Никаких функций.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    NSQC4.QuestsFieldConst = {
        COLS           = 10,
        ROWS           = 10,
        CELL_GAP       = 0,
        GRID_PADDING   = 40,
        DEFAULT_CELL   = 32,
        MIN_CELL       = 10,
        MAX_CELL       = 128,
        SAVE_KEY       = "questsField",
        SCREEN_PERCENT = 0.9,
    }

end, 160)