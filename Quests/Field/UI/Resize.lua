-- ============================================================================
-- NSQC4 / Quests / Field / UI / Resize
-- Хэндл ресайза в правом нижнем углу.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS     = CONST.COLS, CONST.ROWS
    local CELL_GAP       = CONST.CELL_GAP
    local GRID_PADDING   = CONST.GRID_PADDING
    local MIN_CELL       = CONST.MIN_CELL
    local MAX_CELL       = CONST.MAX_CELL

    function QuestsField:CreateResizeHandle()
        local f = self.frame
        local h = CreateFrame("Button", "NSQC4FieldResize", f)
        h:SetSize(16, 16)
        h:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -4)
        h:SetFrameLevel(f:GetFrameLevel() + 30)
        h:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        h:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        h:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        h:EnableMouse(true)

        local anchorL, anchorT
        local lastCell
        local inst = self

        local function apply()
            local scale = UIParent:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            local rawW = cx - anchorL
            local rawH = anchorT - cy
            local csX = (rawW - (COLS - 1) * CELL_GAP - GRID_PADDING * 2) / COLS
            local csY = (rawH - (ROWS - 1) * CELL_GAP - GRID_PADDING * 2) / ROWS
            local cs = math.max(csX, csY)
            cs = math.floor(cs + 0.5)
            if cs < MIN_CELL then cs = MIN_CELL end
            if cs > MAX_CELL then cs = MAX_CELL end
            if cs == lastCell then return end
            lastCell = cs
            inst.cellSize = cs
            local w, hh = inst._FrameSizeForCell(cs)
            f:SetSize(w, hh)
            inst:ReflowCells()
            inst:ApplyBorderAnchors()
        end

        h:SetScript("OnMouseDown", function(self2, button)
            if button ~= "LeftButton" then return end
            anchorL = f:GetLeft()
            anchorT = f:GetTop()
            lastCell = nil
            self2:SetScript("OnUpdate", function()
                if not IsMouseButtonDown("LeftButton") then
                    self2:SetScript("OnUpdate", nil)
                    inst:Save()
                    return
                end
                apply()
            end)
            apply()
        end)
        h:SetScript("OnHide", function(self2) self2:SetScript("OnUpdate", nil) end)

        self.resizeHandle = h
        return h
    end
end)