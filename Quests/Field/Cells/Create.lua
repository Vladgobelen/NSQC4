-- ============================================================================
-- NSQC4 / Quests / Field / Cells / Create
-- Одна логика: сетка 10×10 ЛИНИЯМИ (20 текстур), а не 100 клетками.
--
--   self.gridLines = {
--       v = { [1..COLS+1] = texture },   -- вертикальные линии
--       h = { [1..ROWS+1] = texture },   -- горизонтальные линии
--   }
--   self._pressTex  = texture          -- одна текстура «вдавливания» клетки
--
-- Слои:
--   линии  ARTWORK sublevel 4   (видимый серый 0.5 — контраст и на чёрной
--                                подложке, и на фоне мира)
--   press  OVERLAY sublevel 5   (как было)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS = CONST.COLS, CONST.ROWS

    local LINE_COLOR  = { 0.5, 0.5, 0.5, 1 }
    local PRESS_ALPHA = 0.35

    function QuestsField:CreateCells()
        if self.gridLines then return self.gridLines end

        local f = self.frame
        if not f then return nil end

        local lines = { v = {}, h = {} }

        -- Вертикальные линии: COLS + 1
        for i = 1, COLS + 1 do
            local tex = f:CreateTexture(nil, "ARTWORK", nil, 4)
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:SetVertexColor(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4])
            tex:SetWidth(1)
            tex:Hide()
            lines.v[i] = tex
        end

        -- Горизонтальные линии: ROWS + 1
        for i = 1, ROWS + 1 do
            local tex = f:CreateTexture(nil, "ARTWORK", nil, 4)
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:SetVertexColor(LINE_COLOR[1], LINE_COLOR[2], LINE_COLOR[3], LINE_COLOR[4])
            tex:SetHeight(1)
            tex:Hide()
            lines.h[i] = tex
        end

        -- «Вдавливание» клетки при клике — одна текстура, не 100
        local press = f:CreateTexture(nil, "OVERLAY", nil, 5)
        press:SetTexture("Interface\\Buttons\\WHITE8x8")
        press:SetVertexColor(0, 0, 0, PRESS_ALPHA)
        press:Hide()

        self.gridLines = lines
        self._pressTex = press

        return lines
    end

end, 320)