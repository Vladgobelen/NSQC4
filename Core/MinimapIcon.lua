-- ============================================================================
-- NSQC4 / Core / MinimapIcon
-- Иконка аддона у миникарты.
-- ЛКМ — панель слэш-команд.
-- Двойной ЛКМ — окно ГП.
-- ПКМ — настройки аддона.
-- СКМ — управление списком алертов.
-- ============================================================================

NSQC4 = NSQC4 or {}

local ICON_TEXTURE = "Interface\\AddOns\\NSQC4\\Media\\Addon\\emblem.tga"
local ICON_SIZE    = 32
local ICON_RADIUS  = 80

-- Цвета тултипа
local TOOLTIP_COLOR_TITLE   = "|cFF6495EDNSQC4|cFF808080-|r"
local TOOLTIP_COLOR_VERSION = "|cff00BFFF"
local TOOLTIP_COLOR_LATEST  = "|cFF6495EDАктуальная версия: |r"
local TOOLTIP_COLOR_UNKNOWN = "|cFF6495EDАктуальная версия: |cffff0000Неизвестно|r"

-- ============================================================================
-- Двойной клик — переменные состояния
-- ============================================================================
local lastClickTime   = 0
local lastClickButton = nil
local clickPending    = false

-- ============================================================================
-- Обработка одинарного клика
-- ============================================================================
local function HandleSingleClick(button)
    if button == "RightButton" then
        if NSQC4.Settings and NSQC4.Settings.OpenPanel then
            NSQC4.Settings.OpenPanel()
        end
    elseif button == "LeftButton" then
        -- ЛКМ — открыть/закрыть панель слэш-команд
        if NSQC4.SlashPanel_Toggle then
            NSQC4.SlashPanel_Toggle()
        end
    elseif button == "MiddleButton" then
        -- СКМ — окно управления списком алертов
        if NSQC4.ListUI_Show then
            NSQC4.ListUI_Show()
        end
    end
end

-- ============================================================================
-- Обработка двойного клика
-- ============================================================================
local function HandleDoubleClick(button)
    if button == "LeftButton" then
        -- Двойной ЛКМ — окно ГП
        local target = nil
        if gpDb_old and gpDb_old.Show then
            target = gpDb_old
        elseif gpDb and gpDb.Show then
            target = gpDb
        elseif NSQC4.gpDb and NSQC4.gpDb.Show then
            target = NSQC4.gpDb
        end

        if target then
            target:Show()
        else
            print("|cff808080[NSQC4]|r Окно ГП недоступно.")
        end
    end
end

-- ============================================================================
-- Фрейм-таймер (один на всю иконку)
-- ============================================================================
local ClickTimerFrame = CreateFrame("Frame")
ClickTimerFrame:Hide()
ClickTimerFrame.elapsed = 0
ClickTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    if not clickPending then return end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 0.3 then
        self.elapsed = 0
        self:Hide()
        clickPending = false
        HandleSingleClick(lastClickButton)
    end
end)

-- ============================================================================
-- Сброс состояния клика
-- ============================================================================
local function ResetClickState()
    lastClickTime   = 0
    lastClickButton = nil
    clickPending    = false
    if ClickTimerFrame then
        ClickTimerFrame.elapsed = 0
        ClickTimerFrame:Hide()
    end
end

-- ============================================================================
-- Обработчик кликов
-- ============================================================================
local function OnMinimapClick(self, button)
    local now = GetTime()

    if clickPending
        and (now - lastClickTime < 0.3)
        and (button == lastClickButton)
    then
        -- Двойной клик
        clickPending = false
        ClickTimerFrame.elapsed = 0
        ClickTimerFrame:Hide()
        HandleDoubleClick(button)
    else
        -- Первый клик
        clickPending = true
        lastClickTime = now
        lastClickButton = button
        ClickTimerFrame.elapsed = 0
        ClickTimerFrame:Show()
    end
end

-- ============================================================================
-- Создание кнопки
-- ============================================================================
local function CreateMinimapButton()
    local btn = CreateFrame("Button", "NSQC4MinimapButton", Minimap)
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn:SetFrameLevel(8)
    btn:SetMovable(true)

    btn:SetNormalTexture(ICON_TEXTURE)
    btn:SetPushedTexture(ICON_TEXTURE)
    btn:SetHighlightTexture(ICON_TEXTURE)

    -- Позиция из nsDbc4
    nsDbc4 = nsDbc4 or {}
    nsDbc4.minimap = nsDbc4.minimap or {}

    local angle
    if nsDbc4.minimap.x and nsDbc4.minimap.y then
        angle = math.atan2(nsDbc4.minimap.y, nsDbc4.minimap.x)
    else
        angle = math.rad(45)
    end

    local function UpdatePosition()
        local x = ICON_RADIUS * math.cos(angle)
        local y = ICON_RADIUS * math.sin(angle)
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    UpdatePosition()

    -- Клики
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    btn:SetScript("OnClick", OnMinimapClick)

    -- Тултип
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")

        local ver = NSQC4_VERSION and (NSQC4_VERSION.major .. "." .. NSQC4_VERSION.minor) or "?"
        GameTooltip:AddLine(TOOLTIP_COLOR_TITLE .. TOOLTIP_COLOR_VERSION .. ver ..
            " |cffbbbbbbОЗУ: |cff00BFFF" ..
            string.format("%.0f", GetAddOnMemoryUsage("NSQC4")) .. " |cffbbbbbbкб")

        if NSQC4_LAST_VERSION then
            GameTooltip:AddLine(TOOLTIP_COLOR_LATEST .. TOOLTIP_COLOR_VERSION ..
                NSQC4_LAST_VERSION.major .. "." .. NSQC4_LAST_VERSION.minor)
        else
            GameTooltip:AddLine(TOOLTIP_COLOR_UNKNOWN)
        end

        -- Илвл (если модуль включён)
        if NSQC4.Settings.IsModuleEnabled("itemlevel")
            and NSQC4.BS and NSQC4.BS.GetAverageItemLevel
        then
            GameTooltip:AddLine("|cFF6495EDСредний уровень предметов: |cff00BFFF" ..
                NSQC4.BS.GetAverageItemLevel("player"))
        end

        -- ГС (если аддон GS_Data есть)
        local myName = UnitName("player")
        if GS_Data and GS_Data[GetRealmName()]
            and GS_Data[GetRealmName()].Players[myName]
        then
            GameTooltip:AddLine("|cFF6495EDGearScore: |cff00BFFF" ..
                GS_Data[GetRealmName()].Players[myName].GearScore)
        end

        -- ГП из третьего слова офицерской заметки
        local gp = "0"
        for i = 1, GetNumGuildMembers() do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
            if name then
                name = name:gsub("%-.+", "")
                if name == myName then
                    local words = {}
                    for w in (officerNote or ""):gmatch("%S+") do
                        table.insert(words, w)
                    end
                    if #words >= 3 then gp = words[3] end
                    break
                end
            end
        end
        GameTooltip:AddLine("|cFF6495EDГП: |cff00BFFF" .. gp)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFF8C00ЛКМ|r — панель слэш-команд")
        GameTooltip:AddLine("|cffFF8C00ЛКМ×2|r — открыть окно ГП")
        GameTooltip:AddLine("|cffF4A460ПКМ|r — настройки аддона")
        GameTooltip:AddLine("|cff32CD32СКМ|r — управление списком алертов")
        GameTooltip:AddLine("|cff808080Shift+ЛКМ|r — перетащить иконку")

        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Перетаскивание
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:SetAlpha(0.5)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            angle = math.atan2(cy - my, cx - mx)
            UpdatePosition()
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:SetAlpha(1)

        nsDbc4.minimap = nsDbc4.minimap or {}
        nsDbc4.minimap.x = ICON_RADIUS * math.cos(angle)
        nsDbc4.minimap.y = ICON_RADIUS * math.sin(angle)
    end)

    -- Сброс клика при скрытии
    btn:SetScript("OnHide", ResetClickState)

    return btn
end

-- ============================================================================
-- Инициализация
-- ============================================================================
function NSQC4.InitMinimapIcon()
    if NSQC4.minimapButton then return end
    NSQC4.minimapButton = CreateMinimapButton()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    NSQC4.InitMinimapIcon()
end)