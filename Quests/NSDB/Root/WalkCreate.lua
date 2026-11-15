NSQC4.RegisterModule("quests", function()
    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:WalkCreate(scope)
        if type(scope) ~= "string" or scope == "" then return nil end
        local cur = self:Root()
        for part in scope:gmatch("[^%.]+") do
            if type(cur[part]) ~= "table" then
                cur[part] = {}
            end
            cur = cur[part]
        end
        return cur
    end
end, 183)