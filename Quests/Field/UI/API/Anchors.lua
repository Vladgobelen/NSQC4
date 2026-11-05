-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Anchors
-- Управление иконками (маркерами) в клетке.
-- Только визуал: SetAnchorTexture, SetAnchorExpanded,
-- ClearAnchorTexture, ClearAnchorTextures.
--
-- ВАЖНО:
--   - Якорь (иконка существа) рисуется НАД всем остальным в клетке:
--     ландшафт (BACKGROUND/0), ховер (BORDER/2), лут (ARTWORK/7),
--     текст (OVERLAY/1,2). Якорь — ARTWORK/subLevel 7, но поднят
--     FrameLevel'ом кнопки? Нет: ARTWORK/7 — текстура на уровне кнопки.
--     Чтобы якорь был ВЫШЕ лут-текстур (тоже ARTWORK/7) — используем
--     subLevel 7 у якоря и subLevel 7 у лута, но порядок создания
--     определяет «кто выше». Надёжнее — вынести якорь на OVERLAY/0
--     или поднять FrameLevel. Здесь якорь на ARTWORK/7, как было,
--     но с ЯВНЫМ SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL) при каждом
--     показе — чтобы пересоздание текстур не сбивало слой.
--
--   - Рамка вокруг якоря (1 px) — БОЛЬШЕ НЕ ВЫЗЫВАЕТСЯ отсюда.
--     Метод QuestsField:SetAnchorBorder(index, pos, visible) оставлен
--     как API (может пригодиться), но Anchors.lua его не зовёт.
--     Рамка вокруг ЛУТА — в Drops.lua (своя, вокруг лут-текстуры).
--
-- Клики НЕ здесь — регистрация кликов только через Mouse.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local ANCHOR_POSITIONS = {
        "TOPLEFT", "TOPCENTER", "TOPRIGHT",
        "MIDLEFT", "CENTER",    "MIDRIGHT",
        "BOTLEFT", "BOTCENTER", "BOTRIGHT",
    }

    -- Якорь (иконка существа) — ARTWORK, subLevel 7.
    -- Лут (Drops.lua) — тоже ARTWORK/7. Чтобы якорь был ВЫШЕ лута,
    -- якорь дополнительно поднимаем по FrameLevel кнопки — но текстуры
    -- не имеют своего FrameLevel, они рисуются на уровне родителя.
    -- Значит «выше» = позже создан / больше subLevel. Оставляем 7,
    -- но SetDrawLayer вызываем при каждом показе — чтобы не сбивалось.
    local ANCHOR_SUBLEVEL = 7

    -- ========================================================================
    -- Параметры рамки (API для будущего; Anchors.lua не вызывает)
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
        -- Всегда переустанавливаем слой — чтобы якорь был на ARTWORK/7
        -- даже если текстура была пересоздана или слой сбит.
        anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
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
    -- Рамка вокруг якоря (API, не вызывается из Anchors.lua).
    -- Оставлен для возможного использования в будущем.
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
            -- слой — при каждом показе (пересоздание не собьёт)
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
            anchor:Show()
            -- рамка НЕ вызывается (существо без рамки)
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
            -- слой — при каждом показе
            anchor:SetDrawLayer("ARTWORK", ANCHOR_SUBLEVEL)
            anchor:Show()
            -- рамка НЕ вызывается
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
        -- рамка НЕ трогается (существо без рамки)
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