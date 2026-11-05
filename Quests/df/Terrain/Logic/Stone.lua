-- ============================================================================
-- NSQC4 / Quests / df / Terrain / Logic / Stone
-- Логика и свойства типа "Камень" (stone).
--
-- Только поведение: onClick и contextMenu.
-- Базовые характеристики (hardness, texture, textSize, color) —
-- в df/Terrain/Data/Stone.lua.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local Terrain = NSQC4.QuestsDfTerrain
    if not Terrain then return end

    -- ========================================================================
    -- РЕГИСТРАЦИЯ СЕБЯ В СИСТЕМЕ
    -- ========================================================================
    Terrain:RegisterType("stone", {
        -- ====================================================================
        -- ЛОГИКА КЛИКА (ЛКМ)
        -- ====================================================================
        onClick = function(index)
            -- Разбираем камни (меняем на землю)
            Terrain:SetTerrain(index, "earth")
            print("|cff00ff00[NSQC4]|r Камни разобраны в клетке " .. index)
        end,

        -- ====================================================================
        -- КОНТЕКСТНОЕ МЕНЮ (ПКМ)
        -- ====================================================================
        contextMenu = {
            { text = "Добыть руду", func = function(index)
                Terrain:SetTerrain(index, "earth")
                print("|cff00ff00[NSQC4]|r Руда добыта в клетке " .. index)
            end },
            { text = "Разбить камни", func = function(index)
                Terrain:SetTerrain(index, "earth")
            end }
        }
    })
end)