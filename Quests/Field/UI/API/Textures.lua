-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Textures
-- Слои (задаются при CreateTexture, SetDrawLayer не используем):
--   LOW     ← cell.texture (ландшафт)
--   MEDIUM  ← cell.build   (строение: лестница)
--   OVERLAY ← cell.hoverTexture (ховер — самый верх)
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local function TextureInset()
        return QuestsField:IsBorderless() and 0 or 1
    end

    function QuestsField:SetCellTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        local inset = TextureInset()

        if not btn.texture then
            btn.texture = btn:CreateTexture(nil, "LOW", nil, 0)
        end

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

    function QuestsField:SetCellBuild(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        local inset = TextureInset()

        if not btn.build then
            btn.build = btn:CreateTexture(nil, "MEDIUM", nil, 0)
            btn.build:Hide()
        end

        btn.build:ClearAllPoints()
        btn.build:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
        btn.build:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)

        if texture then
            btn.build:SetTexture(texture)
            btn.build:SetTexCoord(0, 1, 0, 1)
            btn.build:SetVertexColor(1, 1, 1, 1)
            btn.build:SetAlpha(alpha or 1.0)
            btn.build:Show()
        else
            btn.build:SetTexture(nil)
            btn.build:Hide()
        end
    end

    -- Ховер — самый верхний слой
    function QuestsField:SetCellHoverTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        local inset = TextureInset()

        if not btn.hoverTexture then
            btn.hoverTexture = btn:CreateTexture(nil, "OVERLAY", nil, 0)
            btn.hoverTexture:Hide()
        end

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