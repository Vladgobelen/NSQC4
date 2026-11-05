-- ============================================================================
-- NSQC4 / Quests / df / Init
-- EnsureCreatures проверяет byName (есть ли уже гоблин/дворф), не Grid.
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

        -- Свободные клетки
        local free = {}
        for i = 1, 100 do
            if not Grid:GetEntityName(i) then
                free[#free + 1] = i
            end
        end

        local function pickFree()
            if #free == 0 then return nil end
            local p = math.random(#free)
            return table.remove(free, p)
        end

        local Goblin = NSQC4.QuestsDfGoblin
        local Dwarf  = NSQC4.QuestsDfDwarf

        if not hasGoblin and Goblin and Goblin.Spawn then
            local idx = pickFree()
            if idx then Goblin:Spawn(idx) end
        end
        if not hasDwarf and Dwarf and Dwarf.Spawn then
            local idx = pickFree()
            if idx then Dwarf:Spawn(idx) end
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

        local pool = { "grass", "stone", "tree", "earth" }
        for i = 1, 100 do
            Terrain:SetTerrain(i, pool[math.random(1, #pool)])
        end
        if Terrain.Render then Terrain:Render() end
        print("|cffff0000[GEN]|r Ландшафт сгенерирован.")

        EnsureCreatures()
        StartAITicker()

        print("|cff00ff00[NSQC4]|r Карта сгенерирована.")
        return true
    end

    -- ========================================================================
    -- ПОЛНЫЙ РЕСТАРТ
    -- ========================================================================
    function NSQC4:RestartDfMap()
        print("|cffff8800[NSQC4]|r Полный рестарт поля df...")

        local Terrain = NSQC4.QuestsDfTerrain
        if Terrain and Terrain.Clear then Terrain:Clear() end
        local Entities = NSQC4.QuestsDfEntities
        if Entities and Entities.Clear then Entities:Clear() end
        local Grid = NSQC4.QuestsDfGrid
        if Grid and Grid.ClearAll then Grid:ClearAll() end
        if NSQC4.QuestsField and NSQC4.QuestsField.ClearAll then
            NSQC4.QuestsField:ClearAll()
        end

        self:SetDfInitialized(false)
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
            EnsureCreatures()
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