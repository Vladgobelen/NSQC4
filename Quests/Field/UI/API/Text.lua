-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Text
-- Управление текстом клетки (основной и при наведении).
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:SetCellText(index, text_main, text_hover, r, g, b, size)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        -- Ленивое создание основного текста (слой OVERLAY, subLevel 1)
        if not btn.text_main then
            btn.text_main = btn:CreateFontString(nil, "OVERLAY")
            btn.text_main:SetDrawLayer("OVERLAY", 1) -- жёсткая фиксация слоя
            btn.text_main:SetPoint("CENTER", 0, 0)
            btn.text_main:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        else
            btn.text_main:SetDrawLayer("OVERLAY", 1)
        end

        -- Ленивое создание текста при наведении (слой OVERLAY, subLevel 2 — над основным)
        if not btn.text_hover then
            btn.text_hover = btn:CreateFontString(nil, "OVERLAY")
            btn.text_hover:SetDrawLayer("OVERLAY", 2) -- жёсткая фиксация слоя
            btn.text_hover:SetPoint("CENTER", 0, 0)
            btn.text_hover:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        else
            btn.text_hover:SetDrawLayer("OVERLAY", 2)
        end

        -- Настройка основного текста
        if text_main and text_main ~= "" then
            btn.text_main:SetText(text_main)
            if r and g and b then btn.text_main:SetTextColor(r, g, b, 1) end
            if size then
                local path = btn.text_main:GetFont()
                if path then btn.text_main:SetFont(path, size, "OUTLINE") end
            end
            btn.text_main:Show()
        else
            btn.text_main:SetText("")
            btn.text_main:Hide()
        end

        -- Настройка текста при наведении
        if text_hover and text_hover ~= "" then
            btn.text_hover:SetText(text_hover)
            if r and g and b then btn.text_hover:SetTextColor(r, g, b, 1) end
            if size then
                local path = btn.text_hover:GetFont()
                if path then btn.text_hover:SetFont(path, size, "OUTLINE") end
            end
        else
            btn.text_hover:SetText("")
        end

        -- Изначально текст при наведении скрыт
        btn.text_hover:Hide()
    end

    function QuestsField:ClearCellText(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        if btn.text_main then btn.text_main:SetText(""); btn.text_main:Hide() end
        if btn.text_hover then btn.text_hover:SetText(""); btn.text_hover:Hide() end
    end
end)