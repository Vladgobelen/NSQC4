-- ============================================================================
-- NSQC4 / Quests / df / Transform / Drops
-- Лут: слой OVERLAY.
--
-- ЕДИНОЕ ПРАВИЛО: у всех лут-якорей одна логика размера/слоя/позиции.
-- Текстура берётся по d.id из таблицы ICON_BY_ID (fallback → d.icon → nil).
--
-- ПОРЯДОК СЛОЁВ (все — текстуры на btn, один frame level btn+10):
--   sublevel 2 — бордер лута (4 тонкие текстуры)
--   sublevel 3 — иконка лута
--   sublevel 4 — anchor существа (Anchors.lua)
--   sublevel 5 — temp существа (Entities/UI/Api.lua)
--
-- РАНЬШЕ бордер лута был ФРЕЙМОМ btn+11 — выше любых текстур btn+10,
-- поэтому существа оказывались ПОД дропами. Теперь бордер — текстуры
-- с sublevel 2, и всё в одном frame level: лут < anchor < temp.
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
    local ANCHOR_INSET = CONST and CONST.ANCHOR_INSET or 0

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

    local LOOT_LAYER    = "OVERLAY"
    local LOOT_SUBLEVEL = 3

    local BORDER_LAYER    = "OVERLAY"
    local BORDER_SUBLEVEL = 2      -- ниже лута(3), anchor(4), temp(5)
    local BORDER_SIZE     = 1

    Drops.DEBUG = false

    local function dbg(...)
        if Drops.DEBUG then print("|cff00ffff[DROPS]|r", ...) end
    end

    -- Единый резолвер иконки: ICON_BY_ID[id] → d.icon → nil
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
    function Drops:Add(index, id)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return nil end
        if not id then return nil end
        local free = self:FreeAnchors(index)
        if #free == 0 then return nil end
        local anchor = free[1]
        local loot = EnsureLoot(index)
        if not loot then return nil end
        loot[anchor] = { id = id }
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

    -- ========================================================================
    -- Очистка текстур лута и его бордеров
    -- ========================================================================
    local function ClearLootBorders(btn)
        if not btn._lootBorders then return end
        for _, sides in pairs(btn._lootBorders) do
            for _, tex in ipairs(sides) do
                tex:Hide()
                tex:ClearAllPoints()
                tex:SetTexture(nil)
            end
        end
        btn._lootBorders = nil
    end

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
        ClearLootBorders(btn)
    end

    -- ========================================================================
    -- Бордер лута: 4 тонкие текстуры на btn с sublevel 2.
    -- ========================================================================
    local function SetLootBorder(index, anchor, lootTex)
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn or not lootTex then return end
        if not btn._lootBorders then btn._lootBorders = {} end
        local sides = btn._lootBorders[anchor]
        if not sides then
            sides = {}
            for i = 1, 4 do
                local t = btn:CreateTexture(nil, BORDER_LAYER, nil, BORDER_SUBLEVEL)
                t:SetTexture("Interface\\Buttons\\WHITE8x8")
                t:SetVertexColor(0, 0, 0, 1)
                sides[i] = t
            end
            btn._lootBorders[anchor] = sides
        end

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

    -- Единое правило позиции для всех анкоров
    local function AnchorPoint(tex, btn, anchor)
        local ins = ANCHOR_INSET
        if anchor == "TOPCENTER" then
            tex:SetPoint("TOP", btn, "TOP", 0, -ins)
        elseif anchor == "TOPRIGHT" then
            tex:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -ins, -ins)
        elseif anchor == "MIDLEFT" then
            tex:SetPoint("LEFT", btn, "LEFT", ins, 0)
        elseif anchor == "CENTER" then
            tex:SetPoint("CENTER", btn, "CENTER", 0, 0)
        elseif anchor == "MIDRIGHT" then
            tex:SetPoint("RIGHT", btn, "RIGHT", -ins, 0)
        elseif anchor == "BOTLEFT" then
            tex:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", ins, ins)
        elseif anchor == "BOTCENTER" then
            tex:SetPoint("BOTTOM", btn, "BOTTOM", 0, ins)
        elseif anchor == "BOTRIGHT" then
            tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -ins, ins)
        end
    end

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
            local icon = ResolveIcon(d)
            local tex = btn:CreateTexture(nil, LOOT_LAYER, nil, LOOT_SUBLEVEL)
            tex:SetTexture(icon)
            tex:SetTexCoord(0, 1, 0, 1)
            local size = btn:GetWidth() / 3 - 2
            tex:SetSize(size, size)
            AnchorPoint(tex, btn, anchor)
            tex:Show()
            btn._lootTextures[anchor] = tex
            SetLootBorder(index, anchor, tex)
        end
        return true
    end

    function Drops:RefreshAllLootSizes()
        for i = 1, TOTAL do
            local btn = QuestsField.cells and QuestsField.cells[i]
            if btn and btn._lootTextures then
                local size = btn:GetWidth() / 3 - 2
                for anchor, tex in pairs(btn._lootTextures) do
                    if tex:IsShown() then
                        tex:SetSize(size, size)
                        SetLootBorder(i, anchor, tex)
                    end
                end
            end
        end
    end

    function Drops:RenderAll()
        for i = 1, TOTAL do
            self:Render(i)
        end
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

    print("|cff00ffff[DROPS]|r Drops загружен (бордер лута — текстуры sublevel 2, существа выше).")

end)