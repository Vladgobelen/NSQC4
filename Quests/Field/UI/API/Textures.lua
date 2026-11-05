-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Textures
-- Управление основной текстурой и ховер-текстурой клетки.
-- Основная текстура (ландшафт): BACKGROUND / subLevel 0 — самый низ.
-- Ховер-текстура:              BORDER     / subLevel 2 — над ландшафтом, под иконками.
--
-- ОТСТУП ТЕКСТУРЫ (TEXTURE_INSET):
--   - borderless = nil (рамка есть) → inset = 1 px, чтобы текстура не
--     перекрывала 1 px рамки (рамка видна по краю кнопки).
--   - borderless = 1 (рамки нет)    → inset = 0, текстура на всю кнопку,
--     соседние клетки сливаются без просвета.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Отступ текстуры от края кнопки:
    --   1 — есть рамка (borderless = nil), 0 — нет (borderless = 1).
    -- ========================================================================
    local function TextureInset()
        return QuestsField:IsBorderless() and 0 or 1
    end

    -- ========================================================================
    -- Основная текстура (ландшафт) — самый низкий слой текстур.
    -- ========================================================================
    function QuestsField:SetCellTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        local inset = TextureInset()

        -- Ленивое создание: BACKGROUND, subLevel 0
        if not btn.texture then
            btn.texture = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
            btn.texture:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
            btn.texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
        end

        -- При каждом вызове — обновить слой и точки (inset мог измениться)
        btn.texture:SetDrawLayer("BACKGROUND", 0)
        btn.texture:ClearAllPoints()
        btn.texture:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        btn.texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)

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
    -- Ховер-текстура — над ландшафтом, под иконками.
    -- ========================================================================
    function QuestsField:SetCellHoverTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        local inset = TextureInset()

        -- Ленивое создание: BORDER, subLevel 2
        if not btn.hoverTexture then
            btn.hoverTexture = btn:CreateTexture(nil, "BORDER", nil, 2)
            btn.hoverTexture:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
            btn.hoverTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
            btn.hoverTexture:Hide()
        end

        btn.hoverTexture:SetDrawLayer("BORDER", 2)
        btn.hoverTexture:ClearAllPoints()
        btn.hoverTexture:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        btn.hoverTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)

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