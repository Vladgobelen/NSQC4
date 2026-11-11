-- ============================================================================
-- NSQC4 / Quests / Field / Window / Init
-- Одна логика: namespace + константы окон, привязанных к полю.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    NSQC4.FieldWindow = NSQC4.FieldWindow or {}

    NSQC4.FieldWindowConst = {
        DEFAULT_WIDTH   = 220,
        GAP             = 8,
        FRAME_LEVEL_ADD = 20,
    }

end, 480)