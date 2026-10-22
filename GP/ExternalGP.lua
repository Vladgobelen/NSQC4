-- ============================================================================
-- NSQC4 / GP / ExternalGP
-- Запрос ГП для не-гильдейцев: nsGpGet → GUILD
-- Приём ответа:             nsGpGetResp ← GUILD
-- Обновление кеша из офицерского чата:
--   "<nick> <delta> ГП: <old> >> <new>"
-- Берём ТОЛЬКО последнее число (new) и пишем в кеш для <nick>.
--
-- Анти-спам: pending_gp[nick]=true, пока ответ не пришёл. Повторно
-- не отправляем. Сбрасывается в SetExternalGp (ответ пришёл) и в
-- OnLeave у MinimapGP (мышь ушла — начинаем заново при след. наведении).
-- ============================================================================

NSQC4.RegisterModule("gp", function()
    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    -- ========================================================================
    -- Отладка ВЫКЛЮЧЕНА
    -- ========================================================================
    NSQC4.GPDebug = NSQC4.GPDebug or {}
    NSQC4.GPDebug.enabled = false

    local function dbgExt(tag, ...)
        if NSQC4.GPDebug and NSQC4.GPDebug.enabled then
            print("|cff00aaff[GP-EXT " .. tag .. "]|r", ...)
        end
    end

    local P_GP_GET      = "nsGpGet"
    local P_GP_GET_RESP = "nsGpGetResp"

    local myName  = UnitName("player") or ""

    -- ========================================================================
    -- Регистрация префиксов на приёмнике
    -- ========================================================================
    if RegisterAddonMessagePrefix then
        pcall(RegisterAddonMessagePrefix, P_GP_GET)
        pcall(RegisterAddonMessagePrefix, P_GP_GET_RESP)
    end

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

    local function ReadMyGuildGp(nick)
        if not nick or nick == "" then return nil end
        local short = nick:match("^([^%-]+)") or nick
        for i = 1, GetNumGuildMembers(true) do
            local gName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
            if gName then
                local gShort = gName:match("^([^%-]+)") or gName
                if gShort == short then
                    local parts = {}
                    for w in (officerNote or ""):gmatch("%S+") do table.insert(parts, w) end
                    return tonumber(parts[3]) or 0
                end
            end
        end
        return nil
    end

    function NSQC4.RequestGp(nick)
        if not nick or nick == "" then
            dbgExt("REQ-SKIP", "пустой nick")
            return
        end

        local short = nick:match("^([^%-]+)") or nick

        -- Анти-спам: уже отправлен, ответа ещё нет — не повторяем
        if gpDb and gpDb.pending_gp and gpDb.pending_gp[short] then
            dbgExt("REQ-PENDING", "nick=", short)
            return
        end

        dbgExt("REQ-ENTER", "nick=", tostring(nick), "short=", tostring(short))

        local isOwn = IsMyGuildMember(short)
        dbgExt("REQ-GUILD-CHECK", "nick=", short, "isMyGuildMember=", tostring(isOwn))

        if isOwn then
            local localGp = ReadMyGuildGp(short)
            dbgExt("REQ-LOCAL", "nick=", short, "localGp=", tostring(localGp))
            if gpDb and gpDb.SetExternalGp then
                gpDb:SetExternalGp(short, localGp or 0)
            end
            return
        end

        -- Помечаем «отправлено, ждём ответ»
        if gpDb then
            gpDb.pending_gp = gpDb.pending_gp or {}
            gpDb.pending_gp[short] = true
        end

        dbgExt("REQ-SEND", "nick=", short, "prefix=", P_GP_GET, "channel=GUILD")
        SendAddonMessage(P_GP_GET, short, "GUILD")
    end

    local function SaveExternalGp(nick, gp)
        if not nick or nick == "" then return end
        local short = nick:match("^([^%-]+)") or nick
        dbgExt("SAVE", "nick=", short, "gp=", tostring(gp))
        if gpDb and gpDb.SetExternalGp then
            gpDb:SetExternalGp(short, tonumber(gp) or 0)
        end
    end

    -- ========================================================================
    -- Приём ответа на nsGpGet
    -- ========================================================================
    NSQC4.ChatHandler:Register("ADDON:nsgpgetresp", {
        func = function(words, sender, text, channel, prefix)
            dbgExt("RESP-ENTER", "from=", tostring(sender), "channel=", tostring(channel), "body=", tostring(text))

            if channel ~= "GUILD" then
                return
            end
            if not text or text == "" then
                return
            end

            local reqID, gpStr, okStr, err, nick =
                text:match("^(%d+_%d+)|(%-?%d+)|([01])|([^|]*)|(.+)$")

            if not reqID then
                dbgExt("RESP-SKIP", "не resp (relay-чанк или мусор):", tostring(text))
                return
            end

            if okStr ~= "1" then
                dbgExt("RESP-FAIL", "сервер ответил ok=0", "nick=", tostring(nick), "err=", tostring(err))
                return
            end

            local gp = tonumber(gpStr) or 0
            dbgExt("RESP-OK", "nick=", tostring(nick), "gp=", tostring(gp))
            SaveExternalGp(nick, gp)
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- Обновление кеша из офицерского чата (фрейм-слушатель)
    -- Формат: "<nick> <delta> ГП: <old> >> <new>"
    -- Пример: "Кербес -10 ГП: 0 >> -10"
    -- В 3.3.5a msg может содержать префикс канала "[O6:122] Шеф: ",
    -- поэтому ищем "ГП:" и ">>" с конца, не полагаясь на фикс. позиции.
    -- Ник — за 2 слова до "ГП:" (с учётом дельты) или за 1 (без дельты).
    -- ========================================================================
    local officerFrame = CreateFrame("Frame")
    officerFrame:RegisterEvent("CHAT_MSG_OFFICER")
    officerFrame:SetScript("OnEvent", function(_, event, msg, author, ...)
        if not msg or msg == "" then return end

        local words = {}
        for w in msg:gmatch("%S+") do
            table.insert(words, w)
        end

        local n = #words
        if n < 4 then return end

        local newGp, oldGp, nick

        for i = n, 4, -1 do
            if words[i] == "ГП:" and words[i + 2] == ">>" then
                oldGp = tonumber(words[i + 1])
                newGp = tonumber(words[i + 3])

                -- Если перед "ГП:" стоит число — это дельта, ник ещё на 1 слово раньше
                local delta = tonumber(words[i - 1])
                if delta then
                    nick = words[i - 2]
                else
                    nick = words[i - 1]
                end
                break
            end
        end

        if not nick or not newGp then return end

        -- Если перед ником стоит "Шеф:" (префикс канала) — отрезаем
        local short = nick:match("^([^:%-]+)") or nick

        dbgExt("OFFICER-MATCH", "nick=", short,
            "old=", tostring(oldGp), "new=", tostring(newGp))

        if gpDb and gpDb.SetExternalGp then
            gpDb:SetExternalGp(short, newGp)
        end
    end)
end)