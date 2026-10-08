-- ============================================================================
-- NSQC4 / GP / LogReceiver
-- Приём логов ГП из гильд-чата (префикс nsYourLog) и вывод в окно логов.
-- Модуль: gp (тот же ключ, что и остальные GP-файлы).
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    -- ========================================================================
    -- Обработчик логов
    -- ========================================================================
    local function OnGuildLogMessage(words, sender, text, channel, prefix)
        -- prefix = "nsYourLog Шеф"
        local targetNick = prefix and prefix:match("^%S+%s+(%S+)")
        local myName = UnitName("player") or ""

        if targetNick and targetNick ~= myName then
            return
        end

        local timestamp, rl, raid_id, gp, targets =
            text:match("^(%d+)%s+(%S+)%s+(%S+)%s+([-+]?%d+)%s+(.+)$")

        if not timestamp then
            return
        end

        if gpDb and gpDb.showOnlyNotes and not (raid_id:find(">>", 1, true)) then
            return
        end

        local timeStr = date("%d %H:%M:%S", tonumber(timestamp))

        local decodedTargets = {}
        for word in targets:gmatch("%S+") do
            if gpDb and gpDb.nsUnitID_tbl and gpDb.nsUnitID_tbl[word] then
                table.insert(decodedTargets, gpDb.nsUnitID_tbl[word])
            else
                table.insert(decodedTargets, word)
            end
        end
        local finalTargets = table.concat(decodedTargets, " ")

        if gpDb and gpDb.AddLogEntry then
            gpDb:AddLogEntry(timeStr, gp, rl, raid_id, finalTargets)
        end
    end

    -- ========================================================================
    -- Регистрация триггера в ChatHandler
    -- ========================================================================
    if NSQC4.ChatHandler and NSQC4.ChatHandler.Register then
        NSQC4.ChatHandler:Register("ADDON:nsyourlog", {
            func = function(words, sender, text, channel, prefix)
                OnGuildLogMessage(words, sender, text, channel, prefix)
            end,
            stopOnMatch = true,
        })
    end

end)