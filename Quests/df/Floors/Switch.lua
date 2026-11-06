-- ============================================================================
-- NSQC4 / Quests / df / Floors / Switch
-- Переключение этажа + отладка.
--
-- Порядок:
--   1. CanSwitch(to) — если нельзя, сообщение и выход.
--   2. Animate:StopAll — оборвать анимации (temp со старого этажа).
--   3. Save текущего этажа (grid + selections + entities).
--   4. Generate(to), если этаж ещё не сгенерирован.
--   5. Load(to) — восстановить grid + selections + byName.
--   6. Set(to).
--   7. Render: QuestsField:RefreshAllCells() — поле само перечитает Grid
--      и перерисует все слои (terrain/build/loot/entity/highlight) +
--      тултипы/клики. Отдельные Terrain/Entities/Drops.Render не нужны —
--      RefreshAllCells делает всё то же + сбрасывает состояние кликов.
--
-- ШАГ 7:
--   Убран цикл QuestsField:ClearAnchorTextures(i) по 100 клеткам — это
--   deprecated API (см. Anchors.lua) и лишняя работа. ClearAllVisuals —
--   тоже больше не нужен: RefreshAllCells перечитывает Grid заново и
--   снимает все слои сам (если entity в клетке нет — spec.entity = nil).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = NSQC4.QuestsDfFloors
    if not Floors then
        print("|cffff0000[NSQC4]|r Floors/Switch: Init.lua не загружен.")
        return
    end

    local function dbg(...)
        if Floors.DEBUG then print("|cff00ffff[FLOORS-SW]|r", ...) end
    end

    -- ========================================================================
    -- Рендер всего поля через API поля.
    --   RefreshAllCells:
    --     - перечитывает Grid для каждой клетки
    --     - собирает ПОЛНЫЙ spec (bg/terrain/build/loot/entity/highlight)
    --     - перевешивает тултип/клики (по state key)
    --   Никаких ручных ClearAllVisuals / ClearAnchorTextures / RenderAll
    --   по слоям — это работа поля.
    -- ========================================================================
    local function RenderAll()
        local QuestsField = NSQC4.QuestsField
        if not QuestsField then
            dbg("Render: QuestsField не загружен")
            return
        end

        if not QuestsField.RefreshAllCells then
            dbg("Render: RefreshAllCells не найден (Field/UI/API/Refresh.lua не загружен?)")
            return
        end

        local ok = QuestsField:RefreshAllCells()
        dbg("Render: RefreshAllCells -> " .. tostring(ok))
    end

    -- ========================================================================
    -- Switch
    -- ========================================================================
    function Floors:Switch(to)
        to = tonumber(to) or 0
        local from = self:Get()
        dbg(string.format("Switch: from=%d to=%d", from, to))

        local ok, reason = self:CanSwitch(to)
        if not ok then
            print("|cffff0000[NSQC4]|r Нельзя переключить этаж: " .. tostring(reason))
            dbg("Switch: CanSwitch=false, reason=" .. tostring(reason))
            return false
        end
        dbg("Switch: CanSwitch=true")

        -- 1. Оборвать все анимации
        local Animate = NSQC4.QuestsDfEntitiesAnimate
        if Animate and Animate.StopAll then
            local n = Animate:StopAll()
            dbg("Switch: Animate:StopAll -> " .. tostring(n))
        else
            dbg("Switch: Animate:StopAll SKIPPED")
        end

        -- 2. Сохранить текущий этаж
        if self.Save then
            local okSave = self:Save()
            dbg("Switch: Save -> " .. tostring(okSave))
        else
            dbg("Switch: Save SKIPPED")
        end

        -- 3. Сгенерировать целевой, если нужно
        if not self:IsVisited(to) then
            if self.Generate then
                local okGen = self:Generate(to)
                dbg("Switch: Generate(" .. to .. ") -> " .. tostring(okGen))
            else
                dbg("Switch: Generate SKIPPED")
            end
        else
            dbg("Switch: floor " .. to .. " already visited")
        end

        -- 4. Загрузить целевой
        if self.Load then
            local okLoad = self:Load(to)
            dbg("Switch: Load(" .. to .. ") -> " .. tostring(okLoad))
        else
            dbg("Switch: Load SKIPPED")
        end

        -- 5. Set текущего
        self:Set(to)
        dbg("Switch: Set(" .. to .. ") -> current=" .. tostring(self:Get()))

        -- 6. Render — через API поля
        RenderAll()

        -- 7. Обновить кнопки этажей (если есть)
        local QuestsField = NSQC4.QuestsField
        if QuestsField and QuestsField.RefreshFloorButtons then
            QuestsField.RefreshFloorButtons()
            dbg("Switch: RefreshFloorButtons done")
        end

        print(string.format("|cff00ff00[NSQC4]|r Этаж: %d → %d", from, to))
        return true
    end

end)