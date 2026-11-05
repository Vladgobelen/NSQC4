-- ============================================================================
-- NSQC4 / Quests / df / Goblin / Stats
-- [1] — бог (максимум), [10] — отброс (минимум).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    NSQC4.QuestsDfGoblinStats = {
        [1] = {
            skills_max = {10, 10},
            skills_cap = {10, 10},
            strength   = {10, 100},
            agility    = {10, 100},
            vitality   = {10, 100},
            intellect  = {10, 100},
            lineage    = {0, 1},
            prof = {1,100},
        },
        [2] = {
            skills_max = {5, 9},
            skills_cap = {5, 9},
            strength   = {5, 50},
            agility    = {5, 50},
            vitality   = {5, 50},
            intellect  = {5, 50},
            lineage    = {0, 1},
            prof = {1,50},
        },
        [3] = {
            skills_max = {5, 8},
            skills_cap = {5, 8},
            strength   = {5, 10},
            agility    = {5, 10},
            vitality   = {5, 10},
            intellect  = {5, 10},
            lineage    = {0, 1},
            prof = {1,40},
        },
        [4] = {
            skills_max = {4, 7},
            skills_cap = {4, 7},
            strength   = {4, 9},
            agility    = {4, 9},
            vitality   = {4, 9},
            intellect  = {4, 9},
            lineage    = {0, 1},
            prof = {1,30},
        },
        [5] = {
            skills_max = {3, 6},
            skills_cap = {3, 6},
            strength   = {3, 8},
            agility    = {3, 8},
            vitality   = {3, 8},
            intellect  = {3, 8},
            lineage    = {0, 1},
            prof = {1,20},
        },
        [6] = {
            skills_max = {2, 5},
            skills_cap = {2, 5},
            strength   = {2, 7},
            agility    = {2, 7},
            vitality   = {2, 7},
            intellect  = {2, 7},
            lineage    = {0, 1},
            prof = {1,10},
        },
        [7] = {
            skills_max = {1, 4},
            skills_cap = {1, 4},
            strength   = {1, 6},
            agility    = {1, 6},
            vitality   = {1, 6},
            intellect  = {1, 6},
            lineage    = {0, 1},
            prof = {1,9},
        },
        [8] = {
            skills_max = {1, 3},
            skills_cap = {1, 3},
            strength   = {1, 5},
            agility    = {1, 5},
            vitality   = {1, 5},
            intellect  = {1, 5},
            lineage    = {0, 1},
            prof = {1,8},
        },
        [9] = {
            skills_max = {1, 2},
            skills_cap = {1, 2},
            strength   = {1, 4},
            agility    = {1, 4},
            vitality   = {1, 4},
            intellect  = {1, 4},
            lineage    = {0, 1},
            prof = {1,7},
        },
        [10] = {
            skills_max = {1, 1},
            skills_cap = {1, 1},
            strength   = {1, 3},
            agility    = {1, 3},
            vitality   = {1, 3},
            intellect  = {1, 3},
            lineage    = {0, 1},
            prof = {1,6},
        },
    }

    print("|cff00ffff[GOB-DEBUG]|r Goblin Stats загружены.")

end)