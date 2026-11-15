NSQC4.RegisterModule("quests", function()
    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    function NSDB:Root()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.quests = nsDbc4.quests or {}
        return nsDbc4.quests
    end
end, 181)