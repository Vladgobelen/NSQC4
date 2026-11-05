-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Init
-- Каркас «объекта ландшафта» для регистрации кликов.
--
-- Namespace: NSQC4.QuestsDfTerrainActions
--
-- Подпапки (по типу ландшафта), каждая с четырьмя файлами:
--   Earth/  { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
--   Grass/  { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
--   Stone/  { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
--   Tree/   { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
--   Pool/   { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
--
-- Каждый тип регистрирует себя в реестре:
--   TerrainActions.Types[<id>] = {
--       Check, LeftClickSelf, LeftClickEntities, RightClickEntities
--   }
--
-- Точка входа: TerrainUIApi:RenderCellFromStorage(index) зовёт
--   local T = TerrainActions.Types[terrainId]
--   if T and T.Check and T.Check(index) then
--       T.LeftClickSelf(index)
--       T.RightClickEntities(index)
--   end
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Actions = {}
    NSQC4.QuestsDfTerrainActions = Actions

    -- Реестр типов: id → { Check, LeftClickSelf, LeftClickEntities, RightClickEntities }
    Actions.Types = {}

    -- ========================================================================
    -- Регистрация типа (вызывается из подпапки)
    --   id      — "earth" | "grass" | "stone" | "tree" | "pool"
    --   handler — { Check=fn, LeftClickSelf=fn, LeftClickEntities=fn, RightClickEntities=fn }
    -- ========================================================================
    function Actions:RegisterTypeHandler(id, handler)
        if type(id) ~= "string" or id == "" then return end
        if type(handler) ~= "table" then return end
        self.Types[id] = handler
    end

    function Actions:GetTypeHandler(id)
        return self.Types[id]
    end

    -- ========================================================================
    -- Проверка готовности (ленивая, для диагностики)
    -- ========================================================================
    function Actions:Init()
        local count = 0
        for id, handler in pairs(self.Types) do
            if handler.Check
               and handler.LeftClickSelf
               and handler.LeftClickEntities
               and handler.RightClickEntities then
                count = count + 1
            else
                print("|cffffaa00[NSQC4]|r TerrainActions: тип '" .. id .. "' зарегистрирован неполно.")
            end
        end

        if count == 0 then
            print("|cffffaa00[NSQC4]|r TerrainActions: ни один тип ландшафта не зарегистрирован.")
            return false
        end

        return true
    end

end)