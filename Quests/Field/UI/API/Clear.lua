-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Clear
-- Полная очистка визуала клетки и всего поля.
-- Клики НЕ трогает — их вешают/снимают модули через Mouse.
--
-- РАМКИ:
--   - Якорь существа (btn.anchors[pos]) — БЕЗ рамки.
--   - Лут (btn._lootTextures + btn._lootBorders) — рамка вокруг каждой
--     лут-текстуры. Здесь скрываем и текстуры, и рамки.
--
-- BORDERLESS:
--   Рамка клетки (SetBackdropBorderColor) выставляется через
--   QuestsField:IsBorderless():
--     - false (nil) → 0.25, 0.25, 0.25, 1  (рамка есть)
--     - true  (1)   → 0,    0,    0,    0  (рамки нет)
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS = CONST.COLS, CONST.ROWS

    function QuestsField:ClearCell(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        -- 1. Основная текстура (ландшафт)
        if btn.texture then
            btn.texture:SetTexture(nil)
            btn.texture:SetVertexColor(1, 1, 1, 1)
            btn.texture:Hide()
        end

        -- 2. Ховер-текстура
        if btn.hoverTexture then
            btn.hoverTexture:SetTexture(nil)
            btn.hoverTexture:Hide()
        end

        -- 3. Текст (основной и ховер)
        if btn.text_main then
            btn.text_main:SetText("")
            btn.text_main:Hide()
        end
        if btn.text_hover then
            btn.text_hover:SetText("")
            btn.text_hover:Hide()
        end

        -- 4. Иконки-якоря (существо) — без рамок
        if btn.anchors then
            for _, anchor in pairs(btn.anchors) do
                anchor:SetTexture(nil)
                anchor:Hide()
            end
        end

        -- 5. Лут-текстуры + их рамки
        if btn._lootTextures then
            for _, tex in pairs(btn._lootTextures) do
                tex:Hide()
                tex:ClearAllPoints()
                tex:SetTexture(nil)
            end
            btn._lootTextures = nil
        end
        if btn._lootBorders then
            for _, border in pairs(btn._lootBorders) do
                border:Hide()
            end
        end

        -- 6. Рамка кнопки — по IsBorderless()
        if self:IsBorderless() then
            btn:SetBackdropBorderColor(0, 0, 0, 0)
        else
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end

        -- 7. Ховер-обработчики
        btn._onEnter = nil
        btn._onLeave = nil
    end

    function QuestsField:ClearAll()
        for i = 1, COLS * ROWS do
            self:ClearCell(i)
        end
    end
end)