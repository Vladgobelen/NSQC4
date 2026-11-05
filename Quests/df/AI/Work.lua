-- ============================================================================
-- NSQC4 / Quests / df / AI / Work
-- Стройка лестницы: ПОРЦИЯМИ ПО 1 МАТЕРИАЛУ.
--
-- ЛОГИКА TickBuild:
--   stored = Grid:GetStored(bIdx) — сколько материалов лежит в клетке лестницы.
--   hpPerMaterial = 100 (из TerrainData:GetLadderParams(material)).
--
--   1. Если stored <= 0:
--        return false, "need_material"
--   2. Иначе строим:
--        clicksTotal = CalcClicks("builder", "agility", totalHP, entity)
--        stepDamage  = totalHP / clicksTotal
--        за каждый клик:
--          hp += stepDamage
--          накопленный счётчик HP за этот материал += stepDamage
--          если >= hpPerMaterial:
--             Grid:TakeStored(bIdx, 1)
--             hpSinceMaterial = 0
--   3. DONE только когда hp >= max.
--
-- ЗВУК РАБОТЫ:
--   Убран из тика. Теперь звук — в Hover.lua (при наведении на работающее
--   существо, раз в SOUND_INTERVAL секунд). См. Field/UI/API/Hover.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Work = {}
    NSQC4.QuestsDfAIWork = Work
    Work.DEBUG = false

    local function dbg(...)
        if Work.DEBUG then print("|cff00ffff[WORK]|r", ...) end
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then return end

    local TERRAIN_TO_STAT = {
        tree  = { stat = "agility",   vitality = true  },
        stone = { stat = "strength",  vitality = true  },
        grass = { stat = "intellect", vitality = false },
    }

    local function LadderParams(material)
        local Data = NSQC4.QuestsDfTerrainData
        if Data and Data.GetLadderParams then return Data:GetLadderParams(material) end
        return 100, 100
    end

    local function CalcClicks(profId, stat, hardness, entity)
        hardness = tonumber(hardness) or 0
        if hardness <= 0 then return 1 end
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        local Resolve = NSQC4.QuestsDfProfessionsResolve
        local profDef = profId and ProfApi and ProfApi:Get(profId) or nil
        if profDef and profDef.clicks and Resolve then
            local pp = Resolve:ProfPct(entity, profDef.terrain)
            local sp = Resolve:StatPct(entity, stat or profDef.stat)
            local total = profDef.clicks(hardness, pp, sp)
            if not total or total < 1 then total = 1 end
            return total
        end
        return math.max(1, math.floor(hardness + 0.5))
    end

    local function DropMaterialToNeighbors(bIndex, material, count)
        if count <= 0 then return 0 end
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Drops then return 0 end
        local icon
        local Transform = NSQC4.QuestsDfTransform
        if Transform and Transform.Get then
            local def = Transform:Get(material)
            if def and def.dropIcon then icon = def.dropIcon end
        end
        if not icon then
            local Data = NSQC4.QuestsDfTerrainData
            if Data and Data:Get(material) then icon = Data:Get(material).texture end
        end
        local neighbors = Grid:Neighbors(bIndex)
        if #neighbors == 0 then return 0 end
        local placed = 0
        for _ = 1, count do
            for _try = 1, #neighbors do
                local n = neighbors[math.random(#neighbors)]
                local c = Grid:GetCell(n)
                if c and c.terrain ~= "void" then
                    if Drops:Add(n, material) then
                        placed = placed + 1
                        break
                    end
                end
            end
        end
        return placed
    end

    -- ========================================================================
    -- BUILD: порциями по 1 материалу.
    -- ========================================================================
    local function TickBuild(entity, ai, bIndex)
        local b = Grid:GetBuilding(bIndex)
        if not b then return true end

        local totalHP  = tonumber(b.max) or 0
        local curH     = Grid:GetHardness(bIndex) or tonumber(b.hp) or 0
        local material = b.material or "wood"
        local hpPer    = LadderParams(material)
        local stored   = Grid.GetStored and Grid:GetStored(bIndex) or 0

        if totalHP > 0 and curH >= totalHP then
            Grid:SetHardness(bIndex, totalHP)
            b.hp = totalHP
            ai.work = nil
            ai.wasBuilding = true
            local T = NSQC4.QuestsDfTerrainUIApi
            if T and T.RenderCellFromStorage then T:RenderCellFromStorage(bIndex) end
            dbg(string.format("TickBuild cell=%d: DONE hp=%d/%d", bIndex, totalHP, totalHP))
            return true
        end

        if stored <= 0 then
            ai.work = nil
            dbg(string.format("TickBuild cell=%d: stored=0 → need_material (hp=%d/%d)",
                bIndex, math.floor(curH + 0.5), totalHP))
            return false, "need_material"
        end

        local w = ai.work
        if not w or w.kind ~= "build" then
            local total = CalcClicks("builder", "agility", totalHP, entity)
            local stepDamage = (totalHP > 0) and (totalHP / total) or 0
            w = {
                kind             = "build",
                total            = total,
                stepDamage       = stepDamage,
                hpSinceMaterial  = 0,
            }
            ai.work = w
        end

        w.hpSinceMaterial = w.hpSinceMaterial + w.stepDamage
        local newH = curH + w.stepDamage
        if newH > totalHP then newH = totalHP end
        Grid:SetHardness(bIndex, newH)
        b.hp = newH
        if b.by == nil then b.by = entity.id end

        if w.hpSinceMaterial >= hpPer then
            Grid:TakeStored(bIndex, 1)
            w.hpSinceMaterial = w.hpSinceMaterial - hpPer
            stored = Grid:GetStored(bIndex)
            dbg(string.format("TickBuild cell=%d: материал израсходован, stored=%d (hp=%d/%d)",
                bIndex, stored, math.floor(newH + 0.5), totalHP))
        end

        local Stats = NSQC4.QuestsDfAIStats
        if Stats and Stats.TryUpStat then Stats:TryUpStat(entity, "agility") end

        if totalHP > 0 and newH >= totalHP then
            Grid:SetHardness(bIndex, totalHP)
            b.hp = totalHP
            ai.work = nil
            ai.wasBuilding = true
            local T = NSQC4.QuestsDfTerrainUIApi
            if T and T.RenderCellFromStorage then T:RenderCellFromStorage(bIndex) end
            dbg(string.format("TickBuild cell=%d: DONE hp=%d/%d", bIndex, totalHP, totalHP))
            return true
        end

        if Grid:GetStored(bIndex) <= 0 then
            ai.work = nil
            dbg(string.format("TickBuild cell=%d: stored кончился → need_material (hp=%d/%d)",
                bIndex, math.floor(newH + 0.5), totalHP))
            return false, "need_material"
        end

        return false
    end

    -- ========================================================================
    -- DEMOLISH
    -- ========================================================================
    local function TickDemolish(entity, ai, bIndex)
        local b = Grid:GetBuilding(bIndex)
        if not b then return true end
        if ai.carrying then ai.carrying = nil end

        local totalHP  = tonumber(b.max) or 0
        local curH     = Grid:GetHardness(bIndex) or tonumber(b.hp) or 0
        local material = b.material or "wood"
        local hpPer, returnPer = LadderParams(material)

        if curH <= 0 then
            Grid:SetHardness(bIndex, 0)
            b.hp = 0
            ai.work = nil
            ai.wasBuilding = true
            local T = NSQC4.QuestsDfTerrainUIApi
            if T and T.RenderCellFromStorage then T:RenderCellFromStorage(bIndex) end
            return true
        end

        local w = ai.work
        if not w or w.kind ~= "demolish" then
            local total = CalcClicks("builder", "agility", curH, entity)
            local stepDamage = (total > 0) and (curH / total) or 0
            w = { kind = "demolish", done = 0, total = total, startHardness = curH,
                  stepDamage = stepDamage, materialDropped = false }
            ai.work = w
        end

        w.done = w.done + 1
        local newH = curH - w.stepDamage
        if newH < 0 then newH = 0 end
        Grid:SetHardness(bIndex, newH)
        b.hp = newH
        if b.by == nil then b.by = entity.id end

        local Stats = NSQC4.QuestsDfAIStats
        if Stats and Stats.TryUpStat then Stats:TryUpStat(entity, "agility") end

        if newH <= 0 then
            if not w.materialDropped then
                local count = math.max(0, math.floor(totalHP / (returnPer or 100)))
                if count > 0 then DropMaterialToNeighbors(bIndex, material, count) end
                w.materialDropped = true
            end
            Grid:SetHardness(bIndex, 0)
            b.hp = 0
            ai.work = nil
            ai.wasBuilding = true
            local T = NSQC4.QuestsDfTerrainUIApi
            if T and T.RenderCellFromStorage then T:RenderCellFromStorage(bIndex) end
            return true
        end
        return false
    end

    -- ========================================================================
    -- BREAK
    -- ========================================================================
    local function TickBreak(entity, ai)
        local curH = Grid:GetHardness(ai.target)
        if curH == nil or curH <= 0 then return true end
        local w = ai.work
        if not w or w.kind ~= "break" then
            local ProfApi = NSQC4.QuestsDfProfessionsApi
            local profDef = ai.profId and ProfApi and ProfApi:Get(ai.profId) or nil
            local total = CalcClicks(ai.profId, profDef and profDef.stat, curH, entity)
            local stepDamage = curH / total
            w = { kind = "break", done = 0, total = total, startHardness = curH, stepDamage = stepDamage }
            ai.work = w
        end
        w.done = w.done + 1
        local hardness = Grid:GetHardness(ai.target) or 0
        local newHardness = hardness - w.stepDamage
        if newHardness < 0 then newHardness = 0 end
        Grid:SetHardness(ai.target, newHardness)
        local Stats = NSQC4.QuestsDfAIStats
        if Stats then
            local rule = TERRAIN_TO_STAT[ai.terrainId]
            if rule and rule.stat then Stats:TryUpStat(entity, rule.stat) end
            local wantVitality = (rule == nil) or (rule.vitality ~= false)
            if wantVitality then Stats:TryUpVitality(entity) end
        end
        if newHardness <= 0 then
            Grid:SetHardness(ai.target, 0)
            return true
        end
        return false
    end

    -- ========================================================================
    -- Tick
    -- ========================================================================
    function Work:Tick(entity)
        if not entity or not entity.opts then return nil end
        local ai = entity.opts.ai
        if not ai or ai.state ~= "working" then return nil end
        if not ai.target then return nil end

        local bIndex = ai.workTarget or ai.target

        if Grid.IsBuilding and Grid:IsBuilding(bIndex) then
            local b = Grid:GetBuilding(bIndex)
            local hp  = tonumber(b.hp)  or 0
            local max = tonumber(b.max) or 0
            if hp < max then
                return TickBuild(entity, ai, bIndex)
            else
                return TickDemolish(entity, ai, bIndex)
            end
        end

        return TickBreak(entity, ai)
    end

    function Work:Reset(entity)
        if not entity or not entity.opts then return end
        local ai = entity.opts.ai
        if ai then ai.work = nil; ai.buildWork = nil end
    end

    SLASH_NSWORK1 = "/ns_work"
    SlashCmdList["NSWORK"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()
        if cmd == "" or cmd == "on" then Work.DEBUG = true; print("[WORK] DEBUG = true")
        elseif cmd == "off" then Work.DEBUG = false; print("[WORK] DEBUG = false")
        elseif cmd == "reset" then
            local E = NSQC4.QuestsDfEntities
            local e = arg ~= "" and E and E:GetByName(arg) or nil
            if e and e.opts.ai then e.opts.ai.work = nil; e.opts.ai.state = "idle"; print("[WORK] reset " .. tostring(arg)) end
        else print("[WORK] /ns_work on | off | reset <name>") end
    end

end)