-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Init
-- Ландшафт на поле 10×10. Точка входа подмодуля.
--
-- Контракт (реализуется в Storage/UI/Logic):
--   Terrain:EnsureStorage()                  -- nsDbc4.quests.df.terrain
--   Terrain:IsInitialized() / SetInitialized(v)
--   Terrain:GetAt(index)                     -- terrainId в ячейке (или nil)
--   Terrain:SetAt(index, terrainId, opts?)   -- задать ландшафт
--   Terrain:ClearAt(index)                   -- убрать ландшафт из ячейки
--   Terrain:Clear()                          -- сбросить карту
--   Terrain:GetTypes()                       -- список известных типов
--   Terrain:RegisterType(id, opts)           -- объявить тип (напр. "grass")
--   Terrain:Render() / RenderCell(index)     -- перерисовать
--
-- Правило: работа с полем — только через API QuestsField
-- (SetCellTexture/SetCellText/SetAnchorTexture/SetCellOnClick/ClearCell).
-- Прямой доступ к btn.* и nsDbc4.quests.field запрещён.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Terrain: ядро поля не загружено.")
        return
    end

    -- ========================================================================
    -- Namespace подмодуля
    -- ========================================================================
    local Terrain = {}
    Terrain.__index = Terrain

    NSQC4.QuestsDfTerrain = Terrain
    NSQC4.QuestsDfModules = NSQC4.QuestsDfModules or {}
    NSQC4.QuestsDfModules["terrain"] = NSQC4.QuestsDfModules["terrain"] or {
        label   = "Ландшафт",
        order   = 200,
        enabled = true,
    }
    NSQC4.QuestsDfModules["terrain"].api = Terrain

    -- ========================================================================
    -- Ленивая проверка готовности Storage/UI/Logic
    -- ========================================================================
    local function Ready()
        return Terrain.EnsureStorage ~= nil
           and Terrain.SetAt       ~= nil
           and Terrain.Render      ~= nil
    end

    -- ========================================================================
    -- Инициализация подмодуля (идемпотентно)
    -- ========================================================================
    function Terrain:Init()
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

    -- ========================================================================
    -- Регистрация в df/Init.lua
    -- ========================================================================
    NSQC4.QuestsDfModules["terrain"].init = function()
        return NSQC4.QuestsDfTerrain:Init()
    end

    -- ========================================================================
    -- Слэш-команды
    -- ========================================================================
    SLASH_NSDF_TERRAIN1 = "/ns_df_terrain"
    SlashCmdList["NSDF_TERRAIN"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        local T = NSQC4.QuestsDfTerrain

        if cmd == "" or cmd == "info" then
            print("|cff00ff00[NSQC4]|r df/terrain — ландшафт")
            if not Ready() then
                print("|cffffaa00  Storage/UI/Logic ещё не загружены.|r")
                return
            end
            local st = T:EnsureStorage()
            local n = 0
            if st and st.map then
                for _ in pairs(st.map) do n = n + 1 end
            end
            print("  initialized:", T:IsInitialized())
            print("  закрашенных клеток:", n)
            local types = T:GetTypes() or {}
            local tcount = 0
            for _ in pairs(types) do tcount = tcount + 1 end
            print("  объявленных типов:", tcount)
            print("|cff808080Команды: /ns_df_terrain init | clear|r")

        elseif cmd == "init" then
            local ok = T:Init()
            print("|cff00ff00[NSQC4]|r terrain:",
                  ok and "инициализирован."
                     or  "уже был инициализирован (или Storage не готов).")

        elseif cmd == "clear" then
            if not Ready() then
                print("|cffffaa00[NSQC4]|r terrain: Storage ещё не загружен.")
                return
            end
            T:Clear()
            print("|cffff8800[NSQC4]|r terrain: карта очищена.")

        else
            print("|cffff0000[NSQC4]|r terrain: неизвестная команда '" .. cmd .. "'")
        end
    end

end)