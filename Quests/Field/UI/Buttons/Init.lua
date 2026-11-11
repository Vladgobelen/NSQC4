-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Init
-- Универсальный рендерер кнопок.
--
-- НИЧЕГО не знает о поле (QuestsField) и об окнах (FieldWindow).
-- Рисует кнопки на любом parent-фрейме, где скажут.
--
-- Публичный API (NSQC4.UIButton):
--   CreateRecord(label, onClick, opts)       → rec
--   Draw(parent, rec, y, availableW)         → height
--   HitTest(rec)                             → boolean
--   FindHit(items)                           → rec | nil
--   Press(rec)
--   Release()
--   SetupMouse(parent, getItems)
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local UIButton = {}
    NSQC4.UIButton = UIButton

    local BUTTON_H = 24
    local PIXELS   = 2

    -- ========================================================================
    -- CreateRecord — создать запись кнопки (без отрисовки).
    -- ========================================================================
    function UIButton:CreateRecord(label, onClick, opts)
        return {
            kind    = "button",
            label   = label,
            onClick = onClick,
            opts    = opts or {},
        }
    end

    -- ========================================================================
    -- Draw — отрисовать кнопку на parent в позиции y.
    -- Возвращает высоту блока (для раскладки).
    -- ========================================================================
    function UIButton:Draw(parent, rec, y, availableW)
        if not parent then return 0 end

        if not rec.frame then
            local tex = parent:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:SetVertexColor(0.4, 0, 0, 1)

            local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetText(rec.label)
            fs:SetPoint("CENTER", tex, "CENTER", 0, 0)

            rec.frame = tex
            rec.text  = fs
        end

        rec.frame:ClearAllPoints()
        rec.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
        rec.frame:SetSize(availableW, BUTTON_H)
        rec.frame:Show()

        if rec.text then rec.text:Show() end

        return BUTTON_H + 4
    end

    -- ========================================================================
    -- HitTest — попал ли курсор в кнопку.
    -- ========================================================================
    function UIButton:HitTest(rec)
        if not rec or not rec.frame or not rec.frame:IsShown() then
            return false
        end

        local left  = rec.frame:GetLeft()
        local right = rec.frame:GetRight()
        local top   = rec.frame:GetTop()
        local bot   = rec.frame:GetBottom()

        if not (left and right and top and bot) then return false end

        local scale = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale

        return cx >= left and cx <= right and cy <= top and cy >= bot
    end

    -- ========================================================================
    -- FindHit — найти кнопку под курсором в таблице items.
    -- ========================================================================
    function UIButton:FindHit(items)
        if not items then return nil end

        for _, rec in pairs(items) do
            if rec.kind == "button" and self:HitTest(rec) then
                return rec
            end
        end

        return nil
    end

    -- ========================================================================
    -- Press / Release — анимация нажатия.
    -- ========================================================================
    function UIButton:Press(rec)
        if not rec or not rec.frame then return end

        local tex = rec.frame
        local w, h = tex:GetWidth(), tex:GetHeight()
        if not w or not h then return end

        tex:SetSize(w - PIXELS * 2, h - PIXELS * 2)
        self._pressed = { tex = tex, w = w, h = h }
    end

    function UIButton:Release()
        local p = self._pressed
        if not p then return end

        self._pressed = nil
        if p.tex and p.w and p.h then
            p.tex:SetSize(p.w, p.h)
        end
    end

    -- ========================================================================
    -- SetupMouse — подключить мышь к parent.
    --   getItems() — функция, возвращающая таблицу кнопок для хит-теста.
    -- ========================================================================
    function UIButton:SetupMouse(parent, getItems)
        if not parent or parent._uiButtonMouseSetup then return end
        parent._uiButtonMouseSetup = true
        parent:EnableMouse(true)

        parent:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then return end

            local items = getItems()
            local rec   = UIButton:FindHit(items)

            if rec then
                UIButton:Press(rec)
                if rec.onClick then rec.onClick(button) end
            end
        end)

        parent:SetScript("OnMouseUp", function()
            UIButton:Release()
        end)
    end
end, 530)