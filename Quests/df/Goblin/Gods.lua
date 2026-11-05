-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Gods
-- Три бога-основателя гоблинов: буквы-корни в имени.
--   1 — Ы, 2 — У, 4 — О
-- kinship = сумма битов по буквам в имени.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Gods = {}
    NSQC4.QuestsDfGoblinGods = Gods

    Gods.BITS = {
        [1] = "Ы",
        [2] = "У",
        [4] = "О",
    }

    Gods.MAX_BIT = 4

    function Gods:GetKinship(name)
        if type(name) ~= "string" or name == "" then return 0 end
        local lower = string.lower(name)
        local k = 0
        if lower:find("ы", 1, true) then k = k + 1 end
        if lower:find("у", 1, true) then k = k + 2 end
        if lower:find("о", 1, true) then k = k + 4 end
        return k
    end

    -- b, а не bit — чтобы не перекрывать глобальную таблицу bit в шаге цикла
    function Gods:GetGods(kinship)
        local list = {}
        kinship = tonumber(kinship) or 0
        local b = 1
        while b <= Gods.MAX_BIT do
            if math.floor(kinship / b) % 2 == 1 then
                local ch = Gods.BITS[b]
                if ch then list[#list + 1] = ch end
            end
            b = b * 2
        end
        return list
    end

    function Gods:GetByName(name)
        local k = self:GetKinship(name)
        return k, self:GetGods(k)
    end

end)