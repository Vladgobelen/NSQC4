-- ============================================================================
-- NSQC4 / Guild / BlackList
-- Команда: "-чс <Ник>" в гильд-чате — добавляет ник в чёрный список гильдии.
-- При появлении ника в любом чате (в т.ч. системном) — автоматический кик.
--
-- Хранилище: nsDbc4.blacklist[name_lower] = { name, added, by }
-- ============================================================================

NSQC4.RegisterModule("blacklist", function()

    -- ========================================================================
    -- Хранилище: подтаблица в общей базе nsDbc4
    -- ========================================================================
    nsDbc4 = nsDbc4 or {}
    nsDbc4.blacklist = nsDbc4.blacklist or {}

    local DB = nsDbc4.blacklist

    -- ========================================================================
    -- Утилиты: нормализация ников
    -- ========================================================================
    local function NormalizeName(name)
        if not name or name == "" then return nil end
        local short = name:match("^([^%-]+)") or name
        return short
    end

    local function KeyOf(name)
        local short = NormalizeName(name)
        if not short then return nil end
        return short:lower()
    end

    -- ========================================================================
    -- Проверка границы слова с учётом UTF-8 (латиница + кириллица)
    -- ========================================================================
    local function IsWordByte(b)
        if not b then return false end
        if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then
            return true
        end
        if b >= 0xD0 and b <= 0xFF then return true end
        if b >= 0x80 and b <= 0xBF then return true end
        return false
    end

    -- ========================================================================
    -- API чёрного списка
    -- ========================================================================
    local BlackList = {}
    NSQC4.BlackList = BlackList

    function BlackList:Add(name, by)
        local key = KeyOf(name)
        if not key then return false end
        if DB[key] then return false end
        DB[key] = {
            name  = NormalizeName(name),
            added = time(),
            by    = by or (UnitName("player") or "?"),
        }
        return true
    end

    function BlackList:Remove(name)
        local key = KeyOf(name)
        if not key then return false end
        if not DB[key] then return false end
        DB[key] = nil
        return true
    end

    function BlackList:Contains(name)
        local key = KeyOf(name)
        if not key then return false end
        return DB[key] ~= nil
    end

    function BlackList:List()
        local out = {}
        for _, entry in pairs(DB) do
            table.insert(out, entry)
        end
        return out
    end

    -- ========================================================================
    -- Поиск ника из ЧС в произвольном тексте
    -- ========================================================================
    local function ContainsBlacklisted(text)
        if not text or text == "" then return nil end
        if not next(DB) then return nil end

        local lowerText = text:lower()

        for key, entry in pairs(DB) do
            local pos = 1
            while true do
                local s, e = lowerText:find(key, pos, true)
                if not s then break end

                local beforeByte = s > 1 and lowerText:byte(s - 1) or nil
                local afterByte  = e < #lowerText and lowerText:byte(e + 1) or nil

                if not IsWordByte(beforeByte) and not IsWordByte(afterByte) then
                    return entry.name
                end
                pos = e + 1
            end
        end
        return nil
    end

    -- ========================================================================
    -- Кик + оповещение офицеров
    -- ========================================================================
    local kickedRecently = {}
    local pendingKicks   = {}

    local function DoKick(short, reason)
        local key = short:lower()
        if kickedRecently[key] then return end
        kickedRecently[key] = true

        GuildUninvite(short)
        SendChatMessage(string.format(
            "[gBlackList] %s — КИКНУТ (%s)", short, reason or "в чёрном списке"
        ), "OFFICER")

        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if t >= 5 then
                kickedRecently[key] = nil
                self:SetScript("OnUpdate", nil)
            end
        end)
    end

    local function IsInGuildByName(short)
        local key = short:lower()
        for i = 1, GetNumGuildMembers() do
            local gname = GetGuildRosterInfo(i)
            if gname and NormalizeName(gname):lower() == key then
                return true
            end
        end
        return false
    end

    local function KickTarget(name, reason)
        local short = NormalizeName(name)
        if not short then return end

        local key = short:lower()
        if kickedRecently[key] then return end

        -- Кикаем сразу. GuildUninvite безопасен: если игрока нет — молча ничего.
        DoKick(short, reason)

        -- На случай, если клиент ещё не догнал вступление — повторяем
        -- при GUILD_ROSTER_UPDATE, если игрок всё ещё в гильдии.
        pendingKicks[key] = { name = short, reason = reason, expires = time() + 15 }
    end

    -- ========================================================================
    -- Отложенные кики: ждём обновления ростера
    -- ========================================================================
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:SetScript("OnEvent", function()
        if not next(pendingKicks) then return end
        local now = time()
        for key, info in pairs(pendingKicks) do
            if info.expires < now then
                pendingKicks[key] = nil
            elseif not IsInGuildByName(info.name) then
                pendingKicks[key] = nil
            else
                kickedRecently[key] = nil
                pendingKicks[key] = nil
                DoKick(info.name, info.reason)
            end
        end
    end)

    -- ========================================================================
    -- Сканирование строки чата
    -- ========================================================================
    local function ScanAndKick(text, sender, source)
        if not text or text == "" then return end
        if not next(DB) then return end

        -- Форсируем обновление ростера при вступлении в гильдию —
        -- это ускоряет GUILD_ROSTER_UPDATE и повторный кик.
        if source == "система" and text:lower():find("присоединяется к гильдии", 1, true) then
            GuildRoster()
        end

        if sender and sender ~= "" then
            local s = NormalizeName(sender)
            if s and BlackList:Contains(s) then
                KickTarget(s, "автор сообщения (" .. (source or "чат") .. ")")
                return
            end
        end

        local found = ContainsBlacklisted(text)
        if found then
            KickTarget(found, "упоминание в " .. (source or "чате"))
        end
    end

    -- ========================================================================
    -- Слушатель системного чата
    -- ========================================================================
    local sysFrame = CreateFrame("Frame")
    sysFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    sysFrame:SetScript("OnEvent", function(_, _, text)
        ScanAndKick(text, nil, "система")
    end)

    -- ========================================================================
    -- Подписка на ChatCatcher (гильд-чат)
    -- ========================================================================
    NSQC4.ChatCatcher:Register(function(words, sender, text, channel, prefix)
        ScanAndKick(text, sender, channel or "guild")
    end, "blacklist")

    -- ========================================================================
    -- Обработчик команды "-чс"
    --   -чс <Ник>   — добавить
    --   -чс -<Ник>  — удалить
    --   -чс         — показать список
    -- ========================================================================
    local function HandleBlackList(words, sender, text, channel, prefix)
        if sender ~= UnitName("player") then return end
        if not IsInGuild() then return end

        local arg = words[2]

        -- Показать список
        if not arg or arg == "" then
            local list = BlackList:List()
            if #list == 0 then
                print("|cff00ff00[NSQC4]|r Чёрный список пуст.")
                return
            end
            print(string.format("|cffff8080[NSQC4]|r Чёрный список (%d):", #list))
            for _, e in ipairs(list) do
                print(string.format("  %s  (добавил: %s)", e.name, e.by or "?"))
            end
            return
        end

        -- Удаление: "-чс -Ник"
        if arg:sub(1, 1) == "-" and #arg > 1 then
            local name = NormalizeName(arg:sub(2))
            if not name then
                print("|cffff8080[NSQC4]|r Некорректный ник.")
                return
            end

            local key = name:lower()
            if DB[key] then
                DB[key] = nil
                print("|cff00ff00[NSQC4]|r " .. name .. " удалён из ЧС.")
                SendChatMessage(string.format("[gBlackList] %s — УДАЛЁН из ЧС", name), "OFFICER")
            else
                print("|cffff8080[NSQC4]|r " .. name .. " не найден в ЧС (ключ: " .. key .. ").")
                local keys = {}
                for k in pairs(DB) do keys[#keys + 1] = k end
                if #keys > 0 then
                    print("|cffff8080[NSQC4]|r В базе: " .. table.concat(keys, ", "))
                else
                    print("|cffff8080[NSQC4]|r База пуста.")
                end
            end
            return
        end

        -- Добавление: "-чс Ник"
        local name = NormalizeName(arg)
        if not name then
            print("|cffff8080[NSQC4]|r Некорректный ник.")
            return
        end

        if BlackList:Add(name, UnitName("player")) then
            SendChatMessage(string.format("[gBlackList] %s — ДОБАВЛЕН в ЧС", name), "OFFICER")
            if IsInGuildByName(name) then
                KickTarget(name, "добавлен в ЧС")
            end
        else
            print("|cffff8080[NSQC4]|r " .. name .. " уже в ЧС.")
        end
    end

    NSQC4.ChatHandler:Register("GUILD:-чс", {
        func = HandleBlackList,
        stopOnMatch = true,
    })

end)