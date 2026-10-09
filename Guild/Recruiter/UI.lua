-- ============================================================================
-- NSQC4 / Guild / Recruiter / UI
-- Интерфейс: построение окна, чекбоксы, список игроков.
-- Модуль: guild_recruiter.
-- ============================================================================

NSQC4.RegisterModule("guild_recruiter", function()

    local GuildRecruiter = NSQC4.GuildRecruiterClass
    local CONST = NSQC4.GuildRecruiterConst
    if not GuildRecruiter or not CONST then return end

    local CLASSES        = CONST.CLASSES
    local RACES_ALLIANCE = CONST.RACES_ALLIANCE
    local RACES_HORDE    = CONST.RACES_HORDE
    local ALL_RACES      = CONST.ALL_RACES

    -- ========================================================================
    -- Пикер уровня (выпадающий список 1–80 со скроллом)
    -- ========================================================================
    local function CreateLevelPicker(parent, current, callback)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(180, 300)
        frame:SetPoint("CENTER")
        frame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        frame:Hide()

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
        scrollFrame:SetPoint("TOPLEFT", 10, -10)
        scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(160)
        content:SetHeight(80 * 22)
        scrollFrame:SetScrollChild(content)
        scrollFrame:UpdateScrollChildRect()

        local slider = CreateFrame("Slider", nil, frame)
        slider:SetOrientation("VERTICAL")
        slider:SetPoint("TOPRIGHT", -8, -10)
        slider:SetPoint("BOTTOMRIGHT", -8, 10)
        slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
            edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 3, right = 3, top = 6, bottom = 6 },
        })

        local scrollRange = math.max(0, content:GetHeight() - scrollFrame:GetHeight())
        slider:SetMinMaxValues(0, scrollRange)
        slider:SetValue(0)
        slider:SetValueStep(10)

        frame.scrollFrame = scrollFrame
        frame.slider = slider

        slider:SetScript("OnValueChanged", function(self, value)
            local sf = self:GetParent().scrollFrame
            if sf then sf:SetVerticalScroll(value) end
        end)

        scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            offset = math.max(0, math.min(offset, scrollRange))
            self:SetVerticalScroll(offset)
            local s = self:GetParent().slider
            if s then s:SetValue(offset) end
        end)

        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(self, delta)
            local sf = self.scrollFrame
            if not sf then return end
            local current = sf:GetVerticalScroll()
            local step = 20
            local newOffset = current - delta * step
            newOffset = math.max(0, math.min(newOffset, scrollRange))
            sf:SetVerticalScroll(newOffset)
            local s = self.slider
            if s then s:SetValue(newOffset) end
        end)

        for lvl = 1, 80 do
            local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            btn:SetSize(140, 20)
            btn:SetPoint("TOP", 0, -5 - (lvl - 1) * 22)
            btn:SetText(lvl)
            btn:SetScript("OnClick", function()
                callback(lvl)
                frame:Hide()
            end)
        end

        return frame
    end

    -- ========================================================================
    -- Построение UI
    -- ========================================================================
    function GuildRecruiter:BuildUI()
        if self.isUIBuilt then return end
        self.isUIBuilt = true

        if self.loadingText then
            self.loadingText:Hide()
            self.loadingText = nil
        end

        local y = -45

        local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetText("Набор в гильдию")
        title:SetPoint("TOP", 0, -10)

        local minLevelBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        minLevelBtn:SetSize(40, 20)
        minLevelBtn:SetPoint("TOPLEFT", 20, y)
        minLevelBtn:SetText(self.settings.minLevel)

        local maxLevelBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        maxLevelBtn:SetSize(40, 20)
        maxLevelBtn:SetPoint("LEFT", minLevelBtn, "RIGHT", 10, 0)
        maxLevelBtn:SetText(self.settings.maxLevel)

        local minPicker = CreateLevelPicker(self.frame, self.settings.minLevel, function(lvl)
            self.settings.minLevel = lvl
            minLevelBtn:SetText(lvl)
            self:AutoSave()
        end)

        local maxPicker = CreateLevelPicker(self.frame, self.settings.maxLevel, function(lvl)
            self.settings.maxLevel = lvl
            maxLevelBtn:SetText(lvl)
            self:AutoSave()
        end)

        minLevelBtn:SetScript("OnClick", function() minPicker:Show() end)
        maxLevelBtn:SetScript("OnClick", function() maxPicker:Show() end)

        local stepDD = CreateFrame("Frame", "GuildRecruiterStepDropdown", self.frame, "UIDropDownMenuTemplate")
        stepDD:SetPoint("TOPRIGHT", -20, y)
        UIDropDownMenu_SetWidth(stepDD, 80)
        UIDropDownMenu_Initialize(stepDD, function()
            local info = UIDropDownMenu_CreateInfo()
            for _, v in ipairs({1, 2, 5, 10}) do
                info.text = "Шаг: " .. tostring(v)
                info.func = function()
                    UIDropDownMenu_SetText(stepDD, "Шаг: " .. tostring(v))
                    self.settings.step = v
                    self:AutoSave()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(stepDD, "Шаг: " .. tostring(self.settings.step))

        y = y - 35

        local factionChecks = {}
        for i, f in ipairs({"Alliance", "Horde"}) do
            local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 20 + (i-1)*100, y)
            cb:SetChecked(self.settings.factions[f] and true or false)
            cb:SetScript("OnClick", function()
                local isChecked = cb:GetChecked()
                self.settings.factions[f] = isChecked
                local raceList = (f == "Alliance") and RACES_ALLIANCE or RACES_HORDE
                for _, race in ipairs(raceList) do
                    self.settings.races[race] = isChecked
                    if self.ui and self.ui.raceChecks and self.ui.raceChecks[race] then
                        self.ui.raceChecks[race]:SetChecked(isChecked)
                    end
                end
                self:AutoSave()
            end)
            local lbl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetText(f)
            lbl:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            factionChecks[f] = cb
        end

        local allClassesCB = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
        allClassesCB:SetPoint("TOPLEFT", 220, y)
        allClassesCB:SetScript("OnClick", function()
            local isChecked = allClassesCB:GetChecked()
            for _, cls in ipairs(CLASSES) do
                self.settings.classes[cls] = isChecked
                if self.ui and self.ui.classChecks and self.ui.classChecks[cls] then
                    self.ui.classChecks[cls]:SetChecked(isChecked)
                end
            end
            self:AutoSave()
        end)
        local lblAll = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblAll:SetText("Все классы")
        lblAll:SetPoint("LEFT", allClassesCB, "RIGHT", 5, 0)

        y = y - 30

        local classChecks = {}
        for i, cls in ipairs(CLASSES) do
            local col = (i-1) % 2
            local row = math.floor((i-1)/2)
            local x = 20 + col * 140
            local yy = y - row * 20
            local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", x, yy)
            cb:SetChecked(self.settings.classes[cls] and true or false)
            cb:SetScript("OnClick", function()
                local isChecked = cb:GetChecked()
                self.settings.classes[cls] = isChecked
                self:AutoSave()
            end)
            local lbl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetText(cls)
            lbl:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            classChecks[cls] = cb
        end

        y = y - 110

        local raceChecks = {}
        for i, race in ipairs(ALL_RACES) do
            local col = (i-1) % 2
            local row = math.floor((i-1)/2)
            local x = 20 + col * 140
            local yy = y - row * 20
            local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", x, yy)
            cb:SetChecked(self.settings.races[race] and true or false)
            cb:SetScript("OnClick", function()
                local isChecked = cb:GetChecked()
                self.settings.races[race] = isChecked
                self:AutoSave()
            end)
            local lbl = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetText(race)
            lbl:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            raceChecks[race] = cb
        end

        y = y - 110

        local scrollFrame = CreateFrame("ScrollFrame", "GuildRecruiterScrollFrame", self.frame)
        scrollFrame:SetPoint("TOPLEFT", 15, y)
        scrollFrame:SetPoint("BOTTOMRIGHT", -28, 60)

        local playerList = CreateFrame("Frame", nil, scrollFrame)
        playerList:SetWidth(scrollFrame:GetWidth() - 20)
        playerList:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
        playerList:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
        scrollFrame:SetScrollChild(playerList)
        scrollFrame:UpdateScrollChildRect()

        local slider = CreateFrame("Slider", "GuildRecruiterScrollSlider", self.frame)
        slider:SetOrientation("VERTICAL")
        slider:SetPoint("TOPRIGHT", -8, y)
        slider:SetPoint("BOTTOMRIGHT", -8, 60)
        slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
            edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 3, right = 3, top = 6, bottom = 6 },
        })
        slider:SetMinMaxValues(0, 0)
        slider:SetValue(0)
        slider:SetValueStep(10)

        scrollFrame:SetScript("OnVerticalScroll", function(self2, offset)
            local maxRange = math.max(0, playerList:GetHeight() - scrollFrame:GetHeight())
            offset = math.max(0, math.min(offset, maxRange))
            self2:SetVerticalScroll(offset)
            slider:SetMinMaxValues(0, maxRange)
            slider:SetValue(offset)
        end)

        slider:SetScript("OnValueChanged", function(self2, value)
            scrollFrame:SetVerticalScroll(value)
        end)

        self.frame:EnableMouseWheel(true)
        self.frame:SetScript("OnMouseWheel", function(self2, delta)
            local sf = GuildRecruiter.instance.ui.scroll
            if not sf then return end
            local current = sf:GetVerticalScroll()
            local maxRange = math.max(0, GuildRecruiter.instance.ui.playerList:GetHeight() - sf:GetHeight())
            local step = 20
            local newOffset = current - delta * step
            newOffset = math.max(0, math.min(newOffset, maxRange))
            sf:SetVerticalScroll(newOffset)
            GuildRecruiter.instance.ui.slider:SetValue(newOffset)
        end)

        local autoCB = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
        autoCB:SetPoint("BOTTOMLEFT", 20, 30)
        autoCB:SetChecked(self.settings.autoAccept and true or false)
        autoCB:SetScript("OnClick", function()
            self.settings.autoAccept = autoCB:GetChecked()
            self:AutoSave()
            if self.settings.autoAccept and #self.results > 0 then
                self:StartAutoInvite()
            end
        end)
        autoCB:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText("Автоматически приглашать игроков из списка", 1, 1, 1)
            GameTooltip:Show()
        end)
        autoCB:SetScript("OnLeave", GameTooltip_Hide)

        local recursiveCB = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
        recursiveCB:SetPoint("LEFT", autoCB, "RIGHT", 110, 0)
        recursiveCB:SetChecked(self.settings.recursive and true or false)
        recursiveCB:SetScript("OnClick", function()
            self.settings.recursive = recursiveCB:GetChecked()
            self:AutoSave()
        end)
        recursiveCB:SetScript("OnEnter", function()
            GameTooltip:SetOwner(recursiveCB, "ANCHOR_RIGHT")
            GameTooltip:SetText("Набирать рекурсивно", 1, 1, 1)
            GameTooltip:AddLine("При достижении максимального уровня поиск начнётся заново с минимального.", 1, 0.8, 0, true)
            GameTooltip:Show()
        end)
        recursiveCB:SetScript("OnLeave", GameTooltip_Hide)

        local searchBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
        searchBtn:SetSize(80, 22)
        searchBtn:SetPoint("BOTTOMRIGHT", -20, 30)
        searchBtn:SetText("Найти")
        searchBtn:SetScript("OnClick", function()
            if self.isSearching then
                self:StopSearch()
                searchBtn:SetText("Найти")
            else
                self:StartSearch()
                searchBtn:SetText("Стоп")
            end
        end)

        self.ui = {
            minLevelBtn = minLevelBtn,
            maxLevelBtn = maxLevelBtn,
            minPicker   = minPicker,
            maxPicker   = maxPicker,
            stepDD      = stepDD,
            playerList  = playerList,
            scroll      = scrollFrame,
            slider      = slider,
            autoCB      = autoCB,
            recursiveCB = recursiveCB,
            searchBtn   = searchBtn,
            raceChecks  = raceChecks,
            factionChecks = factionChecks,
            classChecks = classChecks,
            allClassesCB = allClassesCB,
        }
    end

    -- ========================================================================
    -- Применение настроек к UI
    -- ========================================================================
    function GuildRecruiter:ApplySettingsToUI()
        if not self.ui then return end

        self.ui.minLevelBtn:SetText(self.settings.minLevel)
        self.ui.maxLevelBtn:SetText(self.settings.maxLevel)
        UIDropDownMenu_SetText(self.ui.stepDD, "Шаг: " .. tostring(self.settings.step))
        self.ui.autoCB:SetChecked(self.settings.autoAccept and true or false)

        if self.ui.recursiveCB then
            self.ui.recursiveCB:SetChecked(self.settings.recursive and true or false)
        end

        if self.ui.factionChecks then
            self.ui.factionChecks.Alliance:SetChecked(self.settings.factions.Alliance and true or false)
            self.ui.factionChecks.Horde:SetChecked(self.settings.factions.Horde and true or false)
        end

        if self.ui.classChecks then
            for cls, cb in pairs(self.ui.classChecks) do
                cb:SetChecked(self.settings.classes[cls] and true or false)
            end
        end

        if self.ui.raceChecks then
            for race, cb in pairs(self.ui.raceChecks) do
                cb:SetChecked(self.settings.races[race] and true or false)
            end
        end
    end

    -- ========================================================================
    -- Обновление списка игроков
    -- ========================================================================
    function GuildRecruiter:UpdatePlayerList()
        if not self.ui or not self.ui.playerList or not self.ui.scroll then return end
        local list = self.ui.playerList
        local scroll = self.ui.scroll

        for i = 1, 200 do
            local btn = _G["GuildRecruiterPlayerBtn" .. i]
            if btn then btn:Hide() end
        end

        for i, p in ipairs(self.results) do
            local btnName = "GuildRecruiterPlayerBtn" .. i
            local btn = _G[btnName]
            if not btn then
                btn = CreateFrame("Button", btnName, list, "UIPanelButtonTemplate")
                btn:SetSize(list:GetWidth() - 20, 20)
                btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

                btn:SetScript("OnClick", function(self2, button)
                    if GuildRecruiter.instance.cooldown then return end

                    if button == "LeftButton" then
                        GuildInvite(p.name)
                        GuildRecruiter.instance.exceptions[p.name] = time()
                        print("|cFF00FF00[GUILD RECRUITER]|r (Клик) " .. p.name .. " приглашён, добавлен в игнор.")
                        GuildRecruiter.instance:RemoveFromList(p.name)
                        GuildRecruiter.instance:SetCooldown()
                        GuildRecruiter.instance:AutoSave()

                    elseif button == "RightButton" then
                        GuildRecruiter.instance.exceptions[p.name] = time()
                        print("|cFF00FF00[GUILD RECRUITER]|r (ПКМ) " .. p.name .. " добавлен в игнор без инвайта.")
                        GuildRecruiter.instance:RemoveFromList(p.name)
                        GuildRecruiter.instance:AutoSave()
                    end
                end)
            end

            btn:SetText(p.name)
            btn:Show()
            btn:SetPoint("TOP", list, "TOP", 0, -5 - (i - 1) * 25)
        end

        local contentHeight = math.max(1, #self.results) * 25 + 10
        list:SetHeight(contentHeight)

        scroll:SetScrollChild(list)
        scroll:UpdateScrollChildRect()

        local _, maxRange = scroll:GetVerticalScrollRange()
        if maxRange and maxRange > 0 then
            scroll:SetVerticalScroll(maxRange)
        end
    end

    -- ========================================================================
    -- Загрузка настроек из хранилища при инициализации модуля
    -- ========================================================================
    if NSQC4.GuildRecruiter then
        NSQC4.GuildRecruiter:LoadSettings()
    end
end)