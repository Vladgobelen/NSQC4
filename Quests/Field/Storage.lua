-- ============================================================================
-- NSQC4 / Quests / Field / Storage
-- Хранилище nsDbc4.quests.field + API флага и шаблона заполнения.
-- Модуль: quests.
--
-- borderless:
--   nil (по умолчанию) — рамка клеток есть (0.25, 0.25, 0.25, 1),
--                        текстура с отступом 1 px (рамка видна).
--   1                  — рамки нет (0, 0, 0, 0), клетки перекрываются
--                        (gap -1), текстура на всю клетку (inset 0).
-- Хранится в nsDbc4.quests.field.borderless. Переживает /reload.
--
-- SetBorderless при переключении:
--   1. Меняет SetBackdropBorderColor у всех клеток.
--   2. ReflowCells() — пересчитывает gap (-1 или 0).
--   3. Terrain:Render() — перерисовывает текстуры (inset 0 или 1).
-- Без шагов 2 и 3 клетки/текстуры останутся в старом состоянии
-- до следующего ресайза/рендера.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Гарантирует, что таблица существует
    -- ========================================================================
    function QuestsField:EnsureStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        nsDbc4.quests.field = nsDbc4.quests.field or {}
        return nsDbc4.quests.field
    end

    -- ========================================================================
    -- Загрузка из nsDbc4 → self
    -- ========================================================================
    function QuestsField:Load()
        local s = self:EnsureStorage()
        self.saved = {
            x             = s.x,
            y             = s.y,
            cellSize      = s.cellSize,
            borderVisible = s.borderVisible,
        }
    end

    -- ========================================================================
    -- Сохранение self → nsDbc4
    -- ========================================================================
    function QuestsField:Save()
        local s = self:EnsureStorage()

        if self.frame then
            s.x = self.frame:GetLeft()
            s.y = self.frame:GetBottom()
        end

        if self.cellSize then
            s.cellSize = self.cellSize
        end

        s.borderVisible = self.borderVisible and true or false
    end

    -- ========================================================================
    -- API: флаг «поле заполнено» — един на всё поле
    -- ========================================================================
    function QuestsField:IsFilled()
        local s = self:EnsureStorage()
        return s.filled and true or false
    end

    function QuestsField:SetFilled(v)
        local s = self:EnsureStorage()
        s.filled = v and true or false
    end

    -- ========================================================================
    -- API: шаблон заполнения поля
    -- ========================================================================
    function QuestsField:GetFillTemplate()
        local s = self:EnsureStorage()
        return s.template
    end

    function QuestsField:SetFillTemplate(tpl)
        local s = self:EnsureStorage()
        s.template = tpl
        return s.template
    end

    -- ========================================================================
    -- API: «без рамки клеток» (borderless).
    --   nil  → рамка есть (по умолчанию)
    --   1    → рамки нет (клетки сливаются вплотную)
    -- Хранится в nsDbc4.quests.field.borderless.
    -- ========================================================================
    function QuestsField:IsBorderless()
        local s = self:EnsureStorage()
        return s.borderless == 1
    end

    function QuestsField:SetBorderless(v)
        local s = self:EnsureStorage()
        s.borderless = (v == 1) and 1 or nil

        -- 1. Рамка у всех клеток
        if self.cells then
            local r, g, b, a
            if s.borderless == 1 then
                r, g, b, a = 0, 0, 0, 0
            else
                r, g, b, a = 0.25, 0.25, 0.25, 1
            end
            for i = 1, #self.cells do
                local btn = self.cells[i]
                if btn then
                    btn:SetBackdropBorderColor(r, g, b, a)
                end
            end
        end

        -- 2. Пересчитать раскладку (gap зависит от borderless)
        if self.frame and self.ReflowCells then
            self:ReflowCells()
        end

        -- 3. Перерисовать текстуры (inset зависит от borderless)
        local Terrain = NSQC4.QuestsDfTerrain
        if Terrain and Terrain.Render then
            Terrain:Render()
        end
    end

end)