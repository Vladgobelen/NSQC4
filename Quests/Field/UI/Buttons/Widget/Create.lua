-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Widget / Create
-- Одна логика: создание записи кнопки (без отрисовки).
--
--   UIButton:CreateRecord(label, onClick, opts) → rec
--
-- rec — «сырые» данные. Фрейм/текстура появятся при первом Draw.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local UIButton = NSQC4.UIButton
    if not UIButton then return end

    function UIButton:CreateRecord(label, onClick, opts)
        return {
            kind    = "button",
            label   = label,
            onClick = onClick,
            opts    = opts or {},
        }
    end

end, 531)