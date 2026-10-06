-- ============================================================================
-- NSQC4 / Interface / ui_frames / Layers
-- Изменение слоёв (FrameStrata) фреймов. Модуль "ui_frames_layers".
-- ============================================================================

NSQC4.RegisterModule("ui_frames_layers", function()

    -- ========================================================================
    -- Хранилище: nsDbc4.settings.framesLayers
    -- ========================================================================
    nsDbc4.settings.framesLayers = nsDbc4.settings.framesLayers or {
        layers = {},
        layersOriginal = {},
        captureDelay = 5,
    }
    local db = nsDbc4.settings.framesLayers
    db.layers = db.layers or {}
    db.layersOriginal = db.layersOriginal or {}
    db.captureDelay = db.captureDelay or 5

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local STRATAS = {
        "BACKGROUND", "LOW", "MEDIUM", "HIGH",
        "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP",
    }

    local STRATA_NAMES = {
        BACKGROUND         = "Фон (BACKGROUND)",
        LOW                = "Низкий (LOW)",
        MEDIUM             = "Средний (MEDIUM)",
        HIGH               = "Высокий (HIGH)",
        DIALOG             = "Диалог (DIALOG)",
        FULLSCREEN         = "Полный экран (FULLSCREEN)",
        FULLSCREEN_DIALOG  = "Полный экран, диалог (FULLSCREEN_DIALOG)",
        TOOLTIP            = "Подсказка (TOOLTIP)",
    }

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function IsValidStrata(value)
        for _, s in ipairs(STRATAS) do
            if s == value then return true end
        end
        return false
    end

    local function GetStrataIndex(value)
        for i, s in ipairs(STRATAS) do
            if s == value then return i end
        end
        return nil
    end

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

    local function CanSetStrata(frame)
        if not frame or not frame.SetFrameStrata then return false end
        if frame.IsProtected and frame:IsProtected()
            and InCombatLockdown and InCombatLockdown()
        then
            return false
        end
        return true
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
    -- Применение / установка / удаление
    -- ========================================================================
    local function ApplySavedLayers()
        for key, strata in pairs(db.layers) do
            if IsValidStrata(strata) then
                local frame = GetFrameByKey(key)
                if frame and frame.SetFrameStrata then
                    if not db.layersOriginal[key] then
                        db.layersOriginal[key] = frame:GetFrameStrata()
                    end
                    if CanSetStrata(frame) then
                        frame:SetFrameStrata(strata)
                    end
                end
            else
                db.layers[key] = nil
                db.layersOriginal[key] = nil
            end
        end
    end

    local function SetLayerByKey(key, strata)
        if not key or not IsValidStrata(strata) then return end

        local frame = GetFrameByKey(key)
        if frame then
            if not CanSetStrata(frame) then
                print("|cFFFFFF00NSQC4:|r нельзя изменить слой этого объекта сейчас.")
                return
            end

            if not db.layersOriginal[key] then
                db.layersOriginal[key] = frame.GetFrameStrata and frame:GetFrameStrata() or "MEDIUM"
            end

            frame:SetFrameStrata(strata)
        end

        db.layers[key] = strata

        if NSQC4.FramesLayers_RefreshList then
            NSQC4.FramesLayers_RefreshList()
        end
    end

    local function RemoveLayerByKey(key)
        if not key then return end

        local frame = GetFrameByKey(key)
        if frame then
            if not CanSetStrata(frame) then
                print("|cFFFFFF00NSQC4:|r нельзя сбросить слой этого объекта сейчас.")
                return
            end

            local restore = db.layersOriginal[key]
            if not IsValidStrata(restore) then restore = "MEDIUM" end
            frame:SetFrameStrata(restore)
        end

        db.layers[key] = nil
        db.layersOriginal[key] = nil

        if NSQC4.FramesLayers_RefreshList then
            NSQC4.FramesLayers_RefreshList()
        end
    end

    local function ChangeLayerByKey(key, direction)
        if not key then return end

        local current = db.layers[key]
        local frame = GetFrameByKey(key)

        if not IsValidStrata(current) then
            if frame and frame.GetFrameStrata then
                current = frame:GetFrameStrata()
            else
                current = "MEDIUM"
            end
        end

        local idx = GetStrataIndex(current) or GetStrataIndex("MEDIUM") or 3
        local newIdx = idx + (tonumber(direction) or 0)

        if newIdx < 1 or newIdx > #STRATAS then return end

        SetLayerByKey(key, STRATAS[newIdx])
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

        local f = CreateFrame("Frame", "NSQC4LayersCountdown", UIParent)
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
    -- Окно выбора слоя
    -- ========================================================================
    local layerDialog
    local currentFrame
    local layerDropDown

    local function InitDropDown(self, level)
        if not currentFrame or not currentFrame.GetFrameStrata then return end

        level = level or UIDROPDOWNMENU_MENU_LEVEL or 1
        local current = currentFrame:GetFrameStrata()

        for _, strata in ipairs(STRATAS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = STRATA_NAMES[strata] or strata
            info.value = strata
            info.checked = (current == strata) and 1 or nil
            info.func = function()
                if not currentFrame then return end
                if UIDropDownMenu_SetSelectedValue then
                    UIDropDownMenu_SetSelectedValue(layerDropDown, strata)
                end
                if UIDropDownMenu_SetText then
                    UIDropDownMenu_SetText(layerDropDown, STRATA_NAMES[strata] or strata)
                end
                local key = GetObjectKey(currentFrame)
                if key then SetLayerByKey(key, strata) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    local function UpdateDialog(frame)
        currentFrame = frame
        if not layerDialog then return end

        local objLabel = layerDialog.objLabel
        if not frame then
            objLabel:SetText("Объект: нет")
            return
        end

        objLabel:SetText("Объект: " .. GetObjectDisplayName(frame))

        if frame.GetFrameStrata then
            local strata = frame:GetFrameStrata()
            if layerDropDown then
                if UIDropDownMenu_SetSelectedValue then
                    UIDropDownMenu_SetSelectedValue(layerDropDown, strata)
                end
                if UIDropDownMenu_SetText then
                    UIDropDownMenu_SetText(layerDropDown, STRATA_NAMES[strata] or strata)
                end
            end
        end
    end

    local function OpenLayerDialog(frame)
        frame = NormalizeToFrame(frame)
        if not frame then
            print("|cFFFFFF00NSQC4:|r не удалось выбрать объект.")
            return
        end
        if frame == UIParent or frame == WorldFrame then
            print("|cFFFFFF00NSQC4:|r нельзя выбрать UIParent или WorldFrame.")
            return
        end

        local key = GetObjectKey(frame)
        if key then
            local saved = db.layers[key]
            if saved and IsValidStrata(saved) then
                if not db.layersOriginal[key] then
                    db.layersOriginal[key] = frame.GetFrameStrata and frame:GetFrameStrata() or "MEDIUM"
                end
                if CanSetStrata(frame) then
                    frame:SetFrameStrata(saved)
                end
            elseif not db.layersOriginal[key] then
                db.layersOriginal[key] = frame.GetFrameStrata and frame:GetFrameStrata() or "MEDIUM"
            end
        end

        if not layerDialog then
            local d = CreateFrame("Frame", "NSQC4LayersDialog", UIParent)
            d:SetSize(360, 180)
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
            title:SetText("Изменение слоя")

            local closeBtn = CreateFrame("Button", nil, d, "UIPanelCloseButton")
            closeBtn:SetPoint("TOPRIGHT", -5, -5)
            closeBtn:SetScript("OnClick", function() d:Hide() end)

            local objLabel = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            objLabel:SetPoint("TOPLEFT", 15, -45)
            objLabel:SetWidth(270)
            objLabel:SetJustifyH("LEFT")
            d.objLabel = objLabel

            local upBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            upBtn:SetSize(32, 22)
            upBtn:SetPoint("TOPRIGHT", -15, -40)
            upBtn:SetText("^")
            upBtn:SetScript("OnClick", function()
                if not currentFrame then return end
                local parent = currentFrame.GetParent and currentFrame:GetParent()
                parent = NormalizeToFrame(parent)
                if parent then OpenLayerDialog(parent)
                else print("|cFFFFFF00NSQC4:|r у объекта нет родителя выше.") end
            end)

            local dd = CreateFrame("Frame", "NSQC4LayersDropDown", d, "UIDropDownMenuTemplate")
            dd:SetPoint("TOPLEFT", objLabel, "BOTTOMLEFT", -15, -10)
            if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, 220) end
            UIDropDownMenu_Initialize(dd, InitDropDown)
            layerDropDown = dd

            local remBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            remBtn:SetSize(32, 22)
            remBtn:SetPoint("BOTTOMRIGHT", -15, 15)
            remBtn:SetText("X")
            remBtn:SetScript("OnClick", function()
                if currentFrame then
                    local k = GetObjectKey(currentFrame)
                    if k then RemoveLayerByKey(k) end
                end
            end)

            layerDialog = d
        end

        layerDialog:Raise()
        layerDialog:Show()
        UpdateDialog(frame)
    end

    -- ========================================================================
    -- Главное окно модуля
    -- ========================================================================
    local mainFrame

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesLayersFrame", UIParent)
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
        title:SetText("Слои фреймов")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetSize(24, 24)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesLayers_OpenSettings() end)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(160, 22)
        addBtn:SetPoint("TOPLEFT", 20, -45)
        addBtn:SetText("Добавить слой")
        addBtn:SetScript("OnClick", function()
            StartCountdown(function(frame) OpenLayerDialog(frame) end)
        end)

        local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        refreshBtn:SetSize(110, 22)
        refreshBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        refreshBtn:SetText("Обновить")
        refreshBtn:SetScript("OnClick", function()
            if NSQC4.FramesLayers_RefreshList then NSQC4.FramesLayers_RefreshList() end
        end)

        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesLayersScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -80)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        f.scroll = scroll

        local child = CreateFrame("Frame", "NSQC4FramesLayersList", scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        f.list = child

        mainFrame = f
        return f
    end

    function NSQC4.FramesLayers_RefreshList()
        local f = mainFrame
        if not f or not f.list then return end

        local child = f.list
        local scroll = f.scroll

        for _, c in ipairs({ child:GetChildren() }) do
            c:Hide()
        end

        local keys = {}
        for k in pairs(db.layers) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        local ENTRY_H = 26
        child:SetHeight(math.max(#keys * ENTRY_H, 10))

        for i, key in ipairs(keys) do
            local strata = db.layers[key]
            if not IsValidStrata(strata) then strata = "MEDIUM" end

            local frame = GetFrameByKey(key)
            local display = frame and GetObjectDisplayName(frame) or key

            local row = CreateFrame("Frame", nil, child)
            row:SetWidth(400)
            row:SetHeight(ENTRY_H)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
            row:EnableMouse(true)

            local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            nameLbl:SetPoint("LEFT", 5, 0)
            nameLbl:SetWidth(210)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetText(display)

            local layerLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            layerLbl:SetPoint("LEFT", nameLbl, "RIGHT", 5, 0)
            layerLbl:SetWidth(110)
            layerLbl:SetJustifyH("LEFT")
            layerLbl:SetText(strata)
            layerLbl:SetTextColor(0.8, 0.8, 0.8)

            local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            xBtn:SetSize(24, 22)
            xBtn:SetPoint("RIGHT", -5, 0)
            xBtn:SetText("X")
            xBtn:SetScript("OnClick", function() RemoveLayerByKey(key) end)

            local minusBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            minusBtn:SetSize(24, 22)
            minusBtn:SetPoint("RIGHT", xBtn, "LEFT", -3, 0)
            minusBtn:SetText("-")
            minusBtn:SetScript("OnClick", function() ChangeLayerByKey(key, -1) end)

            local plusBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            plusBtn:SetSize(24, 22)
            plusBtn:SetPoint("RIGHT", minusBtn, "LEFT", -3, 0)
            plusBtn:SetText("+")
            plusBtn:SetScript("OnClick", function() ChangeLayerByKey(key, 1) end)

            local idx = GetStrataIndex(strata) or 3
            if idx >= #STRATAS then plusBtn:Disable() else plusBtn:Enable() end
            if idx <= 1 then minusBtn:Disable() else minusBtn:Enable() end

            row:SetScript("OnEnter", function()
                nameLbl:SetTextColor(1, 1, 0)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText("Объект: " .. key, 1, 1, 1)
                GameTooltip:AddLine("Слой: " .. (STRATA_NAMES[strata] or strata), 0, 1, 0)
                if frame then
                    GameTooltip:AddLine("Объект найден.", 0, 1, 0)
                else
                    GameTooltip:AddLine("Объект не найден.", 1, 0, 0, true)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                nameLbl:SetTextColor(1, 1, 1)
                GameTooltip:Hide()
            end)
        end

        scroll:UpdateScrollChildRect()
    end

    -- ========================================================================
    -- Настройки модуля
    -- ========================================================================
    local settingsFrame

    function NSQC4.FramesLayers_OpenSettings()
        if settingsFrame then
            settingsFrame:Raise()
            settingsFrame:Show()
            return
        end

        local f = CreateFrame("Frame", "NSQC4FramesLayersSettings", UIParent)
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
        title:SetText("Настройки: Слои")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 20, -50)
        lbl:SetText("Время до применения: " .. (db.captureDelay or 5) .. " сек")

        local slider = CreateFrame("Slider", "NSQC4LayersSlider", f, "OptionsSliderTemplate")
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
    -- Слэш-команда /ns_fclayer
    -- ========================================================================
    SLASH_NS_FCLAYER1 = "/ns_fclayer"
    SlashCmdList["NS_FCLAYER"] = function(msg)
        msg = (msg or ""):lower()

        if msg == "apply" then
            ApplySavedLayers()
            print("|cFF00FF00NSQC4:|r сохранённые слои применены.")
        elseif msg == "cancel" then
            captureToken = captureToken + 1
            if countdownFrame then countdownFrame:Hide(); countdownFrame = nil end
            print("|cFFFFFF00NSQC4:|r захват отменён.")
        else
            local f = CreateMainFrame()
            if f:IsShown() then
                f:Hide()
            else
                f:Raise()
                f:Show()
                NSQC4.FramesLayers_RefreshList()
            end
        end
    end

    -- ========================================================================
    -- Регистрация кнопки на панели
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("L", "/ns_fclayer", "Слои фреймов", function()
            SlashCmdList["NS_FCLAYER"]("")
        end)
    end

    -- ========================================================================
    -- Восстановление при загрузке
    -- ========================================================================
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_LOGIN")
    restoreFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        ApplySavedLayers()
    end)

end)