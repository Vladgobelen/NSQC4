-- ============================================================================
-- NSQC4 / Guild / Recruiter / Logic
-- Логика поиска и приглашения.
-- Модуль: guild_recruiter.
-- ============================================================================

NSQC4.RegisterModule("guild_recruiter", function()

    local GuildRecruiter = NSQC4.GuildRecruiterClass
    if not GuildRecruiter then return end

    -- ========================================================================
    -- Мониторинг событий
    -- ========================================================================
    function GuildRecruiter:EnableEventMonitoring()
        self.frame:RegisterEvent("WHO_LIST_UPDATE")
        self.frame:RegisterEvent("GUILD_INVITE_REQUEST")
        self.frame:SetScript("OnEvent", function(_, event, ...)
            self:OnEvent(event, ...)
        end)
    end

    function GuildRecruiter:DisableEventMonitoring()
        self.frame:UnregisterEvent("WHO_LIST_UPDATE")
        self.frame:UnregisterEvent("GUILD_INVITE_REQUEST")
        self.frame:SetScript("OnEvent", nil)
    end

    function GuildRecruiter:OnEvent(event, ...)
        if event == "WHO_LIST_UPDATE" and self.isSearching then
            self:ProcessWhoResults()
        elseif event == "GUILD_INVITE_REQUEST" then
            local name = ...
            self:RemoveFromList(name)
        end
    end

    -- ========================================================================
    -- Поиск
    -- ========================================================================
    function GuildRecruiter:StartSearch()
        self.isSearching = true
        self.currentLevel = self.settings.minLevel
        self.results = {}
        self.autoInviteLoop = false

        FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
        SetWhoToUI(1)

        self:EnableEventMonitoring()
        self:SendNextWhoQuery()
    end

    function GuildRecruiter:StopSearch()
        self.isSearching = false
        self:DisableEventMonitoring()
        self.autoInviteLoop = false

        FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
        SetWhoToUI(1)

        if self.ui and self.ui.searchBtn then
            self.ui.searchBtn:SetText("Найти")
        end

        if self.searchTimer then
            self.searchTimer:SetScript("OnUpdate", nil)
            self.searchTimer:Hide()
            self.searchTimer = nil
        end
    end

    function GuildRecruiter:SendNextWhoQuery()
        if self.currentLevel > self.settings.maxLevel then
            if self.settings.recursive then
                self.currentLevel = self.settings.minLevel
            else
                self:StopSearch()
                if self.settings.autoAccept and #self.results > 0 then
                    self:StartAutoInvite()
                end
                return
            end
        end

        local maxL = math.min(self.currentLevel + self.settings.step - 1, self.settings.maxLevel)
        local query = self.currentLevel .. "-" .. maxL

        SendWho(query)

        self.currentLevel = maxL + 1

        if not self.searchTimer then
            self.searchTimer = CreateFrame("Frame")
            self.searchTimer.guildRecruiter = self
            self.searchTimer:SetScript("OnUpdate", function(frame, deltaTime)
                frame.elapsed = (frame.elapsed or 0) + deltaTime
                if frame.elapsed >= 6 then
                    local gr = frame.guildRecruiter
                    if gr and gr.isSearching then
                        gr:SendNextWhoQuery()
                    end
                    frame.elapsed = 0
                end
            end)
        else
            self.searchTimer.elapsed = 0
        end
        self.searchTimer:Show()
    end

    -- ========================================================================
    -- Обработка результатов
    -- ========================================================================
    function GuildRecruiter:ProcessWhoResults()
        local n = GetNumWhoResults()
        local now = time()

        for i = 1, n do
            local name, guildName, lvl, raceRU, classRU, _, classENG = GetWhoInfo(i)
            if not (guildName and guildName ~= "") then
                local inviteTime = self.exceptions[name]
                if not (type(inviteTime) == "number" and now - inviteTime <= 7 * 24 * 60 * 60) then
                    if self:MatchesFilters(raceRU, classENG) then
                        local already = false
                        for _, r in ipairs(self.results) do
                            if r.name == name then already = true; break end
                        end
                        if not already then
                            table.insert(self.results, {
                                name = name, level = lvl,
                                race = raceRU, class = classENG,
                            })
                        end
                    end
                end
            end
        end

        self:UpdatePlayerList()

        if self.settings.autoAccept and #self.results > 0 and not self.autoInviteLoop then
            self:StartAutoInvite()
        end
    end

    function GuildRecruiter:MatchesFilters(race, class)
        if not self.settings.classes[class] then return false end
        if not self.settings.races[race]   then return false end
        return true
    end

    -- ========================================================================
    -- Действия с игроками
    -- ========================================================================
    function GuildRecruiter:InviteAndExclude(name)
        if self.exceptions[name] then
            print("|cFFFF0000[GUILD RECRUITER]|r АВТО-ИНВАЙТ: " .. name .. " уже в исключениях. Отменено.")
            return
        end

        GuildInvite(name)
        self.exceptions[name] = time()

        if self.exceptions[name] then
            print("|cFF00FF00[GUILD RECRUITER]|r АВТО-ИНВАЙТ: " .. name .. " приглашён, добавлен в игнор.")
        else
            print("|cFFFF0000[GUILD RECRUITER]|r ОШИБКА: " .. name .. " не попал в игнор-лист!")
        end

        self:RemoveFromList(name)
        self:SetCooldown()
        self:AutoSave()
    end

    function GuildRecruiter:ExcludeOnly(name)
        self.exceptions[name] = time()
        self:RemoveFromList(name)
        self:AutoSave()
    end

    function GuildRecruiter:RemoveFromList(name)
        local i = 1
        while i <= #self.results do
            if self.results[i].name == name then
                table.remove(self.results, i)
            else
                i = i + 1
            end
        end
        self:UpdatePlayerList()
    end

    -- ========================================================================
    -- Кулдаун
    -- ========================================================================
    function GuildRecruiter:SetCooldown()
        self.cooldown = true

        if not self.cooldownTimer then
            self.cooldownTimer = CreateFrame("Frame")
            self.cooldownTimer.elapsed = 0
            self.cooldownTimer.guildRecruiter = self
            self.cooldownTimer:SetScript("OnUpdate", function(self2, deltaTime)
                self2.elapsed = self2.elapsed + deltaTime
                if self2.elapsed >= 6 then
                    if self2.guildRecruiter then
                        self2.guildRecruiter.cooldown = false
                    end
                    self2.elapsed = 0
                    self2:SetScript("OnUpdate", nil)
                    self2:Hide()
                    self2.guildRecruiter.cooldownTimer = nil
                end
            end)
        else
            self.cooldownTimer.elapsed = 0
        end
        self.cooldownTimer:Show()
    end

    -- ========================================================================
    -- Авто-приглашение
    -- ========================================================================
    function GuildRecruiter:StartAutoInvite()
        if self.autoInviteLoop or #self.results == 0 then return end
        self.autoInviteLoop = true

        if self.autoInviteTimer then
            self.autoInviteTimer:SetScript("OnUpdate", nil)
            self.autoInviteTimer:Hide()
            self.autoInviteTimer = nil
        end

        self:ProcessAutoInvite()
    end

    function GuildRecruiter:ProcessAutoInvite()
        if not self.settings.autoAccept or #self.results == 0 then
            self.autoInviteLoop = false
            if self.autoInviteTimer then
                self.autoInviteTimer:SetScript("OnUpdate", nil)
                self.autoInviteTimer:Hide()
                self.autoInviteTimer = nil
            end
            return
        end

        local p = table.remove(self.results, 1)
        if p then
            self:InviteAndExclude(p.name)

            if not self.autoInviteTimer then
                self.autoInviteTimer = CreateFrame("Frame")
                self.autoInviteTimer.guildRecruiter = self
                self.autoInviteTimer:SetScript("OnUpdate", function(frame, deltaTime)
                    frame.elapsed = (frame.elapsed or 0) + deltaTime
                    if frame.elapsed >= 6 then
                        local gr = frame.guildRecruiter
                        if gr and gr.autoInviteLoop then
                            gr:ProcessAutoInvite()
                        end
                        frame.elapsed = 0
                    end
                end)
            else
                self.autoInviteTimer.elapsed = 0
            end
            self.autoInviteTimer:Show()
        else
            self.autoInviteLoop = false
            if self.autoInviteTimer then
                self.autoInviteTimer:SetScript("OnUpdate", nil)
                self.autoInviteTimer:Hide()
                self.autoInviteTimer = nil
            end
        end
    end

end)