-- ============================================================================
-- NSQC4 / Quests / df / Transform / Drops
-- Лут: данные + сборка spec.loot для поля.
--
-- ВАЖНО (шаг 5b — через API поля):
--   Дропы БОЛЬШЕ НЕ лезут в btn._crSpec и НЕ зовут RenderCell со
--   собранным spec. Всё, что делает Drops:
--     - хранит c.loot[anchor] = { id, icon }
--     - отдаёт BuildLootSpec(index) → массив { anchor, texture, border }
--     - зовёт QuestsField:SetCellLootSpec(index, list) — поле само мержит
--       слой loot в btn._crSpec и перерисовывает
--
--   RefreshAllLootSizes → no-op (поле пересчитывает размеры само через
--   QuestsField:RefreshAllCellSizes, вызывается из Frame/Resize/Overview).
--
-- ICON_BY_ID — единственный резолвер иконки по id дропа.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Drops = {}
    NSQC4.QuestsDfTransformDrops = Drops

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then return end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then return end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    local IMG = "Interface\\AddOns\\NSQC4\\Media\\Images\\"

    -- Единая таблица иконок по id дропа
    local ICON_BY_ID = {
        wood  = IMG .. "00t",
        stone = IMG .. "0ka",
        herb  = IMG .. "00f",
        earth = IMG .. "00z",
    }

    local LOOT_ANCHORS = {
        "TOPCENTER", "TOPRIGHT",
        "MIDLEFT",   "CENTER",    "MIDRIGHT",
        "BOTLEFT",   "BOTCENTER", "BOTRIGHT",
    }
    Drops.LOOT_ANCHORS = LOOT_ANCHORS

    Drops.DEBUG = false

    local function dbg(...)
        if Drops.DEBUG then print("|cff00ffff[DROPS]|r", ...) end
    end

    local function ResolveIcon(d)
        if not d then return nil end
        if d.id and ICON_BY_ID[d.id] then return ICON_BY_ID[d.id] end
        if d.icon then return d.icon end
        return nil
    end

    local function EnsureLoot(index)
        local c = Grid:GetCell(index)
        if not c then return nil end
        if not c.loot then c.loot = {} end
        return c.loot
    end

    -- ========================================================================
    -- Сборка spec.loot для поля
    --   Возвращает массив { anchor, texture, border=true } или nil.
    -- ========================================================================
    function Drops:BuildLootSpec(index)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return nil end

        local list = {}
        for _, anchor in ipairs(LOOT_ANCHORS) do
            local d = c.loot[anchor]
            if d then
                local icon = ResolveIcon(d)
                if icon then
                    list[#list + 1] = {
                        anchor  = anchor,
                        texture = icon,
                        border  = true,
                    }
                end
            end
        end
        if #list == 0 then return nil end
        return list
    end

    -- ========================================================================
    -- Рендер клетки: отдать поле готовый loot-spec.
    --   Поле (SetCellLootSpec) само:
    --     - берёт btn._crSpec
    --     - заменяет .loot
    --     - зовёт RenderCell (там spec сохраняется обратно)
    -- ========================================================================
    function Drops:Render(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end
        return QuestsField:SetCellLootSpec(index, self:BuildLootSpec(index))
    end

    function Drops:RenderAll()
        for i = 1, TOTAL do
            self:Render(i)
        end
    end

    -- ========================================================================
    -- @deprecated
    -- Размеры теперь пересчитывает поле (QuestsField:RefreshAllCellSizes).
    -- Оставлено no-op для совместимости с Frame/Resize/Overview, которые
    -- ещё могут звать Drops.RefreshAllLootSizes.
    -- ========================================================================
    function Drops:RefreshAllLootSizes()
        if QuestsField.RefreshAllCellSizes then
            QuestsField:RefreshAllCellSizes()
        end
    end

    -- ========================================================================
    -- Данные (без изменений)
    -- ========================================================================
    function Drops:FreeAnchors(index)
        local c = Grid:GetCell(index)
        if not c then return {} end
        if c.terrain == "void" then return {} end
        local loot = c.loot or {}
        local free = {}
        for _, a in ipairs(LOOT_ANCHORS) do
            if not loot[a] then free[#free + 1] = a end
        end
        return free
    end

    function Drops:HasAny(index)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return false end
        for _ in pairs(c.loot) do return true end
        return false
    end

    function Drops:Count(index)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return 0 end
        local n = 0
        for _ in pairs(c.loot) do n = n + 1 end
        return n
    end

    function Drops:CountAllById(id)
        if not id then return 0 end
        local n = 0
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c and c.loot then
                for _, d in pairs(c.loot) do
                    if d.id == id then n = n + 1 end
                end
            end
        end
        return n
    end

    function Drops:TakeFromAnywhere(id)
        if not id then return false end
        for i = 1, TOTAL do
            local c = Grid:GetCell(i)
            if c and c.loot then
                for anchor, d in pairs(c.loot) do
                    if d.id == id then
                        c.loot[anchor] = nil
                        local anyLeft = false
                        for _ in pairs(c.loot) do anyLeft = true; break end
                        if not anyLeft then c.loot = nil end
                        self:Render(i)
                        return true
                    end
                end
            end
        end
        return false
    end

    -- Add теперь принимает только id. Иконка — из ICON_BY_ID.
    function Drops:Add(index, id, iconOverride)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        if not id then return nil end
        local free = self:FreeAnchors(index)
        if #free == 0 then return nil end
        local anchor = free[1]
        local loot = EnsureLoot(index)
        if not loot then return nil end
        loot[anchor] = { id = id, icon = iconOverride }
        self:Render(index)
        return anchor
    end

    function Drops:Get(index, anchor)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return nil end
        return c.loot[anchor]
    end

    function Drops:GetAll(index)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return {} end
        local list = {}
        for _, a in ipairs(LOOT_ANCHORS) do
            local d = c.loot[a]
            if d then
                list[#list + 1] = { anchor = a, id = d.id }
            end
        end
        return list
    end

    function Drops:Clear(index)
        local c = Grid:GetCell(index)
        if not c then return false end
        c.loot = nil
        self:Render(index)
        return true
    end

    SLASH_NSDROPS1 = "/ns_drops"
    SlashCmdList["NSDROPS"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then
            Drops.DEBUG = true
            print("[DROPS] DEBUG = true")
        elseif cmd == "off" then
            Drops.DEBUG = false
            print("[DROPS] DEBUG = false")
        else
            print("[DROPS] /ns_drops on | off")
        end
    end

    print("|cff00ffff[DROPS]|r Drops загружен (шаг 5b: через QuestsField:SetCellLootSpec, без btn._crSpec).")

end)