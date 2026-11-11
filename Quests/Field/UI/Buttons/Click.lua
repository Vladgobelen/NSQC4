-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Click
-- Одна логика: клик по кнопкам панелей.
--
--   OnPanelButtonClick(rec, button)  -- ЛКМ: PressTexture + callback
--   OnMouseUp()                      -- ReleaseTexture
--   ToggleTooltipButton(rec)         -- СКМ: тултип-триггер
--
-- НЕ рисует, НЕ создаёт, НЕ регистрирует обработчики мыши.
-- Анимация — через Press.lua (PressTexture / ReleaseTexture).
-- Callbacks — в self._callbacks (Register.lua).
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- OnPanelButtonClick — ЛКМ по кнопке панели.
    --   1) PressTexture (визуал "вдавливания")
    --   2) Вызов callback из self._callbacks[key]
    --
    -- key = "side:panelIndex:slot"
    -- ========================================================================
    function QuestsField:OnPanelButtonClick(rec, button)
        if not rec or not rec.texture then return end

        self:PressTexture(rec.texture)

        local key = rec.side .. ":" .. rec.panelIndex .. ":" .. rec.slot
        local cb  = self._callbacks and self._callbacks[key]

        if cb then
            cb(button)
        end
    end

    -- ========================================================================
    -- OnMouseUp — отпускание мыши (снять анимацию).
    -- ========================================================================
    function QuestsField:OnMouseUp()
        self:ReleaseTexture()
    end

    -- ========================================================================
    -- ToggleTooltipButton — СКМ по кнопке: показать/скрыть тултип.
    --
    -- Повторный СКМ по той же кнопке — скрыть.
    -- СКМ по другой кнопке — переключить тултип на новую.
    -- ========================================================================
    function QuestsField:ToggleTooltipButton(rec)
        if not rec then return end

        if self._tooltipTarget == rec then
            self._tooltipTarget = nil
            GameTooltip:Hide()
            return
        end

        self._tooltipTarget = rec

        local tip = rec.settings.tooltip
            or (rec.settings.opts and rec.settings.opts.tooltip)

        if tip and self.frame then
            GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end
end, 467)