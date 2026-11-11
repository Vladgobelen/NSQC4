-- ============================================================================
-- NSQC4 / Quests / Field / UI / Label / Init
-- Регистрация лейблов. opts.align = "LEFT" | "CENTER" | "RIGHT".
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local W = NSQC4.FieldWindow
    if not W then return end

    function W:RegisterLabel(windowId, index, title, desc, opts)
        index = tonumber(index)
        if not windowId or not index then return nil end

        self._items = self._items or {}
        local items = self._items[windowId]
        if not items then items = {}; self._items[windowId] = items end
        if items[index] then return items[index] end

        opts = opts or {}

        items[index] = {
            kind  = "label",
            title = title,
            desc  = (desc and desc ~= "") and desc or nil,
            opts  = opts,
            align = opts.align or "LEFT",
        }

        if self[windowId] and self.LayoutWindow then
            self:LayoutWindow(windowId)
        end
        return items[index]
    end

end, 510)