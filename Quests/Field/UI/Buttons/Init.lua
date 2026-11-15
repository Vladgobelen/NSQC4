-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Init
-- Одна логика: namespace универсального рендерера кнопок.
--
-- НИЧЕГО не знает о поле (QuestsField) и об окнах (FieldWindow).
-- Рисует кнопки на любом parent-фрейме, где скажут.
--
-- Публичный API (NSQC4.UIButton):
--   CreateRecord(label, onClick, opts)       → rec    (Widget/Create.lua)
--   Draw(parent, rec, y, availableW)         → height (Widget/Draw.lua)
--   Press(rec)                                       (Widget/Press.lua)
--   Release()                                        (Widget/Press.lua)
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    NSQC4.UIButton = NSQC4.UIButton or {}
end, 530)