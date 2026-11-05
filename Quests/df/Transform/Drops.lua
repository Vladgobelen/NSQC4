-- ============================================================================
-- NSQC4 / Quests / df / Transform / Drops
-- Хранение дропов в клетке и рендер в правый верхний угол.
--
-- Дропы живут в cell.drops = { { id, icon, anchor, count }, ... }.
-- Рендер: иконка (anchor, по умолчанию TOPRIGHT), размер 1/3 клетки.
-- Несколько дропов — стопкой со смещением вниз.
--
-- API:
--   Drops:Add(index, { id, icon, anchor })   — добавить дроп
--   Drops:Get(index)                         — массив дропов | nil
--   Drops:Count(index, id)                   — сколько дропов с данным id
--   Drops:Clear(index)                       — убрать все дропы клетки
--   Drops:Render(index)                      — перерисовать дропы клетки
--   Drops:RenderAll()                        — перерисовать все клетки
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

    local DROP_SIZE_PCT = 1 / 3   -- размер дропа относительно клетки
    local DROP_GAP      = 2       -- смещение между дропами (пиксели)

    -- ========================================================================
    -- Внутренний доступ к cell.drops
    -- ========================================================================
    local function GetCell(index)
        return Grid:GetCell(index)
    end

    local function EnsureDrops(index)
        local c = GetCell(index)
        if not c then return nil end
        if not c.drops then c.drops = {} end
        return c.drops
    end

    -- ========================================================================
    -- API: добавить дроп
    --   index — 1..100
    --   def   — { id, icon, anchor }
    -- Возвращает запись дропа или nil.
    -- ========================================================================
    function Drops:Add(index, def)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        if type(def) ~= "table" or not def.id then return nil end

        local drops = EnsureDrops(index)
        if not drops then return nil end

        local entry = {
            id     = def.id,
            icon   = def.icon,
            anchor = def.anchor or "TOPRIGHT",
            count  = 1,
        }
        drops[#drops + 1] = entry

        self:Render(index)
        return entry
    end

    -- ========================================================================
    -- API: получить дропы клетки
    -- ========================================================================
    function Drops:Get(index)
        local c = GetCell(index)
        return c and c.drops or nil
    end

    -- ========================================================================
    -- API: сколько дропов данного id в клетке
    -- ========================================================================
    function Drops:Count(index, id)
        local drops = self:Get(index)
        if not drops then return 0 end
        local n = 0
        for _, d in ipairs(drops) do
            if d.id == id then n = n + 1 end
        end
        return n
    end

    -- ========================================================================
    -- API: очистить дропы клетки
    -- ========================================================================
    function Drops:Clear(index)
        local c = GetCell(index)
        if not c then return false end
        c.drops = nil
        self:Render(index)
        return true
    end

    -- ========================================================================
    -- Внутренний: убрать визуальные текстуры дропов с клетки
    -- ========================================================================
    local function ClearDropTextures(index)
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then return end
        if btn._dropTextures then
            for _, tex in ipairs(btn._dropTextures) do
                tex:Hide()
                tex:ClearAllPoints()
                tex:SetTexture(nil)
            end
            btn._dropTextures = nil
        end
    end

    -- ========================================================================
    -- Рендер дропов клетки (правый верхний угол, стопка вниз)
    -- ========================================================================
    function Drops:Render(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then return false end

        ClearDropTextures(index)

        local drops = self:Get(index)
        if not drops or #drops == 0 then return true end

        btn._dropTextures = {}

        local cellW = btn:GetWidth()  or 0
        local cellH = btn:GetHeight() or 0
        local size  = math.floor(math.min(cellW, cellH) * DROP_SIZE_PCT)
        if size < 1 then size = 1 end

        local yOff = 0
        for i, d in ipairs(drops) do
            local tex = btn:CreateTexture(nil, "ARTWORK", nil, 7)
            tex:SetDrawLayer("ARTWORK", 7)
            tex:SetTexture(d.icon)
            tex:SetTexCoord(0, 1, 0, 1)
            tex:SetSize(size, size)

            -- правый верхний угол, стопкой вниз
            tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2 - yOff)

            tex:Show()
            btn._dropTextures[#btn._dropTextures + 1] = tex

            yOff = yOff + size + DROP_GAP
        end

        return true
    end

    -- ========================================================================
    -- Рендер всех клеток
    -- ========================================================================
    function Drops:RenderAll()
        for i = 1, TOTAL do
            self:Render(i)
        end
    end

end)