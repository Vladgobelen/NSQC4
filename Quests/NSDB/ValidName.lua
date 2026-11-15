NSQC4.RegisterModule("quests", function()
    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:ValidName(name)
        return type(name) == "string" and name ~= ""
    end
end, 171)