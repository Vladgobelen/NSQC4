-- ============================================================================
-- NSQC4 / GP / PveSeason
-- Синхронизация флага «ПВЕ-сезон» с сервером.
-- Модуль: gp.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    local GUILD_NAME  = "Ночная стража"
    local CAPTAIN_RANK = "Капитан"
    local SEASON_MIN_PERCENT = 0.8

    -- ========================================================================
    -- Кэш гильдейских ников (обновляется по GUILD_ROSTER_UPDATE)
    -- ========================================================================
    local guildSet = {}
    local guildSetReady = false

    local function RefreshGuildSet()
        wipe(guildSet)
        for i = 1, GetNumGuildMembers(true) do
            local name = GetGuildRosterInfo(i)
            if name then
                local short = name:match("^([^%-]+)") or name
                guildSet[short] = true
            end
        end
        guildSetReady = true
    end

    local function IsInGuildByNick(nick)
        if not nick then return false end
        local short = nick:match("^([^%-]+)") or nick
        if not guildSetReady then RefreshGuildSet() end
        return guildSet[short] == true
    end

    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_LOGOUT")
    rosterFrame:SetScript("OnEvent", function(_, event)
        guildSetReady = false
        if event == "PLAYER_LOGOUT" then wipe(guildSet) end
    end)

    -- ========================================================================
    -- Проверка «я — Капитан?»
    -- ========================================================================
    local function IsCaptain(nick)
        if not nick then return false end
        for i = 1, GetNumGuildMembers(true) do
            local name, rank = GetGuildRosterInfo(i)
            if name then
                local short = name:match("^([^%-]+)") or name
                if short == nick and rank == CAPTAIN_RANK then
                    return true
                end
            end
        end
        return false
    end

    -- ========================================================================
    -- Проверка 80%
    -- ========================================================================
    function NSQC4.CanAssignGp()
        if not nsDbc4.settings.gp.pveSeason then return true end

        local total = GetNumGroupMembers()
        if not total or total == 0 then return true end

        local inRaid = IsInRaid()
        local inGuild = 0

        for i = 1, total do
            local unit = inRaid and ("raid"..i) or (i == 1 and "player" or ("party"..(i-1)))
            local nick = UnitName(unit)
            if nick and IsInGuildByNick(nick) then
                inGuild = inGuild + 1
            end
        end

        local needed = math.ceil(total * SEASON_MIN_PERCENT)
        if inGuild >= needed then
            return true
        end

        local percent = math.floor((inGuild / total) * 100)
        print(string.format(
            "|cffff8080[ПВЕ-сезон]|r В рейде гильдейских: %d из %d (%d%%). Нужно минимум %d (80%%).",
            inGuild, total, percent, needed))
        return false
    end

    -- ========================================================================
    -- Синхронизация с сервером
    -- ========================================================================
    local syncFrame = CreateFrame("Frame")
    syncFrame:RegisterEvent("CHAT_MSG_ADDON")
    syncFrame:RegisterEvent("PLAYER_LOGIN")

    syncFrame:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
        if event == "PLAYER_LOGIN" then
            -- Запрос текущего состояния
            local myName = UnitName("player")
            if myName then
                SendAddonMessage("nsPveSeasonGet", myName, "GUILD")
            end
            return
        end

        if event == "CHAT_MSG_ADDON" and prefix == "nsPveSeasonState" then
            local value = tonumber(msg)
            if value == 0 or value == 1 then
                nsDbc4.settings.gp.pveSeason = (value == 1)
                -- Обновляем чекбокс, если он уже создан
                if NSQC4.RefreshPveSeasonCheckbox then
                    NSQC4.RefreshPveSeasonCheckbox()
                end
            end
        end
    end)

    -- ========================================================================
    -- Установка состояния (только Капитан)
    -- ========================================================================
    function NSQC4.SetPveSeason(value)
        local myName = UnitName("player")
        if not myName then return end

        local short = myName:match("^([^%-]+)") or myName

        if not IsCaptain(short) then
            print("|cffff8080[ПВЕ-сезон]|r Только Капитаны могут менять эту настройку.")
            return
        end

        -- Локально сразу
        nsDbc4.settings.gp.pveSeason = (value == true)

        -- На сервер
        SendAddonMessage("nsPveSeasonSet", short .. " " .. (value and "1" or "0"), "GUILD")
    end

end)