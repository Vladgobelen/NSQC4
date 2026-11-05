-- ============================================================================
-- NSQC4 / Quests / df / Init
-- EnsureCreatures проверяет byName (есть ли уже гоблин/дворф), не Grid.
--
-- СПАВН СУЩЕСТВ:
--   1. Не спавним в воду (water) и в пустоту (void).
--   2. Оба существа — на ОДНОЙ стороне от воды: дворф выбирается из клеток,
--      достижимых от гоблина BFS-ом без пересечения воды/void.
--      Если таких нет — fallback: любая свободная не-вода.
--
-- Генерация воды в GenerateDfMap:
--   - SeedRiver (река) и SeedLake (озеро) — из df/Terrain/Logic/Water.lua.
--     Каждый с шансом 50% (см. RIVER_CHANCE/LAKE_CHANCE там).
--   - Water ставит depth через Grid:SetDepth; Generate не лезет в глубину.
--   - Вода ставится ПОСЛЕ FillRandom — перетирает часть grass/stone/tree/earth.
--
-- ПОЛНЫЙ РЕСТАРТ (RestartDfMap):
--   - Оборвать анимации.
--   - Очистить Terrain/Entities/Grid текущего этажа.
--   - ПОЛНОСТЬЮ сбросить floors: visited/snapshots/min/max/current.
--     Без этого старые этажи (-1, -2, ...) остаются «visited», и
--     Switch(-1) грузит старый снимок без воды — вода не «проваливается».
--   - Сбросить IsDfInitialized → существа заспавнятся заново.
--   - GenerateDfMap() с нуля.
--
-- Существа спавнятся ТОЛЬКО при первой инициализации мира (IsDfInitialized).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    NSQC4.QuestsProfiles    = NSQC4.QuestsProfiles    or {}
    NSQC4.QuestsDfModules   = NSQC4.QuestsDfModules   or {}
    NSQC4.QuestsDfState     = NSQC4.QuestsDfState     or {}

    NSQC4.QuestsProfiles["df"] = {
        label   = "df",
        tooltip = "Проект поля: живые существа, ландшафт, постройки.",
        order   = 100,
    }

    local function DfStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        return nsDbc4.quests.df
    end

    function NSQC4:IsDfInitialized() return DfStorage().initialized and true or false end
    function NSQC4:SetDfInitialized(v) DfStorage().initialized = v and true or false end

    local function StartAITicker()
        local Ticker = NSQC4.QuestsDfAITicker
        if Ticker and Ticker.Start then
            Ticker:Start()
        end
    end

    -- ========================================================================
    -- Вспомогательное: «годится ли клетка под спавн»
    --   - нет существа
    --   - не вода
    --   - не void
    -- ========================================================================
    local function IsSpawnableCell(Grid, i)
        if not Grid then return false end
        if Grid:GetEntityName(i) then return false end
        local t = Grid:GetTerrain(i)
        if t == "water" then return false end
        if t == "void" then return false end
        return true
    end

    -- ========================================================================
    -- Вспомогательное: собрать свободные клетки (не вода, не void, без сущ.)
    -- ========================================================================
    local function CollectFreeCells(Grid)
        local free = {}
        for i = 1, 100 do
            if IsSpawnableCell(Grid, i) then
                free[#free + 1] = i
            end
        end
        return free
    end

    -- ========================================================================
    -- BFS от startIndex по «суше» (не вода, не void, без существ).
    -- Возвращает таблицу reachable[idx] = true.
    -- ========================================================================
    local function ReachableLand(Grid, startIndex)
        local reachable = {}
        if not startIndex then return reachable end
        if not IsSpawnableCell(Grid, startIndex) then return reachable end

        local queue = { startIndex }
        local head  = 1
        reachable[startIndex] = true

        while head <= #queue do
            local cur = queue[head]
            head = head + 1
            for _, n in ipairs(Grid:Neighbors(cur)) do
                if not reachable[n] and IsSpawnableCell(Grid, n) then
                    reachable[n] = true
                    queue[#queue + 1] = n
                end
            end
        end

        return reachable
    end

    -- ========================================================================
    -- Доспавн недостающих: проверка по byName
    -- ========================================================================
    local function EnsureCreatures()
        local Entities = NSQC4.QuestsDfEntities
        local Grid     = NSQC4.QuestsDfGrid
        if not Entities or not Grid then return end

        local byName = Entities:EnsureByName()
        local hasGoblin, hasDwarf = false, false
        for _, e in pairs(byName) do
            if e.opts then
                local k = e.opts.kind or e.kind
                if k == "goblin" then hasGoblin = true end
                if k == "dwarf"  then hasDwarf  = true end
            end
        end

        if hasGoblin and hasDwarf then return end

        -- Свободные клетки: не вода, не void, без существ
        local free = CollectFreeCells(Grid)
        if #free == 0 then
            print("|cffff0000[NSQC4]|r EnsureCreatures: нет свободных клеток на суше.")
            return
        end

        -- helper: убрать idx из free
        local function removeFromFree(list, value)
            for i = #list, 1, -1 do
                if list[i] == value then
                    table.remove(list, i)
                    return
                end
            end
        end

        -- helper: случайный элемент массива
        local function pickRandom(list)
            if #list == 0 then return nil end
            return list[math.random(#list)]
        end

        local Goblin = NSQC4.QuestsDfGoblin
        local Dwarf  = NSQC4.QuestsDfDwarf

        -- 1. Гоблин (если нет)
        local goblinIdx = nil
        if not hasGoblin and Goblin and Goblin.Spawn then
            goblinIdx = pickRandom(free)
            if goblinIdx then
                Goblin:Spawn(goblinIdx)
                removeFromFree(free, goblinIdx)
            end
        end

        -- 2. Дворф (если нет) — на ОДНОЙ СТОРОНЕ от воды с гоблином.
        if not hasDwarf and Dwarf and Dwarf.Spawn then
            local dwarfIdx = nil

            if goblinIdx then
                -- BFS от гоблина по суше
                local reachable = ReachableLand(Grid, goblinIdx)
                local sameSide = {}
                for _, idx in ipairs(free) do
                    if reachable[idx] then
                        sameSide[#sameSide + 1] = idx
                    end
                end
                dwarfIdx = pickRandom(sameSide)
            end

            -- Fallback: если гоблина не было (hasGoblin==true) или
            -- не нашлось клетки на той же стороне — любая свободная не-вода
            if not dwarfIdx then
                dwarfIdx = pickRandom(free)
            end

            if dwarfIdx then
                Dwarf:Spawn(dwarfIdx)
                removeFromFree(free, dwarfIdx)
            end
        end
    end

    NSQC4._EnsureDfCreatures = EnsureCreatures

    -- ========================================================================
    -- Генератор
    -- ========================================================================
    function NSQC4:GenerateDfMap()
        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then
            print("|cffff0000[GEN]|r ОШИБКА: Terrain не загружен")
            return false
        end

        local types = Terrain:GetTypes() or {}
        local typeIds = {}
        for id in pairs(types) do typeIds[#typeIds + 1] = id end
        table.sort(typeIds)
        if #typeIds == 0 then
            print("|cffff0000[GEN]|r ОШИБКА: нет зарегистрированных типов — генерация невозможна")
            return false
        end
        print("|cffff0000[GEN]|r Зарегистрированные типы: " .. table.concat(typeIds, ", "))

        Terrain:Clear()
        if NSQC4.QuestsDfEntities then NSQC4.QuestsDfEntities:Clear() end

        -- 1. База: земля/трава/камень/дерево
        local pool = { "grass", "stone", "tree", "earth" }
        for i = 1, 100 do
            Terrain:SetTerrain(i, pool[math.random(1, #pool)])
        end

        -- 2. Вода: река + озеро (после базы — перетирает часть клеток).
        --    SeedRiver/SeedLake сами решают, появиться ли (шанс 50%).
        local placedWater = 0
        if Terrain.SeedRiver then
            local ok, res = pcall(Terrain.SeedRiver, Terrain)
            if ok and type(res) == "number" then placedWater = placedWater + res end
        end
        if Terrain.SeedLake then
            local ok, res = pcall(Terrain.SeedLake, Terrain)
            if ok and type(res) == "number" then placedWater = placedWater + res end
        end
        if placedWater > 0 then
            print(string.format("|cff00ffff[GEN]|r Вода на карте: %d клеток", placedWater))
        else
            print("|cff808080[GEN]|r Вода на карте: 0 клеток")
        end

        if Terrain.Render then Terrain:Render() end
        print("|cffff0000[GEN]|r Ландшафт сгенерирован.")

        -- Существа спавнятся ТОЛЬКО при первой генерации мира.
        if not self:IsDfInitialized() then
            EnsureCreatures()
            self:SetDfInitialized(true)
            print("|cff00ff00[GEN]|r Существа заспавнены (первая инициализация мира).")
        else
            print("|cff808080[GEN]|r Мир уже инициализирован — существа не спавнятся.")
        end

        StartAITicker()

        print("|cff00ff00[NSQC4]|r Карта сгенерирована.")
        return true
    end

    -- ========================================================================
    -- ПОЛНЫЙ РЕСТАРТ
    -- ========================================================================
    function NSQC4:RestartDfMap()
        print("|cffff8800[NSQC4]|r Полный рестарт поля df...")

        -- 1. Оборвать все анимации (temp-текстуры старого этажа)
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and Animate.StopAll then
            Animate:StopAll()
        end

        -- 2. Очистить сущности и ландшафт текущего этажа
        local Terrain = NSQC4.QuestsDfTerrain
        if Terrain and Terrain.Clear then Terrain:Clear() end
        local Entities = NSQC4.QuestsDfEntities
        if Entities and Entities.Clear then Entities:Clear() end
        local Grid = NSQC4.QuestsDfGrid
        if Grid and Grid.ClearAll then Grid:ClearAll() end
        if NSQC4.QuestsField and NSQC4.QuestsField.ClearAll then
            NSQC4.QuestsField:ClearAll()
        end

        -- 3. ПОЛНЫЙ СБРОС ЭТАЖЕЙ: visited, snapshots, min/max, current.
        --    Без этого Switch(-1) грузит старый снимок без воды.
        local floors = NSQC4.QuestsDfFloors
        if floors and floors.EnsureStorage then
            local s = floors:EnsureStorage()
            s.current   = 0
            s.min       = 0
            s.max       = 0
            s.visited   = { [0] = true }
            s.snapshots = {}
            print("|cffff8800[FLOORS]|r Все этажи сброшены (snapshots, visited, current=0).")
        end

        -- 4. Сбросить флаг инициализации мира (чтобы существа заспавнились заново)
        self:SetDfInitialized(false)

        -- 5. Сгенерировать карту 0 с нуля
        self:GenerateDfMap()

        if Terrain and Terrain.Render then Terrain:Render() end
        if Entities and Entities.Render then Entities:Render() end

        print("|cff00ff00[NSQC4]|r Поле полностью пересоздано с нуля!")
    end

    StaticPopupDialogs["NSQC4_RESTART_DF"] = {
        text = "Полный рестарт поля df?\nВсё будет удалено и сгенерировано заново.",
        button1 = YES,
        button2 = NO,
        OnAccept = function() NSQC4:RestartDfMap() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- ========================================================================
    -- Открыть/Сгенерировать
    -- ========================================================================
    function NSQC4:OpenOrGenerateDf()
        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return end

        if Terrain:Count() == 0 then
            self:GenerateDfMap()
        else
            Terrain:Render()
            if NSQC4.QuestsDfEntities then NSQC4.QuestsDfEntities:Render() end
            -- EnsureCreatures() убран: открытие поля НЕ должно доспавнивать существ.
            -- Существа появляются только при первой генерации мира (GenerateDfMap).
        end

        StartAITicker()

        local field = NSQC4.QuestsField
        if field and field.Show then
            field:Show()
        end
    end

    -- ========================================================================
    -- Слэш
    -- ========================================================================
    SLASH_NSDF1 = "/ns_df"
    SlashCmdList["NSDF"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "open" then
            NSQC4:OpenOrGenerateDf()
        elseif cmd == "generate" then
            NSQC4:GenerateDfMap()
            NSQC4.QuestsField:Show()
        elseif cmd == "restart" then
            StaticPopup_Show("NSQC4_RESTART_DF")
        elseif cmd == "ensure" then
            -- Ручной доспавн (для отладки). Осознанно оставлен как явная команда.
            EnsureCreatures()
            print("|cff00ff00[NSQC4]|r ensure: существ в byName " .. tostring(NSQC4.QuestsDfEntities:Count()))
        end
    end

    if NSQC4.SlashPanel_RegisterSectionButton then
        NSQC4.SlashPanel_RegisterSectionButton(
            "Квесты", "Г", "/ns_df open",
            { { text = "Открыть/Сгенерировать", r = 0.00, g = 0.82, b = 1.00 } }
        )
        NSQC4.SlashPanel_RegisterSectionButton(
            "Квесты", "Р", "/ns_df restart",
            { { text = "Полный рестарт (сброс и генерация)", r = 1.00, g = 0.20, b = 0.20 } }
        )
    end

end)