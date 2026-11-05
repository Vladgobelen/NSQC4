-- ============================================================================
-- NSQC4 / Quests / df / Transform / Drops
-- Лут в клетке: хранение в лут-якорях (все 9, кроме TOPLEFT) + рендер.
--
--   cell.loot = { [anchor] = { id, icon }, ... }   -- занятые лут-якоря
--
-- TOPLEFT — под существо, лут туда НЕ кладётся.
--
-- РАМКА ВОКРУГ ЛУТ-ЯКОРЯ:
--   Каждый лут (ARTWORK/7) обёрнут тонкой рамкой 1 px (Frame с backdrop
--   WHITE8x8, edgeSize = 1, прозрачная заливка, чёрная граница).
--   Рамка создаётся в самом Drops.lua (btn._lootBorders[anchor]) — вокруг
--   лут-текстуры (tex), а НЕ вокруг btn.anchors[pos] (это якорь существа).
--   Anchors.lua больше НЕ вызывает SetAnchorBorder — вокруг существа
--   рамки нет. Рамка только вокруг лута.
--
-- ЯКОРЬ ВЫШЕ ЛУТА:
--   Якорь (существо) — ARTWORK/8 (ANCHOR_SUBLEVEL = 8 в Anchors.lua).
--   Лут — ARTWORK/7. Якорь рисуется ВЫШЕ лута. Не меняем subLevel лута.
--
-- API:
--   Drops:FreeAnchors(index)       → массив свободных лут-якорей
--   Drops:HasAny(index)            → true, если занят хоть один лут-якорь
--   Drops:Count(index)             → сколько лут-якорей занято
--   Drops:Add(index, id, icon)     → положить в свободный лут-якорь (или nil)
--   Drops:Get(index, anchor)       → { id, icon } | nil
--   Drops:GetAll(index)            → массив { anchor, id, icon }
--   Drops:Clear(index)             → убрать весь лут клетки
--   Drops:Render(index)            → перерисовать лут клетки
--   Drops:RenderAll()              → перерисовать все клетки
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Drops = {}
    NSQC4.QuestsDfTransformDrops = Drops

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Transform/Drops: поле не загружено.")
        return
    end

    local Grid = NSQC4.QuestsDfGrid
    if not Grid then
        print("|cffff0000[NSQC4]|r Transform/Drops: Grid не загружен.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100

    -- Лут-якоря: все 9, кроме TOPLEFT (он под существо).
    local LOOT_ANCHORS = {
        "TOPCENTER", "TOPRIGHT",
        "MIDLEFT",   "CENTER",    "MIDRIGHT",
        "BOTLEFT",   "BOTCENTER", "BOTRIGHT",
    }

    Drops.LOOT_ANCHORS = LOOT_ANCHORS

    -- ========================================================================
    -- Параметры рамки вокруг лут-текстуры
    -- ========================================================================
    local LOOT_SUBLEVEL  = 7         -- лут — ARTWORK/7 (якорь выше: ARTWORK/8)
    local BORDER_SIZE    = 1         -- 1 px
    local BORDER_R       = 0.0
    local BORDER_G       = 0.0
    local BORDER_B       = 0.0
    local BORDER_A       = 1.0
    local BORDER_PAD     = 1         -- выступ рамки наружу на 1 px,
                                     -- чтобы edgeSize=1 не перекрывал иконку

    local function EnsureLoot(index)
        local c = Grid:GetCell(index)
        if not c then return nil end
        if not c.loot then c.loot = {} end
        return c.loot
    end

    -- ========================================================================
    -- Свободные лут-якоря клетки
    -- ========================================================================
    function Drops:FreeAnchors(index)
        local c = Grid:GetCell(index)
        if not c then return {} end
        if c.terrain == "void" then return {} end   -- в пустоте лут-якоря «заняты»
        local loot = c.loot or {}
        local free = {}
        for _, a in ipairs(LOOT_ANCHORS) do
            if not loot[a] then free[#free + 1] = a end
        end
        return free
    end

    -- ========================================================================
    -- Есть ли лут в клетке
    -- ========================================================================
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

    -- ========================================================================
    -- Положить дроп в свободный лут-якорь.
    -- Возвращает anchor или nil (если свободных нет / void).
    -- ========================================================================
    function Drops:Add(index, id, icon)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        if not id then return nil end

        local free = self:FreeAnchors(index)
        if #free == 0 then return nil end

        local anchor = free[1]
        local loot = EnsureLoot(index)
        if not loot then return nil end

        loot[anchor] = { id = id, icon = icon }
        self:Render(index)
        return anchor
    end

    -- ========================================================================
    -- Получить дроп по anchor
    -- ========================================================================
    function Drops:Get(index, anchor)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return nil end
        return c.loot[anchor]
    end

    -- ========================================================================
    -- Все дропы клетки (массив { anchor, id, icon })
    -- ========================================================================
    function Drops:GetAll(index)
        local c = Grid:GetCell(index)
        if not c or not c.loot then return {} end
        local list = {}
        for _, a in ipairs(LOOT_ANCHORS) do
            local d = c.loot[a]
            if d then
                list[#list + 1] = { anchor = a, id = d.id, icon = d.icon }
            end
        end
        return list
    end

    -- ========================================================================
    -- Очистить лут клетки
    -- ========================================================================
    function Drops:Clear(index)
        local c = Grid:GetCell(index)
        if not c then return false end
        c.loot = nil
        self:Render(index)
        return true
    end

    -- ========================================================================
    -- Очистить визуал лута (текстуры + рамки)
    -- ========================================================================
    local function ClearLootTextures(index)
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then return end

        if btn._lootTextures then
            for _, tex in pairs(btn._lootTextures) do
                tex:Hide()
                tex:ClearAllPoints()
                tex:SetTexture(nil)
            end
            btn._lootTextures = nil
        end

        if btn._lootBorders then
            for _, border in pairs(btn._lootBorders) do
                border:Hide()
            end
        end
    end

    -- ========================================================================
    -- Создать/обновить рамку вокруг лут-текстуры tex (в клетке index,
    -- для якоря anchor). Рамка — Frame с backdrop WHITE8x8, edgeSize = 1.
    -- BORDER_PAD = 1 — рамка на 1 px больше иконки со всех сторон;
    -- SetBackdrop рисует границу ВНУТРИ этого Frame — снаружи иконки.
    -- ========================================================================
    local function SetLootBorder(index, anchor, tex)
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn or not tex then return end

        if not btn._lootBorders then btn._lootBorders = {} end
        local border = btn._lootBorders[anchor]

        if not border then
            border = CreateFrame("Frame", nil, btn)
            border:SetFrameLevel(btn:GetFrameLevel() + 11)
            border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = BORDER_SIZE,
            })
            border:SetBackdropColor(0, 0, 0, 0)
            border:SetBackdropBorderColor(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
            btn._lootBorders[anchor] = border
        end

        border:ClearAllPoints()
        border:SetPoint("TOPLEFT",     tex, "TOPLEFT",     -BORDER_PAD,  BORDER_PAD)
        border:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT",  BORDER_PAD, -BORDER_PAD)
        border:Show()
    end

    -- ========================================================================
    -- Рендер лута клетки: каждая иконка — в свой лут-якорь + рамка вокруг
    -- ========================================================================
    function Drops:Render(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then return false end

        ClearLootTextures(index)

        local c = Grid:GetCell(index)
        if not c or not c.loot then return true end

        btn._lootTextures = {}

        for anchor, d in pairs(c.loot) do
            local tex = btn:CreateTexture(nil, "ARTWORK", nil, LOOT_SUBLEVEL)
            tex:SetDrawLayer("ARTWORK", LOOT_SUBLEVEL)
            tex:SetTexture(d.icon)
            tex:SetTexCoord(0, 1, 0, 1)
            -- размер и позиция — как у существа (1/3 клетки), через якорь
            local size = btn:GetWidth() / 3
            tex:SetSize(size, size)
            if anchor == "TOPCENTER" then
                tex:SetPoint("TOP", btn, "TOP", 0, 0)
            elseif anchor == "TOPRIGHT" then
                tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
            elseif anchor == "MIDLEFT" then
                tex:SetPoint("LEFT", btn, "LEFT", 0, 0)
            elseif anchor == "CENTER" then
                tex:SetPoint("CENTER", btn, "CENTER", 0, 0)
            elseif anchor == "MIDRIGHT" then
                tex:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
            elseif anchor == "BOTLEFT" then
                tex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
            elseif anchor == "BOTCENTER" then
                tex:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
            elseif anchor == "BOTRIGHT" then
                tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            end
            tex:Show()
            btn._lootTextures[anchor] = tex

            -- рамка вокруг лут-текстуры (1 px, снаружи)
            SetLootBorder(index, anchor, tex)
        end

        return true
    end

    function Drops:RenderAll()
        for i = 1, TOTAL do
            self:Render(i)
        end
    end

end)