-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Anchors
-- Управление иконками (маркерами) в клетке.
-- Только визуал: SetAnchorTexture, SetAnchorExpanded,
-- ClearAnchorTexture, ClearAnchorTextures.
--
-- Клики НЕ здесь — регистрация кликов только через Mouse.lua
-- (SetCellOnMouseClick / ClearCellMouse). Реестр подмен кликов удалён:
-- TerrainUIApi сразу проверяет существо и вешает нужный клик.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local ANCHOR_POSITIONS = {
        "TOPLEFT", "TOPCENTER", "TOPRIGHT",
        "MIDLEFT", "CENTER",    "MIDRIGHT",
        "BOTLEFT", "BOTCENTER", "BOTRIGHT",
    }

    local ANCHOR_SUBLEVEL = 7

    local function GetOrCreateAnchor(btn, pos)
        if not btn.anchors then btn.anchors = {} end
        local anchor = btn.anchors[pos]
        if not anchor then
            anchor = btn:CreateTexture(nil, "ARTWORK", nil, ANCHOR_SUBLEVEL)
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
            btn.anchors[pos] = anchor
        else
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
        end
        return anchor
    end

    local function ApplyAnchorPosition(texture, btn, pos, expanded)
        texture:ClearAllPoints()
        if expanded then
            texture:SetAllPoints(btn)
        else
            local size = btn:GetWidth() / 3
            texture:SetSize(size, size)
            if pos == "TOPLEFT" then
                texture:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
            elseif pos == "TOPCENTER" then
                texture:SetPoint("TOP", btn, "TOP", 0, 0)
            elseif pos == "TOPRIGHT" then
                texture:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
            elseif pos == "MIDLEFT" then
                texture:SetPoint("LEFT", btn, "LEFT", 0, 0)
            elseif pos == "CENTER" then
                texture:SetPoint("CENTER", btn, "CENTER", 0, 0)
            elseif pos == "MIDRIGHT" then
                texture:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
            elseif pos == "BOTLEFT" then
                texture:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
            elseif pos == "BOTCENTER" then
                texture:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
            elseif pos == "BOTRIGHT" then
                texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            end
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