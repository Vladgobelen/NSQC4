-- ============================================================================
-- NSQC4 / Course / Triggers
-- Регистрация чат-триггеров курса в NSQC4.chat.
-- ============================================================================

NSQC4.RegisterModule("course", function()

    NSQC4.Course = NSQC4.Course or {}

    if type(RegisterAddonMessagePrefix) == "function" then
        RegisterAddonMessagePrefix("nsModuleCode")
    end

    if NSQC4.chat and type(NSQC4.chat.Register) == "function" then
        NSQC4.chat:Register("ADDON:nsmodulecode", {
            func = function(words, sender, text, channel, prefix)
                local handler = NSQC4.Course and NSQC4.Course.nsModuleCode

                if type(handler) == "function" then
                    handler(channel, text, sender, prefix)
                end
            end,
            stopOnMatch = true,
        })
    end
end)