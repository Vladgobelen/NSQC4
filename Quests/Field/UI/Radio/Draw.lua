-- ============================================================================
-- NSQC4 / Quests / Field / UI / Radio / Draw
-- Одна логика: раскладка кнопок радио-группы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    local RADIO_H, RADIO_GAP, MARGIN, ICON_W, ICON_GAP = 24, 6, 8, 24, 12

    function W:DrawRadio(windowId, rec, y, availableW)
        local win = self[windowId]
        if not win then return 0 end
        local btns = self:EnsureRadioGroup(windowId, rec.groupId)
        if not btns then return 0 end
        local grp = self._radioGroups[windowId][rec.groupId]
        if not grp then return 0 end

        local align = grp.align or "LEFT"
        local winW = win:GetWidth()
        local n = 0
        for _, opt in ipairs(grp.options or {}) do
            if btns[opt.value] then n = n + 1 end
        end
        local totalW = ICON_W * n + (n > 1 and ICON_GAP * (n - 1) or 0)

        local x = (align == "CENTER") and (winW - totalW) / 2
               or (align == "RIGHT") and (winW - MARGIN - totalW)
               or MARGIN

        for _, opt in ipairs(grp.options or {}) do
            local rb = btns[opt.value]
            if rb then
                rb:ClearAllPoints()
                rb:SetPoint("TOPLEFT", win, "TOPLEFT", x, y)
                rb:Show()
                x = x + ICON_W + ICON_GAP
            end
        end
        return RADIO_H + RADIO_GAP
    end
end, 554)