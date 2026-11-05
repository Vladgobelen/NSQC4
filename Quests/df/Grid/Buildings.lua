-- ============================================================================
-- NSQC4 / Quests / df / Grid / Buildings
-- ЕДИНАЯ таблица построек. Флаг demolish УБРАН.
--   hp < max → можно строить (builder)
--   hp >= max → можно ломать (любой)
--   выделение (IsTerrainSelected(idx, "ladder")) → задача активна
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Grid/Buildings: Grid не загружен.")
        return
    end

    local TOTAL = 100

    local function EnsureBuildings()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.buildings = nsDbc4.quests.df.buildings or {}
        return nsDbc4.quests.df.buildings
    end

    function Grid:AddBuilding(index, kind, maxHp, material)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        kind = kind or "ladder"
        maxHp = tonumber(maxHp) or 1000
        EnsureBuildings()[index] = {
            kind     = kind,
            hp       = 1,
            max      = maxHp,
            material = material or "wood",
            stored   = 0,
            by       = nil,
            byName   = nil,
        }
        return true
    end

    function Grid:GetBuilding(index)
        return EnsureBuildings()[tonumber(index) or 0]
    end

    function Grid:RemoveBuilding(index)
        EnsureBuildings()[tonumber(index) or 0] = nil
    end

    function Grid:IsBuilding(index)
        return EnsureBuildings()[tonumber(index) or 0] ~= nil
    end

    function Grid:GetAllBuildings()
        return EnsureBuildings()
    end

    function Grid:GetBuildingMaterial(index)
        local b = self:GetBuilding(index)
        return b and b.material or nil
    end

    function Grid:SetBuildingMaterial(index, material)
        local b = self:GetBuilding(index)
        if b then b.material = material end
    end

    -- Резерв
    function Grid:ReserveBuilding(index, entity)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        if not entity or not entity.id then return false end
        local b = EnsureBuildings()[index]
        if not b then return false end
        if b.by == entity.id then
            b.byName = entity.opts and entity.opts.name or b.byName
            return true
        end
        if b.by ~= nil then return false end
        b.by     = entity.id
        b.byName = entity.opts and entity.opts.name or nil
        return true
    end

    function Grid:ReleaseBuilding(index, entityId)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        if not entityId then return false end
        local b = EnsureBuildings()[index]
        if not b then return false end
        if b.by == entityId then
            b.by     = nil
            b.byName = nil
            return true
        end
        return false
    end

    function Grid:IsBuildingReserved(index, entityId)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        local b = EnsureBuildings()[index]
        if not b then return false end
        if b.by == nil then return false end
        if entityId and b.by == entityId then return false end
        return true
    end

    function Grid:GetBuildingOwner(index)
        local b = self:GetBuilding(index)
        if not b then return nil, nil end
        return b.by, b.byName
    end

    -- stored
    function Grid:GetStored(index)
        local b = self:GetBuilding(index)
        return b and tonumber(b.stored) or 0
    end

    function Grid:AddStored(index, n)
        local b = self:GetBuilding(index)
        if not b then return false end
        b.stored = (tonumber(b.stored) or 0) + (tonumber(n) or 1)
        return true
    end

    function Grid:TakeStored(index, n)
        local b = self:GetBuilding(index)
        if not b then return false end
        local cur = tonumber(b.stored) or 0
        n = tonumber(n) or 1
        if cur < n then return false end
        b.stored = cur - n
        return true
    end

    -- Заглушки для совместимости (флаг УБРАН)
    function Grid:SetDemolish(index, v) end
    function Grid:IsDemolish(index) return false end

end)