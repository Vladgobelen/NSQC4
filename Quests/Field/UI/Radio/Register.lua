-- ============================================================================
-- NSQC4 / Quests / Field / UI / Radio / Register
-- Одна логика: регистрация радио-группы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    function W:RegisterRadioGroup(windowId, index, groupId, options, onSelect, opts)
        index = tonumber(index)
        if not windowId or not index or not groupId then return nil end
        opts = opts or {}

        self._radioGroups = self._radioGroups or {}
        self._radioGroups[windowId] = self._radioGroups[windowId] or {}
        if self._radioGroups[windowId][groupId] then
            return self._radioGroups[windowId][groupId]
        end

        self._radioGroups[windowId][groupId] = {
            groupId   = groupId,
            options   = options,
            onSelect  = onSelect,
            align     = opts.align or "LEFT",
            direction = opts.direction or "HORIZONTAL",
        }

        self._items = self._items or {}
        local items = self._items[windowId]
        if not items then items = {}; self._items[windowId] = items end

        if not items[index] then
            items[index] = { kind = "radio", groupId = groupId }
        end

        if self[windowId] and self.LayoutWindow then
            self:LayoutWindow(windowId)
        end
        return self._radioGroups[windowId][groupId]
    end
end, 551)