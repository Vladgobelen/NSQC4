-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Logic / Void
-- Логика пустоты: без onClick/contextMenu (клики — в Actions/Terrain/Void).
-- Регистрирует "void" как тип ландшафта, чтобы он был в реестре GetTypes().
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then return end

    Terrain:RegisterType("void", {
        onClick = function(index)
            -- ничего
        end,
        contextMenu = nil,
    })
end)