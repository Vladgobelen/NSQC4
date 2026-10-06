-- ============================================================================
-- NSQC4 / Interface / ui_frames / Alpha
-- Прозрачность фреймов. Модуль "ui_frames_alpha".
-- ============================================================================

NSQC4.RegisterModule("ui_frames_alpha", function()

    -- ========================================================================
    -- Хранилище: nsDbc4.settings.framesAlpha
    -- ========================================================================
    nsDbc4.settings.framesAlpha = nsDbc4.settings.framesAlpha or {
        frames = {},
        captureDelay = 5,
    }
    local db = nsDbc4.settings.framesAlpha
    db.frames = db.frames or {}
    db.captureDelay = db.captureDelay or 5

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function IsUsableRegion(region)
        if not region then return false end
        if region.IsForbidden and region:IsForbidden() then return false end
        return true
    end

    local function NormalizeToFrame(region)
        if not IsUsableRegion(region) then return nil end
        if region.IsObjectType and region:IsObjectType("Frame") then return region end
        if region.GetParent then return NormalizeToFrame(region:GetParent()) end
        return nil
    end

    local function GetMouseFrame()
        local focus
        if GetMouseFoci then
            local foci = GetMouseFoci()
            if foci and foci[1] then focus = foci[1] end
        elseif GetMouseFocus then
            focus = GetMouseFocus()
        end
        local frame = NormalizeToFrame(focus)
        if not frame then return nil end
        if frame == WorldFrame or frame == UIParent then return nil end
        return frame
    end

    local function GetObjectKey(frame)
        if not frame then return nil end

        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end

        local path = {}
        local current = frame
        while current do
            local parent = current.GetParent and current:GetParent()
            if not parent then break end
            local children = { parent:GetChildren() }
            local index
            for i, child in ipairs(children) do
                if child == current then index = i; break end
            end
            if not index then return nil end
            table.insert(path, 1, index)

            if parent.GetName then
                local pname = parent:GetName()
                if pname and pname ~= "" then
                    return pname .. "|FCChild|" .. table.concat(path, ",")
                end
            end
            current = parent
        end
        return nil
    end

    local function GetFrameByKey(key)
        if not key or type(key) ~= "string" then return nil end

        local direct = _G[key]
        if direct then
            local frame = NormalizeToFrame(direct)
            if frame then return frame end
        end

        local base, path = key:match("^(.-)|FCChild|(.+)$")
        if not base or not path then return nil end

        local current = _G[base]
        if not current or not current.GetChildren then return nil end

        for indexText in path:gmatch("([^,]+)") do
            local index = tonumber(indexText)
            if not index then return nil end
            local children = { current:GetChildren() }
            current = children[index]
            if not current then return nil end
        end
        return NormalizeToFrame(current)
    end

    local function GetObjectDisplayName(frame)
        if not frame then return "нет объекта" end
        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        local otype = "Frame"
        if frame.GetObjectType then
            otype = frame:GetObjectType()
        end
        local parent
        if frame.GetParent then
            parent = frame:GetParent()
        end
        if parent and parent.GetName then
            local pname = parent:GetName()
            if pname and pname ~= "" then return otype .. " внутри " .. pname end
        end
        return otype
    end

    -- ========================================================================
    -- Применение / сброс alpha
    -- ========================================================================
    local function ApplyAlphaByKey(key)
        local frame = GetFrameByKey(key)
        if not frame then return end

        local data = db.frames[key]
        if not data or not data.alphaSettings then return end

        local settings = data.alphaSettings
        local alpha = settings.alpha or 100
        local onlyInCombat = settings.onlyInCombat or false

        if onlyInCombat then
            frame:RegisterEvent("PLAYER_REGEN_DISABLED")
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            frame:SetScript("OnEvent", function(self, event)
                if event == "PLAYER_REGEN_DISABLED" then
                    self:SetAlpha(alpha / 100)
                elseif event == "PLAYER_REGEN_ENABLED" then
                    self:SetAlpha(1.0)
                end
            end)
            if UnitAffectingCombat("player") then
                frame:SetAlpha(alpha / 100)
            else
                frame:SetAlpha(1.0)
            end
        else
            frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            frame:SetScript("OnEvent", nil)
            frame:SetAlpha(alpha / 100)
        end
    end

    local function ResetFrameByKey(key)
        local frame = GetFrameByKey(key)
        if frame then
            frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
            frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            frame:SetScript("OnEvent", nil)

            local data = db.frames[key]
            if data and data.defaultAlpha then
                frame:SetAlpha(data.defaultAlpha)
            else
                frame:SetAlpha(1.0)
            end
        end
        db.frames[key] = nil

        if NSQC4.FramesAlpha_RefreshList then NSQC4.FramesAlpha_RefreshList() end
    end

    local function ResetAll()
        for key in pairs(db.frames) do
            local frame = GetFrameByKey(key)
            if frame then
                frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
                frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
                frame:SetScript("OnEvent", nil)
                frame:SetAlpha(1.0)
            end
        end
        db.frames = {}
        if NSQC4.FramesAlpha_RefreshList then NSQC4.FramesAlpha_RefreshList() end
    end

    local function ApplyAllSaved()
        for key in pairs(db.frames) do
            ApplyAlphaByKey(key)
        end
    end

    -- ========================================================================
    -- Счётчик и захват
    -- ========================================================================
    local countdownFrame
    local countdownTicker
    local countdownValue = 0
    local captureToken = 0

    local function StartCountdown(callback)
        if countdownTicker then
            countdownTicker:SetScript("OnUpdate", nil)
            countdownTicker = nil
        end
        if countdownFrame then
            countdownFrame:Hide()
            countdownFrame = nil
        end

        captureToken = captureToken + 1
        local token = captureToken
        local delay = db.captureDelay or 5

        local f = CreateFrame("Frame", "NSQC4AlphaCountdown", UIParent)
        f:SetSize(400, 50)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")

        local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        txt:SetPoint("CENTER")
        txt:SetText("Наведите мышь на фрейм: " .. delay)

        countdownValue = delay
        countdownFrame = f

        local ticker = CreateFrame("Frame")
        ticker.last = GetTime()
        ticker:SetScript("OnUpdate", function(self)
            if token ~= captureToken then
                self:SetScript("OnUpdate", nil)
                if countdownFrame then countdownFrame:Hide() end
                return
            end

            if GetTime() - self.last >= 1 then
                self.last = GetTime()
                countdownValue = countdownValue - 1

                if countdownValue > 0 then
                    txt:SetText("Наведите мышь на фрейм: " .. countdownValue)
                else
                    self:SetScript("OnUpdate", nil)

                    local frame = GetMouseFrame()
                    if frame then
                        txt:SetText("Захвачено: " .. GetObjectDisplayName(frame))
                        callback(frame)
                    else
                        txt:SetText("Фрейм не найден!")
                    end

                    local hideTimer = CreateFrame("Frame")
                    hideTimer.last = GetTime()
                    hideTimer:SetScript("OnUpdate", function(self2)
                        if GetTime() - self2.last >= 1.5 then
                            self2:SetScript("OnUpdate", nil)
                            if countdownFrame then countdownFrame:Hide() end
                            countdownFrame = nil
                        end
                    end)
                end
            end
        end)
        countdownTicker = ticker
    end

    -- ========================================================================
    -- Диалог настройки alpha
    -- ========================================================================
    local alphaDialog
    local currentFrame

    local function ShowAlphaDialog(frame)
        if not frame then return end

        local key = GetObjectKey(frame)
        if not key then
            print("|cFFFFFF00NSQC4:|r объект без имени, настройка не сохранится.")
        end

        currentFrame = frame

        -- Данные
        if key then
            db.frames[key] = db.frames[key] or {}
            local data = db.frames[key]
            if not data.alphaSettings then
                data.alphaSettings = { alpha = 100, onlyInCombat = false }
            end
            if not data.defaultAlpha then
                data.defaultAlpha = frame:GetAlpha()
            end
        end

        local data = key and db.frames[key] or nil
        local alpha = data and data.alphaSettings.alpha or 100
        local onlyInCombat = data and data.alphaSettings.onlyInCombat or false

        -- Диалог
        if not alphaDialog then
            local d = CreateFrame("Frame", "NSQC4AlphaDialog", UIParent)
            d:SetSize(320, 200)
            d:SetPoint("CENTER")
            d:SetMovable(true)
            d:EnableMouse(true)
            d:SetFrameStrata("FULLSCREEN_DIALOG")
            d:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            d:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" then self:StartMoving() end
            end)
            d:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then self:StopMovingOrSizing() end
            end)

            local title = d:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOP", 0, -15)
            d.title = title

            local closeBtn = CreateFrame("Button", nil, d, "UIPanelCloseButton")
            closeBtn:SetPoint("TOPRIGHT", -5, -5)
            closeBtn:SetScript("OnClick", function() d:Hide() end)

            local cb = CreateFrame("CheckButton", "NSQC4AlphaCB", d, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 20, -50)
            d.cb = cb

            local cbText = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cbText:SetPoint("LEFT", cb, "RIGHT", 5, 0)
            cbText:SetText("Только в бою")

            local st = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            st:SetPoint("TOP", 0, -75)
            d.sliderText = st

            local s = CreateFrame("Slider", "NSQC4AlphaSlider", d, "OptionsSliderTemplate")
            s:SetPoint("TOPLEFT", 20, -100)
            s:SetWidth(280)
            s:SetHeight(20)
            s:SetMinMaxValues(1, 100)
            s:SetValueStep(1)
            d.slider = s

            local status = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            status:SetPoint("BOTTOM", 0, 50)
            status:SetTextColor(0, 1, 0)
            d.status = status

            local applyBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            applyBtn:SetSize(100, 22)
            applyBtn:SetPoint("BOTTOM", 0, 20)
            applyBtn:SetText("Применить")
            applyBtn:SetScript("OnClick", function()
                if not currentFrame then return end
                local k = GetObjectKey(currentFrame)
                if not k then
                    currentFrame:SetAlpha(d.slider:GetValue() / 100)
                    d.status:SetText("Применено (без сохранения)")
                    return
                end

                local dt = db.frames[k]
                if not dt then return end

                dt.alphaSettings.alpha = math.floor(d.slider:GetValue())
                dt.alphaSettings.onlyInCombat = d.cb:GetChecked() and true or false

                ApplyAlphaByKey(k)
                d.status:SetText("Применено")

                if NSQC4.FramesAlpha_RefreshList then NSQC4.FramesAlpha_RefreshList() end
            end)

            alphaDialog = d
        end

        alphaDialog.title:SetText("Прозрачность: " .. GetObjectDisplayName(frame))
        alphaDialog.slider:SetValue(alpha)
        alphaDialog.sliderText:SetText("Прозрачность: " .. alpha .. "%")
        alphaDialog.cb:SetChecked(onlyInCombat)
        alphaDialog.status:SetText("")

        alphaDialog.slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value)
            if alphaDialog and alphaDialog.sliderText then
                alphaDialog.sliderText:SetText("Прозрачность: " .. value .. "%")
            end
        end)

        alphaDialog:Raise()
        alphaDialog:Show()
    end

    -- ========================================================================
    -- Главное окно модуля
    -- ========================================================================
    local mainFrame

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesAlphaFrame", UIParent)
        f:SetSize(480, 420)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Прозрачность фреймов")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetSize(24, 24)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesAlpha_OpenSettings() end)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(160, 22)
        addBtn:SetPoint("TOPLEFT", 20, -45)
        addBtn:SetText("Добавить фрейм")
        addBtn:SetScript("OnClick", function()
            StartCountdown(function(frame) ShowAlphaDialog(frame) end)
        end)

        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetSize(140, 22)
        resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        resetBtn:SetText("Сбросить всё")
        resetBtn:SetScript("OnClick", function() ResetAll() end)

        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesAlphaScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -80)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        f.scroll = scroll

        local child = CreateFrame("Frame", "NSQC4FramesAlphaList", scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        f.list = child

        mainFrame = f
        return f
    end

    function NSQC4.FramesAlpha_RefreshList()
        local f = mainFrame
        if not f or not f.list then return end

        local child = f.list
        local scroll = f.scroll

        for _, c in ipairs({ child:GetChildren() }) do
            c:Hide()
        end

        local keys = {}
        for k in pairs(db.frames) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        local ENTRY_H = 26
        child:SetHeight(math.max(#keys * ENTRY_H, 10))

        for i, key in ipairs(keys) do
            local data = db.frames[key]
            if data and data.alphaSettings then
                local frame = GetFrameByKey(key)
                local display = frame and GetObjectDisplayName(frame) or key
                local a = data.alphaSettings.alpha or 100
                local combat = data.alphaSettings.onlyInCombat and " (бой)" or ""

                local row = CreateFrame("Frame", nil, child)
                row:SetWidth(400)
                row:SetHeight(ENTRY_H)
                row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
                row:EnableMouse(true)

                local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                nameLbl:SetPoint("LEFT", 5, 0)
                nameLbl:SetWidth(240)
                nameLbl:SetJustifyH("LEFT")
                nameLbl:SetText(display)

                local aLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                aLbl:SetPoint("LEFT", nameLbl, "RIGHT", 5, 0)
                aLbl:SetWidth(110)
                aLbl:SetJustifyH("LEFT")
                aLbl:SetText(a .. "%" .. combat)
                aLbl:SetTextColor(0.8, 0.8, 0.8)

                local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                xBtn:SetSize(24, 22)
                xBtn:SetPoint("RIGHT", -5, 0)
                xBtn:SetText("X")
                xBtn:SetScript("OnClick", function() ResetFrameByKey(key) end)

                local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                editBtn:SetSize(60, 22)
                editBtn:SetPoint("RIGHT", xBtn, "LEFT", -5, 0)
                editBtn:SetText("Изменить")
                editBtn:SetScript("OnClick", function()
                    if frame then ShowAlphaDialog(frame) end
                end)

                row:SetScript("OnEnter", function()
                    nameLbl:SetTextColor(1, 1, 0)
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Объект: " .. key, 1, 1, 1)
                    GameTooltip:AddLine("Прозрачность: " .. a .. "%", 0, 1, 0)
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    nameLbl:SetTextColor(1, 1, 1)
                    GameTooltip:Hide()
                end)
            end
        end

        scroll:UpdateScrollChildRect()
    end

    -- ========================================================================
    -- Настройки модуля
    -- ========================================================================
    local settingsFrame

    function NSQC4.FramesAlpha_OpenSettings()
        if settingsFrame then
            settingsFrame:Raise()
            settingsFrame:Show()
            return
        end

        local f = CreateFrame("Frame", "NSQC4FramesAlphaSettings", UIParent)
        f:SetSize(320, 180)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Настройки: Прозрачность")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 20, -50)
        lbl:SetText("Время до применения: " .. (db.captureDelay or 5) .. " сек")

        local slider = CreateFrame("Slider", "NSQC4AlphaSettingsSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, -80)
        slider:SetWidth(250)
        slider:SetHeight(20)
        slider:SetMinMaxValues(3, 15)
        slider:SetValueStep(1)
        slider:SetValue(db.captureDelay or 5)

        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value)
            lbl:SetText("Время до применения: " .. value .. " сек")
        end)

        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 22)
        saveBtn:SetPoint("BOTTOM", 0, 15)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            db.captureDelay = math.floor(slider:GetValue())
            f:Hide()
        end)

        settingsFrame = f
        f:Raise()
        f:Show()
    end

    -- ========================================================================
    -- Слэш-команда /ns_fcalpha
    -- ========================================================================
    SLASH_NS_FCALPHA1 = "/ns_fcalpha"
    SlashCmdList["NS_FCALPHA"] = function(msg)
        msg = (msg or ""):lower()

        if msg == "cancel" then
            captureToken = captureToken + 1
            if countdownFrame then countdownFrame:Hide(); countdownFrame = nil end
            print("|cFFFFFF00NSQC4:|r захват отменён.")
        elseif msg == "apply" then
            ApplyAllSaved()
            print("|cFF00FF00NSQC4:|r прозрачности применены.")
        else
            local f = CreateMainFrame()
            if f:IsShown() then
                f:Hide()
            else
                f:Raise()
                f:Show()
                NSQC4.FramesAlpha_RefreshList()
            end
        end
    end

    -- ========================================================================
    -- Регистрация кнопки на панели
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("A", "/ns_fcalpha", "Прозрачность фреймов", function()
            SlashCmdList["NS_FCALPHA"]("")
        end)
    end

    -- ========================================================================
    -- Восстановление при загрузке
    -- ========================================================================
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_LOGIN")
    restoreFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        ApplyAllSaved()
    end)

end)