-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw / Refresh
-- Одна логика: оркестрация отрисовки всех кнопок панелей.
--
-- Вызывает:
--   ShouldShowButton       (Visible.lua)
--   SetButtonPosition      (Position.lua)
--   ApplyButtonAppearance  (Appearance.lua)
--   ApplyButtonSize        (Size.lua)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB
    if not QuestsField or not NSDB then return end

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

    function QuestsField:RefreshAllButtons()
        local f = self.frame
        if not f then return end

        self._panelButtons = self._panelButtons or {}
        local buttons = NSDB:Table("buttons")
        if not buttons then return end

        for key, data in pairs(buttons) do
            local side = data.side
            local cellIndex = data.slot and CellForSlot(side, data.slot)

            if cellIndex then
                -- Создаем текстуру, если ее еще нет
                local rec = self._panelButtons[key]
                if not rec then
                    rec = { 
                        texture = f:CreateTexture(nil, "OVERLAY", nil, 10),
                        side = side, 
                        slot = data.slot 
                    }
                    self._panelButtons[key] = rec
                end

                rec.settings   = data
                rec.panelIndex = data.panelIndex
                rec.slot       = data.slot

                -- 1. Видимость
                local show = self:ShouldShowButton(data)
                if show then
                    -- 2. Позиция
                    local posOk = self:SetButtonPosition(rec, cellIndex)
                    if posOk then
                        -- 3. Внешний вид
                        self:ApplyButtonAppearance(rec, data)
                        -- 4. Размер
                        self:ApplyButtonSize(rec)
                        
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