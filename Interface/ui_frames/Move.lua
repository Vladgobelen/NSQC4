-- ============================================================================
-- NSQC4 / Interface / ui_frames / Move
-- Перемещение фреймов. Модуль "ui_frames_move".
-- ============================================================================

SLASH_NS_FCMOVE1 = "/ns_fcmove"
SLASH_NS_FCMOVE2 = "/nsfcm"
SlashCmdList["NS_FCMOVE"] = function(msg)
    msg = (msg or ""):lower()
    if not NSQC4 or not NSQC4._FramesMoveDispatch then
        print("|cFFFFFF00NSQC4:|r модуль перемещения ещё не инициализирован.")
        return
    end
    NSQC4._FramesMoveDispatch(msg)
end

NSQC4.RegisterModule("ui_frames_move", function()

    -- ========================================================================
    -- Хранилище (Персональное для персонажа)
    -- ========================================================================
    local charKey = UnitName("player") .. " - " .. (GetRealmName() or "Unknown")
    
    -- Жесткая проверка структуры (защита от старой базы)
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.framesMove = nsDbc4.settings.framesMove or {}
    nsDbc4.settings.framesMove.chars = nsDbc4.settings.framesMove.chars or {}
    
    local globalMove = nsDbc4.settings.framesMove
    globalMove.chars[charKey] = globalMove.chars[charKey] or { frames = {}, captureDelay = 5 }
    
    local db = globalMove.chars[charKey]
    db.frames = db.frames or {}
    db.captureDelay = db.captureDelay or 5

    local debugEnabled = false
    local LOG_PREFIX = "|cFF66CCFF[FCMOVE]|r "

    local function L(fmt, ...)
        if debugEnabled then print(LOG_PREFIX .. string.format(fmt, ...)) end
    end

    local function NameOf(obj)
        if not obj then return "nil" end
        if obj.GetName then
            local n = obj:GetName()
            if n and n ~= "" then return n end
        end
        return "<obj>"
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

    local function GetObjectKey(frame)
        if not frame then return nil end
        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        return nil
    end

    local function GetFrameByKey(key)
        if not key then return nil end
        local direct = _G[key]
        if direct then return NormalizeToFrame(direct) end
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

    -- ========================================================================
    -- ЖЕСТКАЯ ГЕОМЕТРИЯ (Только X, Y от левого верхнего угла экрана)
    -- ========================================================================
    local function CaptureGeometry(frame)
        if not frame then return nil end
        
        local left = frame:GetLeft()
        local top = frame:GetTop()
        local uiLeft = UIParent:GetLeft()
        local uiTop = UIParent:GetTop()
        
        local absX = 0
        local absY = 0
        
        if left and top and uiLeft and uiTop then
            absX = left - uiLeft
            absY = top - uiTop
        end

        return {
            x = absX,
            y = absY,
            width = frame:GetWidth(),
            height = frame:GetHeight(),
            scale = frame:GetScale()
        }
    end

    local function FormatGeometry(g)
        if not g then return "nil" end
        return string.format("pos(%.1f, %.1f) size=%.0fx%.0f", g.x or 0, g.y or 0, g.width or 0, g.height or 0)
    end

    local function ApplyGeometry(frame, g)
        if not frame or not g then return false end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return false end

        local wasMovable = frame.IsMovable and frame:IsMovable()
        if frame.SetMovable then frame:SetMovable(true) end

        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", g.x, g.y)

        if g.width and g.height then frame:SetSize(g.width, g.height) end
        if g.scale then frame:SetScale(g.scale) end

        if frame.SetMovable and wasMovable ~= nil then frame:SetMovable(wasMovable) end
        return true
    end

    local function ApplyPositionByKey(key)
        local frame = GetFrameByKey(key)
        local data = db.frames[key]
        if frame and data and data.geometry then
            return ApplyGeometry(frame, data.geometry)
        end
        return false
    end

    local function ResetFrameByKey(key)
        local frame = GetFrameByKey(key)
        local data  = db.frames[key]
        if frame and data and data.defaultGeometry then
            ApplyGeometry(frame, data.defaultGeometry)
        end
        db.frames[key] = nil
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ResetAll()
        for key, data in pairs(db.frames) do
            local frame = GetFrameByKey(key)
            if frame and data.defaultGeometry then
                ApplyGeometry(frame, data.defaultGeometry)
            end
        end
        db.frames = {}
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ApplyAllSaved()
        for key in pairs(db.frames) do
            ApplyPositionByKey(key)
        end
    end

    -- ========================================================================
    -- ОТЛАДКА (Выводит только то, что нужно по /nsfcm debug)
    -- ========================================================================
    local function ReportAll()
        local keys = {}
        for k in pairs(db.frames) do table.insert(keys, k) end
        table.sort(keys)
        print(LOG_PREFIX .. "===== ОТЧЕТ: " .. #keys .. " фреймов =====")
        for _, key in ipairs(keys) do
            local frame = GetFrameByKey(key)
            local data = db.frames[key]
            print(LOG_PREFIX .. "Фрейм: " .. key)
            if frame then
                print(LOG_PREFIX .. "  Сейчас в игре: " .. FormatGeometry(CaptureGeometry(frame)))
            else
                print(LOG_PREFIX .. "  Сейчас в игре: |cFFFF6060НЕ НАЙДЕН|r")
            end
            if data and data.geometry then
                print(LOG_PREFIX .. "  Сохранено:     " .. FormatGeometry(data.geometry))
            else
                print(LOG_PREFIX .. "  Сохранено:     |cFFFF6060НЕТ ДАННЫХ|r")
            end
        end
        print(LOG_PREFIX .. "===== КОНЕЦ =====")
    end

    -- ========================================================================
    -- Режим перемещения
    -- ========================================================================
    local moveOverlay

    local function SaveCurrentPosition(frame, key)
        if not frame or not key then return end
        local data = db.frames[key]
        if not data then return end
        data.geometry = CaptureGeometry(frame)
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function StopMoveMode()
        if moveOverlay then
            moveOverlay:Hide()
            moveOverlay:SetParent(nil)
            moveOverlay = nil
        end
        print("|cFF00FF00NSQC4:|r режим перемещения выключен.")
    end

    local function StartMoveForFrame(frame)
        if not frame then return end
        local target = frame
        local key = GetObjectKey(target)
        
        if not key then
            print("|cFFFFFF00NSQC4:|r у фрейма нет имени, нельзя сохранить.")
            return
        end

        db.frames[key] = db.frames[key] or {}
        local data = db.frames[key]
        if not data.defaultGeometry then
            data.defaultGeometry = CaptureGeometry(target)
        end

        if moveOverlay then moveOverlay:Hide() end

        local ov = CreateFrame("Frame", nil, target)
        ov:SetAllPoints(target)
        ov:EnableMouse(true)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(200)

        local hl = ov:CreateTexture(nil, "OVERLAY")
        hl:SetAllPoints(true)
        hl:SetTexture(0.2, 1, 0.2, 0.2)

        ov:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                if target.SetMovable then target:SetMovable(true) end
                target:EnableMouse(true)
                target:StartMoving()
            elseif button == "RightButton" then
                target:StopMovingOrSizing()
                if key then ApplyPositionByKey(key) end
                StopMoveMode()
            end
        end)

        ov:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                target:StopMovingOrSizing()
                SaveCurrentPosition(target, key)
                StopMoveMode()
            end
        end)

        moveOverlay = ov
        print("|cFF00FF00NSQC4:|r перемещение активно. Тяни ЛКМ, ПКМ — отмена.")
    end

    -- ========================================================================
    -- Счётчик
    -- ========================================================================
    local countdownFrame, countdownTicker, countdownValue = nil, nil, 0
    local captureToken = 0

    local function StartCountdown(callback)
        if countdownTicker then countdownTicker:SetScript("OnUpdate", nil) end
        if countdownFrame then countdownFrame:Hide() end

        captureToken = captureToken + 1
        local token = captureToken
        local delay = db.captureDelay or 5

        local f = CreateFrame("Frame", "NSQC4MoveCountdown", UIParent)
        f:SetSize(400, 50)
        f:SetPoint("CENTER")
        f:SetFrameStrata("TOOLTIP")

        local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        txt:SetPoint("CENTER")
        txt:SetText("Наведите мышь: " .. delay)

        countdownValue = delay
        countdownFrame = f

        local ticker = CreateFrame("Frame")
        ticker.last = GetTime()
        ticker:SetScript("OnUpdate", function(self)
            if token ~= captureToken then self:SetScript("OnUpdate", nil) return end
            if GetTime() - self.last >= 1 then
                self.last = GetTime()
                countdownValue = countdownValue - 1
                if countdownValue > 0 then
                    txt:SetText("Наведите мышь: " .. countdownValue)
                else
                    self:SetScript("OnUpdate", nil)
                    local frame = GetMouseFrame()
                    if frame then
                        txt:SetText("Захвачено: " .. NameOf(frame))
                        callback(frame)
                    else
                        txt:SetText("Фрейм не найден!")
                    end
                    C_Timer.After(1.5, function() if countdownFrame == f then f:Hide() end end)
                end
            end
        end)
        countdownTicker = ticker
    end

    -- ========================================================================
    -- Главное окно
    -- ========================================================================
    local mainFrame

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesMoveFrame", UIParent)
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
        f:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self:StartMoving() end end)
        f:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() end end)
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Перемещение (" .. UnitName("player") .. ")")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetSize(24, 24)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesMove_OpenSettings() end)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(160, 22)
        addBtn:SetPoint("TOPLEFT", 20, -45)
        addBtn:SetText("Добавить фрейм")
        addBtn:SetScript("OnClick", function() StartCountdown(function(frame) StartMoveForFrame(frame) end) end)

        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetSize(140, 22)
        resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        resetBtn:SetText("Сбросить всё")
        resetBtn:SetScript("OnClick", function() ResetAll() end)

        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesMoveScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -80)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)

        local child = CreateFrame("Frame", "NSQC4FramesMoveList", scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        
        f.scroll = scroll
        f.list = child

        mainFrame = f
        return f
    end

    function NSQC4.FramesMove_RefreshList()
        local f = mainFrame
        if not f or not f.list then return end
        local child, scroll = f.list, f.scroll

        for _, c in ipairs({ child:GetChildren() }) do c:Hide() end

        local keys = {}
        for k in pairs(db.frames) do table.insert(keys, k) end
        table.sort(keys)

        local ENTRY_H = 26
        child:SetHeight(math.max(#keys * ENTRY_H, 10))

        for i, key in ipairs(keys) do
            local data = db.frames[key]
            local frame = GetFrameByKey(key)
            local display = frame and NameOf(frame) or key

            local row = CreateFrame("Frame", nil, child)
            row:SetWidth(400)
            row:SetHeight(ENTRY_H)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
            row:EnableMouse(true)

            local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            nameLbl:SetPoint("LEFT", 5, 0)
            nameLbl:SetWidth(260)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetText(display)

            local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            xBtn:SetSize(24, 22)
            xBtn:SetPoint("RIGHT", -5, 0)
            xBtn:SetText("X")
            xBtn:SetScript("OnClick", function() ResetFrameByKey(key) end)

            local moveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            moveBtn:SetSize(60, 22)
            moveBtn:SetPoint("RIGHT", xBtn, "LEFT", -5, 0)
            moveBtn:SetText("Двигать")
            moveBtn:SetScript("OnClick", function() if frame then StartMoveForFrame(frame) end end)

            local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            upBtn:SetSize(24, 22)
            upBtn:SetPoint("RIGHT", moveBtn, "LEFT", -5, 0)
            upBtn:SetText("^")
            upBtn:SetScript("OnClick", function()
                local base = frame or GetFrameByKey(key)
                local parent = base and base.GetParent and base:GetParent()
                if not parent or parent == UIParent or parent == WorldFrame then
                    print("|cFFFFFF00NSQC4:|r у объекта нет подходящего родителя.")
                    return
                end
                local pkey = GetObjectKey(parent)
                if not pkey then
                    print("|cFFFFFF00NSQC4:|r родитель без имени — не сохранить.")
                    return
                end
                db.frames[pkey] = db.frames[pkey] or {}
                local pdata = db.frames[pkey]
                if not pdata.defaultGeometry then
                    pdata.defaultGeometry = CaptureGeometry(parent)
                end
                print("|cFF00FF00NSQC4:|r родитель добавлен: " .. NameOf(parent))
                StartMoveForFrame(parent)
                NSQC4.FramesMove_RefreshList()
            end)

            row:SetScript("OnEnter", function()
                nameLbl:SetTextColor(1, 1, 0)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText("Объект: " .. key, 1, 1, 1)
                if data and data.geometry then
                    GameTooltip:AddLine("Сохранено: " .. FormatGeometry(data.geometry), 0, 1, 0)
                end
                if data and data.defaultGeometry then
                    GameTooltip:AddLine("По умолчанию: " .. FormatGeometry(data.defaultGeometry), 0.7, 0.7, 1)
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
    -- Настройки
    -- ========================================================================
    local settingsFrame

    function NSQC4.FramesMove_OpenSettings()
        if settingsFrame then
            settingsFrame:Raise()
            settingsFrame:Show()
            return
        end

        local f = CreateFrame("Frame", "NSQC4FramesMoveSettings", UIParent)
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
        f:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self:StartMoving() end end)
        f:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self:StopMovingOrSizing() end end)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Настройки: Перемещение")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 20, -50)
        lbl:SetText("Время до применения: " .. (db.captureDelay or 5) .. " сек")

        local slider = CreateFrame("Slider", "NSQC4MoveSettingsSlider", f, "OptionsSliderTemplate")
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
    -- Диспетчер команд и кнопка на панели
    -- ========================================================================
    NSQC4._FramesMoveDispatch = function(msg)
        msg = (msg or ""):lower()

        if msg == "debug" or msg == "verify" or msg == "list" then
            ReportAll()
        elseif msg == "apply" or msg == "applynow" then
            ApplyAllSaved()
            print("|cFF00FF00NSQC4:|r позиции применены.")
        elseif msg == "on" then
            debugEnabled = true
            print("|cFF00FF00NSQC4:|r отладка включена.")
        elseif msg == "off" then
            debugEnabled = false
            print("|cFF00FF00NSQC4:|r отладка выключена.")
        else
            local f = CreateMainFrame()
            if f:IsShown() then f:Hide() else
                f:Raise()
                f:Show()
                NSQC4.FramesMove_RefreshList()
            end
        end
    end

    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("M", "/ns_fcmove", "Перемещение фреймов", function()
            SlashCmdList["NS_FCMOVE"]("")
        end)
    end

    -- ========================================================================
    -- Восстановление при входе
    -- ========================================================================
    local function DelayedApply(seconds)
        C_Timer.After(seconds, function() ApplyAllSaved() end)
    end

    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    restoreFrame:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent(event)
        ApplyAllSaved()
        DelayedApply(0.5)
        DelayedApply(2)
        DelayedApply(5)
    end)

    local scaleWatch = CreateFrame("Frame")
    scaleWatch:RegisterEvent("UI_SCALE_CHANGED")
    scaleWatch:RegisterEvent("DISPLAY_SIZE_CHANGED")
    scaleWatch:SetScript("OnEvent", function() DelayedApply(1) end)

    NSQC4.SetModuleMeta("ui_frames_move", {
        label   = "Перемещение",
        tooltip = "Перемещение любых фреймов. /ns_fcmove.",
        order   = 300,
    })
end)