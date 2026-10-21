-- ============================================================================
-- NSQC4 / GP / ExternalGP
-- Кеш ГП для ЧУЖИХ игроков (не из моей гильдии).
--
-- Своих читаем напрямую из GetGuildRosterInfo (этим занимается GpDb в GP.lua).
-- Сюда попадают ТОЛЬКО чужие — через ретрансляцию nsGpGet.
--
-- Схема:
--   клиент -> GUILD: nsGpGet <nick>                      (только если ник чужой)
--   сервер -> GUILD: nsGpGetResp <reqID>|<gp>|<ok>|<err>|<nick>
--   клиент ловит nsGpGetResp, кладёт gp в gpDb.external_gp_cache[nick]
--
-- Старый протокол (GetGPA / showGPA / hisGP / enAlToGi / ns_hisGP) удалён.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    -- ========================================================================
    -- Локальные префиксы (модуль автономен)
    -- ========================================================================
    local P_GP_GET      = "nsGpGet"
    local P_GP_GET_RESP = "nsGpGetResp"

    local myName  = UnitName("player") or ""
    local plainMe = myName:match("^(.-)-") or myName

    -- ========================================================================
    -- Свой ли ник (есть в моём ростере)?
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
    -- Прочитать ГП своего гильдейца напрямую из ростера
    -- ========================================================================
    local function ReadMyGuildGp(nick)
        if not nick or nick == "" then return nil end
        local short = nick:match("^([^%-]+)") or nick
        for i = 1, GetNumGuildMembers(true) do
            local gName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
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
    -- Публичный API: запросить ГП ника.
    --   свой   -> читаем локально, в GUILD не шлём
    --   чужой  -> шлём nsGpGet в GUILD
    -- ========================================================================
    function NSQC4.RequestGp(nick)
        if not nick or nick == "" then return end
        local short = nick:match("^([^%-]+)") or nick

        if IsMyGuildMember(short) then
            -- Свой: GpDb сам прочитает из ростера, дублировать в кеш не нужно.
            ReadMyGuildGp(short)
            return
        end

        SendAddonMessage(P_GP_GET, short, "GUILD")
    end

    -- ========================================================================
    -- Сохранить чужой ГП в кеш GpDb
    -- ========================================================================
    local function SaveExternalGp(nick, gp)
        if not nick or nick == "" then return end
        local short = nick:match("^([^%-]+)") or nick
        if gpDb and gpDb.SetExternalGp then
            gpDb:SetExternalGp(short, tonumber(gp) or 0)
        end
    end

    -- ========================================================================
    -- Приём nsGpGetResp из GUILD
    --   payload = <reqID>|<gp>|<ok>|<err>|<nick>
    --   reqID не нужен: ник в payload, ответ адресный.
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:nsgpgetresp", {
        func = function(words, sender, text, channel, prefix)
            if not text or text == "" then return end

            local reqID, gpStr, okStr, err, nick =
                text:match("^(%S+)|(%-?%d+)|([01])|([^|]*)|(.+)$")
            if not reqID or not nick then return end

            if okStr ~= "1" then return end

            local gp = tonumber(gpStr) or 0
            SaveExternalGp(nick, gp)
        end,
        stopOnMatch = true,
    })

end)