-- ============================================================================
-- NSQC4 / Guild / Recruiter / Init
-- Рекрутер гильдии: поиск и приглашение игроков без гильдии.
-- Модуль: guild_recruiter.
-- Открывается автоматически вместе с вкладкой Who.
-- ============================================================================

NSQC4.RegisterModule("guild_recruiter", function()

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local CLASSES = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
        "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID"
    }

    local RACES_ALLIANCE = { "Человек", "Дворф", "Ночной эльф", "Гном", "Дреней" }
    local RACES_HORDE    = { "Орк", "Нежить", "Таурен", "Тролль", "Эльф крови" }

    local ALL_RACES = {}
    for _, r in ipairs(RACES_ALLIANCE) do table.insert(ALL_RACES, r) end
    for _, r in ipairs(RACES_HORDE)    do table.insert(ALL_RACES, r) end

    -- ========================================================================
    -- Класс
    -- ========================================================================
    local GuildRecruiter = {}
    GuildRecruiter.__index = GuildRecruiter

    NSQC4.GuildRecruiterClass = GuildRecruiter
    NSQC4.GuildRecruiterConst = {
        CLASSES        = CLASSES,
        RACES_ALLIANCE = RACES_ALLIANCE,
        RACES_HORDE    = RACES_HORDE,
        ALL_RACES      = ALL_RACES,
    }

    -- ========================================================================
    -- Создание инстанса
    -- ========================================================================
    function GuildRecruiter.new()
        local self = setmetatable({}, GuildRecruiter)

        self.frame = CreateFrame("Frame", "GuildRecruiterFrame", UIParent)
        self.frame:SetSize(320, 520)
        self.frame:Hide()
        self.frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        self.frame:SetBackdropColor(0, 0, 0, 1)
        self.frame:SetFrameStrata("DIALOG")

        self.loadingText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.loadingText:SetText("ЗАГРУЗКА...")
        self.loadingText:SetPoint("CENTER")

        self.isUIBuilt    = false
        self.results      = {}
        self.cooldown     = false
        self.autoInviteLoop = false
        self.isSearching  = false
        self.searchTimer  = nil
        self.autoInviteTimer = nil
        self.cooldownTimer   = nil

        self.settings = {
            minLevel = 1,
            maxLevel = 80,
            step = 5,
            autoAccept = false,
            recursive = false,
            factions = { Alliance = false, Horde = false },
            classes = {},
            races = {},
        }
        for _, cls in ipairs(CLASSES) do
            self.settings.classes[cls] = false
        end
        for _, race in ipairs(ALL_RACES) do
            self.settings.races[race] = false
        end
        self.exceptions = {}

        self:SafeHookWhoFrame()

        return self
    end

    -- ========================================================================
    -- Интеграция с WhoFrame
    -- ========================================================================
    function GuildRecruiter:SafeHookWhoFrame()
        if not WhoFrame then
            local wait = CreateFrame("Frame")
            wait:SetScript("OnUpdate", function(self2)
                if WhoFrame then
                    self2:SetScript("OnUpdate", nil)
                    self:DoHookWhoFrame()
                    self.frame:SetParent(WhoFrame)
                    self.frame:SetPoint("TOPLEFT", WhoFrame, "TOPRIGHT", 10, 0)
                end
            end)
            return
        end
        self:DoHookWhoFrame()
        self.frame:SetParent(WhoFrame)
        self.frame:SetPoint("TOPLEFT", WhoFrame, "TOPRIGHT", 10, 0)
    end

    function GuildRecruiter:DoHookWhoFrame()
        local instance = self
        local origShow = WhoFrame.Show
        WhoFrame.Show = function(...)
            instance.frame:Show()
            if not instance.isUIBuilt then
                instance:BuildUI()
            end
            instance:LoadSettings()
            instance:ApplySettingsToUI()
            return origShow(...)
        end

        local origHide = WhoFrame.Hide
        WhoFrame.Hide = function(...)
            instance.frame:Hide()
            return origHide(...)
        end
    end

    NSQC4.GuildRecruiter = GuildRecruiter.new()

end)