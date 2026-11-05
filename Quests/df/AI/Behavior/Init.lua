-- ============================================================================
-- NSQC4 / Quests / df / AI / Behavior / Init
-- Реестр поведений по видам и характерам.
--
--   NSQC4.QuestsDfBehavior[kind][behavior] = { Tick = function(entity) ... end }
--
-- kind     — "goblin" | "dwarf" | ...
-- behavior — "aggressive" | "peaceful" | ...
--
-- Каждый вид регистрирует свои поведения в df/<Kind>/Behavior/*.lua.
-- Если чего-то нет — Tick упадёт в Default.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Registry = {}
    NSQC4.QuestsDfBehavior = Registry

    -- ========================================================================
    -- Регистрация поведения.
    --   kind     — "goblin" | "dwarf"
    --   behavior — "aggressive" | "peaceful"
    --   handler  — { Tick = function(entity) ... end }
    -- ========================================================================
    function Registry:Register(kind, behavior, handler)
        if type(kind) ~= "string" or kind == "" then return false end
        if type(behavior) ~= "string" or behavior == "" then return false end
        if type(handler) ~= "table" then return false end

        if not self[kind] then self[kind] = {} end
        self[kind][behavior] = handler
        return true
    end

    function Registry:Get(kind, behavior)
        if type(kind) ~= "string" or type(behavior) ~= "string" then return nil end
        local byKind = self[kind]
        return byKind and byKind[behavior] or nil
    end

end)