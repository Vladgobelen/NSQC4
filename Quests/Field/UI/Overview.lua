-- ============================================================================
-- NSQC4 / Quests / Field / UI / Overview
-- Режим «обзор» (вид сверху / уменьшенный масштаб).
--
-- ИЗМЕНЕНИЯ (миграция на CellRender):
--   ShowOverview / HideOverview теперь зовут RefreshAllCellSizes() —
--   размеры лута/anchor/temp пересчитываются по btn:GetWidth(), когда
--   детальные клетки снова показываются.
--   RefreshOverviewLayout — без изменений (это layout overview-квадратов,
--   не клеток поля).
--
-- При активации:
--   - детальные клетки (QuestsField.cells) скрываются;
--   - показывается overviewFrame: 10×10 квадратов;
--   - наш этаж — ОДИН квадрат в центре (позиция OUR_COL/OUR_ROW);
--   - вокруг — чёрные «неизвестные» квадраты (10×10 = 100, наш 1 из 100);
--   - ВНУТРИ центрального квадрата — 10×10 пикселей (1 пиксель = 1 клетка
--     нашего этажа), цвет по типу ландшафта.
--
-- ОРИЕНТАЦИЯ:
--   В Grid row = 0 — НИЗ, row = ROWS-1 — ВЕРХ (как в детальном виде).
--   В overview используется TOPLEFT-якорь, поэтому row инвертируется:
--   (ROWS - 1 - row). Так верх детального вида совпадает с верхом overview.
--
-- Цвета (по ТЗ):
--   stone  — серый
--   tree   — тёмно-зелёный
--   grass  — светло-зелёный
--   water  — голубой
--   earth  — коричневый
--   void   — чёрный
--   pool   — бирюза (чуть темнее воды)
--   ladder — жёлтый
--   nil    — чёрный (пусто)
--
-- API:
--   QuestsField:ShowOverview()             — включить обзор
--   QuestsField:HideOverview()             — вернуться к детальному виду
--   QuestsField:ToggleOverview()           — переключить
--   QuestsField:IsOverview()               — true, если сейчас обзор
--   QuestsField:RefreshOverviewLayout()    — пересчитать раскладку и цвета
--                                            (вызывается из Frame.lua в OnSizeChanged)
--
-- Слэш: /ns_view — переключить detail ⇄ overview.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Overview: поле не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local COLS, ROWS = CONST.COLS, CONST.ROWS
    local TOTAL = COLS * ROWS

    -- ========================================================================
    -- Позиция нашего этажа в сетке overview 10×10.
    -- ========================================================================
    local OUR_COL = 4
    local OUR_ROW = 4

    -- ========================================================================
    -- Цвета по типу ландшафта (r, g, b)
    -- ========================================================================
    local TERRAIN_COLOR = {
        stone  = { 0.60, 0.60, 0.60 },   -- серый
        tree   = { 0.10, 0.40, 0.10 },   -- тёмно-зелёный
        grass  = { 0.40, 0.85, 0.40 },   -- светло-зелёный
        water  = { 0.30, 0.70, 1.00 },   -- голубой
        earth  = { 0.55, 0.35, 0.20 },   -- коричневый
        void   = { 0.00, 0.00, 0.00 },   -- чёрный
        pool   = { 0.15, 0.45, 0.75 },   -- бирюза (темнее воды)
        ladder = { 1.00, 0.85, 0.10 },   -- жёлтый
    }
    local DEFAULT_COLOR = { 0.00, 0.00, 0.00 }   -- пусто → чёрный

    -- ========================================================================
    -- Ленивое состояние
    -- ========================================================================
    local overviewFrame = nil
    local overviewCells = {}   -- 100 «больших» квадратов 10×10
    local centerPixels  = {}   -- 100 пикселей внутри центрального

    -- ========================================================================
    -- Ленивое создание overview-фрейма
    -- ========================================================================
    local function EnsureOverview()
        if overviewFrame then return overviewFrame end

        local f = QuestsField.frame
        if not f then return nil end

        local of = CreateFrame("Frame", "NSQC4OverviewFrame", f)
        of:SetAllPoints(f)
        of:SetFrameLevel(f:GetFrameLevel() + 20)
        of:EnableMouse(false)
        of:Hide()

        -- 10×10 «больших» квадратов (наш этаж + 99 чёрных)
        for row = 0, ROWS - 1 do
            for col = 0, COLS - 1 do
                local idx = row * COLS + col + 1
                local tex = of:CreateTexture(nil, "ARTWORK", nil, 0)
                tex:SetTexture("Interface\\Buttons\\WHITE8x8")
                tex:SetVertexColor(0, 0, 0, 1)   -- чёрный по умолчанию
                tex:SetPoint("TOPLEFT", of, "TOPLEFT", 0, 0)
                overviewCells[idx] = tex
            end
        end

        -- 10×10 пикселей внутри центрального (наш этаж)
        for row = 0, ROWS - 1 do
            for col = 0, COLS - 1 do
                local idx = row * COLS + col + 1
                local tex = of:CreateTexture(nil, "ARTWORK", nil, 1)
                tex:SetTexture("Interface\\Buttons\\WHITE8x8")
                tex:SetVertexColor(0, 0, 0, 1)
                tex:Hide()
                centerPixels[idx] = tex
            end
        end

        overviewFrame = of
        return of
    end

    -- ========================================================================
    -- Раскладка overview-квадратов и пикселей под текущий размер фрейма
    -- ========================================================================
    local function Layout()
        local of = overviewFrame
        if not of then return end

        local w = of:GetWidth() or 0
        local h = of:GetHeight() or 0
        if w <= 0 or h <= 0 then return end

        local cellW = w / COLS
        local cellH = h / ROWS

        -- overview-квадраты (10×10), row инвертирован: row=0 → низ
        for row = 0, ROWS - 1 do
            for col = 0, COLS - 1 do
                local idx = row * COLS + col + 1
                local tex = overviewCells[idx]
                if tex then
                    tex:ClearAllPoints()
                    tex:SetPoint("TOPLEFT", of, "TOPLEFT",
                        col * cellW,
                        -(ROWS - 1 - row) * cellH)
                    tex:SetSize(cellW, cellH)
                end
            end
        end

        -- пиксели внутри центрального (каждый = cellW/COLS × cellH/ROWS)
        -- row инвертирован: row=0 → низ центрального
        local pw = cellW / COLS
        local ph = cellH / ROWS
        for row = 0, ROWS - 1 do
            for col = 0, COLS - 1 do
                local idx = row * COLS + col + 1
                local tex = centerPixels[idx]
                if tex then
                    tex:ClearAllPoints()
                    tex:SetPoint("TOPLEFT", of, "TOPLEFT",
                        OUR_COL * cellW + col * pw,
                        -(OUR_ROW * cellH) - (ROWS - 1 - row) * ph)
                    tex:SetSize(pw, ph)
                end
            end
        end
    end

    -- ========================================================================
    -- Обновить цвета пикселей центрального квадрата по данным Grid
    -- ========================================================================
    local function RefreshCenterPixels()
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return end

        for idx = 1, TOTAL do
            local tex = centerPixels[idx]
            if tex then
                local t = Grid:GetTerrain(idx)
                local c = TERRAIN_COLOR[t] or DEFAULT_COLOR
                tex:SetVertexColor(c[1], c[2], c[3], 1)
                tex:Show()
            end
        end
    end

    -- ========================================================================
    -- Сбросить все «большие» квадраты в чёрный
    -- ========================================================================
    local function ClearBigCells()
        for idx = 1, TOTAL do
            local tex = overviewCells[idx]
            if tex then
                tex:SetVertexColor(0, 0, 0, 1)
                tex:Show()
            end
        end
    end

    -- ========================================================================
    -- Show / Hide / Toggle / Is / Refresh
    -- ========================================================================
    function QuestsField:ShowOverview()
        local of = EnsureOverview()
        if not of then return end

        -- Скрыть детальные клетки
        for i = 1, TOTAL do
            local btn = self.cells and self.cells[i]
            if btn then btn:Hide() end
        end

        -- Скрыть тултип
        GameTooltip:Hide()

        -- Раскладка + цвета
        Layout()
        ClearBigCells()
        RefreshCenterPixels()

        of:Show()
        self.viewMode = "overview"

        -- ФИКС: размеры клеток могли измениться, пока их не было видно
        if self.RefreshAllCellSizes then self:RefreshAllCellSizes() end
    end

    function QuestsField:HideOverview()
        if overviewFrame then
            overviewFrame:Hide()
        end

        -- Показать детальные клетки
        for i = 1, TOTAL do
            local btn = self.cells and self.cells[i]
            if btn then btn:Show() end
        end

        -- ФИКС: пересчитать размеры лута/anchor/temp — фрейм мог измениться
        -- в overview (ресайз не мог, но клетки были скрыты — на всякий случай).
        if self.RefreshAllCellSizes then self:RefreshAllCellSizes() end

        -- Перерисовать детальный вид
        local Terrain = NSQC4.QuestsDfTerrain
        if Terrain and Terrain.Render then Terrain:Render() end
        local Entities = NSQC4.QuestsDfEntities
        if Entities and Entities.Render then Entities:Render() end
        local Drops = NSQC4.QuestsDfTransformDrops
        if Drops and Drops.RenderAll then Drops:RenderAll() end

        self.viewMode = "detail"
    end

    function QuestsField:ToggleOverview()
        if self.viewMode == "overview" then
            self:HideOverview()
        else
            self:ShowOverview()
        end
    end

    function QuestsField:IsOverview()
        return self.viewMode == "overview"
    end

    -- ========================================================================
    -- Публичный метод: пересчитать раскладку и цвета.
    -- Вызывается из Frame.lua в OnSizeChanged, когда viewMode == "overview".
    -- ========================================================================
    function QuestsField:RefreshOverviewLayout()
        if not overviewFrame or self.viewMode ~= "overview" then return end
        Layout()
        RefreshCenterPixels()
    end

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSVIEW1 = "/ns_view"
    SlashCmdList["NSVIEW"] = function()
        local inst = NSQC4.QuestsField
        if not inst or not inst.ToggleOverview then
            print("|cffff0000[NSQC4]|r Overview не загружен.")
            return
        end
        inst:ToggleOverview()
        print("|cff00ff00[NSQC4]|r Режим: " .. tostring(inst.viewMode))
    end

end)