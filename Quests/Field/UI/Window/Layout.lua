-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / Layout
-- Одна логика: управление расположением элементов окна по вертикали (Y).
--
-- Не создает фреймы, текстуры или текст. Только двигает.
-- Порядок — строго по индексу (table.sort по числовым ключам).
-- Кнопки окна рисует универсальный рендерер NSQC4.UIButton:Draw.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    local START_Y   = -8
    local CONTENT_W = 16 -- отступы 8 слева + 8 справа

    function W:LayoutWindow(windowId)
        local win = self[windowId]
        if not win then return end

        local items = self._items and self._items[windowId]
        if not items then return end

        -- 1. Собираем и сортируем индексы (числовые — как числа)
        local indices = {}
        for i in pairs(items) do
            indices[#indices + 1] = i
        end
        table.sort(indices, function(a, b)
            if type(a) == "number" and type(b) == "number" then
                return a < b
            end
            return tostring(a) < tostring(b)
        end)

        local y          = START_Y
        local availableW = win:GetWidth() - CONTENT_W
        local UIButton   = NSQC4.UIButton

        -- 2. Проходим сверху вниз
        for _, i in ipairs(indices) do
            local rec = items[i]
            if rec then
                local h = 0

                if rec.kind == "label" and self.DrawLabel then
                    h = self:DrawLabel(windowId, rec, y, availableW)

                elseif rec.kind == "button" and UIButton and UIButton.Draw then
                    h = UIButton:Draw(win, rec, y, availableW)

                elseif rec.kind == "radio" and self.DrawRadio then
                    h = self:DrawRadio(windowId, rec, y, availableW)
                end

                y = y - (h or 0)
            end
        end
    end
end, 500)