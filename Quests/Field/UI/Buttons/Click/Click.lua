-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Click / Click
-- Одна логика: ЛКМ по кнопке панели (PressTexture + callback).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:OnPanelButtonClick(rec, button)
        if not rec or not rec.texture then return end

        self:PressTexture(rec.texture)

        local key = rec.side .. ":" .. rec.panelIndex .. ":" .. rec.slot
        local cb  = self._callbacks and self._callbacks[key]

        if cb then
            cb(button)
        end
    end

end, 467)