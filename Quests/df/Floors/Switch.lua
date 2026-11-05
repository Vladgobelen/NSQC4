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
--   7. Render: Terrain:Render, Entities:Render, Drops:RenderAll.
--   8. (Отладка) принудительно скрыть все якоря существ на всякий случай.
--
-- Отладка:
--   Floors.DEBUG = true (по умолчанию)
--   /ns_floors on | off
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
    -- Рендер всего поля
    -- ========================================================================
    local function RenderAll()
        local Terrain  = NSQC4.QuestsDfTerrain
        local Entities = NSQC4.QuestsDfEntities
        local Drops    = NSQC4.QuestsDfTransformDrops
        local QuestsField = NSQC4.QuestsField

        dbg("Render: Terrain=" .. tostring(Terrain and "ok" or "nil") ..
            " Entities=" .. tostring(Entities and "ok" or "nil") ..
            " Drops=" .. tostring(Drops and "ok" or "nil") ..
            " Field=" .. tostring(QuestsField and "ok" or "nil"))

        -- Скрыть все якоря существ на всех клетках (старый этаж)
        if QuestsField and QuestsField.ClearAnchorTextures then
            local CONST = NSQC4.QuestsFieldConst
            local TOTAL = CONST and (CONST.COLS * CONST.ROWS) or 100
            for i = 1, TOTAL do
                QuestsField:ClearAnchorTextures(i)
            end
            dbg("Render: ClearAnchorTextures all")
        end

        -- Ландшафт
        if Terrain and Terrain.Render then
            Terrain:Render()
            dbg("Render: Terrain:Render done")
        else
            dbg("Render: Terrain:Render SKIPPED")
        end

        -- Существа
        if Entities and Entities.Render then
            Entities:Render()
            dbg("Render: Entities:Render done")
        else
            dbg("Render: Entities:Render SKIPPED")
        end

        -- Лут
        if Drops and Drops.RenderAll then
            Drops:RenderAll()
            dbg("Render: Drops:RenderAll done")
        else
            dbg("Render: Drops:RenderAll SKIPPED")
        end
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

        -- 6. Render
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