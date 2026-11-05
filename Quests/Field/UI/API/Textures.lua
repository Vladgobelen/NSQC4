-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Textures
-- Управление основной текстурой и ховер-текстурой клетки.
-- Основная текстура (ландшафт): BACKGROUND / subLevel 0 — самый низ.
-- Ховер-текстура:              BORDER     / subLevel 2 — над ландшафтом, под иконками.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Основная текстура (ландшафт) — самый низкий слой текстур.
    -- ========================================================================
    function QuestsField:SetCellTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        -- Ленивое создание: BACKGROUND, subLevel 0
        if not btn.texture then
            btn.texture = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
            btn.texture:SetDrawLayer("BACKGROUND", 0)
            btn.texture:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
            btn.texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        else
            btn.texture:SetDrawLayer("BACKGROUND", 0)
        end

        if texture then
            btn.texture:SetTexture(texture)
            btn.texture:SetTexCoord(0, 1, 0, 1)
            btn.texture:SetVertexColor(1, 1, 1, 1)
            btn.texture:SetAlpha(alpha or 1.0)
            btn.texture:Show()
        else
            btn.texture:SetTexture(nil)
            btn.texture:Hide()
        end
    end

    -- ========================================================================
    -- Ховер-текстура — над ландшафтом, под иконками существ.
    -- ========================================================================
    function QuestsField:SetCellHoverTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        -- Ленивое создание: BORDER, subLevel 2
        if not btn.hoverTexture then
            btn.hoverTexture = btn:CreateTexture(nil, "BORDER", nil, 2)
            btn.hoverTexture:SetDrawLayer("BORDER", 2)
            btn.hoverTexture:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
            btn.hoverTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
            btn.hoverTexture:Hide()
        else
            btn.hoverTexture:SetDrawLayer("BORDER", 2)
        end

        if texture then
            btn.hoverTexture:SetTexture(texture)
            btn.hoverTexture:SetTexCoord(0, 1, 0, 1)
            btn.hoverTexture:SetVertexColor(1, 1, 1, 1)
            btn.hoverTexture:SetAlpha(alpha or 1.0)
            btn.hoverTexture:Show()
        else
            btn.hoverTexture:SetTexture(nil)
            btn.hoverTexture:Hide()
        end
    end
end)