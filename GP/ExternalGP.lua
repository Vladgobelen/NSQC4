-- ============================================================================
-- NSQC4 / GP / ExternalGP
-- Запрос ГП для не-гильдейцев: nsGpGet → GUILD
-- Приём ответа:             nsGpGetResp ← GUILD
--
-- Схема:
--   1. Клиент вызывает NSQC4.RequestGp(nick)
--   2. Если nick свой гильдеец — читаем из ростера (ReadMyGuildGp).
--      Если чужой — шлём nsGpGet в GUILD.
--   3. Сервер чужой гильдии читает из своего ростера и отвечает
--      nsGpGetResp в RAID (через Relay чанками).
--   4. Наш сервер (NSQS2) собирает чанки и пересылает ответ в GUILD.
--   5. Клиент ловит nsGpGetResp ТОЛЬКО из GUILD и пишет в кеш.
--
-- ВАЖНО (исправление спама):
--   Relay шлёт чанки nsGpGetResp с тем же префиксом, что и собранный
--   ответ. Клиент ловит ОБА. Фильтруем:
--     • channel должен быть "GUILD" (relay-чанки идут в RAID),
--     • reqID должен быть в формате %d+_%d+ (без "/N" от relay-чанка).
--
-- Отладка:
--   NSQC4.GPDebug.enabled = true   -- включить (общий флаг из GP/GP.lua)
--   NSQC4.GPDebug.enabled = false  -- выключить
--   /gpd                           -- переключить
-- ============================================================================

NSQC4.RegisterModule("gp", function()
    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    -- ========================================================================
    -- Точечная отладка (используем общий флаг NSQC4.GPDebug из GP/GP.lua)
    -- ========================================================================
    local function dbgExt(tag, ...)
        if NSQC4.GPDebug and NSQC4.GPDebug.enabled then
            print("|cff00aaff[GP-EXT " .. tag .. "]|r", ...)
        end
    end

    local P_GP_GET      = "nsGpGet"
    local P_GP_GET_RESP = "nsGpGetResp"

    local myName  = UnitName("player") or ""
    local plainMe = myName:match("^(.-)-") or myName

    -- ========================================================================
    -- Проверка: свой ли гильдеец?
    -- ========================================================================
    local function IsMyGuildMember(nick)
        if not nick or nick == "" then return false end
        local short = nick:match("^([^%-]+)") or nick
        for i = 1, GetNumGuildMembers(true) do
            local gName = GetGuildRosterInfo(i)
            if gName then
                local gShort = gName:match("^([^%-]+)") or gName
                if gShort == short then return true end
            end
        end
        return false
    end

    -- ========================================================================
    -- Чтение ГП из своего ростера (для своих гильдейцев)
    -- ========================================================================
    local function ReadMyGuildGp(nick)
        if not nick or nick == "" then return nil end
        local short = nick:match("^([^%-]+)") or nick
        for i = 1, GetNumGuildMembers(true) do
            local gName, _, _, _, _, _, _, officerNote =
                GetGuildRosterInfo(i)
            if gName then
                local gShort = gName:match("^([^%-]+)") or gName
                if gShort == short then
                    local parts = {}
                    for w in (officerNote or ""):gmatch("%S+") do
                        table.insert(parts, w)
                    end
                    return tonumber(parts[3]) or 0
                end
            end
        end
        return nil
    end

    -- ========================================================================
    -- Публичный API: запрос ГП
    -- ========================================================================
    function NSQC4.RequestGp(nick)
        if not nick or nick == "" then
            dbgExt("REQ-SKIP", "пустой nick")
            return
        end

        local short = nick:match("^([^%-]+)") or nick

        dbgExt("REQ-ENTER",
            "nick=", tostring(nick),
            "short=", tostring(short)
        )

        -- Шаг 1: проверка — свой ли гильдеец?
        local isOwn = IsMyGuildMember(short)

        dbgExt("REQ-GUILD-CHECK",
            "nick=", short,
            "isMyGuildMember=", tostring(isOwn)
        )

        if isOwn then
            -- Свой гильдеец — читаем из своего ростера, запрос не нужен
            local localGp = ReadMyGuildGp(short)
            dbgExt("REQ-LOCAL",
                "nick=", short,
                "localGp=", tostring(localGp),
                "запрос nsGpGet НЕ нужен"
            )
            if gpDb and gpDb.SetExternalGp then
                gpDb:SetExternalGp(short, localGp or 0)
            end
            return
        end

        -- Шаг 2: чужой гильдеец — отправляем запрос
        dbgExt("REQ-SEND",
            "nick=", short,
            "prefix=", P_GP_GET,
            "channel=GUILD",
            "body=", short,
            "отправляем запрос ГП для чужого гильдейца"
        )

        SendAddonMessage(P_GP_GET, short, "GUILD")

        dbgExt("REQ-SENT",
            "ОТПРАВЛЕНО:",
            "prefix=" .. P_GP_GET,
            "channel=GUILD",
            "body=" .. short
        )
    end

    -- ========================================================================
    -- Сохранение полученного ГП в кеш gpDb
    -- ========================================================================
    local function SaveExternalGp(nick, gp)
        if not nick or nick == "" then return end
        local short = nick:match("^([^%-]+)") or nick

        dbgExt("SAVE",
            "nick=", short,
            "gp=", tostring(gp),
            "сохраняем в external_gp_cache"
        )

        if gpDb and gpDb.SetExternalGp then
            gpDb:SetExternalGp(short, tonumber(gp) or 0)
        else
            dbgExt("SAVE-SKIP", "gpDb.SetExternalGp недоступен")
        end
    end

    -- ========================================================================
    -- Приём ответа: nsGpGetResp
    --   Формат: "<reqID>|<gp>|<ok>|<err>|<nick>"
    --   Приходит в GUILD от нашего сервера (после сборки чанков Relay).
    --
    -- ВАЖНО: Relay шлёт чанки nsGpGetResp с тем же префиксом.
    --   Чанк:   "<chunkNum>/<total>|<groupID>|..."
    --   Ответ:  "<reqID>|<gp>|<ok>|<err>|<nick>"
    --   Отличие: reqID в формате %d+_%d+, БЕЗ "/N".
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:nsgpgetresp", {
        func = function(words, sender, text, channel, prefix)
            -- 1. Канал: только GUILD. Relay-чанки идут в RAID.
            if channel ~= "GUILD" then
                return
            end

            if not text or text == "" then
                dbgExt("RESP-SKIP", "пустой text")
                return
            end

            dbgExt("RESP-ENTER",
                "from=", tostring(sender),
                "channel=", tostring(channel),
                "prefix=", tostring(prefix),
                "body=", tostring(text)
            )

            -- 2. Формат: reqID = %d+_%d+ (без "/N" от relay-чанка).
            local reqID, gpStr, okStr, err, nick =
                text:match("^(%d+_%d+)|(%-?%d+)|([01])|([^|]*)|(.+)$")

            if not reqID then
                dbgExt("RESP-SKIP",
                    "не resp (relay-чанк или мусор):",
                    tostring(text)
                )
                return
            end

            dbgExt("RESP-PARSED",
                "reqID=", tostring(reqID),
                "gpStr=", tostring(gpStr),
                "okStr=", tostring(okStr),
                "err=", tostring(err),
                "nick=", tostring(nick)
            )

            if okStr ~= "1" then
                dbgExt("RESP-FAIL",
                    "сервер ответил ok=0",
                    "nick=", tostring(nick),
                    "err=", tostring(err)
                )
                return
            end

            local gp = tonumber(gpStr) or 0

            dbgExt("RESP-OK",
                "nick=", tostring(nick),
                "gp=", tostring(gp),
                "принимаем ГП для чужого гильдейца"
            )

            SaveExternalGp(nick, gp)
        end,
        stopOnMatch = true,
    })
end)