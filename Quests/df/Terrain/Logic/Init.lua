-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Logic / Init
-- Менеджер генерации и слэш-команд для ландшафта.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then return end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local COLS, ROWS = CONST.COLS, CONST.ROWS
    local TOTAL = COLS * ROWS

    -- ========================================================================
    -- УСТАНОВКА ТИПА
    -- ========================================================================
    function Terrain:SetTerrain(index, terrainId, opts)
        -- Просто вызываем SetAt, типы уже зарегистрированы в Storage
        return self:SetAt(index, terrainId, opts)
    end

    function Terrain:ClearTerrain(index)
        return self:ClearAt(index)
    end

    -- ========================================================================
    -- ГЕНЕРАЦИЯ (Пятна и случайное заполнение)
    -- ========================================================================
    function Terrain:SeedDemo(kind, count)
        kind = kind or "grass"
        count = math.min(tonumber(count) or 20, TOTAL)

        local free = {}
        for i = 1, TOTAL do
            if not self:GetAt(i) then
                free[#free + 1] = i
            end
        end

        if #free == 0 then return 0 end

        local made = 0
        for _ = 1, count do
            if #free == 0 then break end
            local pick = math.random(#free)
            local idx = table.remove(free, pick)
            self:SetTerrain(idx, kind)
            made = made + 1
        end

        if self.Render then self:Render() end
        return made
    end

    function Terrain:SeedPatch(kind, centerIndex, radius)
        kind = kind or "grass"
        centerIndex = tonumber(centerIndex) or 0
        radius = math.max(0, math.floor(tonumber(radius) or 1))

        if centerIndex < 1 or centerIndex > TOTAL then return 0 end

        local function RC(index)
            local i = index - 1
            return i % COLS, math.floor(i / COLS)
        end

        local cCol, cRow = RC(centerIndex)
        local made = 0

        for row = cRow - radius, cRow + radius do
            for col = cCol - radius, cCol + radius do
                if col >= 0 and col < COLS and row >= 0 and row < ROWS then
                    local idx = row * COLS + col + 1
                    self:SetTerrain(idx, kind)
                    made = made + 1
                end
            end
        end

        if self.Render then self:Render() end
        return made
    end

    -- ========================================================================
    -- СЛЭШ-КОМАНДЫ
    -- ========================================================================
    SLASH_NSDF_TERRAIN_LOGIC1 = "/ns_df_terr"
    SlashCmdList["NSDF_TERRAIN_LOGIC"] = function(msg)
        local T = NSQC4.QuestsDfTerrain
        if not T then return end

        local cmd, a1, a2, a3 = (msg or ""):match("^(%S*)%s*(%S*)%s*(%S*)%s*(%S*)")
        cmd = (cmd or ""):lower()

        if cmd == "" or cmd == "help" then
            print("|cff00ff00[NSQC4]|r df/terrain — логика")
            print("  /ns_df_terr types                — список типов")
            print("  /ns_df_terr set <index> <id>     — поставить тип")
            print("  /ns_df_terr clear <index>        — снять тип")
            print("  /ns_df_terr seed <id> [count]    — залить случайные")
            print("  /ns_df_terr patch <id> <center> [radius] — пятно")

        elseif cmd == "types" then
            local types = T:GetTypes() or {}
            local names = {}
            for id in pairs(types) do names[#names + 1] = id end
            table.sort(names)
            print("|cff00ff00[NSQC4]|r terrain types:", #names)
            for _, id in ipairs(names) do
                local o = types[id]
                print(string.format("  %s → %s", id, tostring(o and o.texture)))
            end

        elseif cmd == "set" then
            local index = tonumber(a1)
            local id = a2
            if index and id then T:SetTerrain(index, id) end

        elseif cmd == "clear" then
            local index = tonumber(a1)
            if index then T:ClearTerrain(index) end

        elseif cmd == "seed" then
            local id = a1 ~= "" and a1 or "grass"
            local n = tonumber(a2) or 20
            T:SeedDemo(id, n)

        elseif cmd == "patch" then
            local id = a1 ~= "" and a1 or "grass"
            local center = tonumber(a2)
            local radius = tonumber(a3) or 1
            if center then T:SeedPatch(id, center, radius) end
        end
    end

end)