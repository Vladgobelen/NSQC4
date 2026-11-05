-- ============================================================================
-- NSQC4 / Quests / df / Actions / Terrain / Pool / LeftClickEntities
-- Действие ЛКМ по существу в клетке с "pool".
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local A = NSQC4.QuestsDfTerrainActions
    if not A then
        print("|cffff0000[NSQC4]|r Pool/LeftClickEntities: Init.lua не загружен.")
        return
    end

    A.Types["pool"] = A.Types["pool"] or {}

    A.Types["pool"].LeftClickEntities = function(index)
        index = tonumber(index) or 0
        if index < 1 then return false end

        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end

        local entity = Grid:GetEntity(index)
        if not entity or not entity.opts then return false end

        if entity.opts.sleeping then return false end

        entity.opts.expanded = not entity.opts.expanded

        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and Animate:IsAnimating(entity.id) then
            Animate:SetExpanded(entity.id, entity.opts.expanded)
        else
            local Entities = NSQC4.QuestsDfEntities
            if Entities then
                Entities:Spawn(entity.id, index, entity.opts)
            end
        end

        print(string.format("|cff00ff00[NSQC4]|r %s: %s",
            entity.opts.name or "Существо",
            entity.opts.expanded and "развёрнут" or "свёрнут"))

        return true
    end

end)