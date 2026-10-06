NSQC4.RegisterModule("course", function()
    NSQC4.Course = NSQC4.Course or {}

    NSQC4.Course.ui = NSQC4.Course.UI:new(UIParent)

    NSQC4.Course.logic = NSQC4.Course.Logic:new(NSQC4.Course.ui, ns_llua['lua'])
    logic = NSQC4.Course.logic

    NSQC4.Course.reminder = NSQC4.Course.NSReminder:New()
    NSQC4.Course.reminder:Init()

    SLASH_NSCOURSE1 = "/ns_course"
    SlashCmdList["NSCOURSE"] = function(msg)
        msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        logic:ManageCourse(msg ~= "" and msg or nil)
    end

    NSQC4.SlashPanel_RegisterButton("К", "/ns_course", "Курс Lua", function()
        logic:ManageCourse()
    end)
end)