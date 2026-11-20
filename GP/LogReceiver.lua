-- ============================================================================
-- NSQC4 / GP / LogReceiver
-- Приём логов ГП из гильд-чата (префикс nsYourLog) и вывод в окно логов.
-- Модуль: gp (тот же ключ, что и остальные GP-файлы).
--
-- ПОДДЕРЖИВАЕТ:
-- 1. Старый формат: "time sender raid gp targets" (без итога)
-- 2. Новый формат:  "time sender raid gp/total targets" (с итогом)
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    local function OnGuildLogMessage(words, sender, text, channel, prefix)
        -- 1. Проверяем, нам ли адресовано
        -- prefix = "nsYourLog Шеф"
        local targetNick = prefix and prefix:match("^%S+%s+(%S+)")
        local myName = UnitName("player") or ""

        if targetNick and targetNick ~= myName then
            return
        end

        -- 2. Парсим сообщение.
        -- Захватываем gp как строку (вдруг там слэш). 
        -- Разрешаем дефис, плюс, цифры и слэш: [%-%+%d/]+
        local timestamp, rl, raid_id, gp, targets =
            text:match("^(%d+)%s+(%S+)%s+(%S+)%s+([%-%+%d/]+)%s+(.+)$")

        if not timestamp then
            return
        end

        -- 3. Разбираем gp на дельту и итог (если есть слэш)
        local gpDelta, gpTotal
        local slashPos = gp:find("/", 1, true)
        
        if slashPos then
            gpDelta = gp:sub(1, slashPos - 1)
            gpTotal = gp:sub(slashPos + 1)
        else
            gpDelta = gp
            gpTotal = nil
        end

        -- 4. Фильтр "только заметки"
        if gpDb and gpDb.showOnlyNotes and not (raid_id:find(">>", 1, true)) then
            return
        end

        -- 5. Форматируем время
        local timeStr = date("%d %H:%M:%S", tonumber(timestamp))
        
        -- 6. Декодируем таргеты (если используется таблица замен)
        local decodedTargets = {}
        for word in targets:gmatch("%S+") do
            if gpDb and gpDb.nsUnitID_tbl and gpDb.nsUnitID_tbl[word] then
                table.insert(decodedTargets, gpDb.nsUnitID_tbl[word])
            else
                table.insert(decodedTargets, word)
            end
        end
        local finalTargets = table.concat(decodedTargets, " ")

        -- 7. Передаем в UI (gpDb).
        if gpDb and gpDb.AddLogEntry then
            gpDb:AddLogEntry(timeStr, gpDelta, rl, raid_id, finalTargets, gpTotal)
        end
    end

    -- Регистрация
    if NSQC4.ChatHandler and NSQC4.ChatHandler.Register then
        NSQC4.ChatHandler:Register("ADDON:nsyourlog", {
            func = function(words, sender, text, channel, prefix)
                OnGuildLogMessage(words, sender, text, channel, prefix)
            end,
            stopOnMatch = true,
        })
    end

end)