-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw
-- Одна логика: отрисовка кнопок панелей.
--
-- Только RefreshAllButtons и GetButtonSize.
-- Хит-тест — в Hit.lua, клик — в Click.lua, мышь — в Mouse.lua.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB
    if not QuestsField or not NSDB then return end

    local SIZE = 32

    local STEP = {
        TOP    =  1,
        RIGHT  = -10,
        LEFT   = -10,
        BOTTOM =  1,
    }

    local FIRST_CELL = {
        TOP    = 91,
        RIGHT  = 100,
        LEFT   = 91,
        BOTTOM = 1,
    }

    local function CellForSlot(side, slot)
        local step  = STEP[side]
        local first = FIRST_CELL[side]
        if not step or not first or not slot then return nil end
        return first + step * slot
    end

    -- ========================================================================
    -- Размер кнопки (минимум из cellSize и 32)
    -- ========================================================================
    function QuestsField:GetButtonSize()
        local cs = self.cellSize or SIZE
        if cs < SIZE then return cs end
        return SIZE
    end

    -- ========================================================================
    -- Отрисовка всех зарегистрированных кнопок панелей
    -- ========================================================================
    function QuestsField:RefreshAllButtons()
        local f = self.frame
        if not f then return end

        self._panelButtons = self._panelButtons or {}

        local buttons = NSDB:Table("buttons")
        if not buttons then return end

        local bs = self:GetButtonSize()

        for key, data in pairs(buttons) do
            local side = data.side
            local cellIndex = data.slot and CellForSlot(side, data.slot)

            if cellIndex then
                local rec = self._panelButtons[key]
                if not rec then
                    rec = { texture = f:CreateTexture(nil, "OVERLAY", nil, 10),
                            side = side, slot = data.slot }
                    self._panelButtons[key] = rec
                end

                rec.settings   = data
                rec.panelIndex = data.panelIndex
                rec.slot       = data.slot

                local show = (data.panelIndex == self:GetPanelIndex(side))

                local v = (data.opts and data.opts.visible) or 1
                if v == 2 then show = show and self.borderVisible == true
                elseif v == 3 then show = show and self.borderVisible == false end

                if show then
                    local cx, cy = self:PanelButtonXY(side, cellIndex)
                    if cx then
                        rec.texture:SetTexture(data.icon)
                        local c = data.opts and data.opts.color
                        if c then rec.texture:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
                        else rec.texture:SetVertexColor(1, 1, 1, 1) end

                        rec.texture:ClearAllPoints()
                        rec.texture:SetPoint("CENTER", f, "BOTTOMLEFT", cx, cy)

                        if not self:IsPressed(rec.texture) then
                            rec.texture:SetSize(bs, bs)
                        end
                        rec.texture:Show()
                    else
                        rec.texture:Hide()
                    end
                else
                    rec.texture:Hide()
                end
            end
        end
    end
end, 465)