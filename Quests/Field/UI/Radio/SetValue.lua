-- ============================================================================
-- NSQC4 / Quests / Field / UI / Radio / SetValue
-- Одна логика: установка значения радио-группы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:SetRadioValue(windowId, groupId, value)
        local grp = self._radioGroups and self._radioGroups[windowId] and self._radioGroups[windowId][groupId]
        if not grp then return end
        if grp._buttons then
            for v, btn in pairs(grp._buttons) do btn:SetChecked(v == value) end
        end
        if grp.onSelect then grp.onSelect(value) end
    end
end, 552)