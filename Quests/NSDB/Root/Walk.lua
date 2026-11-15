NSQC4.RegisterModule("quests", function()
    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Walk(scope)
        if type(scope) ~= "string" or scope == "" then return nil end
        local cur = self:Root()
        for part in scope:gmatch("[^%.]+") do
            cur = cur[part]
            if cur == nil then return nil end
            if type(cur) ~= "table" then return nil end
        end
        return cur
    end
end, 182)