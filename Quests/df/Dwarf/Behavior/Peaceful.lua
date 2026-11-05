-- ============================================================================
-- NSQC4 / Quests / df / Dwarf / Behavior / Peaceful
-- Мирное поведение дворфа.
--
-- Пока совпадает с общим Default (idle → moving → working).
-- Когда появятся уникальные действия — переопределим Tick здесь.
--
-- Регистрация: Registry:Register("dwarf", "peaceful", handler)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Registry = NSQC4.QuestsDfBehavior
    if not Registry then
        print("|cffff0000[NSQC4]|r Dwarf/Peaceful: Behavior/Init.lua не загружен.")
        return
    end

    local Default = NSQC4.QuestsDfAIDefault
    if not Default then
        print("|cffff0000[NSQC4]|r Dwarf/Peaceful: AI/Default.lua не загружен.")
        return
    end

    -- Пока — делегируем в Default.
    Registry:Register("dwarf", "peaceful", {
        Tick = function(entity)
            return Default:Tick(entity)
        end,
    })

end)