-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Hit
-- Одна логика: хит-тест кнопок панелей (HitPanelButton).
--
-- Не рисует, не создаёт, не регистрирует. Только проверка попадания
-- курсора (x, y в координатах frame) в видимую кнопку панели.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

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
    -- HitPanelButton — попадание в видимую кнопку панели.
    -- x, y — координаты курсора в системе frame (BOTTOMLEFT = 0,0).
    -- ========================================================================
    function QuestsField:HitPanelButton(x, y)
        local list = self._panelButtons
        if not list then return nil end

        local bs = self:GetButtonSize()

        for _, rec in pairs(list) do
            if rec.texture:IsShown() then
                local cellIndex = CellForSlot(rec.side, rec.slot)
                if cellIndex then
                    local cx, cy = self:PanelButtonXY(rec.side, cellIndex)
                    if cx and x >= cx - bs/2 and x <= cx + bs/2
                           and y >= cy - bs/2 and y <= cy + bs/2 then
                        return rec
                    end
                end
            end
        end

        return nil
    end
end, 466)