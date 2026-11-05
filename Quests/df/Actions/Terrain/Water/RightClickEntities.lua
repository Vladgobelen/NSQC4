-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Water / RightClickEntities
-- ПКМ по воде — пока ПУСТОЙ (по ТЗ).
--
-- Меню не показываем. Клик правой кнопкой по клетке воды снимается
-- (SetCellOnMouseClick(index, "RightButton", nil)), чтобы старый обработчик
-- (если клетка раньше была другим ландшафтом) не сработал.
--
-- Сюда позже добавятся пункты: «Нырнуть», «Построить мост», «Осмотреть дно»
-- и т.п. — через QuestsField:ShowContextMenu(menuItems, btn), как в
-- Earth/RightClickEntities.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Water/RightClickEntities: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    A.Types["water"] = A.Types["water"] or {}

    A.Types["water"].RightClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        -- Клик не вешаем — ПКМ по воде ничего не делает.
        QuestsField:SetCellOnMouseClick(index, "RightButton", nil)

        return true
    end

end)