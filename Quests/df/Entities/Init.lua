-- ============================================================================
-- NSQC4 / Quests / df / Entities / Init
-- Точка входа подмодуля живых существ.
--
-- Модель byName:
--   nsDbc4.quests.df.entities.byName[name] = entity
--   grid[i].entityName = name
--
-- Реестр тултипов:
--   Entities:RegisterTooltip(kind, buildFn) — kind → function(opts) → function(btn)
--   Entities:GetTooltip(kind)               — вернуть билдер (или nil)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Entities: ядро поля не загружено.")
        return
    end

    local Entities = {}
    Entities.__index = Entities

    NSQC4.QuestsDfEntities = Entities
    NSQC4.QuestsDfModules = NSQC4.QuestsDfModules or {}
    NSQC4.QuestsDfModules["entities"] = NSQC4.QuestsDfModules["entities"] or {
        label   = "Живые существа",
        order   = 100,
        enabled = true,
    }
    NSQC4.QuestsDfModules["entities"].api = Entities

    -- ========================================================================
    -- Реестр тултипов
    -- ========================================================================
    local tooltipBuilders = {}

    function Entities:RegisterTooltip(kind, buildFn)
        if type(kind) ~= "string" or kind == "" then return false end
        if type(buildFn) ~= "function" then return false end
        tooltipBuilders[kind] = buildFn
        return true
    end

    function Entities:GetTooltip(kind)
        if type(kind) ~= "string" or kind == "" then return nil end
        return tooltipBuilders[kind]
    end

    -- ========================================================================
    -- byName: таблица существ по имени
    -- ========================================================================
    local function EnsureByName()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.df = nsDbc4.quests.df or {}
        nsDbc4.quests.df.entities = nsDbc4.quests.df.entities or {}
        nsDbc4.quests.df.entities.byName = nsDbc4.quests.df.entities.byName or {}
        return nsDbc4.quests.df.entities.byName
    end

    function Entities:EnsureByName() return EnsureByName() end

    -- ========================================================================
    -- Проверка готовности (Storage/UI/Logic)
    -- ========================================================================
    local function Ready()
        return Entities.EnsureStorage ~= nil
           and Entities.Spawn        ~= nil
           and Entities.Render       ~= nil
    end

    function Entities:Init()
        if not Ready() then
            return false
        end

        self:EnsureStorage()
        if self:IsInitialized() then
            return false
        end

        self:SetInitialized(true)
        return true
    end

    NSQC4.QuestsDfModules["entities"].init = function()
        return NSQC4.QuestsDfEntities:Init()
    end

    -- ========================================================================
    -- Слэш-команды
    -- ========================================================================
    SLASH_NSDF_ENTITIES1 = "/ns_df_entities"
    SlashCmdList["NSDF_ENTITIES"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        local E = NSQC4.QuestsDfEntities

        if cmd == "" or cmd == "info" then
            print("|cff00ff00[NSQC4]|r df/entities — живые существа")
            if not Ready() then
                print("|cffffaa00  Storage/UI/Logic ещё не загружены.|r")
                return
            end
            local st = E:EnsureStorage()
            local byName = EnsureByName()
            local n = 0
            for _ in pairs(byName) do n = n + 1 end
            print("  initialized:", E:IsInitialized())
            print("  существ в byName:", n)
            print("  в Grid:", E:Count())
            print("|cff808080Команды: /ns_df_entities init | clear|r")

        elseif cmd == "init" then
            local ok = E:Init()
            print("|cff00ff00[NSQC4]|r entities:", ok and "инициализированы." or "уже были инициализированы (или Storage не готов).")

        elseif cmd == "clear" then
            if not Ready() then
                print("|cffffaa00[NSQC4]|r entities: Storage ещё не загружен.")
                return
            end
            E:Clear()
            print("|cffff8800[NSQC4]|r entities: все существа убраны.")

        else
            print("|cffff0000[NSQC4]|r entities: неизвестная команда '" .. cmd .. "'")
        end
    end

end)