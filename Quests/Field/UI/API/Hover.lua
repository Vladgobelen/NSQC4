-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Hover
-- Управление поведением при наведении мыши.
--
-- OnEnter / OnLeave ставят btn._hovered = true/false.
-- Это использует AI/Work.lua, чтобы играть звук работы только когда
-- мышь на существе. Тултип тоже идёт через _onEnter/_onLeave.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local function ApplyHover(btn)
        if btn._hoverTexture and btn.hoverTexture then
            btn.hoverTexture:Show()
        end
        if btn._hoverHighlight then
            local r, g, b, a = unpack(btn._hoverHighlight)
            btn:SetBackdropBorderColor(r, g, b, a)
        end
    end

    local function ResetHover(btn)
        if btn.hoverTexture then
            btn.hoverTexture:Hide()
        end
        if btn._hoverHighlight then
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end

    function QuestsField:InitCellHover(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        if not btn._hoverInitialized then
            btn:SetScript("OnEnter", function(self2)
                self2._hovered = true
                ApplyHover(self2)
                if self2._onEnter then self2._onEnter(self2, index) end
            end)
            btn:SetScript("OnLeave", function(self2)
                self2._hovered = false
                ResetHover(self2)
                if self2._onLeave then self2._onLeave(self2, index) end
            end)
            btn._hoverInitialized = true
        end
    end

    function QuestsField:SetCellOnEnter(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onEnter = fn
        self:InitCellHover(index)
    end

    function QuestsField:SetCellOnLeave(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onLeave = fn
        self:InitCellHover(index)
    end

    function QuestsField:SetCellHoverTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

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
            btn._hoverTexture = texture
            btn.hoverTexture:SetTexture(texture)
            btn.hoverTexture:SetTexCoord(0, 1, 0, 1)
            btn.hoverTexture:SetAlpha(alpha or 1.0)
        else
            btn._hoverTexture = nil
            btn.hoverTexture:SetTexture(nil)
            btn.hoverTexture:Hide()
        end

        self:InitCellHover(index)
    end

    function QuestsField:SetCellHoverHighlight(index, r, g, b, a)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        btn._hoverHighlight = { r, g, b, a or 1 }
        self:InitCellHover(index)
    end
end)