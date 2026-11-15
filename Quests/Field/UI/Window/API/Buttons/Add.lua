-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Buttons / Add
-- Одна логика: добавить кнопку в окно (запись + перестроить, если окно есть).
--
--   W:AddButton(windowId, index, label, onClick) → rec
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W        = NSQC4.FieldWindow
    local UIButton = NSQC4.UIButton
    if not W or not UIButton then return end

    function W:AddButton(windowId, index, label, onClick)
        local rec = UIButton:CreateRecord(label, onClick)

        self._items = self._items or {}
        local items = self._items[windowId]
        if not items then
            items = {}
            self._items[windowId] = items
        end
        items[index] = rec

        if self[windowId] and self.LayoutWindow then
            self:LayoutWindow(windowId)
        end

        return rec
    end

end, 560)