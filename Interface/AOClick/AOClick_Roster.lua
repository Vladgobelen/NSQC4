-- ============================================================================
-- NSQC4 / Interface / AOClick / Roster
-- Модуль ui_ao: кэш ростера.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local A = NSQC4.AOClick
    if not A then return end

    local guildInfo  = {}
    local guildIndex = {}
    A.guildInfo  = guildInfo
    A.guildIndex = guildIndex

    local function FullRebuild()
        for k in pairs(guildInfo)  do guildInfo[k]  = nil end
        for k in pairs(guildIndex) do guildIndex[k] = nil end
        if not IsInGuild() then return end

        local n = GetNumGuildMembers(true)
        if not n or n == 0 then return end

        for i = 1, n do
            local name, _, _, level, _, _, _, officerNote, _, _, classFile = GetGuildRosterInfo(i)
            if name then
                local cleanName = A.CleanName(name)
                local words = A.mysplit(officerNote or "")
                guildInfo[cleanName] = {
                    level     = level,
                    gp        = words[3],
                    classFile = classFile,
                    onote     = officerNote,
                }
                guildIndex[cleanName] = i
            end
        end
    end
    A.FullRebuild = FullRebuild

    local function LazyLoadOne(cleanName)
        if not cleanName then return nil end
        if guildInfo[cleanName] then return guildInfo[cleanName] end
        if not IsInGuild() then return nil end

        local idx = guildIndex[cleanName]
        if idx then
            local name, _, _, level, _, _, _, officerNote, _, _, classFile = GetGuildRosterInfo(idx)
            if name and A.CleanName(name) == cleanName then
                local words = A.mysplit(officerNote or "")
                guildInfo[cleanName] = {
                    level     = level,
                    gp        = words[3],
                    classFile = classFile,
                    onote     = officerNote,
                }
                return guildInfo[cleanName]
            end
            guildIndex[cleanName] = nil
        end

        local n = GetNumGuildMembers()
        if not n or n == 0 then return nil end

        for i = 1, n do
            local name, _, _, level, _, _, _, officerNote, _, _, classFile = GetGuildRosterInfo(i)
            if name then
                local cn = A.CleanName(name)
                if cn == cleanName then
                    local words = A.mysplit(officerNote or "")
                    guildInfo[cleanName] = {
                        level     = level,
                        gp        = words[3],
                        classFile = classFile,
                        onote     = officerNote,
                    }
                    guildIndex[cleanName] = i
                    return guildInfo[cleanName]
                end
            end
        end

        return nil
    end

    function A.GetGuildData(name)
        local cleanName = A.CleanName(name)
        if not cleanName then return nil end
        return guildInfo[cleanName] or LazyLoadOne(cleanName)
    end

    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_GUILD_UPDATE")

    local enteredWorldOnce = false

    rosterFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then
            if enteredWorldOnce then return end
            enteredWorldOnce = true
            FullRebuild()
        elseif event == "GUILD_ROSTER_UPDATE" then
            local isFullUpdate = arg1
            if isFullUpdate == 1 or isFullUpdate == true then
                FullRebuild()
            end
        elseif event == "PLAYER_GUILD_UPDATE" then
            for k in pairs(guildInfo)  do guildInfo[k]  = nil end
            for k in pairs(guildIndex) do guildIndex[k] = nil end
        end
    end)

end)