-- ============================================================================
-- NSQC4 / GP / RaidTracker
-- Отслеживание состава рейда, запрос ГП у не-гильдейских. Модуль "gp".
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    -- Защита от двойной инициализации (если GP.lua тоже активен)
    if NSQC4.RaidTrackerActive then return end
    NSQC4.RaidTrackerActive = true

    local raidTracker = CreateFrame("Frame")
    raidTracker:RegisterEvent("GROUP_ROSTER_UPDATE")
    raidTracker:RegisterEvent("RAID_ROSTER_UPDATE")
    raidTracker:RegisterEvent("PARTY_MEMBERS_CHANGED")
    raidTracker:RegisterEvent("PLAYER_ENTERING_WORLD")

    local wasInRaid = UnitInRaid("player") ~= nil
    local raidMembers = {}

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function GetCurrentRaidMembers()
        local members = {}
        if UnitInRaid("player") then
            for i = 1, GetNumRaidMembers() do
                local name = GetRaidRosterInfo(i)
                if name then
                    local plainName = name:match("^(.-)-") or name
                    members[plainName] = true
                end
            end
        end
        return members
    end

    local function GetGuildMemberSet()
        local guild = {}
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i)
            if name then
                local plainName = name:match("^(.-)-") or name
                guild[plainName] = true
            end
        end
        return guild
    end

    local function RequestGPWithDelay(memberSet)
        local guildSet = GetGuildMemberSet()
        local nicks = {}
        for plainName in pairs(memberSet) do
            if not guildSet[plainName] then
                table.insert(nicks, plainName)
            end
        end
        if #nicks == 0 then return end

        local timerFrame = CreateFrame("Frame")
        local elapsed = 0
        local delay = 0.05
        local currentIndex = 1

        timerFrame:SetScript("OnUpdate", function(frame, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                elapsed = 0
                if currentIndex <= #nicks then
                    SendAddonMessage("GetGPA", nicks[currentIndex], "GUILD")
                    currentIndex = currentIndex + 1
                else
                    frame:SetScript("OnUpdate", nil)
                    frame:Hide()
                end
            end
        end)
    end

    local function RequestGPWithRetry(attempt)
        attempt = attempt or 1
        local maxAttempts = 10

        local memberSet = GetCurrentRaidMembers()
        local memberCount = 0
        for _ in pairs(memberSet) do memberCount = memberCount + 1 end

        if memberCount == 0 and attempt < maxAttempts then
            local timerFrame = CreateFrame("Frame")
            local elapsed = 0
            local delay = 1.0

            timerFrame:SetScript("OnUpdate", function(frame, dt)
                elapsed = elapsed + dt
                if elapsed >= delay then
                    frame:SetScript("OnUpdate", nil)
                    frame:Hide()
                    RequestGPWithRetry(attempt + 1)
                end
            end)
        elseif memberCount > 0 then
            raidMembers = memberSet
            RequestGPWithDelay(memberSet)
        end
    end

    -- ========================================================================
    -- События
    -- ========================================================================
    raidMembers = GetCurrentRaidMembers()

    raidTracker:SetScript("OnEvent", function(_, event)
        local isInRaid = UnitInRaid("player") ~= nil

        -- Рейд только что создан
        if isInRaid and not wasInRaid then
            RequestGPWithRetry(1)
            wasInRaid = true
            return
        end

        -- Рейд уже был — проверяем, не добавились ли новые не-гильдейские
        if isInRaid and wasInRaid then
            local newMembers = GetCurrentRaidMembers()
            local guildSet = GetGuildMemberSet()

            local newNonGuildNicks = {}
            for plainName in pairs(newMembers) do
                if not raidMembers[plainName] then
                    if not guildSet[plainName] then
                        table.insert(newNonGuildNicks, plainName)
                    end
                end
            end

            if #newNonGuildNicks > 0 then
                local timerFrame = CreateFrame("Frame")
                local elapsed = 0
                local delay = 0.05
                local currentIndex = 1

                timerFrame:SetScript("OnUpdate", function(frame, dt)
                    elapsed = elapsed + dt
                    if elapsed >= delay then
                        elapsed = 0
                        if currentIndex <= #newNonGuildNicks then
                            SendAddonMessage("GetGPA", newNonGuildNicks[currentIndex], "GUILD")
                            currentIndex = currentIndex + 1
                        else
                            frame:SetScript("OnUpdate", nil)
                            frame:Hide()
                        end
                    end
                end)
            end

            raidMembers = newMembers
        end

        wasInRaid = isInRaid
    end)

end)