-- ============================================================================
-- NSQC4 / Quests / df / AI / Work
-- Один клик работы существа по клетке-цели.
-- Если hardness уже <= 0 — завершение без клика (не «долбим пустую»).
--
-- Прокачка при клике (каждый — отдельный бросок int/10000):
--   tree  → agility + vitality
--   stone → strength + vitality
--   grass → intellect (только)
--   earth → vitality (только)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Work = {}
    NSQC4.QuestsDfAIWork = Work

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Work: Grid не загружен.")
        return
    end

    -- Какой стат (кроме живучести) качать при работе по terrain.
    -- Живучесть качается всегда, кроме grass (там только intellect).
    local TERRAIN_TO_STAT = {
        tree  = { stat = "agility",   vitality = true  },
        stone = { stat = "strength",  vitality = true  },
        grass = { stat = "intellect", vitality = false },
    }

    local function EnsureWork(entity, ai)
        if ai.work and ai.work.total then return ai.work end

        local ProfApi = NSQC4.QuestsDfProfessionsApi
        local Resolve = NSQC4.QuestsDfProfessionsResolve

        local hardness = Grid:GetHardness(ai.target)
        if not hardness or hardness <= 0 then
            ai.work = { done = 0, total = 1, startHardness = 0, stepDamage = 0 }
            return ai.work
        end

        local total
        local profDef = ai.profId and ProfApi and ProfApi:Get(ai.profId) or nil
        if profDef and profDef.clicks and Resolve then
            local pp = Resolve:ProfPct(entity, ai.terrainId)
            local sp = Resolve:StatPct(entity, profDef.stat)
            total = profDef.clicks(hardness, pp, sp)
        else
            total = math.floor(hardness + 0.5)
        end
        if not total or total < 1 then total = 1 end

        ai.work = {
            done          = 0,
            total         = total,
            startHardness = hardness,
            stepDamage    = hardness / total,
        }
        return ai.work
    end

    function Work:Tick(entity)
        if not entity or not entity.opts then return nil end

        local ai = entity.opts.ai
        if not ai or ai.state ~= "working" then return nil end
        if not ai.target then return nil end

        -- Клетка уже истощена — завершаем без клика
        local curH = Grid:GetHardness(ai.target)
        if curH == nil or curH <= 0 then
            return true
        end

        local w = EnsureWork(entity, ai)
        if not w then return nil end

        w.done = w.done + 1

        local hardness = Grid:GetHardness(ai.target) or 0
        if hardness > 0 then
            local newHardness = hardness - w.stepDamage
            if newHardness < 0 then newHardness = 0 end
            Grid:SetHardness(ai.target, newHardness)
        end

        -- Прокачка при клике
        local Stats = NSQC4.QuestsDfAIStats
        if Stats then
            local rule = TERRAIN_TO_STAT[ai.terrainId]

            -- профильный стат по terrain (agility/strength/intellect)
            if rule and rule.stat and Stats.TryUpStat then
                Stats:TryUpStat(entity, rule.stat)
            end

            -- живучесть: всегда, кроме grass (у неё vitality = false)
            local wantVitality = (rule == nil) or (rule.vitality ~= false)
            if wantVitality and Stats.TryUpVitality then
                Stats:TryUpVitality(entity)
            end
        end

        -- Звук работы: только если мышь на клетке существа
        local QuestsField = NSQC4.QuestsField
        local cell = QuestsField and QuestsField.cells and QuestsField.cells[entity.index]
        if cell and cell._hovered then
            local Sound = NSQC4.QuestsDfAISound
            if Sound then Sound:PlayTerrain(ai.terrainId) end
        end

        if w.done >= w.total then
            Grid:SetHardness(ai.target, 0)
            return true
        end

        return false
    end

    function Work:Reset(entity)
        if not entity or not entity.opts then return end
        local ai = entity.opts.ai
        if ai then ai.work = nil end
    end

end)