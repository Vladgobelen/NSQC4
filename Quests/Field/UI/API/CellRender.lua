-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / CellRender
-- ЕДИНСТВЕННЫЙ рендер клетки. Все слои создаются, двигаются и красятся
-- ЗДЕСЬ. Дф-слой только собирает spec (данные) и зовёт RenderCell.
--
-- ПОРЯДОК СЛОЁВ (снизу вверх, все — на btn, кроме entity temp):
--   bg       texture BACKGROUND -1   (подложка под ladder)
--   terrain  texture LOW        0    (ландшафт)
--   build    texture MEDIUM     0    (строение: лестница)
--   loot     textures OVERLAY   2..3 (border=2, icon=3)
--   anchor   texture OVERLAY    4    (существо в покое)
--   temp     frame  btn+20          (существо в пути, поверх всего)
--   highlight — это tint на terrain texture, а НЕ отдельный слой.
--
-- VOID: terrain = { texture=WHITE8x8, r=0,g=0,b=0,a=1 } в spec.
--   highlight = nil → tint остаётся чёрным (не затирается).
--   highlight = {...} → подсветка перекрывает void (осознанно).
--
-- SPEC:
-- {
--   bg        = { texture, r,g,b,a } | nil,
--   terrain   = { texture, r,g,b,a } | nil,
--   build     = { texture, r,g,b,a, alpha } | nil,
--   loot      = { { anchor, texture, r,g,b,a, border=bool }, ... } | nil,
--   entity    = {
--       anchor   = "TOPLEFT"|"CENTER"|...,
--       expanded = bool,
--       texture  = ...,
--       alpha    = 0..1,
--       moving   = bool,
--       posX     = number, posY = number,
--   } | nil,
--   highlight = { r,g,b,a } | nil,
--   text      = { main, hover, r,g,b,size } | nil,
-- }
--
-- API:
--   QuestsField:RenderCell(index, spec)          — полный рендер клетки
--   QuestsField:ClearCellRender(index)           — RenderCell(index, nil)
--   QuestsField:MoveCellEntity(index, x, y)      — temp в пути (без пересборки spec)
--   QuestsField:RefreshAllCellSizes()            — при ресайзе
--   QuestsField:RefreshCellSize(index)           — при ресайзе одной
--
-- ВАЖНО: RenderCell сохраняет btn._crSpec = spec в конце. Без этого
-- обёртки (Textures/Anchors/Drops/EntitiesUIApi) читают пустой spec и
-- затирают уже нарисованное.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r CellRender: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local DEFAULT_ALPHA  = 1.0
    local ENTITY_LEVEL_OFFSET = 20

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    -- ========================================================================
    -- Кэш на клетке: btn._cr = { bg, terrain, build, loot = {}, lootBorders = {}, anchor, temp }
    -- ========================================================================
    local function Cache(btn)
        if not btn._cr then
            btn._cr = { loot = {}, lootBorders = {} }
        end
        if not btn._cr.loot then btn._cr.loot = {} end
        if not btn._cr.lootBorders then btn._cr.lootBorders = {} end
        return btn._cr
    end

    -- ========================================================================
    -- Утилиты текстур
    -- ========================================================================
    local function EnsureTexture(btn, slot, layer, sublevel)
        local c = Cache(btn)
        local t = c[slot]
        if not t then
            t = btn:CreateTexture(nil, layer, nil, sublevel)
            t:SetTexture(nil)
            t:Hide()
            c[slot] = t
        end
        return t
    end

    local function ApplyTex(t, def)
        if not def or not def.texture then
            t:SetTexture(nil)
            t:Hide()
            return
        end
        t:SetTexture(def.texture)
        t:SetTexCoord(0, 1, 0, 1)
        t:SetVertexColor(def.r or 1, def.g or 1, def.b or 1, def.a or 1)
        t:SetAlpha(def.alpha or DEFAULT_ALPHA)
        t:Show()
    end

    -- ========================================================================
    -- Размеры сущностей/лута — считаются ЗДЕСЬ по btn:GetWidth()/Height()
    -- ========================================================================
    local function EntitySize(btn, expanded)
        local w = btn:GetWidth()  or 32
        local h = btn:GetHeight() or 32
        if expanded then
            return w * 0.9, h * 0.9
        end
        local ew = w / 3 - 1
        local eh = h / 3 - 1
        if ew < 1 then ew = 1 end
        if eh < 1 then eh = 1 end
        return ew, eh
    end

    local function LootSize(btn)
        local w = btn:GetWidth() or 32
        local s = w / 3 - 2
        if s < 1 then s = 1 end
        return s
    end

    -- ========================================================================
    -- Позиции
    -- ========================================================================
    local function AnchorPointTexture(tex, btn, anchor, inset, size)
        inset = inset or 0
        tex:ClearAllPoints()
        if anchor == "TOPLEFT" then
            tex:SetPoint("CENTER", btn, "TOPLEFT", inset + size/2, -(inset + size/2))
        elseif anchor == "TOPCENTER" then
            tex:SetPoint("TOP", btn, "TOP", 0, -inset)
        elseif anchor == "TOPRIGHT" then
            tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -inset, -inset)
        elseif anchor == "MIDLEFT" then
            tex:SetPoint("LEFT", btn, "LEFT", inset, 0)
        elseif anchor == "CENTER" then
            tex:SetPoint("CENTER", btn, "CENTER", 0, 0)
        elseif anchor == "MIDRIGHT" then
            tex:SetPoint("RIGHT", btn, "RIGHT", -inset, 0)
        elseif anchor == "BOTLEFT" then
            tex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", inset, inset)
        elseif anchor == "BOTCENTER" then
            tex:SetPoint("BOTTOM", btn, "BOTTOM", 0, inset)
        elseif anchor == "BOTRIGHT" then
            tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
        end
    end

    -- ========================================================================
    -- BORDER лута (4 тонкие текстуры OVERLAY/2)
    -- ========================================================================
    local BORDER_SUBLEVEL = 2
    local BORDER_SIZE = 1

    local function EnsureLootBorder(btn, anchor)
        local c = Cache(btn)
        local sides = c.lootBorders[anchor]
        if not sides then
            sides = {}
            for i = 1, 4 do
                local t = btn:CreateTexture(nil, "OVERLAY", nil, BORDER_SUBLEVEL)
                t:SetTexture("Interface\\Buttons\\WHITE8x8")
                t:SetVertexColor(0, 0, 0, 1)
                t:Hide()
                sides[i] = t
            end
            c.lootBorders[anchor] = sides
        end
        return sides
    end

    local function ApplyLootBorder(btn, anchor, lootTex, show)
        local c = Cache(btn)
        if not show then
            if c.lootBorders[anchor] then
                for _, t in ipairs(c.lootBorders[anchor]) do t:Hide() end
            end
            return
        end
        local sides = EnsureLootBorder(btn, anchor)
        local top, bottom, left, right = sides[1], sides[2], sides[3], sides[4]

        top:ClearAllPoints()
        top:SetPoint("TOPLEFT",  lootTex, "TOPLEFT",  -BORDER_SIZE,  BORDER_SIZE)
        top:SetPoint("TOPRIGHT", lootTex, "TOPRIGHT",  BORDER_SIZE,  BORDER_SIZE)
        top:SetHeight(BORDER_SIZE)
        top:Show()

        bottom:ClearAllPoints()
        bottom:SetPoint("BOTTOMLEFT",  lootTex, "BOTTOMLEFT",  -BORDER_SIZE, -BORDER_SIZE)
        bottom:SetPoint("BOTTOMRIGHT", lootTex, "BOTTOMRIGHT",  BORDER_SIZE, -BORDER_SIZE)
        bottom:SetHeight(BORDER_SIZE)
        bottom:Show()

        left:ClearAllPoints()
        left:SetPoint("TOPLEFT",    lootTex, "TOPLEFT",    -BORDER_SIZE, -BORDER_SIZE)
        left:SetPoint("BOTTOMLEFT", lootTex, "BOTTOMLEFT", -BORDER_SIZE,  BORDER_SIZE)
        left:SetWidth(BORDER_SIZE)
        left:Show()

        right:ClearAllPoints()
        right:SetPoint("TOPRIGHT",    lootTex, "TOPRIGHT",    BORDER_SIZE, -BORDER_SIZE)
        right:SetPoint("BOTTOMRIGHT", lootTex, "BOTTOMRIGHT", BORDER_SIZE,  BORDER_SIZE)
        right:SetWidth(BORDER_SIZE)
        right:Show()
    end

    -- ========================================================================
    -- TEMP (существо в пути) — фрейм btn+20, поверх всего
    -- ========================================================================
    local function EnsureTemp(btn)
        local c = Cache(btn)
        if c.temp then return c.temp end
        local f = CreateFrame("Frame", nil, btn)
        f:SetFrameLevel(btn:GetFrameLevel() + ENTITY_LEVEL_OFFSET)
        f:EnableMouse(false)
        f:Hide()
        local tex = f:CreateTexture(nil, "OVERLAY", nil, 0)
        tex:SetTexture(nil)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetAlpha(DEFAULT_ALPHA)
        tex:SetAllPoints(f)
        tex:Hide()
        c.temp = { frame = f, tex = tex }
        return c.temp
    end

    local function ApplyTemp(btn, entDef)
        local t = EnsureTemp(btn)
        if not entDef or not entDef.moving or not entDef.texture then
            t.frame:Hide()
            t.tex:SetTexture(nil)
            return
        end
        local w, h = EntitySize(btn, entDef.expanded)
        t.frame:ClearAllPoints()
        t.frame:SetSize(w, h)
        t.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
            entDef.posX or 0, entDef.posY or 0)
        t.frame:Show()
        t.tex:SetTexture(entDef.texture)
        t.tex:SetTexCoord(0, 1, 0, 1)
        t.tex:SetVertexColor(1, 1, 1, 1)
        t.tex:SetAlpha(entDef.alpha or DEFAULT_ALPHA)
        t.tex:Show()
    end

    -- ========================================================================
    -- РЕНДЕР
    -- ========================================================================
    function QuestsField:RenderCell(index, spec)
        index = Valid(index)
        if not index then return false end
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local c = Cache(btn)
        spec = spec or {}

        -- bg
        local bgTex = EnsureTexture(btn, "bg", "BACKGROUND", -1)
        if spec.bg then
            bgTex:ClearAllPoints()
            bgTex:SetAllPoints(btn)
            ApplyTex(bgTex, spec.bg)
        else
            bgTex:Hide()
        end

        -- terrain (учитываем inset из borderless)
        local inset = self:IsBorderless() and 0 or 1
        local terrainTex = EnsureTexture(btn, "terrain", "LOW", 0)
        if spec.terrain then
            terrainTex:ClearAllPoints()
            terrainTex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     inset, -inset)
            terrainTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
            -- highlight перекрывает base-цвет
            local t = spec.terrain
            local r, g, b, a = t.r or 1, t.g or 1, t.b or 1, t.a or 1
            if spec.highlight then
                local h = spec.highlight
                r, g, b, a = h.r or r, h.g or g, h.b or b, h.a or a
            end
            terrainTex:SetTexture(t.texture)
            terrainTex:SetTexCoord(0, 1, 0, 1)
            terrainTex:SetVertexColor(r, g, b, a)
            terrainTex:SetAlpha(t.alpha or DEFAULT_ALPHA)
            terrainTex:Show()
        else
            terrainTex:SetTexture(nil)
            terrainTex:Hide()
        end

        -- build
        local buildTex = EnsureTexture(btn, "build", "MEDIUM", 0)
        if spec.build and spec.build.texture then
            buildTex:ClearAllPoints()
            buildTex:SetPoint("TOPLEFT",     btn, "TOPLEFT",     inset, -inset)
            buildTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
            ApplyTex(buildTex, spec.build)
        else
            buildTex:SetTexture(nil)
            buildTex:Hide()
        end

        -- loot (пул текстур на anchor)
        local lootSpecs = spec.loot or {}
        local usedAnchors = {}
        for _, item in ipairs(lootSpecs) do
            if item.anchor and item.texture then
                usedAnchors[item.anchor] = true
                local lootTex = c.loot[item.anchor]
                if not lootTex then
                    lootTex = btn:CreateTexture(nil, "OVERLAY", nil, 3)
                    c.loot[item.anchor] = lootTex
                end
                local s = LootSize(btn)
                lootTex:SetSize(s, s)
                lootTex:SetTexture(item.texture)
                lootTex:SetTexCoord(0, 1, 0, 1)
                lootTex:SetVertexColor(item.r or 1, item.g or 1, item.b or 1, item.a or 1)
                AnchorPointTexture(lootTex, btn, item.anchor, CONST.ANCHOR_INSET or 0, s)
                lootTex:Show()
                ApplyLootBorder(btn, item.anchor, lootTex, item.border ~= false)
            end
        end
        -- скрыть лут-якоря, которых больше нет
        for anchor, tex in pairs(c.loot) do
            if not usedAnchors[anchor] then
                tex:Hide()
                ApplyLootBorder(btn, anchor, tex, false)
            end
        end

        -- entity (anchor или temp)
        if spec.entity and spec.entity.texture then
            local ent = spec.entity
            if ent.moving then
                -- в пути — temp, anchor спрятан
                local anchorTex = EnsureTexture(btn, "anchor", "OVERLAY", 4)
                anchorTex:SetTexture(nil); anchorTex:Hide()
                ApplyTemp(btn, ent)
            else
                -- в покое — anchor, temp спрятан
                local temp = c.temp
                if temp then temp.frame:Hide(); temp.tex:SetTexture(nil) end
                local anchorTex = EnsureTexture(btn, "anchor", "OVERLAY", 4)
                local w, h = EntitySize(btn, ent.expanded)
                anchorTex:SetSize(w, h)
                anchorTex:SetTexture(ent.texture)
                anchorTex:SetTexCoord(0, 1, 0, 1)
                anchorTex:SetVertexColor(1, 1, 1, 1)
                anchorTex:SetAlpha(ent.alpha or DEFAULT_ALPHA)
                AnchorPointTexture(anchorTex, btn, ent.anchor or "TOPLEFT", CONST.ANCHOR_INSET or 0, w)
                anchorTex:Show()
            end
        else
            local anchorTex = EnsureTexture(btn, "anchor", "OVERLAY", 4)
            anchorTex:SetTexture(nil); anchorTex:Hide()
            local temp = c.temp
            if temp then temp.frame:Hide(); temp.tex:SetTexture(nil) end
        end

        -- текст (main/hover) — через старый механизм Text.lua
        if spec.text then
            self:SetCellText(index, spec.text.main, spec.text.hover,
                spec.text.r, spec.text.g, spec.text.b, spec.text.size)
        else
            self:ClearCellText(index)
        end

        -- ФИКС: сохранить spec — его читают обёртки (Textures/Anchors/Drops/
        -- EntitiesUIApi) и RefreshCellSize. Без этого все слои затирают
        -- друг друга (btn._crSpec == nil → spec = {} → всё скрыто).
        btn._crSpec = spec

        -- ФИКС: сохранить последний entity-spec для RefreshCellSize
        btn._crLastEntity = spec.entity

        return true
    end

    -- ========================================================================
    -- Очистка рендера клетки (без тултипа/кликов — их снимает дф)
    -- ========================================================================
    function QuestsField:ClearCellRender(index)
        return self:RenderCell(index, nil)
    end

    -- ========================================================================
    -- Движение temp (в пути) — без пересборки всего spec
    -- ========================================================================
    function QuestsField:MoveCellEntity(index, x, y)
        index = Valid(index)
        if not index then return false end
        local btn = self.cells and self.cells[index]
        if not btn then return false end
        local c = Cache(btn)
        if not c.temp or not c.temp.frame or not c.temp.frame:IsShown() then
            return false
        end
        c.temp.frame:ClearAllPoints()
        c.temp.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x or 0, y or 0)
        return true
    end

    -- ========================================================================
    -- Ресайз: пересчитать размеры лута и существ по btn:GetWidth()
    -- ========================================================================
    function QuestsField:RefreshCellSize(index)
        index = Valid(index)
        if not index then return false end
        local btn = self.cells and self.cells[index]
        if not btn then return false end
        local c = Cache(btn)

        local s = LootSize(btn)
        for anchor, tex in pairs(c.loot) do
            if tex:IsShown() then
                tex:SetSize(s, s)
                AnchorPointTexture(tex, btn, anchor, CONST.ANCHOR_INSET or 0, s)
                ApplyLootBorder(btn, anchor, tex, true)
            end
        end

        if c.anchor and c.anchor:IsShown() then
            local entSpec = btn._crLastEntity
            local expanded = entSpec and entSpec.expanded or false
            local w, h = EntitySize(btn, expanded)
            c.anchor:SetSize(w, h)
            local anchorName = (entSpec and entSpec.anchor) or "TOPLEFT"
            AnchorPointTexture(c.anchor, btn, anchorName, CONST.ANCHOR_INSET or 0, w)
        end

        if c.temp and c.temp.frame and c.temp.frame:IsShown() then
            local entSpec = btn._crLastEntity
            local expanded = entSpec and entSpec.expanded or false
            local w, h = EntitySize(btn, expanded)
            c.temp.frame:SetSize(w, h)
        end
        return true
    end

    function QuestsField:RefreshAllCellSizes()
        for i = 1, TOTAL do
            self:RefreshCellSize(i)
        end
    end

    print("|cff00ffff[CR]|r CellRender загружен (btn._crSpec сохраняется).")

end)