-- ============================================================================
-- NSQC4 / Core / SlashPanel (ОТЛАДКА)
-- ============================================================================

NSQC4 = NSQC4 or {}

print("|cff00ffff[SlashPanel]|r файл загружается")

NSQC4.SlashPanel_Buttons = NSQC4.SlashPanel_Buttons or {}

local panel
local panelReady = false
local RebuildButtons   -- forward declaration

-- ============================================================================
-- Создание панели
-- ============================================================================
local function EnsurePanel()
    print("|cff00ffff[SlashPanel]|r EnsurePanel вызван")
    if panelReady then return end
    if not NSQC4.minimapButton then return end

    local icon = NSQC4.minimapButton

    panel = CreateFrame("Frame", "NSQC4SlashPanel", UIParent)
    panel:SetFrameStrata("TOOLTIP")
    panel:SetPoint("RIGHT", icon, "LEFT", -5, 0)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0, 0, 0, 0.85)
    panel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    panel:SetSize(1, 1)
    panel:Hide()

    panel.buttons = {}
    panelReady = true

    print("|cff00ff00[SlashPanel]|r панель СОЗДАНА")
end

-- ============================================================================
-- Перестроение кнопок
-- ============================================================================
RebuildButtons = function()
    print("|cff00ffff[SlashPanel]|r RebuildButtons")
    if not panelReady or not panel then
        print("  panelReady="..tostring(panelReady).." panel="..tostring(panel))
        return
    end

    for _, btn in ipairs(panel.buttons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    panel.buttons = {}

    local BTN_SIZE = 24
    local GAP      = 4
    local PADDING  = 4

    local list = NSQC4.SlashPanel_Buttons
    local totalW = 0

    print("  кнопок для создания:", #list)

    for i, entry in ipairs(list) do
        local btn = CreateFrame("Button", "NSQC4SlashBtn" .. i, panel, "UIPanelButtonTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetPoint("LEFT", panel, "LEFT", PADDING + (i - 1) * (BTN_SIZE + GAP), 0)
        btn:SetText(entry.label or "?")
        btn.entry = entry

        local fs = btn:GetFontString()
        if fs then
            fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        end

        btn:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            if type(e.callback) == "function" then
                e.callback()
            elseif e.cmd then
                local slash, args = e.cmd:match("^(%S+)%s*(.*)$")
                if slash then
                    local found = false
                    for name, handler in pairs(SlashCmdList) do
                        local s = _G["SLASH_" .. name .. "1"]
                        if s and s:lower() == slash:lower() then
                            handler(args or "")
                            found = true
                            break
                        end
                    end
                    if not found then
                        ChatFrame_OpenChat(e.cmd, DEFAULT_CHAT_FRAME)
                    end
                end
            end
            if panel then panel:Hide() end
        end)

        btn:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(e.desc or e.label or "?", 1, 0.82, 0)
            if e.cmd then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cff808080" .. e.cmd .. "|r", 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(panel.buttons, btn)
        totalW = totalW + BTN_SIZE + GAP
    end

    if #list > 0 then
        panel:SetSize(totalW - GAP + PADDING * 2, BTN_SIZE + PADDING * 2)
    else
        panel:SetSize(1, 1)
    end
    print("  панель размер:", panel:GetWidth(), "x", panel:GetHeight())
end

-- ============================================================================
-- Регистрация кнопки
-- ============================================================================
function NSQC4.SlashPanel_RegisterButton(label, cmd, desc, callback)
    print("|cff00ff00[SlashPanel]|r RegisterButton: "..tostring(label).." cmd="..tostring(cmd))
    table.insert(NSQC4.SlashPanel_Buttons, {
        label = label, cmd = cmd, desc = desc, callback = callback,
    })
    RebuildButtons()
end

function NSQC4.SlashPanel_ClearButtons()
    NSQC4.SlashPanel_Buttons = {}
    RebuildButtons()
end

-- ============================================================================
-- Toggle
-- ============================================================================
function NSQC4.SlashPanel_Toggle()
    print("|cff00ffff[SlashPanel]|r Toggle вызван")
    EnsurePanel()
    RebuildButtons()   -- всегда перестраиваем перед показом
    if not panel then return end
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

function NSQC4.SlashPanel_Hide()
    if panel then panel:Hide() end
end

function NSQC4.SlashPanel_IsShown()
    return panel and panel:IsShown()
end

-- ============================================================================
-- События
-- ============================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    print("|cff00ffff[SlashPanel]|r PLAYER_LOGIN")
    self:UnregisterEvent("PLAYER_LOGIN")
    EnsurePanel()
    RebuildButtons()
end)

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneFrame:SetScript("OnEvent", function()
    if panel then panel:Hide() end
end)

print("|cff00ff00[SlashPanel]|r файл загружен до конца")