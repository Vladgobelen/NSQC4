-- ============================================================================
-- NSQC4 / Guild / Recruiter / Storage
-- Работа с хранилищем nsDbc4.guild_recruiter.
-- Модуль: guild_recruiter.
-- ============================================================================

NSQC4.RegisterModule("guild_recruiter", function()

    local GuildRecruiter = NSQC4.GuildRecruiterClass
    if not GuildRecruiter then return end

    -- ========================================================================
    -- Инициализация подтаблицы
    -- ========================================================================
    local function EnsureStorage()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.guild_recruiter = nsDbc4.guild_recruiter or {}
        local s = nsDbc4.guild_recruiter
        s.settings   = s.settings   or {}
        s.exceptions = s.exceptions or {}
        return s
    end

    -- ========================================================================
    -- Сохранение в nsDbc4
    -- ========================================================================
    function GuildRecruiter:SaveSettings()
        local s = EnsureStorage()

        s.settings.minLevel   = self.settings.minLevel
        s.settings.maxLevel   = self.settings.maxLevel
        s.settings.step       = self.settings.step
        s.settings.autoAccept = self.settings.autoAccept
        s.settings.recursive  = self.settings.recursive
        s.settings.factions   = {
            Alliance = self.settings.factions.Alliance,
            Horde    = self.settings.factions.Horde,
        }

        s.settings.classes = {}
        for cls, val in pairs(self.settings.classes) do
            s.settings.classes[cls] = val
        end

        s.settings.races = {}
        for race, val in pairs(self.settings.races) do
            s.settings.races[race] = val
        end

        s.exceptions = self.exceptions
    end

    function GuildRecruiter:AutoSave()
        self:SaveSettings()
    end

    -- ========================================================================
    -- Загрузка из nsDbc4
    -- ========================================================================
    function GuildRecruiter:LoadSettings()
        local s = EnsureStorage()
        local saved = s.settings

        if type(saved.minLevel) == "number" then self.settings.minLevel = saved.minLevel end
        if type(saved.maxLevel) == "number" then self.settings.maxLevel = saved.maxLevel end
        if type(saved.step) == "number"     then self.settings.step     = saved.step end

        if type(saved.autoAccept) == "boolean" then self.settings.autoAccept = saved.autoAccept end
        if type(saved.recursive)  == "boolean" then self.settings.recursive  = saved.recursive end

        if saved.factions then
            if type(saved.factions.Alliance) == "boolean" then
                self.settings.factions.Alliance = saved.factions.Alliance
            end
            if type(saved.factions.Horde) == "boolean" then
                self.settings.factions.Horde = saved.factions.Horde
            end
        end

        if saved.classes then
            for cls, val in pairs(saved.classes) do
                if self.settings.classes[cls] ~= nil then
                    self.settings.classes[cls] = val
                end
            end
        end

        if saved.races then
            for race, val in pairs(saved.races) do
                if self.settings.races[race] ~= nil then
                    self.settings.races[race] = val
                end
            end
        end

        if s.exceptions then
            self.exceptions = s.exceptions
        end

        local now = time()
        for name, inviteTime in pairs(self.exceptions) do
            if type(inviteTime) == "number" and now - inviteTime > 7 * 24 * 60 * 60 then
                self.exceptions[name] = nil
            end
        end
    end

end)