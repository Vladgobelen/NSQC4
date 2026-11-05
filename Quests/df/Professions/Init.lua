-- ============================================================================
-- NSQC4 / Quests / df / Professions / Init
-- API реестра профессий.
--
-- Ничего не знает о конкретных профессиях. Только:
--   - хранит зарегистрированные def по id
--   - отдаёт их по запросу (по id, по имени, все, по terrain)
--
-- Каждая профессия — отдельный файл (df/Professions/<Prof>.lua),
-- который при загрузке зовёт Register(id, def).
--
-- Контракт def:
--   name    = "Диггер"                    — русское имя (для known_skills)
--   desc    = "..."                       — описание
--   terrain = "earth"                     — к какому объекту применяется
--   stat    = "strength"                  — какой параметр существа ускоряет
--   clicks  = function(hardness, prof_pct, str_pct) -> int
--                                          — формула кликов (внутри профессии)
--   work    = { verb, duration, yields }  — что делает / что даёт
--
-- API (namespace: NSQC4.QuestsDfProfessionsApi):
--   Register(id, def)             — зарегистрировать
--   Get(id)                       — def | nil
--   GetByName(name)               — def | nil (по русскому имени)
--   GetByTerrain(terrainId)       — первый def с этим terrain | nil
--   GetAll()                      — массив def
--   Count()                       — число
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local P = {}
    NSQC4.QuestsDfProfessionsApi = P

    local byId  = {}
    local order = {}

    -- ========================================================================
    -- Регистрация профессии.
    --   id  — "digger" | "stonecutter" | ...
    --   def — см. контракт в шапке файла
    -- ========================================================================
    function P:Register(id, def)
        if type(id) ~= "string" or id == "" then return false end
        if type(def) ~= "table" then return false end

        if not byId[id] then
            order[#order + 1] = id
        end

        def.id = id
        byId[id] = def
        return true
    end

    -- ========================================================================
    -- Получить по id.
    -- ========================================================================
    function P:Get(id)
        if type(id) ~= "string" or id == "" then return nil end
        return byId[id]
    end

    -- ========================================================================
    -- Получить по имени (opts.known_skills хранит имена).
    -- ========================================================================
    function P:GetByName(name)
        if type(name) ~= "string" or name == "" then return nil end
        for _, id in ipairs(order) do
            local def = byId[id]
            if def and def.name == name then return def end
        end
        return nil
    end

    -- ========================================================================
    -- Получить первую профессию, применимую к данному terrain.
    -- ========================================================================
    function P:GetByTerrain(terrainId)
        if type(terrainId) ~= "string" or terrainId == "" then return nil end
        for _, id in ipairs(order) do
            local def = byId[id]
            if def and def.terrain == terrainId then return def end
        end
        return nil
    end

    -- ========================================================================
    -- Все зарегистрированные (в порядке регистрации).
    -- ========================================================================
    function P:GetAll()
        local list = {}
        for _, id in ipairs(order) do
            if byId[id] then list[#list + 1] = byId[id] end
        end
        return list
    end

    -- ========================================================================
    -- Сколько зарегистрировано.
    -- ========================================================================
    function P:Count()
        return #order
    end

end)