NSQC4.RegisterModule("gp", function()

-- ============================================================================
-- NS Auction System v5.9 - RELEASE (FINAL 3.3.5a COMPATIBLE) - ИСПРАВЛЕНО
-- Для WoW 3.3.5a. Чтение ставок/паса из рейд-чата, адаптивная верстка, GP-расчет, быстрые ставки, тултипы.
-- Исправлено: отправка ГП через аддон-сообщения при старте и ставках
-- ============================================================================

local NSAuk = {}
local auctionFrame = nil
local minimapIcon = nil
local historyWindow = nil
local settingsWindow = nil
local closeTimerFrame = nil
local resizeAnimation = nil
local checkFrame = CreateFrame("Frame")
checkFrame.elapsed = 0
checkFrame:SetScript("OnUpdate", nil)
local scrollFrameID = 0
local isMinimized = false

local CLASS_COLORS = {
    WARRIOR     = {r = 0.78, g = 0.61, b = 0.43, hex = "|cffC79C6E"},
    PALADIN     = {r = 0.96, g = 0.55, b = 0.73, hex = "|cffF58CBA"},
    HUNTER      = {r = 0.67, g = 0.83, b = 0.45, hex = "|cffABD473"},
    ROGUE       = {r = 1.00, g = 0.96, b = 0.41, hex = "|cffFFF569"},
    PRIEST      = {r = 1.00, g = 1.00, b = 1.00, hex = "|cffFFFFFF"},
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23, hex = "|cffC41F3B"},
    SHAMAN      = {r = 0.00, g = 0.44, b = 0.87, hex = "|cff0070DE"},
    MAGE        = {r = 0.41, g = 0.80, b = 0.94, hex = "|cff69CCF0"},
    WARLOCK     = {r = 0.58, g = 0.51, b = 0.79, hex = "|cff9482C9"},
    DRUID       = {r = 1.00, g = 0.49, b = 0.04, hex = "|cffFF7D0A"},
}

-- ============================================================================
-- БАЗОВЫЕ УТИЛИТЫ
-- ============================================================================

function NSAuk.EnsureDB()
    if not nsDbc4 then nsDbc4 = {} end
    if not nsDbc4["аук"] then nsDbc4["аук"] = {} end
    local db = nsDbc4["аук"]
    if not db.history then db.history = {} end
    if not db.iconPosition then db.iconPosition = {x = 0, y = 0} end
    if not db.windowPosition then db.windowPosition = {x = 0, y = 0, point = "CENTER", relativePoint = "CENTER"} end
    if not db.historyPosition then db.historyPosition = {x = 0, y = 0, point = "CENTER", relativePoint = "CENTER"} end
    if not db.settings then db.settings = {defaultStep = 10, defaultTime = 20} end
    
    -- Явная инициализация состояния чекбокса. nil приводится к true по умолчанию.
    if db.settings.autoDeductGP == nil then db.settings.autoDeductGP = true end
    db.settings.autoDeductGP = (db.settings.autoDeductGP == true)
    
    if not db.customButtons then db.customButtons = {} end
    if db.active == nil then db.active = nil end
    return db
end

-- Функция отправки своих ГП в рейд
function NSAuk.BroadcastMyGP()
    local db = NSAuk.EnsureDB()
    if not db.active then return end
    
    local myName = UnitName("player")
    local myBid = db.active.bids[myName]
    if not myBid then return end
    
    -- Получаем актуальные ГП
    local myGP = myBid.gp or 0
    
    -- Если ГП = 0, пробуем получить из других источников
    if myGP == 0 then
        -- Из внешнего кэша
        if gpDb and gpDb.external_gp_cache and gpDb.external_gp_cache[myName] then
            myGP = tonumber(gpDb.external_gp_cache[myName]) or 0
        end
        
        -- Из офицерской заметки (для игроков в гильдии)
        if myGP == 0 then
            for j = 1, GetNumGuildMembers(true) do
                local gName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(j)
                if gName == myName and officerNote and officerNote ~= "" then
                    local z = NSAuk.mysplit(officerNote)
                    myGP = tonumber(z[3]) or 0
                    break
                end
            end
        end
    end
    
    -- Отправляем свои ГП всем в рейде
    local _, myClass = UnitClass("player")
    local publicNote = ""
    for j = 1, GetNumGuildMembers(true) do
        local gName, _, _, _, _, _, pubNote = GetGuildRosterInfo(j)
        if gName == myName then
            publicNote = pubNote or ""
            break
        end
    end
    
    SendAddonMessage("AUC_GP", myName .. ":" .. myGP .. ":" .. (myClass or "WARRIOR") .. ":" .. publicNote, "RAID")
    
    -- Обновляем свои данные в bids
    if myBid then
        myBid.gp = myGP
        myBid.class = myClass or "WARRIOR"
        myBid.public = publicNote
    end
end

function NSAuk.mysplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
    return t
end

function NSAuk.ClampFrameToScreen(frame)
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    local fw, fh = frame:GetWidth(), frame:GetHeight()
    local x, y = frame:GetCenter()
    if not x or not y then return end
    x = math.max(fw / 2, math.min(sw - fw / 2, x))
    y = math.max(fh / 2, math.min(sh - fh / 2, y))
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

function NSAuk.SaveWindowPosition(frame, posTable)
    if not frame or not posTable then return false end
    local point, _, relativePoint, x, y = frame:GetPoint()
    if point and x and y then
        posTable.x = math.floor(x)
        posTable.y = math.floor(y)
        posTable.point = point
        posTable.relativePoint = relativePoint or "CENTER"
        return true
    end
    return false
end

function NSAuk.SmoothResize(frame, targetW, targetH, duration)
    if resizeAnimation then resizeAnimation:SetScript("OnUpdate", nil); resizeAnimation = nil end
    local startW, startH, startTime = frame:GetWidth(), frame:GetHeight(), GetTime()
    resizeAnimation = CreateFrame("Frame")
    resizeAnimation:SetScript("OnUpdate", function(self)
        local t = (GetTime() - startTime) / (duration or 0.15)
        if t >= 1 then
            frame:SetSize(targetW, targetH)
            self:SetScript("OnUpdate", nil)
            resizeAnimation = nil
        else
            local ease = t * t * (3 - 2 * t)
            frame:SetSize(startW + (targetW - startW) * ease, startH + (targetH - startH) * ease)
        end
    end)
end

function NSAuk.ParseAuctionCommand(msg)
    local clean = msg:gsub("^%s+", ""):gsub("%s+$", "")
    local res = { item = "Предмет", itemLink = nil, step = nil, closeTime = nil }
    if not clean:match("^АУК") then return res end
    local rest = clean:gsub("^АУК%s*", "")

    local linkFull = rest:match("|.-|h.-|h|r")
    if linkFull then
        res.itemLink = linkFull
    end

    local sm = rest:match("%s+шаг%s+(%d+)%s*$") or rest:match("%s+шаг%s+(%d+)")
    if sm then
        res.step = tonumber(sm)
        rest = rest:gsub("%s+шаг%s+" .. sm .. "%s*$", ""):gsub("%s+шаг%s+" .. sm, "")
    end
    local tm = rest:match("%s+время%s+(%d+)%s*$") or rest:match("%s+время%s+(%d+)")
    if tm then
        res.closeTime = tonumber(tm)
        rest = rest:gsub("%s+время%s+" .. tm .. "%s*$", ""):gsub("%s+время%s+" .. tm, "")
    end

    local itemName = rest:match("^%s*(.-)%s*$")
    if itemName and itemName ~= "" then
        res.item = itemName:gsub("|.-|h(.-)|h|r", "%1"):gsub("|.-|h", "")
    end
    return res
end

function NSAuk.GetRaidGPData()
    local gpData = {}
    local numRaid = GetNumRaidMembers()
    if numRaid == 0 then return gpData end
    for i = 1, numRaid do
        local name = UnitName("raid"..i)
        if name then
            gpData[name] = { gp = 0, class = "WARRIOR", public = "", rank = "", inGuild = false }
            local _, class = UnitClass("raid"..i)
            if class then gpData[name].class = class end
            for j = 1, GetNumGuildMembers(true) do
                local gName, rankName, _, _, _, _, publicNote, officerNote = GetGuildRosterInfo(j)
                if gName == name then
                    gpData[name].inGuild = true
                    gpData[name].rank = rankName or ""
                    gpData[name].public = publicNote or ""
                    if officerNote and officerNote ~= "" then
                        local z = NSAuk.mysplit(officerNote)
                        gpData[name].gp = tonumber(z[3]) or 0
                    end
                    break
                end
            end
            if not gpData[name].inGuild then
                gpData[name].public = "НЕ В ГИЛЬДИИ"
                if gpDb and gpDb.external_gp_cache and gpDb.external_gp_cache[name] then
                    gpData[name].gp = tonumber(gpDb.external_gp_cache[name]) or 0
                end
            end
        end
    end
    return gpData
end

-- ============================================================================
-- ИНТЕРФЕЙС И UI
-- ============================================================================

function NSAuk.ShowConfirm(title, text, onYes, onNo)
    if NSAuk.confirmFrame and NSAuk.confirmFrame:IsShown() then NSAuk.confirmFrame:Hide() end
    
    local f = CreateFrame("Frame", "NSAukConfirm", UIParent)
    f:SetSize(280, 110)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOP", 0, -15)
    t:SetText(title)

    local tx = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tx:SetPoint("TOP", t, "BOTTOM", 0, -8)
    tx:SetText(text)
    tx:SetWidth(240)
    tx:SetJustifyH("CENTER")

    local btnY = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnY:SetSize(80, 22)
    btnY:SetPoint("BOTTOMRIGHT", -15, 15)
    btnY:SetText("Да")
    btnY:SetScript("OnClick", function() if onYes then onYes() end f:Hide() end)

    local btnN = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnN:SetSize(80, 22)
    btnN:SetPoint("BOTTOMLEFT", 15, 15)
    btnN:SetText("Нет")
    btnN:SetScript("OnClick", function() if onNo then onNo() end f:Hide() end)

    NSAuk.confirmFrame = f
    f:Show()
end

function NSAuk.RenderCustomButtons()
    local frame = auctionFrame
    if not frame or not frame.customButtonBar then return end
    local bar = frame.customButtonBar
    
    -- Очистка старых кнопок
    for _, btn in ipairs(bar.buttons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    bar.buttons = {}

    local db = NSAuk.EnsureDB()
    local btns = db.customButtons
    if #btns == 0 then
        bar:SetHeight(0)
        return
    end

    local btnW = 60
    local gap = 6
    local totalW = 0
    for i, val in ipairs(btns) do
        local b = CreateFrame("Button", "NSAukQuickBid_" .. i, bar, "UIPanelButtonTemplate")
        b:SetSize(btnW, 22)
        b:SetPoint("LEFT", totalW, 0)
        b:SetText(tostring(val) .. " GP")
        b:SetScript("OnClick", function()
            local d = NSAuk.EnsureDB()
            if not d.active then return end
            
            local myName = UnitName("player")
            local myBid = d.active.bids[myName]
            if not myBid or myBid.banned then
                print("|cffff0000[NSAuk]|r Вы забанены в этом аукционе.")
                return
            end
            
            -- Проверка ГП перед ставкой
            if (myBid.gp or 0) < val then
                print("|cffff0000[NSAuk]|r Недостаточно ГП для ставки " .. val .. ". У вас: " .. (myBid.gp or 0))
                return
            end
            
            -- Проверка на лидерство
            local mx = 0
            for _, v in pairs(d.active.bids) do
                if v.hasAction and not v.passed and v.amount > mx then
                    mx = v.amount
                end
            end
            if (myBid.amount or 0) == mx and mx > 0 then
                print("|cffff0000[NSAuk]|r Вы уже лидер. Нельзя перебить свою ставку.")
                return
            end
            
            -- Отправляем свои ГП перед ставкой
            NSAuk.BroadcastMyGP()
            SendChatMessage(tostring(val), "RAID")
        end)
        bar.buttons[i] = b
        totalW = totalW + btnW + gap
    end
    
    bar:SetWidth(totalW - gap)
    bar:SetHeight(25)
end

function NSAuk.CreateAuctionFrame()
    if auctionFrame then NSAuk.DestroyAuctionWindow() end

    auctionFrame = CreateFrame("Frame", "NSAukAuctionFrame", UIParent)
    local frame = auctionFrame
    frame:SetSize(350, 250)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\White8x8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 8, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    local db = NSAuk.EnsureDB()
    local pos = db.windowPosition
    if pos and pos.x and pos.y then
        frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x, pos.y)
    else
        frame:SetPoint("CENTER")
    end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        NSAuk.ClampFrameToScreen(self)
        NSAuk.SaveWindowPosition(self, db.windowPosition)
        if self.customPanel then
            self.customPanel:ClearAllPoints()
            self.customPanel:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
        end
    end)

    frame:SetScript("OnHide", function(self)
        if self.autoDeductCB then
            db.settings.autoDeductGP = (self.autoDeductCB:GetChecked() == 1)
        end
        NSAuk.SaveWindowPosition(self, db.windowPosition)
        if self.customPanel then self.customPanel:Hide() end
    end)

    -- === ПАНЕЛЬ БЫСТРЫХ СТАВОК ===
    local customPanel = CreateFrame("Frame", "NSAukBidPanel", UIParent)
    customPanel:SetSize(118, 26)
    customPanel:SetPoint("TOPRIGHT", frame, "TOPLEFT", -5, 0)
    customPanel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    customPanel:SetBackdropColor(0, 0, 0, 0.8)
    customPanel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
    customPanel:Hide()
    customPanel.isExpanded = false
    frame.customPanel = customPanel

    local cpEdit = CreateFrame("EditBox", "NSAukBidInput", customPanel, "InputBoxTemplate")
    cpEdit:SetSize(50, 20)
    cpEdit:SetPoint("LEFT", 5, 0)
    cpEdit:SetAutoFocus(false)
    cpEdit:SetMaxLetters(4)
    cpEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    cpEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local cpAdd = CreateFrame("Button", "NSAukBtnAdd", customPanel, "UIPanelButtonTemplate")
    cpAdd:SetSize(20, 20)
    cpAdd:SetPoint("LEFT", cpEdit, "RIGHT", 2, 0)
    cpAdd:SetText("+")
    cpAdd:SetScript("OnClick", function()
        local val = tonumber(cpEdit:GetText())
        if val and val > 0 then
            local db = NSAuk.EnsureDB()
            if #db.customButtons < 8 and not tContains(db.customButtons, val) then
                table.insert(db.customButtons, val)
                table.sort(db.customButtons)
                NSAuk.RenderCustomButtons()
                print("|cff00ff00[NSAuk]|r Кнопка " .. val .. " ГП добавлена.")
            end
            cpEdit:SetText("")
        end
    end)

    local cpRem = CreateFrame("Button", "NSAukBtnRem", customPanel, "UIPanelButtonTemplate")
    cpRem:SetSize(20, 20)
    cpRem:SetPoint("LEFT", cpAdd, "RIGHT", 2, 0)
    cpRem:SetText("-")
    cpRem:SetScript("OnClick", function()
        local val = tonumber(cpEdit:GetText())
        if not val or val <= 0 then print("|cffFF8080[NSAuk]|r Введите число для удаления."); return end
        local db = NSAuk.EnsureDB()
        for i, btnVal in ipairs(db.customButtons) do
            if btnVal == val then
                table.remove(db.customButtons, i)
                NSAuk.RenderCustomButtons()
                print("|cff00ff00[NSAuk]|r Кнопка " .. val .. " ГП удалена.")
                cpEdit:SetText("")
                return
            end
        end
        print("|cffFF8080[NSAuk]|r Кнопка " .. val .. " ГП не найдена.")
    end)

    local panelTitle = customPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panelTitle:SetPoint("BOTTOMLEFT", customPanel, "TOPLEFT", 5, 2)
    panelTitle:SetText("Быстрые ставки")
    panelTitle:SetTextColor(1, 0.82, 0)

    local togglePanelBtn = CreateFrame("Button", "NSAukTogglePanel", frame)
    togglePanelBtn:SetSize(24, 24)
    togglePanelBtn:SetPoint("TOPLEFT", 5, -5)
    local toggleTex = togglePanelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggleTex:SetPoint("CENTER")
    toggleTex:SetText(">")
    togglePanelBtn:SetScript("OnClick", function()
        frame.customPanel.isExpanded = not frame.customPanel.isExpanded
        toggleTex:SetText(frame.customPanel.isExpanded and "v" or ">")
        if frame.customPanel.isExpanded then frame.customPanel:Show() else frame.customPanel:Hide() end
    end)

    -- Чекбокс
    local autoDeductCB = CreateFrame("CheckButton", "NSAukAutoDeductCB", frame, "UICheckButtonTemplate")
    autoDeductCB:SetPoint("LEFT", togglePanelBtn, "RIGHT", 8, 0)
    autoDeductCB:SetChecked(db.settings.autoDeductGP == true)
    if autoDeductCB.Text then
        autoDeductCB.Text:SetText("Авто-списание ГП")
        autoDeductCB.Text:SetFontObject(GameFontNormalSmall)
    end
    autoDeductCB:SetScript("OnClick", function(self)
        local isChecked = (self:GetChecked() == 1)
        db.settings.autoDeductGP = isChecked
        print("|cff00FF00[NSAuk]|r Авто-списание: " .. (isChecked and "ВКЛ" or "ВЫКЛ"))
    end)
    autoDeductCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Автоматическое списание ГП", 1, 0.8, 0)
        GameTooltip:AddLine("При завершении аукциона аддон автоматически спишет ГП с победителя.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    autoDeductCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.autoDeductCB = autoDeductCB

    -- Кнопка закрытия (крестик)
    local closeBtn = CreateFrame("Button", "NSAukCloseBtn", frame, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        local d = NSAuk.EnsureDB()
        if not d.active then
            frame:Hide()
            return
        end

        local isStarter = (d.active.startedBy == UnitName("player"))

        if isStarter then
            SendAddonMessage("AUC_CANCEL", "", "RAID")
        end

        if closeTimerFrame then
            closeTimerFrame:SetScript("OnUpdate", nil)
            closeTimerFrame = nil
        end

        d.active = nil
        isMinimized = false

        NSAuk.DestroyAuctionWindow()
        if minimapIcon then minimapIcon:Hide() end
        checkFrame:SetScript("OnUpdate", nil)

        print("|cff00ff00[NSAuk]|r Аукцион закрыт.")
    end)
    closeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Закрыть аукцион", 1, 0.82, 0)
        GameTooltip:AddLine("Полностью закрывает окно и сбрасывает данные аукциона.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.closeBtn = closeBtn

    local helpBtn = CreateFrame("Button", "NSAukHelpBtn", frame)
    helpBtn:SetSize(24, 24)
    helpBtn:SetPoint("TOPRIGHT", -28, -5)
    helpBtn:RegisterForClicks("AnyUp")
    local helpText = helpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("CENTER", 0, 1)
    helpText:SetText("?")
    helpBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffFFD100NS Auction System v5.9|r", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffff00=== КОМАНДЫ ===|r", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00/nsauk|r - настройки", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00/nsauk reset|r - сброс", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff00ff00/nsauk find|r - подсветка окон", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local minBtn = CreateFrame("Button", "NSAukMinBtn", frame)
    minBtn:SetSize(24, 24)
    minBtn:SetPoint("TOPRIGHT", helpBtn, "TOPLEFT", -2, 0)
    minBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    minBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    minBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    minBtn:SetScript("OnClick", function()
        isMinimized = true; frame:Hide(); if frame.customPanel then frame.customPanel:Hide() end
        if not minimapIcon then NSAuk.CreateMinimapIcon() end; minimapIcon:Show()
    end)

    frame.itemTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.itemTitle:SetPoint("TOPLEFT", 10, -30)
    frame.itemTitle:SetPoint("TOPRIGHT", -60, -30)
    frame.itemTitle:SetJustifyH("LEFT")
    frame.itemTitle:SetText(db.active and db.active.item or "Предмет")
    if db.active and db.active.itemLink then
        local hex = db.active.itemLink:match("|cff(%x%x%x%x%x%x)")
        if hex then
            frame.itemTitle:SetTextColor(tonumber(hex:sub(1,2), 16)/255, tonumber(hex:sub(3,4), 16)/255, tonumber(hex:sub(5,6), 16)/255)
        end
    end

    local titleMouseFrame = CreateFrame("Frame", "NSAukTitleMouse", frame)
    titleMouseFrame:SetAllPoints(frame.itemTitle)
    titleMouseFrame:EnableMouse(true)
    titleMouseFrame:SetScript("OnEnter", function()
        local d = NSAuk.EnsureDB()
        if not d.active then return end
        GameTooltip:SetOwner(titleMouseFrame, "ANCHOR_TOPRIGHT")
        GameTooltip:ClearLines()
        if d.active.itemLink and d.active.itemLink:match("item:") then GameTooltip:SetHyperlink(d.active.itemLink)
        else GameTooltip:SetText(d.active.item, 1, 1, 1); GameTooltip:AddLine("|cff808080(Shift-кликните предмет при запуске.)|r", 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    titleMouseFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.infoText:SetPoint("TOPLEFT", 10, -50)

    frame.countdownText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.countdownText:SetPoint("TOPRIGHT", -10, -50)
    frame.countdownText:SetJustifyH("RIGHT")
    frame.countdownText:SetText("0с")

    frame.leaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.leaderText:SetPoint("BOTTOMLEFT", 10, 35)

    frame.nextBidText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nextBidText:SetPoint("BOTTOMLEFT", 10, 15)

    local div = frame:CreateTexture(nil, "OVERLAY")
    div:SetTexture(0.5, 0.5, 0.5, 0.5)
    div:SetSize(frame:GetWidth() - 20, 1)
    div:SetPoint("TOPLEFT", 10, -60)
    div:SetPoint("TOPRIGHT", -10, -60)

    scrollFrameID = scrollFrameID + 1
    local sf = CreateFrame("ScrollFrame", "NSAukScrollFrame" .. scrollFrameID, frame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -65)
    sf:SetPoint("BOTTOMRIGHT", -25, 55)
    local content = CreateFrame("Frame", "NSAukScrollContent" .. scrollFrameID, sf)
    content:SetSize(300, 100)
    sf:SetScrollChild(content)
    frame.content = content
    content.rows = {}

    local passBtn = CreateFrame("Button", "NSAukPassBtn", frame, "UIPanelButtonTemplate")
    passBtn:SetSize(80, 22)
    passBtn:SetPoint("BOTTOMRIGHT", -90, 10)
    passBtn:SetText("Пас")
    passBtn:SetScript("OnClick", function()
        local d = NSAuk.EnsureDB()
        if not d.active then return end
        local myName = UnitName("player")
        local myBid = d.active.bids[myName]
        if myBid and myBid.passed then return end

        local maxAmount = 0
        for _, b in pairs(d.active.bids) do if b.hasAction and not b.passed and b.amount > maxAmount then maxAmount = b.amount end end
        if myBid and myBid.hasAction and not myBid.passed and myBid.amount >= maxAmount and myBid.amount > 0 then
            print("Нельзя выйти из торгов, пока вы лидируете.")
            return
        end

        NSAuk.BroadcastMyGP()
        SendAddonMessage("AUC_PASS", "", "RAID")
        if myBid then myBid.passed = true; myBid.amount = 0; myBid.hasAction = true end
        NSAuk.UpdateAuctionWindow()
    end)

    local bidBtn = CreateFrame("Button", "NSAukBidBtn", frame, "UIPanelButtonTemplate")
    bidBtn:SetSize(80, 22)
    bidBtn:SetPoint("BOTTOMRIGHT", -5, 10)
    bidBtn:SetText("Ставка")
    bidBtn:SetScript("OnClick", function()
        local d = NSAuk.EnsureDB()
        if d.active then
            local me = UnitName("player")
            local myBid = d.active.bids[me] or {amount=0, gp=0}
            local mx = 0
            for _, v in pairs(d.active.bids) do
                if v.hasAction and not v.passed and v.amount > mx then mx = v.amount end
            end
            if mx + d.active.step > (myBid.gp or 0) then
                print("|cffff0000[NSAuk]|r Недостаточно ГП! Ваша ставка превысит доступный баланс.")
                return
            end
            if (myBid.amount or 0) == mx and mx > 0 then print("Вы лидер"); return end

            NSAuk.BroadcastMyGP()
            SendChatMessage(tostring(mx + d.active.step), "RAID")
        end
    end)

    local cbar = CreateFrame("Frame", "NSAukCustomBar", frame)
    cbar:SetSize(300, 25)
    cbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, -35)
    cbar.buttons = {}
    frame.customButtonBar = cbar

    NSAuk.RenderCustomButtons()
    frame:Show()
    frame:Raise()
    return frame
end

function NSAuk.DestroyAuctionWindow()
    if auctionFrame then 
        auctionFrame:Hide()
        if auctionFrame.customPanel then
            auctionFrame.customPanel:Hide()
            auctionFrame.customPanel:SetParent(nil)
            auctionFrame.customPanel = nil
        end
        auctionFrame:SetParent(nil)
        auctionFrame = nil 
    end
    if resizeAnimation then 
        resizeAnimation:SetScript("OnUpdate", nil)
        resizeAnimation = nil 
    end
end

function NSAuk.CreateMinimapIcon()
    if minimapIcon then return minimapIcon end
    local db = NSAuk.EnsureDB()
    minimapIcon = CreateFrame("Button", "NSAukMinimapAuctionIcon", UIParent)
    minimapIcon:SetSize(32, 32)
    minimapIcon:SetPoint("CENTER", Minimap, "CENTER", db.iconPosition.x, db.iconPosition.y)
    minimapIcon:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_01")
    minimapIcon:SetMovable(true)
    minimapIcon:EnableMouse(true)
    minimapIcon:RegisterForDrag("LeftButton")
    minimapIcon:SetScript("OnDragStart", function(self) self:StartMoving() end)
    minimapIcon:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _,_,_,x,y = self:GetPoint()
        local d = NSAuk.EnsureDB()
        d.iconPosition.x = x
        d.iconPosition.y = y
    end)
    minimapIcon:SetScript("OnClick", function()
        isMinimized = false
        minimapIcon:Hide()
        NSAuk.UpdateAuctionWindow()
    end)
    minimapIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local d = NSAuk.EnsureDB()
        if d.active then GameTooltip:SetText("Аукцион: "..d.active.item) else GameTooltip:SetText("Аукцион не активен") end
        GameTooltip:Show()
    end)
    minimapIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapIcon:Hide()
    return minimapIcon
end

function NSAuk.CreateHistoryWindow(historyIndex)
    local db = NSAuk.EnsureDB()
    if historyWindow then NSAuk.SaveWindowPosition(historyWindow, db.historyPosition); historyWindow:Hide(); historyWindow:SetParent(nil); historyWindow = nil end
    if #db.history == 0 then print("История пуста"); return end
    local entry = historyIndex and db.history[historyIndex] or db.history[#db.history]
    if not entry then print("Запись не найдена"); return end

    historyWindow = CreateFrame("Frame", "NSAukHistoryWindow", UIParent)
    historyWindow:SetSize(350, 250)
    historyWindow:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    historyWindow:SetBackdropColor(0,0,0,0.9)
    historyWindow:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
    historyWindow:SetMovable(true)
    historyWindow:EnableMouse(true)
    historyWindow:RegisterForDrag("LeftButton")

    local pos = db.historyPosition
    if pos and pos.x and pos.y then
        historyWindow:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x, pos.y)
    else historyWindow:SetPoint("CENTER") end

    historyWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    historyWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        NSAuk.ClampFrameToScreen(self)
        NSAuk.SaveWindowPosition(self, NSAuk.EnsureDB().historyPosition)
    end)
    historyWindow:SetScript("OnHide", function(self) NSAuk.SaveWindowPosition(self, NSAuk.EnsureDB().historyPosition) end)

    local cb = CreateFrame("Button", nil, historyWindow, "UIPanelCloseButton")
    cb:SetPoint("TOPRIGHT", -5, -5)
    cb:SetScript("OnClick", function() NSAuk.SaveWindowPosition(historyWindow, NSAuk.EnsureDB().historyPosition); historyWindow:Hide(); historyWindow:SetParent(nil); historyWindow = nil end)

    local t = historyWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 10, -15)
    t:SetPoint("TOPRIGHT", -30, -15)
    t:SetText("История: "..entry.item)

    local wt = historyWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wt:SetPoint("TOPLEFT", 10, -35)
    wt:SetText("Победитель: "..(entry.winner or "???").." | Ставка: "..(entry.winAmount or 0).." GP")

    scrollFrameID = scrollFrameID + 1
    local sf = CreateFrame("ScrollFrame", "NSAukHistoryScrollFrame"..scrollFrameID, historyWindow, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 10, -55)
    sf:SetPoint("BOTTOMRIGHT", -25, 10)
    local c = CreateFrame("Frame", nil, sf)
    c:SetSize(300, 20)
    sf:SetScrollChild(c)
    local sb = {}
    for n, d in pairs(entry.bids or {}) do if d.hasAction then table.insert(sb, {name=n, data=d}) end end
    table.sort(sb, function(a,b) return a.data.amount > b.data.amount end)
    local th = 5
    for _, b in ipairs(sb) do
        local r = CreateFrame("Frame", nil, c)
        r:SetSize(c:GetWidth()-10, 20)
        r:SetPoint("TOPLEFT", 5, -th)
        local n1 = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        n1:SetPoint("LEFT",0,0)
        n1:SetText(b.name)
        local n2 = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        n2:SetPoint("RIGHT",0,0)
        n2:SetText(b.data.passed and "|cff808080ПАС|r" or (b.data.amount.." GP"))
        r:Show()
        th = th + 22
    end
    c:SetHeight(th+10)
    historyWindow:SetHeight(th+90)
    historyWindow:Show()
    return historyWindow
end

function NSAuk.CreateSettingsWindow()
    local db = NSAuk.EnsureDB()
    if settingsWindow then settingsWindow:Show(); return end
    settingsWindow = CreateFrame("Frame", "NSAukSettingsWindow", UIParent)
    settingsWindow:SetSize(250, 180)
    settingsWindow:SetPoint("CENTER")
    settingsWindow:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    settingsWindow:SetBackdropColor(0,0,0,0.9)
    settingsWindow:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
    settingsWindow:SetMovable(true)
    settingsWindow:EnableMouse(true)
    settingsWindow:RegisterForDrag("LeftButton")
    settingsWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsWindow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local cb = CreateFrame("Button", nil, settingsWindow, "UIPanelCloseButton")
    cb:SetPoint("TOPRIGHT", -5, -5)
    cb:SetScript("OnClick", function() settingsWindow:Hide() end)

    local t = settingsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOP", 0, -15)
    t:SetText("Настройки аукциона")

    local st = settingsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    st:SetPoint("TOPLEFT", 20, -50)
    st:SetText("Шаг по умолчанию:")
    local se = CreateFrame("EditBox", "se112", settingsWindow, "InputBoxTemplate")
    se:SetSize(60, 25)
    se:SetPoint("LEFT", st, "RIGHT", 10, 0)
    se:SetText(tostring(db.settings.defaultStep))
    se:SetAutoFocus(false)

    local tt = settingsWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tt:SetPoint("TOPLEFT", st, "BOTTOMLEFT", 0, -15)
    tt:SetText("Автозакрытие:")
    local te = CreateFrame("EditBox", "te112", settingsWindow, "InputBoxTemplate")
    te:SetSize(60, 25)
    te:SetPoint("LEFT", tt, "RIGHT", 10, 0)
    te:SetText(tostring(db.settings.defaultTime))
    te:SetAutoFocus(false)

    local sb = CreateFrame("Button", nil, settingsWindow, "UIPanelButtonTemplate")
    sb:SetSize(100, 25)
    sb:SetPoint("BOTTOM", 0, 20)
    sb:SetText("Сохранить")
    sb:SetScript("OnClick", function()
        local ns = tonumber(se:GetText())
        local nt = tonumber(te:GetText())
        if ns and ns > 0 then db.settings.defaultStep = ns end
        if nt and nt > 0 then db.settings.defaultTime = nt end
        print("Настройки сохранены")
        settingsWindow:Hide()
    end)
    return settingsWindow
end

-- ============================================================================
-- ЛОГИКА АУКЦИОНА
-- ============================================================================

local function AnnounceRaid(msg)
    local db = NSAuk.EnsureDB()
    if db.active and db.active.startedBy == UnitName("player") then
        SendChatMessage(msg, "RAID")
    end
end

function NSAuk.DeductGPFromRoster(playerName, amount)
    if not playerName or not amount or amount <= 0 then return end
    
    SendAddonMessage("nsGP1 -" .. amount, playerName, "guild")
    SendAddonMessage("nsGP1A -" .. amount, playerName, "guild")
    SendAddonMessage("nsGPlog", "Аукцион -" .. amount .. " " .. (playerName or ""), "guild")
    print(string.format("|cff00ff00[NSAuk]|r Отправлен запрос на списание %d ГП с %s.", amount, playerName))
end

function NSAuk.SetWinner(playerName, winAmount)
    local db = NSAuk.EnsureDB()
    if not db.active then return end
    
    if closeTimerFrame then 
        closeTimerFrame:SetScript("OnUpdate", nil)
        closeTimerFrame = nil 
    end
    
    -- Сохраняем ссылку на предмет ДО обнуления db.active, т.к. выдача лута может быть отложенной
    local winnerItemLink = db.active.itemLink
    
    -- Выдача лута через GiveMasterLoot (работает только если мы мастер-лутер и окно добычи открыто)
    NSAuk.GiveLootToWinnerDeferred(playerName, winnerItemLink)
    
    if db.active.startedBy == UnitName("player") then
        if db.settings.autoDeductGP and winAmount > 0 then
            NSAuk.DeductGPFromRoster(playerName, winAmount)
        else
            print(string.format("|cff00FF00[NSAuk]|r Аукцион завершён. Победитель: %s, сумма: %d ГП. (Списание %s).", 
                playerName, winAmount, db.settings.autoDeductGP and "выполнено" or "отключено"))
        end
    end
    
    local bc = {}
    for n, d in pairs(db.active.bids) do 
        bc[n] = { 
            amount = d.amount, 
            class = d.class, 
            public = d.public, 
            gp = d.gp, 
            passed = d.passed, 
            hasAction = d.hasAction 
        } 
    end
    table.insert(db.history, { 
        item = db.active.item, 
        itemLink = db.active.itemLink,
        endTime = GetTime(), 
        startedBy = db.active.startedBy, 
        winner = playerName, 
        winAmount = winAmount or 0, 
        bids = bc 
    })
    if #db.history > 10 then 
        table.remove(db.history, 1) 
    end
    
    if db.active.startedBy == UnitName("player") then
        SendChatMessage(playerName .. " побеждает, поставив " .. (winAmount or 0) .. " ГП. Предмет: " .. db.active.item, "RAID_WARNING")
    end
    
    SendAddonMessage("AUC_END", "", "RAID")
    
    db.active = nil
    isMinimized = false
    NSAuk.DestroyAuctionWindow()
    if minimapIcon then minimapIcon:Hide() end
    checkFrame:SetScript("OnUpdate", nil)
end

function NSAuk.FinishAuction(initiator)
    local db = NSAuk.EnsureDB()
    if not db.active then return end
    
    if closeTimerFrame then 
        closeTimerFrame:SetScript("OnUpdate", nil)
        closeTimerFrame = nil 
    end
    
    local w, wa = nil, 0
    for n, d in pairs(db.active.bids) do 
        if d.hasAction and not d.passed and not d.banned and d.amount > wa then 
            w, wa = n, d.amount 
        end 
    end
    
    if w and wa > 0 then
        local bc = {}
        for n, d in pairs(db.active.bids) do 
            bc[n] = { 
                amount = d.amount, 
                class = d.class, 
                public = d.public, 
                gp = d.gp, 
                passed = d.passed, 
                hasAction = d.hasAction 
            } 
        end
        table.insert(db.history, { 
            item = db.active.item, 
            itemLink = db.active.itemLink,
            endTime = GetTime(), 
            startedBy = db.active.startedBy, 
            winner = w, 
            winAmount = wa, 
            bids = bc 
        })
        if #db.history > 10 then 
            table.remove(db.history, 1) 
        end
    end
    
    db.active = nil
    isMinimized = false
    NSAuk.DestroyAuctionWindow()
    if minimapIcon then minimapIcon:Hide() end
    checkFrame:SetScript("OnUpdate", nil)
end

function NSAuk.StartCloseTimer()
    local db = NSAuk.EnsureDB()
    if not db.active then return end
    if closeTimerFrame then 
        closeTimerFrame:SetScript("OnUpdate", nil)
        closeTimerFrame = nil 
    end
    
    closeTimerFrame = CreateFrame("Frame")
    local lc = GetTime()
    local finished = false
    
    closeTimerFrame:SetScript("OnUpdate", function(self)
        local ct = GetTime()
        if ct - lc < 1 then return end
        lc = ct
        
        local d = NSAuk.EnsureDB()
        if not d.active then 
            self:SetScript("OnUpdate", nil)
            closeTimerFrame = nil 
            return 
        end
        
        if auctionFrame and auctionFrame.countdownText then
            local lastTime = d.active.lastBidTime or d.active.startTime
            local rem = math.max(0, math.floor(d.active.closeTime - (GetTime() - lastTime)))
            auctionFrame.countdownText:SetText(rem .. "с")
        end

        if d.active.startedBy ~= UnitName("player") then return end
        
        if GetTime() - (d.active.lastBidTime or d.active.startTime) >= d.active.closeTime then
            if finished then return end
            finished = true
            self:SetScript("OnUpdate", nil)
            closeTimerFrame = nil
            
            local w, wa = nil, 0
            for n, bidData in pairs(d.active.bids) do 
                if bidData.hasAction and not bidData.passed and not bidData.banned and bidData.amount > wa then 
                    w, wa = n, bidData.amount 
                end 
            end
            
            if w and wa > 0 then
                NSAuk.SetWinner(w, wa)
            else
                SendAddonMessage("AUC_END", "", "RAID")
                NSAuk.FinishAuction(d.active.startedBy)
            end
        end
    end)
end

function NSAuk.UpdateAuctionWindow()
    if isMinimized then return end
    local db = NSAuk.EnsureDB()
    if not db.active then return end
    local frame = NSAuk.CreateAuctionFrame()
    local content = frame.content
    if not content then return end

    if content.rows then
        for _, c in ipairs(content.rows) do if c then c:Hide(); c:SetParent(nil) end end
    end
    content.rows = {}

    frame.itemTitle:SetText(db.active.item or "Предмет")
    
    local lastTime = db.active.lastBidTime or db.active.startTime
    local remaining = math.max(0, math.floor(db.active.closeTime - (GetTime() - lastTime)))
    frame.infoText:SetText("Шаг: " .. db.active.step .. " GP | Осталось:")
    if frame.countdownText then frame.countdownText:SetText(remaining .. "с") end

    local sortedBids = {}
    for name, data in pairs(db.active.bids) do
        if data.hasAction then table.insert(sortedBids, {name = name, data = data}) end
    end
    
    table.sort(sortedBids, function(a, b)
        if a.data.passed and not b.data.passed then return false end
        if not a.data.passed and b.data.passed then return true end
        return a.data.amount > b.data.amount
    end)

    local totalHeight = 5
    local rowHeight = 22
    local maxRowWidth = 280
    local myName = UnitName("player")
    local isRL = (db.active.startedBy == myName)

    for i, bid in ipairs(sortedBids) do
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", 10, -totalHeight)
        row:SetPoint("TOPRIGHT", -10, -totalHeight)
        row:EnableMouse(true)

        local cc = CLASS_COLORS[bid.data.class] or CLASS_COLORS.WARRIOR
        local isPassed = bid.data.passed
        local isBanned = bid.data.banned == true

        local nt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nt:SetPoint("LEFT", 5, 0)
        local dn = bid.name
        if bid.data.public and bid.data.public ~= "" and bid.data.public ~= "НЕ В ГИЛЬДИИ" then dn = dn .. " (" .. bid.data.public .. ")" end
        local nameColor = isBanned and "|cffff0000" or (isPassed and "|cff808080" or cc.hex)
        local banSuffix = isBanned and " |cffff0000[ЗАБАНЕН]|r" or ""
        nt:SetText(nameColor .. dn .. banSuffix .. "|r")

        local gt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        gt:SetPoint("LEFT", nt, "RIGHT", 20, 0)
        local gpText = isBanned and "|cff808080[БАН]|r" or (bid.data.gp and bid.data.gp > 0 and ("|cff808080["..bid.data.gp.." GP]|r") or "|cffff0000[БЕЗ ГП]|r")
        if isPassed and not isBanned then gpText = "|cff808080[БЕЗ ГП]|r" end
        gt:SetText(gpText)

        local bt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        bt:SetPoint("RIGHT", -5, 0)
        if isBanned then
            bt:SetText("|cffff0000БАН|r")
        elseif isPassed then
            bt:SetText("|cff808080ПАС|r")
        else
            bt:SetText(bid.data.amount == 0 and "|cff8080800 GP|r" or "|cff00ff00"..bid.data.amount.." GP|r")
        end

        row:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and isRL and not isBanned and not isPassed then
                NSAuk.ShowConfirm("Назначить победителем?", "Назначить " .. bid.name .. " победителем и завершить аукцион?",
                    function() 
                        NSAuk.SetWinner(bid.name, bid.data.amount) 
                    end,
                    nil
                )
            elseif button == "RightButton" and isRL and not isBanned then
                NSAuk.ShowConfirm("Забанить игрока?", "Игрок " .. bid.name .. " будет заблокирован до конца аукциона.",
                    function()
                        bid.data.banned = true
                        bid.data.passed = true
                        if db.active and db.active.startedBy == UnitName("player") then
                            SendAddonMessage("AUC_BAN", bid.name, "RAID")
                        end
                        NSAuk.UpdateAuctionWindow()
                    end,
                    nil
                )
            end
        end)

        row:Show()
        local rw = nt:GetStringWidth() + 20 + gt:GetStringWidth() + 10 + bt:GetStringWidth() + 25
        if rw > maxRowWidth then maxRowWidth = rw end

        content.rows[i] = row
        totalHeight = totalHeight + rowHeight
    end

    if #sortedBids == 0 then
        local er = CreateFrame("Frame", nil, content)
        er:SetHeight(rowHeight)
        er:SetPoint("TOPLEFT", 10, -totalHeight)
        er:SetPoint("TOPRIGHT", -10, -totalHeight)
        local et = er:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        et:SetPoint("CENTER", 0, 0)
        et:SetText("|cff808080Ожидание ставок...|r")
        er:Show()
        content.rows[1] = er
        totalHeight = totalHeight + rowHeight
    end

    local mx, ld = 0, nil
    for n, d in pairs(db.active.bids) do
        if d.hasAction and not d.passed and not d.banned and d.amount > mx then mx, ld = d.amount, n end
    end
    frame.nextBidText:SetText("Мин. ставка: " .. (mx + db.active.step) .. " GP")
    if ld then frame.leaderText:SetText("Лидер: " .. ld .. " (" .. mx .. " GP)"); frame.leaderText:Show() else frame.leaderText:Hide() end

    content:SetHeight(totalHeight + 10)
    content:SetWidth(maxRowWidth)
    NSAuk.SmoothResize(frame, maxRowWidth + 20, totalHeight + 140, 0.15)
    NSAuk.RenderCustomButtons()
    
    if frame.customPanel then
        frame.customPanel:ClearAllPoints()
        frame.customPanel:SetPoint("TOPRIGHT", frame, "TOPLEFT", -5, 0)
    end
end

function NSAuk.CheckAndFixWindow()
    local db = NSAuk.EnsureDB()
    if not db.active then checkFrame:SetScript("OnUpdate", nil); return end
    if not isMinimized and (not auctionFrame or not auctionFrame:IsShown()) then NSAuk.UpdateAuctionWindow() end
end

function NSAuk.EnableCheckFrame()
    if checkFrame:GetScript("OnUpdate") then return end
    checkFrame:SetScript("OnUpdate", function(self, e)
        self.elapsed = self.elapsed + e
        if self.elapsed >= 2 then
            self.elapsed = 0
            if NSAuk.EnsureDB().active then NSAuk.CheckAndFixWindow() else self:SetScript("OnUpdate", nil) end
        end
    end)
end

-- ============================================================================
-- СОБЫТИЯ И ЧАТ
-- ============================================================================

SLASH_NSAUK1 = "/nsauk"
SlashCmdList["NSAUK"] = function(msg)
    local db = NSAuk.EnsureDB()
    local cmd = msg:lower():match("^%s*(%S+)%s*$") or ""
    
    if cmd == "reset" then
        NSAuk.ResetAllSettings()
    elseif cmd == "find" then
        NSAuk.HighlightAllFrames()
    elseif cmd == "save" then
        if auctionFrame then 
            NSAuk.SaveWindowPosition(auctionFrame, db.windowPosition)
            print("|cff00ff00[NSAuk]|r Позиция окна сохранена") 
        else
            print("|cffff8080[NSAuk]|r Окно аукциона не открыто.")
        end
    else
        NSAuk.CreateSettingsWindow()
        if settingsWindow then settingsWindow:Show() end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

local function ProcessRaidMessage(sender, msg, event)
    local db = NSAuk.EnsureDB()
    local myName = UnitName("player")
    local cleanMsg = msg:match("^%s*(.-)%s*$") or ""
    local isLeaderChannel = (event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_RAID_LEADER")

    if cleanMsg:match("^АУК") then
        if cleanMsg:match("^АУК%s+история") then
            if sender == myName then NSAuk.CreateHistoryWindow(tonumber(cleanMsg:match("%d+"))) end
            return true
        end
        if cleanMsg:match("^АУК%s+показать") then
            if isLeaderChannel and db.active and db.active.startedBy == sender then
                local gpStr = ""
                for n, d in pairs(db.active.bids) do
                    gpStr = gpStr .. n .. ":" .. (d.gp or 0) .. ":" .. (d.class or "WARRIOR") .. ":" .. (d.public or "") .. ";"
                end
                SendAddonMessage("AUC_SYNC", db.active.item .. "^^" .. db.active.step .. "^^" .. db.active.closeTime .. "^^" .. (db.active.itemLink or "") .. "^^" .. gpStr, "RAID")
            end
            return true
        end
        if cleanMsg:match("^АУК%s+закрыть") then
            if isLeaderChannel then
                SendAddonMessage("AUC_CANCEL", "", "RAID")
                if closeTimerFrame then closeTimerFrame:SetScript("OnUpdate", nil); closeTimerFrame = nil end
                db.active = nil
                NSAuk.DestroyAuctionWindow()
                isMinimized = false
                if minimapIcon then minimapIcon:Hide() end
                checkFrame:SetScript("OnUpdate", nil)
            end
            return true
        end

        if isLeaderChannel then
            if db.active then
                SendAddonMessage("AUC_END", "", "RAID")
                return true
            else
                local parsed = NSAuk.ParseAuctionCommand(cleanMsg)
                local item = parsed.item
                local itemLink = parsed.itemLink
                local step = parsed.step or db.settings.defaultStep
                local ct = parsed.closeTime or db.settings.defaultTime

                db.active = {
                    item = item, itemLink = itemLink, startTime = GetTime(), startedBy = sender,
                    step = step, closeTime = ct, lastBidTime = GetTime(), bids = {}
                }
                isMinimized = false

                local gpData = NSAuk.GetRaidGPData()
                for name, data in pairs(gpData) do
                    db.active.bids[name] = { amount = 0, class = data.class, public = data.public, gp = data.gp, passed = false, hasAction = false, banned = false }
                end
                if not db.active.bids[myName] then
                    local found = false
                    for fullName, data in pairs(db.active.bids) do
                        if fullName:match("^" .. myName .. "%-") then
                            db.active.bids[myName] = data; found = true; break
                        end
                    end
                    if not found then
                        local _, c = UnitClass("player")
                        db.active.bids[myName] = { amount = 0, class = c, public = "", gp = 0, passed = false, hasAction = false, banned = false }
                    end
                end

                NSAuk.BroadcastMyGP()

                if sender == myName then
                    local gpStr = ""
                    for name, data in pairs(gpData) do
                        gpStr = gpStr .. name .. ":" .. data.gp .. ":" .. data.class .. ":" .. data.public .. ";"
                    end
                    SendAddonMessage("AUC_START", item .. "^^" .. step .. "^^" .. ct .. "^^" .. (itemLink or "") .. "^^" .. gpStr, "RAID")
                end

                NSAuk.UpdateAuctionWindow()
                NSAuk.StartCloseTimer()
                NSAuk.EnableCheckFrame()
                return true
            end
        end
        return false
    end

    if db.active then
        local isPass = (cleanMsg:match("^[Пп]ас$") or cleanMsg == "-")
        local amount = tonumber(cleanMsg:match("^%s*(%d+)%s*$"))

        if isPass or amount then
            local bidData = db.active.bids[sender]
            if not bidData then
                for fullName, data in pairs(db.active.bids) do
                    if fullName:match("^" .. sender .. "%-") then
                        bidData = data; db.active.bids[sender] = data
                        break
                    end
                end
            end
            if not bidData then
                local _, c = UnitClass(sender)
                db.active.bids[sender] = { amount = 0, class = c or "WARRIOR", public = "", gp = 0, passed = false, hasAction = true, banned = false }
                bidData = db.active.bids[sender]
            end

            if bidData.banned then return true end

            if isPass then
                if not bidData.passed then
                    local maxAmount = 0
                    for _, b in pairs(db.active.bids) do if b.hasAction and not b.passed and b.amount > maxAmount then maxAmount = b.amount end end
                    if bidData.amount >= maxAmount and maxAmount > 0 then
                        if sender == myName then print("|cffff0000[NSAuk]|r Нельзя выйти из торгов, пока вы лидируете.") end
                        return true
                    end
                    bidData.passed = true; bidData.amount = 0; bidData.hasAction = true
                    db.active.lastBidTime = GetTime()
                    AnnounceRaid(sender .. " делает ПАС и выбывает из торгов.")
                    NSAuk.UpdateAuctionWindow()
                end
                return true
            end

            if amount then
                if bidData.passed then
                    if sender == myName then print("|cffff0000[NSAuk]|r Вы уже сделали пас.") end
                    return true
                end

                local mx = 0
                for n, d in pairs(db.active.bids) do
                    if n ~= sender and d.hasAction and not d.passed and not d.banned and d.amount > mx then mx = d.amount end
                end
                local mn = mx + db.active.step

                if sender == myName then
                    local playerGP = bidData.gp or 0
                    if amount > playerGP then
                        print("|cffff0000[NSAuk]|r Недостаточно ГП! У вас: " .. playerGP .. ", ставка: " .. amount)
                        return true
                    end
                    NSAuk.BroadcastMyGP()
                end
                
                if amount >= mn then
                    bidData.amount = amount; bidData.passed = false; bidData.hasAction = true
                    db.active.lastBidTime = GetTime()
                    local newMx, newLd = 0, nil
                    for n, d in pairs(db.active.bids) do
                        if d.hasAction and not d.passed and not d.banned and d.amount > newMx then newMx, newLd = d.amount, n end
                    end
                    if newLd then AnnounceRaid(newLd .. " лидирует с " .. newMx .. " GP.") end
                    NSAuk.UpdateAuctionWindow()
                else
                    -- Ставка меньше минимума — сообщаем отправителю шёпотом
                end
                return true
            end
        end
    end

    return false
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2 = ...
    if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" then
        if ProcessRaidMessage(arg2, arg1, event) then return end
    end

    if event == "CHAT_MSG_ADDON" then
        local prefix, addonMsg, _, addonSender = ...
        if not addonSender or addonSender == "" then return end
        local db = NSAuk.EnsureDB()
        local myName = UnitName("player")

        if prefix == "AUC_START" then
            local parts = NSAuk.mysplit(addonMsg or "", "%^%^")
            db.active = {
                item = parts[1] or "Предмет",
                itemLink = parts[4] or nil,
                startTime = GetTime(),
                startedBy = addonSender,
                step = tonumber(parts[2]) or 10,
                closeTime = tonumber(parts[3]) or 20,
                lastBidTime = GetTime(),
                bids = {}
            }
            isMinimized = false
            for pd in (parts[5] or ""):gmatch("([^;]+);") do
                local n, g, c, p = pd:match("([^:]+):([^:]+):([^:]+):(.*)")
                if n then 
                    local gpValue = tonumber(g) or 0
                    db.active.bids[n] = { amount = 0, class = c or "WARRIOR", public = p or "", gp = gpValue, passed = false, hasAction = false, banned = false } 
                end
            end
            if not db.active.bids[myName] then
                local _, c = UnitClass("player")
                db.active.bids[myName] = { amount = 0, class = c, public = "", gp = 0, passed = false, hasAction = false, banned = false }
            end
            
            -- Отправляем свои ГП при получении AUC_START
            NSAuk.BroadcastMyGP()
            
            NSAuk.UpdateAuctionWindow()
            NSAuk.StartCloseTimer()
            NSAuk.EnableCheckFrame()

        elseif prefix == "AUC_GP" and db.active then
            -- Получаем ГП от другого игрока
            local n, g, c, p = addonMsg:match("([^:]+):([^:]+):([^:]+):(.*)")
            if n then
                local gpValue = tonumber(g) or 0
                if db.active.bids[n] then
                    db.active.bids[n].gp = gpValue
                    db.active.bids[n].class = c or db.active.bids[n].class
                    db.active.bids[n].public = p or db.active.bids[n].public
                else
                    db.active.bids[n] = { amount = 0, class = c or "WARRIOR", public = p or "", gp = gpValue, passed = false, hasAction = false, banned = false }
                end
                NSAuk.UpdateAuctionWindow()
            end

        elseif prefix == "AUC_BID" and db.active then
            local a = tonumber(addonMsg)
            if a then
                if not db.active.bids[addonSender] then
                    local _, c = UnitClass(addonSender)
                    db.active.bids[addonSender] = { amount = 0, class = c or "WARRIOR", public = "", gp = 0, passed = false, hasAction = true, banned = false }
                end
                
                if not db.active.bids[addonSender].passed and not db.active.bids[addonSender].banned then
                    db.active.bids[addonSender].amount = a
                    db.active.bids[addonSender].passed = false
                    db.active.bids[addonSender].hasAction = true
                    db.active.lastBidTime = GetTime()
                    NSAuk.UpdateAuctionWindow()
                end
            end

        elseif prefix == "AUC_PASS" and db.active then
            if not db.active.bids[addonSender] then
                local _, c = UnitClass(addonSender)
                db.active.bids[addonSender] = { amount = 0, class = c or "WARRIOR", public = "", gp = 0, passed = true, hasAction = true, banned = false }
            else
                db.active.bids[addonSender].passed = true
                db.active.bids[addonSender].amount = 0
                db.active.bids[addonSender].hasAction = true
            end
            NSAuk.UpdateAuctionWindow()

        elseif prefix == "AUC_BAN" and db.active then
            local targetName = addonMsg
            if db.active.bids[targetName] then
                db.active.bids[targetName].banned = true
                db.active.bids[targetName].passed = true
                print("|cffff0000[NSAuk]|r Игрок " .. targetName .. " забанен на аукционе.")
                NSAuk.UpdateAuctionWindow()
            end

        elseif prefix == "AUC_END" and db.active then
            NSAuk.FinishAuction(db.active.startedBy)

        elseif prefix == "AUC_CANCEL" then
            if closeTimerFrame then closeTimerFrame:SetScript("OnUpdate", nil); closeTimerFrame = nil end
            db.active = nil
            isMinimized = false
            NSAuk.DestroyAuctionWindow()
            if minimapIcon then minimapIcon:Hide() end
            checkFrame:SetScript("OnUpdate", nil)

        elseif prefix == "AUC_SYNC" and not db.active then
            local parts = NSAuk.mysplit(addonMsg or "", "%^%^")
            db.active = {
                item = parts[1] or "Предмет",
                itemLink = parts[4] or nil,
                startTime = GetTime(),
                startedBy = addonSender,
                step = tonumber(parts[2]) or 10,
                closeTime = tonumber(parts[3]) or 20,
                lastBidTime = GetTime(),
                bids = {}
            }
            isMinimized = false
            for pd in (parts[5] or ""):gmatch("([^;]+);") do
                local n, g, c, p = pd:match("([^:]+):([^:]+):([^:]+):(.*)")
                if n then 
                    local gpValue = tonumber(g) or 0
                    db.active.bids[n] = { amount = 0, class = c or "WARRIOR", public = p or "", gp = gpValue, passed = false, hasAction = false, banned = false } 
                end
            end
            if not db.active.bids[myName] then
                local _, c = UnitClass("player")
                db.active.bids[myName] = { amount = 0, class = c, public = "", gp = 0, passed = false, hasAction = false, banned = false }
            end
            
            -- Отправляем свои ГП при синхронизации
            NSAuk.BroadcastMyGP()
            
            NSAuk.UpdateAuctionWindow()
            NSAuk.StartCloseTimer()
            NSAuk.EnableCheckFrame()
        end
    end

    if event == "PLAYER_LOGOUT" then
        if closeTimerFrame then closeTimerFrame:SetScript("OnUpdate", nil); closeTimerFrame = nil end
        if resizeAnimation then resizeAnimation:SetScript("OnUpdate", nil); resizeAnimation = nil end
        checkFrame:SetScript("OnUpdate", nil)
    end
end)

-- ============================================================================
-- ВЫДАЧА ЛУТА ЧЕРЕЗ GIVEMASTERLOOT
-- ============================================================================

-- Приватный метод: ищет слот в окне лута, соответствующий itemLink аукциона
function NSAuk._FindLootSlotByLink(itemLink)
    if not itemLink then return nil end
    local num = GetNumLootItems and GetNumLootItems() or 0
    if num == 0 then return nil end
    local targetId = itemLink:match("item:(%d+)")
    if not targetId then return nil end
    for slot = 1, num do
        local slotLink = GetLootSlotLink(slot)
        if slotLink then
            local slotId = slotLink:match("item:(%d+)")
            if slotId == targetId then
                return slot
            end
        end
    end
    return nil
end

function NSAuk.GiveLootToWinner(playerName, itemLink)
    if not playerName then return false end
    
    -- Проверяем, что мы мастер-лутер
    if GetLootMethod() ~= "master" then
        print("|cffff8080[NSAuk]|r Лут не выдан: рейд не в режиме 'Master Looter'")
        return false
    end
    
    -- Проверяем, что окно лута открыто
    if not LootFrame or not LootFrame:IsShown() then
        print("|cffff8080[NSAuk]|r Лут не выдан: окно добычи не открыто")
        return false
    end
    
    -- Если itemLink не передан — пробуем взять из активного аукциона
    if not itemLink then
        local db = NSAuk.EnsureDB()
        itemLink = db.active and db.active.itemLink or nil
    end
    
    if not itemLink then
        print("|cffff8080[NSAuk]|r Лут не выдан: нет ссылки на предмет")
        return false
    end
    
    -- Ищем слот, в котором лежит нужный предмет
    local slot = NSAuk._FindLootSlotByLink(itemLink)
    if not slot then
        print("|cffff8080[NSAuk]|r Лут не выдан: предмет не найден в окне добычи")
        return false
    end
    
    local lowerPlayer = string.lower(playerName)
    local found = false
    
    -- РЕЙД
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local cand = GetMasterLootCandidate(i)
            if cand and string.lower(cand) == lowerPlayer then
                GiveMasterLoot(slot, i)
                found = true
                break
            end
        end
    -- ГРУППА
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() + 1 do
            local cand = GetMasterLootCandidate(i)
            if cand and string.lower(cand) == lowerPlayer then
                GiveMasterLoot(slot, i)
                found = true
                break
            end
        end
    end
    
    if found then
        print("|cff00ff00[NSAuk]|r Лут выдан игроку " .. playerName .. " (слот " .. slot .. ")")
    else
        print("|cffff8080[NSAuk]|r Лут не выдан: игрок " .. playerName .. " не найден в списке кандидатов")
    end
    return found
end

function NSAuk.GiveLootToWinnerDeferred(playerName, itemLink)
    if not playerName then return end
    if GetLootMethod() ~= "master" then return end
    
    -- Если окно лута уже открыто — выдаём сразу
    if LootFrame and LootFrame:IsShown() then
        NSAuk.GiveLootToWinner(playerName, itemLink)
        return
    end
    
    -- Иначе ждём до 3 секунд появления окна лута
    local waiter = CreateFrame("Frame")
    local elapsed = 0
    waiter:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if LootFrame and LootFrame:IsShown() then
            self:SetScript("OnUpdate", nil)
            NSAuk.GiveLootToWinner(playerName, itemLink)
        elseif elapsed > 3 then
            self:SetScript("OnUpdate", nil)
            print("|cffff8080[NSAuk]|r Окно добычи не открылось за 3 секунды — выдача лута отменена.")
        end
    end)
end

    print("|cff00ff00[NS Auction System v5.9]|r Загружен. Команды: /nsauk, /nsauk reset, /nsauk find")

end)