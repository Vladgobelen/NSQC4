-- ============================================================================
-- NSQC4 / Core / MinimapIcon
-- ============================================================================

NSQC4 = NSQC4 or {}

local ICON_TEXTURE = "Interface\\AddOns\\NSQC4\\Media\\Addon\\emblem.tga"
local ICON_SIZE    = 32
local ICON_RADIUS  = 80

-- Цвета тултипа (как в NSQC3)
local TOOLTIP_COLOR_TITLE   = "|cFF6495EDNSQC4|cFF808080-|r"
local TOOLTIP_COLOR_VERSION = "|cff00BFFF"
local TOOLTIP_COLOR_LATEST  = "|cFF6495EDАктуальная: |r"
local TOOLTIP_COLOR_UNKNOWN = "|cFF6495EDАктуальная: |cffff0000Неизвестно|r"
local TOOLTIP_COLOR_HINT    = "|cff808080"

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

    -- Читаем сохранённую позицию из nsDbc4
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
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if NSAuk and NSAuk.CreateSettingsWindow then
                NSAuk.CreateSettingsWindow()
            else
                print("|cff00ff00[NSQC4]|r ЛКМ — окно ещё не реализовано.")
            end
        elseif button == "RightButton" then
            if NSQC4.Settings and NSQC4.Settings.OpenPanel then
                NSQC4.Settings.OpenPanel()
            end
        elseif button == "MiddleButton" then
            print("|cff00ff00[NSQC4]|r СКМ — гильдбанк (не реализовано).")
        end
    end)

    -- Тултип
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")

        -- Заголовок
        local verText = ""
        if NSQC4_VERSION then
            verText = TOOLTIP_COLOR_VERSION .. NSQC4_VERSION.major .. "." .. NSQC4_VERSION.minor
        end
        GameTooltip:AddLine(TOOLTIP_COLOR_TITLE .. TOOLTIP_COLOR_VERSION .. (NSQC4_VERSION and (NSQC4_VERSION.major .. "." .. NSQC4_VERSION.minor) or "?"))

        -- Актуальная версия
        if NSQC4_LAST_VERSION then
            GameTooltip:AddLine(TOOLTIP_COLOR_LATEST .. TOOLTIP_COLOR_VERSION .. NSQC4_LAST_VERSION.major .. "." .. NSQC4_LAST_VERSION.minor)
        else
            GameTooltip:AddLine(TOOLTIP_COLOR_UNKNOWN)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(TOOLTIP_COLOR_HINT .. "ЛКМ — открыть окно")
        GameTooltip:AddLine(TOOLTIP_COLOR_HINT .. "ПКМ — настройки")
        GameTooltip:AddLine(TOOLTIP_COLOR_HINT .. "СКМ — гильдбанк")
        GameTooltip:AddLine(TOOLTIP_COLOR_HINT .. "Перетащить — тащить мышью")
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

        -- Сохраняем позицию в nsDbc4.minimap
        nsDbc4.minimap = nsDbc4.minimap or {}
        nsDbc4.minimap.x = ICON_RADIUS * math.cos(angle)
        nsDbc4.minimap.y = ICON_RADIUS * math.sin(angle)
    end)

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