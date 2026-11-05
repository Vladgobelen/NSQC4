-- ============================================================================
-- NSQC4 / Quests / df / AI / Find
-- Выбор цели для существа.
--
-- Логика:
--   1. Allowed существа по opts.kind (Goblin/Dwarf).
--   2. Выделенные клетки (nsDbc4.quests.df.selections.terrain_types).
--      Фильтр: allowed[terrainId] И не зарезервировано другим существом.
--   3. Лучшие (есть своя профессия) / просто.
--   4. Случайный из лучших, иначе из просто.
--   5. { index, terrainId, profId|nil } | nil.
--
-- known_skills — таблица [имя] = уровень (1..100). Для выбора цели
-- достаточно самого факта «есть def с этим terrain», уровень не нужен.
--
-- HasProfForSelected(entity) — проверка: есть ли у существа профессия
-- под хотя бы одну из выделенных клеток. Используется в Ticker, чтобы
-- дать приоритет существам с профессией.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Find = {}
    NSQC4.QuestsDfAIFind = Find

    Find.DEBUG = false

    local function dbg(...)
        if Find.DEBUG then print("|cff00ffff[FIND]|r", ...) end
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r AI/Find: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local function GetAllowed(kind)
        if kind == "goblin" then
            local g = NSQC4.QuestsDfGoblin
            return g and g.Allowed or nil
        elseif kind == "dwarf" then
            local d = NSQC4.QuestsDfDwarf
            return d and d.Allowed or nil
        end
        return nil
    end

    local function GetSelectedCells()
        local result = {}
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.selections = nsDbc4.quests.df.selections or {}
        local s = nsDbc4.quests.df.selections

        local byType = s.terrain_types or {}
        for terrainId, list in pairs(byType) do
            for index in pairs(list) do
                result[#result + 1] = { index = index, terrainId = terrainId }
            end
        end
        return result
    end

    -- ========================================================================
    -- Есть ли у существа def профессии под данный terrain?
    -- known_skills — hash [имя] = уровень, поэтому pairs.
    -- ========================================================================
    local function FindProfForTerrain(entity, terrainId)
        local ProfApi = NSQC4.QuestsDfProfessionsApi
        if not ProfApi then return nil end

        local opts = entity.opts
        if not opts or type(opts.known_skills) ~= "table" then return nil end

        for name in pairs(opts.known_skills) do
            local def = ProfApi:GetByName(name)
            if def and def.terrain == terrainId then
                return def
            end
        end
        return nil
    end

    -- ========================================================================
    -- Есть ли у существа профессия под хотя бы одну ВЫДЕЛЕННУЮ клетку?
    -- (учитываем и Allowed, иначе смысла нет)
    -- ========================================================================
    function Find:HasProfForSelected(entity)
        if not entity or not entity.opts then return false end

        local kind = entity.kind or entity.opts.kind
        local allowed = GetAllowed(kind)
        if not allowed then return false end

        local selected = GetSelectedCells()
        if #selected == 0 then return false end

        for _, cell in ipairs(selected) do
            if allowed[cell.terrainId] then
                if FindProfForTerrain(entity, cell.terrainId) then
                    return true
                end
            end
        end
        return false
    end

    function Find:Pick(entity)
        if not entity or not entity.opts then return nil end

        local kind = entity.kind or entity.opts.kind
        local allowed = GetAllowed(kind)
        if not allowed then
            dbg("no allowed for", tostring(kind))
            return nil
        end

        local selected = GetSelectedCells()
        if #selected == 0 then
            dbg("no selected cells")
            return nil
        end

        -- 1. Фильтр: allowed + не зарезервировано другим
        local candidates = {}
        for _, cell in ipairs(selected) do
            if allowed[cell.terrainId] then
                if not Grid:IsReserved(cell.index, entity.id) then
                    candidates[#candidates + 1] = cell
                else
                    dbg("skip reserved", cell.index, "terrain", cell.terrainId,
                        "by", tostring(Grid:GetReservedBy(cell.index)))
                end
            end
        end
        if #candidates == 0 then
            dbg("no candidates (all reserved or not allowed)")
            return nil
        end

        -- 2. Лучшие (с профой) / просто
        local best, rest = {}, {}
        for _, cell in ipairs(candidates) do
            local prof = FindProfForTerrain(entity, cell.terrainId)
            if prof then
                best[#best + 1] = { index = cell.index, terrainId = cell.terrainId, profId = prof.id }
            else
                rest[#rest + 1] = { index = cell.index, terrainId = cell.terrainId }
            end
        end

        local pool = (#best > 0) and best or rest
        if #pool == 0 then return nil end
        local pick = pool[math.random(#pool)]
        dbg("pick", pick.index, pick.terrainId, pick.profId or "-")
        return pick
    end

end)