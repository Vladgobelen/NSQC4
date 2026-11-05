-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / ContextMenu
-- Отрисовка контекстного меню под мышкой.
--
-- Фрейм меню создаётся ОДИН раз (лениво) и переиспользуется.
-- Список пунктов хранится в self._contextMenuItems и читается InitMenu
-- при каждом показе — поэтому повторные вызовы не плодят фреймы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Показ меню
    -- menuItems = { { text = "Текст", func = function() ... end }, ... }
    -- btn = кнопка (клетка), к которой привязано меню
    -- ========================================================================
    function QuestsField:ShowContextMenu(menuItems, btn)
        if not menuItems or #menuItems == 0 then return end

        -- 1. Фрейм меню — один раз на всё поле
        local menuFrame = self._contextMenuFrame
        if not menuFrame then
            menuFrame = CreateFrame("Frame", "NSQC4ContextMenu", UIParent, "UIDropDownMenuTemplate")
            self._contextMenuFrame = menuFrame
        end

        -- 2. Актуальный список пунктов для текущего показа
        self._contextMenuItems = menuItems

        -- 3. InitMenu читает self._contextMenuItems (не замыкание на аргумент)
        local function InitMenu(_, level)
            local items = self._contextMenuItems
            if not items then return end
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item.text
                info.notCheckable = true
                info.func = function()
                    UIDropDownMenu_Initialize(menuFrame, nil)
                    CloseDropDownMenus()
                    if item.func then item.func() end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(menuFrame, InitMenu)
        ToggleDropDownMenu(1, nil, menuFrame, btn, 0, 0)
    end
end)