-- ============================================================================
-- NSQC4 / GP / TargetGP
-- Кнопка «ГП» у рамки цели: быстрое начисление/списание ГП.
--
-- Режимы:
--   hover — панель появляется при наведении мыши, исчезает через 5 сек.
--   click — панель открывается/закрывается по ЛКМ.
--
-- Кнопки значений:
--   ЛКМ  — начислить (ApplyGP +value)
--   ПКМ  — списать    (ApplyGP -value)
--   СКМ  — задать своё значение
--   «?»  — разовое значение через EditBox
--
-- Отладка (общий флаг из GP/GP.lua):
--   NSQC4.GPDebug.enabled = true   -- включить
--   NSQC4.GPDebug.enabled = false  -- выключить
--   /tgpd                          -- переключить (локальный флаг + общий)
-- ============================================================================

NSQC4.RegisterModule("gp", function()

local DEFAULT_VALUES       = { 5, 10, 20, 50 }
local PANEL_HOVER_TIMEOUT  = 5

-- ============================================================================
-- Точечная отладка
-- ============================================================================
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

-- ============================================================================
-- Хранилище настроек
-- ============================================================================
nsDbc4 = nsDbc4 or {}
nsDbc4.settings = nsDbc4.settings or {}
nsDbc4.settings.gp = nsDbc4.settings.gp or {}
local gpDb = nsDbc4.settings.gp

gpDb.targetButtonValues = gpDb.targetButtonValues or { 5, 10, 20, 50 }
gpDb.targetButtonPos    = gpDb.targetButtonPos or {
    point = "RIGHT", relativePoint = "LEFT", x = -8, y = 0,
}
gpDb.targetButtonMode   = gpDb.targetButtonMode or "hover"

local function GetButtonValue(i)
    return gpDb.targetButtonValues[i] or DEFAULT_VALUES[i]
end

local function SetButtonValue(i, v)
    gpDb.targetButtonValues[i] = v
end

-- ============================================================================
-- Утилиты
-- ============================================================================
local function ShortName(name)
    if not name then return nil end
    return name:match("^([^%-]+)") or name
end

local function IsOfficer()
    dbg("IS-OFFICER-ENTER")
    if NSQC4._gpWindow and NSQC4._gpWindow._CheckOfficerRank then
        local result = NSQC4._gpWindow:_CheckOfficerRank()
        dbg("IS-OFFICER-VIA-GPWINDOW", "result=", tostring(result))
        return result
    end

    if not IsInGuild() then
        dbg("IS-OFFICER-SKIP", "not in guild")
        return false
    end

    local playerName = UnitName("player")
    for i = 1, GetNumGuildMembers(true) do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if name and name == playerName then
            local rankName = GuildControlGetRankName(rankIndex + 1)
            dbg("IS-OFFICER-RANK",
                "rankIndex=", tostring(rankIndex),
                "rankName=", tostring(rankName)
            )
            if rankName == "Капитан"
            or rankName == "Лейтенант"
            or rankName == "Командор" then
                dbg("IS-OFFICER-OK", "rankName=", rankName)
                return true
            end
            dbg("IS-OFFICER-FAIL", "rankName=", tostring(rankName))
            break
        end
    end
    dbg("IS-OFFICER-NOT-FOUND", "player not found or not officer")
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

-- ============================================================================
-- ApplyGP: ПРАВИЛЬНЫЙ формат SendAddonMessage (3.3.5a)
--   prefix  = "nsGP1" / "nsGP1A"   (БЕЗ пробела!)
--   message = "<delta> <nick>"
-- ============================================================================
local function ApplyGP(short, value)
    dbg("APPLY-ENTER",
        "short=", tostring(short),
        "value=", tostring(value)
    )

    if not short or not value or value == 0 then
        dbg("APPLY-SKIP", "bad args",
            "short=", tostring(short),
            "value=", tostring(value)
        )
        return
    end

    -- Шаг 1: проверка ПВЕ-сезона
    if not NSQC4.CanAssignGp or not NSQC4.CanAssignGp() then
        dbg("APPLY-SKIP", "CanAssignGp=false (ПВЕ-сезон)")
        return
    end
    dbg("APPLY-CAN-ASSIGN", "OK")

    -- Шаг 2: проверка офицерского ранга
    if not IsOfficer() then
        print("|cFFFF0000[NSQC4]|r Только офицеры могут начислять ГП.")
        dbg("APPLY-SKIP", "not officer")
        return
    end
    dbg("APPLY-IS-OFFICER", "OK")

    -- Шаг 3: проверка «в гильдии ли я»
    if not IsInGuild() then
        dbg("APPLY-SKIP", "not in guild")
        return
    end
    dbg("APPLY-IS-IN-GUILD", "OK")

    -- Шаг 4: определяем свой/чужой гильдеец
    local isOwn = IsInMyGuild(short)
    dbg("APPLY-GUILD-CHECK",
        "nick=", short,
        "isMyGuildMember=", tostring(isOwn)
    )

    -- Шаг 5: выбираем prefix и channel
    local channel = "GUILD"
    local prefix  = isOwn and "nsGP1" or "nsGP1A"
    local message = tostring(value) .. " " .. short

    dbg("APPLY-SEND",
        "nick=", short,
        "gp=", tostring(value),
        "isOwn=", tostring(isOwn),
        "prefix=", prefix,
        "channel=", channel,
        "message=", message
    )

    -- Шаг 6: отправка
    SendAddonMessage(prefix, message, channel)

    dbg("APPLY-SENT",
        "ОТПРАВЛЕНО:",
        "prefix=" .. prefix,
        "channel=" .. channel,
        "body=" .. message
    )

    -- Шаг 7: лог
    SendAddonMessage(
        "nsGPlog",
        string.format("Цель %d %s", value, short),
        "GUILD"
    )
    dbg("APPLY-LOG-SENT", "nsGPlog sent")

    -- Шаг 8: локальный фидбек
    if value > 0 then
        print(
            "|cff00ff00[NSQC4]|r Начислено "
            .. value .. " ГП: " .. short
        )
    else
        print(
            "|cffff8080[NSQC4]|r Снято "
            .. (-value) .. " ГП: " .. short
        )
    end

    dbg("APPLY-DONE", "short=", short, "value=", value)
end

-- ============================================================================
-- Состояние UI
-- ============================================================================
local targetBtn, panel, editBox, editMode
local CreatePanel
local panelCloseAt  = 0
local lastRefresh   = 0

local function ShowPanel()
    dbg("SHOW-PANEL")
    local p = panel or CreatePanel()
    p:ClearAllPoints()
    p:SetPoint("TOP", targetBtn, "BOTTOM", 0, -5)
    p:Show()
    panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
end

local function HidePanel()
    dbg("HIDE-PANEL")
    if panel and panel:IsShown() then panel:Hide() end
end

local function ApplyButtonPos(btn)
    local p = gpDb.targetButtonPos
    btn:ClearAllPoints()
    btn:SetPoint(p.point, TargetFrame, p.relativePoint, p.x, p.y)
end

-- ============================================================================
-- Создание кнопки у рамки цели
-- ============================================================================
local function CreateTargetBtn()
    if targetBtn then return targetBtn end

    dbg("CREATE-TARGET-BTN")

    local btn = CreateFrame(
        "Button", "NSQC4TargetGPBtn", UIParent, "UIPanelButtonTemplate"
    )
    btn:SetSize(36, 22)
    btn:SetText("ГП")
    btn:SetFrameStrata("MEDIUM")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:Hide()
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    if TargetFrame then ApplyButtonPos(btn) end

    local isDragging = false

    btn:SetScript("OnDragStart", function(self)
        isDragging = true
        self:StartMoving()
    end)

    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        isDragging = false

        local cx, cy = self:GetCenter()
        local tx, ty = TargetFrame:GetCenter()
        if not (cx and cy and tx and ty) then return end

        local tw = TargetFrame:GetWidth()  / 2
        local th = TargetFrame:GetHeight() / 2
        local bw = self:GetWidth()         / 2
        local bh = self:GetHeight()        / 2

        local dx = cx - tx
        local dy = cy - ty

        local distRight  = math.abs(dx - tw - bw)
        local distLeft   = math.abs(dx + tw + bw)
        local distTop    = math.abs(dy - th - bh)
        local distBottom = math.abs(dy + th + bh)
        local minDist    = math.min(distRight, distLeft, distTop, distBottom)

        local point, relPoint, x, y
        if minDist == distRight then
            point, relPoint, x, y = "LEFT",   "RIGHT", dx - tw - bw, 0
        elseif minDist == distLeft then
            point, relPoint, x, y = "RIGHT",  "LEFT",  dx + tw + bw, 0
        elseif minDist == distTop then
            point, relPoint, x, y = "BOTTOM", "TOP",   0, dy - th - bh
        else
            point, relPoint, x, y = "TOP",    "BOTTOM",0, dy + th + bh
        end

        self:ClearAllPoints()
        self:SetPoint(
            point, TargetFrame, relPoint,
            math.floor(x), math.floor(y)
        )

        gpDb.targetButtonPos = {
            point = point,
            relativePoint = relPoint,
            x = math.floor(x),
            y = math.floor(y),
        }
        dbg("DRAG-STOP",
            "point=", point,
            "relPoint=", relPoint,
            "x=", tostring(x),
            "y=", tostring(y)
        )
    end)

    btn:SetScript("OnClick", function(self, mouseButton)
        if isDragging then return end

        dbg("BTN-CLICK", "button=", tostring(mouseButton))

        if mouseButton == "RightButton" then
            gpDb.targetButtonMode =
                (gpDb.targetButtonMode == "hover") and "click" or "hover"
            print(
                "|cff00ff00[NSQC4]|r Режим кнопки ГП: "
                .. gpDb.targetButtonMode
            )
            dbg("MODE-CHANGED", "mode=", gpDb.targetButtonMode)
            return
        end

        if mouseButton == "LeftButton" then
            if gpDb.targetButtonMode == "click" then
                if panel and panel:IsShown() then
                    dbg("CLICK-TOGGLE", "hiding panel")
                    HidePanel()
                else
                    dbg("CLICK-TOGGLE", "showing panel")
                    ShowPanel()
                end
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local mode = gpDb.targetButtonMode
        GameTooltip:SetText("ГП для цели", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "|cffFFD100Текущий режим:|r "
            .. (mode == "hover"
                and "|cff00ff00всплывающий|r"
                or  "|cff00BFFFпо клику|r")
        )
        if mode == "hover" then
            GameTooltip:AddLine(
                "Наведи на «ГП» — панель появится",
                0.8, 0.8, 0.8
            )
            GameTooltip:AddLine(
                "Удерживай мышь на панели — останется",
                0.8, 0.8, 0.8
            )
            GameTooltip:AddLine(
                "Ушла мышь — исчезнет через 5 сек",
                0.8, 0.8, 0.8
            )
        else
            GameTooltip:AddLine(
                "ЛКМ — открыть/закрыть панель",
                0.8, 0.8, 0.8
            )
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFF8C00ПКМ|r — переключить режим", 1, 1, 1)
        GameTooltip:AddLine("ЛКМ + движение — перетащить", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            "ЛКМ на кнопке значения — начислить",
            0.6, 1, 0.6
        )
        GameTooltip:AddLine(
            "ПКМ на кнопке значения — снять",
            1, 0.6, 0.6
        )
        GameTooltip:AddLine(
            "СКМ на кнопке значения — задать значение",
            0.6, 0.6, 1
        )
        GameTooltip:AddLine("? — разовое значение", 0.8, 0.8, 0.8)
        GameTooltip:Show()

        if mode == "hover" and not isDragging then
            ShowPanel()
        end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    targetBtn = btn
    dbg("CREATE-TARGET-BTN", "done")
    return btn
end

-- ============================================================================
-- Создание панели значений
-- ============================================================================
CreatePanel = function()
    if panel then return panel end

    dbg("CREATE-PANEL")

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
        local b = CreateFrame(
            "Button",
            "NSQC4TargetGPBtn" .. i,
            f,
            "UIPanelButtonTemplate"
        )
        b:SetSize(btnWidth, btnHeight)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
        b:SetText(tostring(GetButtonValue(i)))
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

        b:SetScript("OnClick", function(self, mouseButton)
            local value = GetButtonValue(i)
            local short = UnitExists("target")
                and ShortName(UnitName("target"))
                or nil

            dbg("CLICK-VALUE",
                "button=", tostring(i),
                "value=", tostring(value),
                "target=", tostring(short),
                "mouse=", tostring(mouseButton)
            )

            if not short then
                dbg("CLICK-VALUE-SKIP", "no target")
                return
            end

            if mouseButton == "LeftButton" then
                dbg("CLICK-VALUE-APPLY",
                    "short=", short,
                    "value=", tostring(value),
                    "action=ADD"
                )
                ApplyGP(short, value)

            elseif mouseButton == "RightButton" then
                dbg("CLICK-VALUE-APPLY",
                    "short=", short,
                    "value=", tostring(-value),
                    "action=SUBTRACT"
                )
                ApplyGP(short, -value)

            elseif mouseButton == "MiddleButton" then
                dbg("CLICK-VALUE-EDIT",
                    "button=", tostring(i),
                    "currentValue=", tostring(value)
                )
                editMode = i
                editBox:SetText(tostring(value))
                editBox:Show()
                editBox:SetFocus()
                editBox:HighlightText()
            end
        end)

        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(
                "ГП: " .. GetButtonValue(i), 1, 0.82, 0
            )
            GameTooltip:AddLine("ЛКМ — начислить", 0.6, 1, 0.6)
            GameTooltip:AddLine("ПКМ — снять",     1, 0.6, 0.6)
            GameTooltip:AddLine(
                "СКМ — задать значение", 0.6, 0.6, 1
            )
            GameTooltip:Show()
        end)

        b:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        f.buttons[i] = b
        xOffset = xOffset + btnWidth + 5
    end

    -- Кнопка «?» — разовое значение
    local qBtn = CreateFrame(
        "Button", nil, f, "UIPanelButtonTemplate"
    )
    qBtn:SetSize(30, btnHeight)
    qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
    qBtn:SetText("?")
    qBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    qBtn:SetScript("OnClick", function(self, mouseButton)
        dbg("CLICK-Q", "mouse=", tostring(mouseButton))
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

    qBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    f.qBtn = qBtn

    local totalWidth = xOffset + 30 + padding

    -- EditBox для ввода значения
    local eb = CreateFrame(
        "EditBox", "NSQC4TargetGPEdit", f, "InputBoxTemplate"
    )
    eb:SetSize(60, 20)
    eb:SetPoint(
        "TOPLEFT", f, "TOPLEFT",
        padding, -(padding + btnHeight + 5)
    )
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(6)
    eb:Hide()

    eb:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText())
        dbg("EDIT-ENTER",
            "value=", tostring(v),
            "editMode=", tostring(editMode)
        )

        if v then
            if editMode == "custom_add" or editMode == "custom_sub" then
                local short = UnitExists("target")
                    and ShortName(UnitName("target"))
                    or nil
                if short then
                    local finalValue = (editMode == "custom_sub") and -v or v
                    dbg("EDIT-CUSTOM-APPLY",
                        "short=", short,
                        "value=", tostring(finalValue),
                        "mode=", tostring(editMode)
                    )
                    ApplyGP(short, finalValue)
                end
            elseif type(editMode) == "number" then
                dbg("EDIT-SAVE-BUTTON",
                    "button=", tostring(editMode),
                    "newValue=", tostring(v)
                )
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
        dbg("EDIT-ESCAPE")
        self:SetText("")
        self:ClearFocus()
        self:Hide()
        editMode = nil
    end)

    editBox = eb
    panel   = f
    f:SetSize(totalWidth, padding + btnHeight + padding)

    dbg("CREATE-PANEL", "done", "width=", tostring(totalWidth))
    return f
end

-- ============================================================================
-- OnUpdate: управление видимостью кнопки и панели
-- ============================================================================
local hoverFrame = CreateFrame("Frame")
hoverFrame:SetScript("OnUpdate", function()
    if not TargetFrame then return end

    local btn = targetBtn or CreateTargetBtn()

    if panel and panel:IsShown() then
        if gpDb.targetButtonMode == "hover" then
            local btnHover = btn:IsMouseOver()
                or (TargetFrame:IsMouseOver() and UnitIsPlayer("target"))
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
        and (TargetFrame:IsMouseOver() or btn:IsMouseOver())

    if show then
        btn:Show()
    else
        btn:Hide()
    end
end)

-- ============================================================================
-- Восстановление позиции при логине
-- ============================================================================
local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_LOGIN")
restoreFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    dbg("PLAYER-LOGIN", "restoring button position")
    if not TargetFrame then
        dbg("PLAYER-LOGIN", "TargetFrame not available yet")
        return
    end
    ApplyButtonPos(CreateTargetBtn())
    dbg("PLAYER-LOGIN", "button position restored")
end)

-- ============================================================================
-- Слэш-команда для отладки
-- ============================================================================
SLASH_NSQC4TGP1 = "/tgpd"
SlashCmdList["NSQC4TGP"] = function()
    local newState = not (
        (NSQC4.GPDebug and NSQC4.GPDebug.enabled) or debugEnabled
    )
    NSQC4.GPDebug = NSQC4.GPDebug or {}
    NSQC4.GPDebug.enabled = newState
    NSQC4.TargetGP.SetDebug(newState)
    print(
        "|cff00ffff[NSQC4 TargetGP]|r debug=",
        tostring(newState)
    )
end

dbg("MODULE-LOADED", "GP/TargetGP.lua loaded")

end)