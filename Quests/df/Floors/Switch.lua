-- ============================================================================
-- NSQC4 / Quests / df / Floors / Switch
-- Переключение этажа:
--   1. Проверить CanSwitch(to) — если нельзя, сообщение и выход.
--   2. Сохранить текущий этаж (Floors:Save()).
--   3. Если целевой не сгенерирован — Generate(to).
--   4. Загрузить целевой этаж (Floors:Load(to)) — восстановить grid.
--   5. Set(to), перерисовать (Terrain, Entities, Drops).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = NSQC4.QuestsDfFloors
    if not Floors then
        print("|cffff0000[NSQC4]|r Floors/Switch: Init.lua не загружен.")
        return
    end

    function Floors:Switch(to)
        to = tonumber(to) or 0

        local ok, reason = self:CanSwitch(to)
        if not ok then
            print("|cffff0000[NSQC4]|r Нельзя переключить этаж: " .. tostring(reason))
            return false
        end

        local from = self:Get()

        -- сохранить текущий
        if self.Save then self:Save() end

        -- сгенерировать целевой, если нужно
        if not self:IsVisited(to) then
            self:Generate(to)
        end

        -- загрузить целевой
        if self.Load then self:Load(to) end

        self:Set(to)

        -- перерисовать
        local Terrain = NSQC4.QuestsDfTerrain
        local Entities = NSQC4.QuestsDfEntities
        local Drops = NSQC4.QuestsDfTransformDrops
        if Terrain and Terrain.Render then Terrain:Render() end
        if Entities and Entities.Render then Entities:Render() end
        if Drops and Drops.RenderAll then Drops:RenderAll() end

        print(string.format("|cff00ff00[NSQC4]|r Этаж: %d → %d", from, to))
        return true
    end

end)