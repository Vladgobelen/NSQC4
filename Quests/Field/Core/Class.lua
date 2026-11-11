-- ============================================================================
-- NSQC4 / Quests / Field / Core / Class
-- Мини-система классов. Одна логика: создание класса по прототипу.
--
--   local MyClass = NSQC4.Class()          -- без родителя
--   local MyClass = NSQC4.Class(Parent)    -- с родителем
--
--   local obj = MyClass.new(...)           -- создаёт, зовёт obj:Init(...)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    function NSQC4.Class(parent)
        local c = {}
        c.__index = c

        if parent then
            setmetatable(c, { __index = parent })
        end

        function c.new(...)
            local o = setmetatable({}, c)
            if o.Init then
                o:Init(...)
            end
            return o
        end

        return c
    end

end, 150)