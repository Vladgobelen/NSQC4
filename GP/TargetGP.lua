-- ============================================================================
-- NSQC4 / GP / TargetGP
-- Кнопка «ГП» у рамки цели.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

local DEFAULT_VALUES       = { 5, 10, 20, 50 }
local PANEL_HOVER_TIMEOUT  = 5

NSQC4 = NSQC4 or {}
NSQC4.GPDebug = NSQC4.GPDebug or { enabled = false }
NSQC4.TargetGP = NSQC4.TargetGP or {}

local debugEnabled = false

local function dbg(tag, ...)
    if (NSQC4.GPDebug and NSQC4.GPDebug.enabled) or debugEnabled then
        print("|cff00ffff[TGP " .. tag .. "]|r", ...)
    end
end

NSQC4.TargetGP.SetDebug = function(enabled)
    debugEnabled = enabled == true
    NSQC4.TargetGP.debug = debugEnabled
    dbg("DEBUG-SET", "debugEnabled=", tostring(debugEnabled))
end

nsDbc4 = nsDbc4 or {}
nsDbc4.settings = nsDbc4.settings or {}
nsDbc4.settings.gp = nsDbc4.settings.gp or {}
local gpDb = nsDbc4.settings.gp

gpDb.targetButtonValues = gpDb.targetButtonValues or { 5, 10, 20, 50 }
gpDb.targetButtonPos    = gpDb.targetButtonPos or {
    point = "RIGHT", relativePoint = "LEFT", x = 0, y = 0,
}
gpDb.targetButtonMode   = gpDb.targetButtonMode or "hover"

local function GetButtonValue(i)
    return gpDb.targetButtonValues[i] or DEFAULT_VALUES[i]
end

local function SetButtonValue(i, v)
    gpDb.targetButtonValues[i] = v
end

local function ShortName(name)
    if not name then return nil end
    return name:match("^([^%-]+)") or name
end

local function IsOfficer()
    if NSQC4._gpWindow and NSQC4._gpWindow._CheckOfficerRank then
        return NSQC4._gpWindow:_CheckOfficerRank()
    end
    if not IsInGuild() then return false end
    local playerName = UnitName("player")
    for i = 1, GetNumGuildMembers(true) do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if name and name == playerName then
            local rankName = GuildControlGetRankName(rankIndex + 1)
            if rankName == "Капитан" or rankName == "Лейтенант" or rankName == "Командор" then
                return true
            end
            break
        end
    end
    return false
end

local function IsInMyGuild(short)
    if not short then return false end
    for i = 1, GetNumGuildMembers(true) do
        local n = GetGuildRosterInfo(i)
        if n and ShortName(n) == short then return true end
    end
    return false
end

local function ApplyGP(short, value)
    if not short or not value or value == 0 then return end
    if not NSQC4.CanAssignGp or not NSQC4.CanAssignGp() then return end
    if not IsOfficer() then
        print("|cFFFF0000[NSQC4]|r Только офицеры могут начислять ГП.")
        return
    end
    if not IsInGuild() then return end

    local isOwn = IsInMyGuild(short)
    local channel = "GUILD"
    local prefix  = isOwn and "nsGP1" or "nsGP1A"
    local message = tostring(value) .. " " .. short

    SendAddonMessage(prefix, message, channel)
    SendAddonMessage("nsGPlog", string.format("Цель %d %s", value, short), "GUILD")

    if value > 0 then
        print("|cff00ff00[NSQC4]|r Начислено " .. value .. " ГП: " .. short)
    else
        print("|cffff8080[NSQC4]|r Снято " .. (-value) .. " ГП: " .. short)
    end
end

-- ============================================================================
-- Поиск фрейма цели
-- ============================================================================
local function GetTargetFrame()
    if _G["XPerl_Target"] then return _G["XPerl_Target"] end
    if _G["SUFUnittarget"] then return _G["SUFUnittarget"] end
    if _G["PitBull4_Frames_Target"] then return _G["PitBull4_Frames_Target"] end
    if _G["ElvUF_Target"] then return _G["ElvUF_Target"] end
    if _G["TukuiTargetFrame"] then return _G["TukuiTargetFrame"] end
    if _G["TargetFrame"] then return _G["TargetFrame"] end
    return nil
end

-- ============================================================================
-- Состояние UI
-- ============================================================================
local targetBtn, panel, editBox, editMode
local CreatePanel
local panelCloseAt  = 0
local lastRefresh   = 0
local lastTargetFrame = nil
local isDragging = false

local function ShowPanel()
    local p = panel or CreatePanel()
    p:ClearAllPoints()
    p:SetPoint("TOP", targetBtn, "BOTTOM", 0, -2)
    p:Show()
    panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
end

local function HidePanel()
    if panel and panel:IsShown() then panel:Hide() end
end

local function ApplyButtonPos(btn)
    local p = gpDb.targetButtonPos
    btn:ClearAllPoints()
    local anchor = GetTargetFrame()
    if anchor then
        btn:SetPoint(p.point, anchor, p.relativePoint, p.x, p.y)
    else
        btn:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    end
end

-- ============================================================================
-- Создание кнопки (с защитой от прыжков)
-- ============================================================================
local function CreateTargetBtn()
    if targetBtn then return targetBtn end
    lastTargetFrame = GetTargetFrame()

    -- Создаем невидимый якорь, который будет двигаться вместо кнопки
    local anchorFrame = CreateFrame("Frame", "NSQC4TargetGPAnchor", UIParent)
    anchorFrame:SetSize(1, 1)
    anchorFrame:SetClampedToScreen(true)
    anchorFrame:SetMovable(true)
    anchorFrame:Hide()

    local btn = CreateFrame("Button", "NSQC4TargetGPBtn", anchorFrame, "UIPanelButtonTemplate")
    btn:SetAllPoints(anchorFrame) -- Кнопка всегда растянута по якорю
    btn:SetText("ГП")
    btn:SetFrameStrata("MEDIUM")
    btn:Hide()
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    anchorFrame:SetWidth(36)
    anchorFrame:SetHeight(22)

    local function UpdateAnchorFromBtn()
        local anchor = GetTargetFrame()
        if not anchor then return end
        local p = gpDb.targetButtonPos
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint(p.point, anchor, p.relativePoint, p.x, p.y)
    end
    
    UpdateAnchorFromBtn()

    -- Перетаскивание теперь делает ЯКОРЬ, а не кнопку
    btn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = false
            anchorFrame:StartMoving()
            
            -- Отслеживаем движение, чтобы понять, тащим мы или кликаем
            local startX, startY = GetCursorPosition()
            local checkFrame = CreateFrame("Frame")
            local elapsed = 0
            checkFrame:SetScript("OnUpdate", function(f, dt)
                elapsed = elapsed + dt
                local cx, cy = GetCursorPosition()
                if math.abs(cx - startX) > 3 or math.abs(cy - startY) > 3 then
                    isDragging = true
                    f:SetScript("OnUpdate", nil)
                    f:Hide()
                elseif elapsed > 0.2 then
                    f:SetScript("OnUpdate", nil)
                    f:Hide()
                end
            end)
        end
    end)

    btn:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and anchorFrame:IsMovable() then
            anchorFrame:StopMovingOrSizing()
            
            if isDragging then
                -- Если это было перетаскивание, прилипаем к ближайшей стороне
                local target = GetTargetFrame()
                if target then
                    local cx, cy = anchorFrame:GetCenter()
                    local tx, ty = target:GetCenter()
                    
                    local dx = cx - tx
                    local dy = cy - ty
                    
                    local point, relPoint
                    if math.abs(dx) > math.abs(dy) then
                        if dx > 0 then point, relPoint = "LEFT", "RIGHT"
                        else point, relPoint = "RIGHT", "LEFT" end
                    else
                        if dy > 0 then point, relPoint = "BOTTOM", "TOP"
                        else point, relPoint = "TOP", "BOTTOM" end
                    end
                    
                    gpDb.targetButtonPos = {
                        point = point,
                        relativePoint = relPoint,
                        x = 0,
                        y = 0,
                    }
                end
                isDragging = false
                UpdateAnchorFromBtn()
            end
        end
    end)

    btn:SetScript("OnClick", function(self, mouseButton)
        if isDragging then return end
        if mouseButton == "RightButton" then
            gpDb.targetButtonMode = (gpDb.targetButtonMode == "hover") and "click" or "hover"
            print("|cff00ff00[NSQC4]|r Режим кнопки ГП: " .. gpDb.targetButtonMode)
            return
        end
        if mouseButton == "LeftButton" then
            if gpDb.targetButtonMode == "click" then
                if panel and panel:IsShown() then HidePanel() else ShowPanel() end
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local mode = gpDb.targetButtonMode
        GameTooltip:SetText("ГП для цели", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFD100Текущий режим:|r " .. (mode == "hover" and "|cff00ff00всплывающий|r" or  "|cff00BFFFпо клику|r"))
        if mode == "hover" then
            GameTooltip:AddLine("Наведи на «ГП» — панель появится", 0.8, 0.8, 0.8)
        else
            GameTooltip:AddLine("ЛКМ — открыть/закрыть панель", 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFF8C00ПКМ|r — переключить режим", 1, 1, 1)
        GameTooltip:AddLine("ЛКМ + движение — перетащить", 0.8, 0.8, 0.8)
        GameTooltip:Show()
        if mode == "hover" and not isDragging then ShowPanel() end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    targetBtn = btn
    -- Сохраняем ссылку на якорь внутри кнопки для доступа извне
    targetBtn.anchor = anchorFrame
    return btn
end

-- ============================================================================
-- Создание панели значений
-- ============================================================================
CreatePanel = function()
    if panel then return panel end

    local f = CreateFrame("Frame", "NSQC4TargetGPPanel", UIParent)
    f:SetSize(1, 1)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    f:EnableMouse(true)
    f:Hide()

    f:SetScript("OnEnter", function()
        if gpDb.targetButtonMode == "hover" then
            panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
        end
    end)

    f.buttons = {}

    local padding   = 8
    local xOffset   = padding
    local yOffset   = -padding
    local btnWidth  = 40
    local btnHeight = 20

    for i = 1, 4 do
        local b = CreateFrame("Button", "NSQC4TargetGPBtn" .. i, f, "UIPanelButtonTemplate")
        b:SetSize(btnWidth, btnHeight)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
        b:SetText(tostring(GetButtonValue(i)))
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

        b:SetScript("OnClick", function(self, mouseButton)
            local value = GetButtonValue(i)
            local short = UnitExists("target") and ShortName(UnitName("target")) or nil
            if not short then return end

            if mouseButton == "LeftButton" then
                ApplyGP(short, value)
            elseif mouseButton == "RightButton" then
                ApplyGP(short, -value)
            elseif mouseButton == "MiddleButton" then
                editMode = i
                editBox:SetText(tostring(value))
                editBox:Show()
                editBox:SetFocus()
                editBox:HighlightText()
            end
        end)

        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("ГП: " .. GetButtonValue(i), 1, 0.82, 0)
            GameTooltip:AddLine("ЛКМ — начислить", 0.6, 1, 0.6)
            GameTooltip:AddLine("ПКМ — снять",     1, 0.6, 0.6)
            GameTooltip:AddLine("СКМ — задать значение", 0.6, 0.6, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)

        f.buttons[i] = b
        xOffset = xOffset + btnWidth + 5
    end

    local qBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    qBtn:SetSize(30, btnHeight)
    qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
    qBtn:SetText("?")
    qBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    qBtn:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            editMode = "custom_sub"
            editBox:SetText("")
        else
            editMode = "custom_add"
            editBox:SetText("")
        end
        editBox:Show()
        editBox:SetFocus()
    end)

    qBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Разовое значение", 1, 0.82, 0)
        GameTooltip:AddLine("ЛКМ — ввести и начислить", 0.6, 1, 0.6)
        GameTooltip:AddLine("ПКМ — ввести и снять",     1, 0.6, 0.6)
        GameTooltip:Show()
    end)
    qBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.qBtn = qBtn

    local totalWidth = xOffset + 30 + padding

    local eb = CreateFrame("EditBox", "NSQC4TargetGPEdit", f, "InputBoxTemplate")
    eb:SetSize(60, 20)
    eb:SetPoint("TOPLEFT", f, "TOPLEFT", padding, -(padding + btnHeight + 5))
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(6)
    eb:Hide()

    eb:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText())
        if v then
            if editMode == "custom_add" or editMode == "custom_sub" then
                local short = UnitExists("target") and ShortName(UnitName("target")) or nil
                if short then
                    local finalValue = (editMode == "custom_sub") and -v or v
                    ApplyGP(short, finalValue)
                end
            elseif type(editMode) == "number" then
                SetButtonValue(editMode, v)
                if panel and panel.buttons[editMode] then
                    panel.buttons[editMode]:SetText(tostring(v))
                end
            end
        end
        self:SetText("")
        self:ClearFocus()
        self:Hide()
        editMode = nil
    end)

    eb:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        self:Hide()
        editMode = nil
    end)

    editBox = eb
    panel   = f
    f:SetSize(totalWidth, padding + btnHeight + padding)
    return f
end

-- ============================================================================
-- OnUpdate: управление видимостью
-- ============================================================================
local hoverFrame = CreateFrame("Frame")
hoverFrame:SetScript("OnUpdate", function()
    if isDragging then return end

    local anchor = GetTargetFrame()
    if not anchor then 
        if targetBtn then targetBtn:Hide() end
        if targetBtn and targetBtn.anchor then targetBtn.anchor:Hide() end
        return 
    end

    local btn = targetBtn or CreateTargetBtn()

    if anchor ~= lastTargetFrame then
        lastTargetFrame = anchor
        local p = gpDb.targetButtonPos
        btn.anchor:ClearAllPoints()
        btn.anchor:SetPoint(p.point, anchor, p.relativePoint, p.x, p.y)
    end

    if panel and panel:IsShown() then
        if gpDb.targetButtonMode == "hover" then
            local btnHover = btn:IsMouseOver() or (anchor:IsMouseOver() and UnitIsPlayer("target"))
            local panelHover = panel:IsMouseOver()

            if btnHover or panelHover then
                if GetTime() - lastRefresh >= 1 then
                    panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
                    lastRefresh  = GetTime()
                end
            end

            if GetTime() >= panelCloseAt then
                if not (btn:IsMouseOver() or panel:IsMouseOver()) then
                    HidePanel()
                else
                    panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
                end
            end
        end
        btn:Show()
        return
    end

    local show = UnitExists("target")
        and UnitIsPlayer("target")
        and (UnitInRaid("target") or UnitInParty("target"))
        and (anchor:IsMouseOver() or btn:IsMouseOver())

    if show then
        btn.anchor:Show()
        btn:Show()
    else
        btn:Hide()
        btn.anchor:Hide()
    end
end)

-- ============================================================================
-- Восстановление при логине
-- ============================================================================
local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_LOGIN")
restoreFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local elapsed = 0
    local tempFrame = CreateFrame("Frame")
    tempFrame:SetScript("OnUpdate", function(f, dt)
        elapsed = elapsed + dt
        if elapsed > 2.0 then
            f:SetScript("OnUpdate", nil)
            local anchor = GetTargetFrame()
            if anchor then
                local btn = CreateTargetBtn()
                local p = gpDb.targetButtonPos
                btn.anchor:ClearAllPoints()
                btn.anchor:SetPoint(p.point, anchor, p.relativePoint, p.x, p.y)
            end
        end
    end)
end)

SLASH_NSQC4TGP1 = "/tgpd"
SlashCmdList["NSQC4TGP"] = function()
    local newState = not ((NSQC4.GPDebug and NSQC4.GPDebug.enabled) or debugEnabled)
    NSQC4.GPDebug = NSQC4.GPDebug or {}
    NSQC4.GPDebug.enabled = newState
    NSQC4.TargetGP.SetDebug(newState)
    print("|cff00ffff[NSQC4 TargetGP]|r debug=", tostring(newState))
end

end)