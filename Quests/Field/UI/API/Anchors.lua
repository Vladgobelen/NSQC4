-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Anchors
-- Иконки существ: OVERLAY/4.
--
-- ФИКС (два anchor в одной клетке):
--   SetAnchorExpanded / SetAnchorTexture перед установкой скрывают ВСЕ
--   другие позиции в клетке. Раньше TOPLEFT оставался видимым при
--   развороте в CENTER — два anchor одновременно.
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

    local ANCHOR_LAYER    = "OVERLAY"
    local ANCHOR_SUBLEVEL = 4

    local BORDER_SIZE = 1
    local BORDER_R, BORDER_G, BORDER_B, BORDER_A = 0, 0, 0, 1
    local BORDER_PAD = 1

    QuestsField._AnchorDebug = false

    local function dbg(...)
        if QuestsField._AnchorDebug then
            print("|cff00ffff[ANCH]|r", ...)
        end
    end

    local function GetOrCreateAnchor(btn, pos)
        if not btn.anchors then btn.anchors = {} end
        local anchor = btn.anchors[pos]

        if anchor then
            local ok, layer = pcall(function() return anchor:GetDrawLayer() end)
            if not ok or layer ~= ANCHOR_LAYER then
                anchor:Hide()
                anchor:SetTexture(nil)
                anchor:ClearAllPoints()
                anchor = nil
                btn.anchors[pos] = nil
            end
        end

        if not anchor then
            anchor = btn:CreateTexture(nil, ANCHOR_LAYER, nil, ANCHOR_SUBLEVEL)
            btn.anchors[pos] = anchor
        end

        return anchor
    end

    -- ========================================================================
    -- Скрыть все anchor-позиции в клетке, КРОМЕ pos.
    -- ========================================================================
    local function HideOtherAnchors(btn, pos)
        if not btn or not btn.anchors then return end
        for _, other in ipairs(ANCHOR_POSITIONS) do
            if other ~= pos and btn.anchors[other] then
                btn.anchors[other]:SetTexture(nil)
                btn.anchors[other]:Hide()
            end
        end
        if btn._anchorExpanded then
            for other in pairs(btn._anchorExpanded) do
                if other ~= pos then btn._anchorExpanded[other] = nil end
            end
        end
    end

    function QuestsField:GetAnchorPos(index, expanded)
        local btn = self.cells and self.cells[index]
        if not btn then return nil end
        local left   = btn:GetLeft()
        local bottom = btn:GetBottom()
        local cw     = btn:GetWidth()
        local ch     = btn:GetHeight()
        if not left or not bottom or not cw or not ch then return nil end

        if expanded then
            local w, h = cw * 0.9, ch * 0.9
            return left + cw / 2, bottom + ch / 2, w, h, "CENTER"
        else
            local size = cw / 3 - 1
            local ins  = ANCHOR_INSET
            local cx   = left + ins + size / 2
            local cy   = bottom + ch - ins - size / 2
            return cx, cy, size, size, "TOPLEFT"
        end
    end

    local function ApplyAnchorPosition(texture, btn, pos, expanded, anchorIndex)
        texture:ClearAllPoints()

        local inst = NSQC4.QuestsField
        if not inst then return end
        local cx, cy, w, h, apos = inst:GetAnchorPos(anchorIndex, expanded)
        if not cx then return end

        texture:SetSize(w, h)
        if expanded then
            texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
        else
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

    function QuestsField:RefreshAnchorSizes(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn or not btn.anchors then return end
        for _, pos in ipairs(ANCHOR_POSITIONS) do
            local anchor = btn.anchors[pos]
            if anchor and anchor:IsShown() then
                local expanded = btn._anchorExpanded and btn._anchorExpanded[pos]
                ApplyAnchorPosition(anchor, btn, pos, expanded and true or false, index)
            end
        end
    end

    function QuestsField:RefreshAllAnchorSizes()
        local n = self.cells and #self.cells or 0
        for i = 1, n do self:RefreshAnchorSizes(i) end
    end

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
                border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = BORDER_SIZE })
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

    function QuestsField:SetAnchorTexture(index, pos, texture)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        local anchor = GetOrCreateAnchor(btn, pos)
        if texture then
            HideOtherAnchors(btn, pos)
            ApplyAnchorPosition(anchor, btn, pos, false, index)
            if not btn._anchorExpanded then btn._anchorExpanded = {} end
            btn._anchorExpanded[pos] = false
            anchor:SetTexture(texture)
            anchor:SetTexCoord(0, 1, 0, 1)
            anchor:SetVertexColor(1, 1, 1, 1)
            anchor:SetAlpha(1)
            anchor:Show()
        else
            anchor:SetTexture(nil); anchor:Hide()
            if btn._anchorExpanded then btn._anchorExpanded[pos] = nil end
        end
    end

    function QuestsField:SetAnchorExpanded(index, pos, texture, expanded)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        local anchor = GetOrCreateAnchor(btn, pos)
        if texture then
            expanded = expanded and true or false
            HideOtherAnchors(btn, pos)
            ApplyAnchorPosition(anchor, btn, pos, expanded, index)
            if not btn._anchorExpanded then btn._anchorExpanded = {} end
            btn._anchorExpanded[pos] = expanded
            anchor:SetTexture(texture)
            anchor:SetTexCoord(0, 1, 0, 1)
            anchor:SetVertexColor(1, 1, 1, 1)
            anchor:SetAlpha(1)
            anchor:Show()
        else
            anchor:SetTexture(nil); anchor:Hide()
            if btn._anchorExpanded then btn._anchorExpanded[pos] = nil end
        end
    end

    function QuestsField:ClearAnchorTexture(index, pos)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn or not btn.anchors or not btn.anchors[pos] then return end
        local anchor = btn.anchors[pos]
        anchor:SetTexture(nil); anchor:Hide()
        if btn._anchorExpanded then btn._anchorExpanded[pos] = nil end
    end

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
        if btn._anchorExpanded then
            for pos in pairs(btn._anchorExpanded) do
                btn._anchorExpanded[pos] = nil
            end
        end
    end

    print("|cff00ffff[ANCH]|r Anchors загружен (OVERLAY/4, HideOtherAnchors)")
end)