-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Anchors
-- Управление иконками (маркерами) в клетке.
-- Только визуал: SetAnchorTexture, SetAnchorExpanded,
-- ClearAnchorTexture, ClearAnchorTextures.
--
-- ANCHOR_INSET (из NSQC4.QuestsFieldConst.ANCHOR_INSET):
--   Дальность крайних якорей от центра клетки (px).
--     0 — якоря вплотную к краю (как было)
--     > 0 — якоря ближе к центру на N px
--   CENTER не двигается.
--
-- РАЗМЕР ИКОНКИ:
--   size = btn:GetWidth() / 3 - 1  (на 1 px меньше 1/3 клетки)
--
-- Рамка вокруг якоря (SetAnchorBorder) — API, НЕ вызывается из этого файла.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local CONST = NSQC4.QuestsFieldConst
    local ANCHOR_INSET = CONST and CONST.ANCHOR_INSET or 0

    local ANCHOR_POSITIONS = {
        "TOPLEFT", "TOPCENTER", "TOPRIGHT",
        "MIDLEFT", "CENTER",    "MIDRIGHT",
        "BOTLEFT", "BOTCENTER", "BOTRIGHT",
    }

    local ANCHOR_SUBLEVEL = 7

    -- ========================================================================
    -- Параметры рамки (API для будущего; не вызывается)
    -- ========================================================================
    local BORDER_SIZE  = 1
    local BORDER_R     = 0.0
    local BORDER_G     = 0.0
    local BORDER_B     = 0.0
    local BORDER_A     = 1.0
    local BORDER_PAD   = 1

    -- ========================================================================
    -- Ленивое создание якоря (текстуры)
    -- ========================================================================
    local function GetOrCreateAnchor(btn, pos)
        if not btn.anchors then btn.anchors = {} end
        local anchor = btn.anchors[pos]
        if not anchor then
            anchor = btn:CreateTexture(nil, "ARTWORK", nil, ANCHOR_SUBLEVEL)
            btn.anchors[pos] = anchor
        end
        anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
        return anchor
    end

    -- ========================================================================
    -- Позиционирование якоря с учётом ANCHOR_INSET.
    --   ins = ANCHOR_INSET:
    --     0 — вплотную к краю
    --     > 0 — ближе к центру на ins px
    --   CENTER — не двигается.
    -- ========================================================================
    local function ApplyAnchorPosition(texture, btn, pos, expanded)
        texture:ClearAllPoints()
        if expanded then
            texture:SetAllPoints(btn)
        else
            local size = btn:GetWidth() / 3 - 1
            texture:SetSize(size, size)

            local ins = ANCHOR_INSET

            if pos == "TOPLEFT" then
                texture:SetPoint("TOPLEFT", btn, "TOPLEFT", ins, -ins)
            elseif pos == "TOPCENTER" then
                texture:SetPoint("TOP", btn, "TOP", 0, -ins)
            elseif pos == "TOPRIGHT" then
                texture:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -ins, -ins)
            elseif pos == "MIDLEFT" then
                texture:SetPoint("LEFT", btn, "LEFT", ins, 0)
            elseif pos == "CENTER" then
                texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
            elseif pos == "MIDRIGHT" then
                texture:SetPoint("RIGHT", btn, "RIGHT", -ins, 0)
            elseif pos == "BOTLEFT" then
                texture:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", ins, ins)
            elseif pos == "BOTCENTER" then
                texture:SetPoint("BOTTOM", btn, "BOTTOM", 0, ins)
            elseif pos == "BOTRIGHT" then
                texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -ins, ins)
            end
        end
    end

    -- ========================================================================
    -- Рамка вокруг якоря (API, не вызывается из Anchors.lua)
    -- ========================================================================
    function QuestsField:SetAnchorBorder(index, pos, visible)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        if not btn.anchors or not btn.anchors[pos] then return end

        local anchor = btn.anchors[pos]

        if not btn._anchorBorders then btn._anchorBorders = {} end
        local border = btn._anchorBorders[pos]

        if visible then
            if not border then
                border = CreateFrame("Frame", nil, btn)
                border:SetFrameLevel(btn:GetFrameLevel() + 11)
                border:SetBackdrop({
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = BORDER_SIZE,
                })
                border:SetBackdropColor(0, 0, 0, 0)
                border:SetBackdropBorderColor(BORDER_R, BORDER_G, BORDER_B, BORDER_A)
                btn._anchorBorders[pos] = border
            end
            border:ClearAllPoints()
            border:SetPoint("TOPLEFT",     anchor, "TOPLEFT",     -BORDER_PAD,  BORDER_PAD)
            border:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT",  BORDER_PAD, -BORDER_PAD)
            border:Show()
        else
            if border then border:Hide() end
        end
    end

    -- ========================================================================
    -- Визуал якоря: текстура 1/3 клетки (expanded = false)
    -- ========================================================================
    function QuestsField:SetAnchorTexture(index, pos, texture)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        local anchor = GetOrCreateAnchor(btn, pos)
        if texture then
            ApplyAnchorPosition(anchor, btn, pos, false)
            anchor:SetTexture(texture)
            anchor:SetTexCoord(0, 1, 0, 1)
            anchor:SetVertexColor(1, 1, 1, 1)
            anchor:SetAlpha(1)
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
            anchor:Show()
        else
            anchor:SetTexture(nil)
            anchor:Hide()
        end
    end

    -- ========================================================================
    -- Визуал якоря с явным expanded (true → на всю клетку)
    -- ========================================================================
    function QuestsField:SetAnchorExpanded(index, pos, texture, expanded)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        local anchor = GetOrCreateAnchor(btn, pos)
        if texture then
            ApplyAnchorPosition(anchor, btn, pos, expanded)
            anchor:SetTexture(texture)
            anchor:SetTexCoord(0, 1, 0, 1)
            anchor:SetVertexColor(1, 1, 1, 1)
            anchor:SetAlpha(1)
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
            anchor:Show()
        else
            anchor:SetTexture(nil)
            anchor:Hide()
        end
    end

    -- ========================================================================
    -- Очистка одного якоря
    -- ========================================================================
    function QuestsField:ClearAnchorTexture(index, pos)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn or not btn.anchors or not btn.anchors[pos] then return end
        local anchor = btn.anchors[pos]
        anchor:SetTexture(nil)
        anchor:Hide()
    end

    -- ========================================================================
    -- Очистка всех якорей клетки
    -- ========================================================================
    function QuestsField:ClearAnchorTextures(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn or not btn.anchors then return end
        for _, pos in ipairs(ANCHOR_POSITIONS) do
            if btn.anchors[pos] then
                btn.anchors[pos]:SetTexture(nil)
                btn.anchors[pos]:Hide()
            end
        end
    end
end)