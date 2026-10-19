-- ============================================================================
-- NSQC4 / Core / SlashPanel
-- ============================================================================

NSQC4 = NSQC4 or {}

NSQC4.SlashPanel_Buttons = NSQC4.SlashPanel_Buttons or {}
NSQC4.SlashPanel_Sections = NSQC4.SlashPanel_Sections or {}

local panel
local panelReady = false
local RebuildButtons

-- ============================================================================
-- Создание панели
-- ============================================================================
local function EnsurePanel()
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
    panel.rows = {}
    panelReady = true
end

-- ============================================================================
-- Создание кнопки
-- ============================================================================
local function CreateButton(parent, entry, index, rowY)
    local BTN_SIZE = 24
    local GAP      = 4
    local PADDING  = 4

    local btn = CreateFrame("Button", "NSQC4SlashBtn_" .. (parent:GetName() or "x") .. "_" .. index, parent, "UIPanelButtonTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    btn:SetPoint("LEFT", parent, "LEFT", PADDING + (index - 1) * (BTN_SIZE + GAP), rowY)
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

    return btn
end

-- ============================================================================
-- Перестроение кнопок
-- ============================================================================
RebuildButtons = function()
    if not panelReady or not panel then return end

    -- Очистка старых кнопок и рядов
    for _, btn in ipairs(panel.buttons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    panel.buttons = {}

    for _, row in ipairs(panel.rows) do
        row:Hide()
        row:SetParent(nil)
    end
    panel.rows = {}

    local BTN_SIZE = 24
    local GAP      = 4
    local PADDING  = 4
    local ROW_GAP  = 4

    local maxWidth = 0
    local totalHeight = PADDING

    -- ========================================================================
    -- 1. Первый ярус: общие кнопки (NSQC4.SlashPanel_Buttons)
    -- ========================================================================
    local list = NSQC4.SlashPanel_Buttons
    if #list > 0 then
        local row1 = CreateFrame("Frame", "NSQC4SlashRow_Top", panel)
        row1:SetSize(1, BTN_SIZE)
        row1:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -PADDING)
        table.insert(panel.rows, row1)

        local totalW = PADDING
        for i, entry in ipairs(list) do
            local btn = CreateButton(row1, entry, i, 0)
            table.insert(panel.buttons, btn)
            totalW = totalW + BTN_SIZE + GAP
        end
        totalW = totalW - GAP + PADDING
        row1:SetWidth(totalW)
        if totalW > maxWidth then maxWidth = totalW end
        totalHeight = totalHeight + BTN_SIZE + ROW_GAP
    end

    -- ========================================================================
    -- 2. Второй ярус: разделы (NSQC4.SlashPanel_Sections)
    -- ========================================================================
    for sectionName, section in pairs(NSQC4.SlashPanel_Sections) do
        local buttons = section.buttons
        if buttons and #buttons > 0 then
            local row = CreateFrame("Frame", "NSQC4SlashRow_" .. sectionName, panel)
            row:SetSize(1, BTN_SIZE)
            row:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -totalHeight)
            table.insert(panel.rows, row)

            local totalW = PADDING
            for i, entry in ipairs(buttons) do
                local btn = CreateButton(row, entry, i, 0)
                table.insert(panel.buttons, btn)
                totalW = totalW + BTN_SIZE + GAP
            end
            totalW = totalW - GAP + PADDING
            row:SetWidth(totalW)
            if totalW > maxWidth then maxWidth = totalW end
            totalHeight = totalHeight + BTN_SIZE + ROW_GAP
        end
    end

    -- ========================================================================
    -- Размер панели
    -- ========================================================================
    if maxWidth > 0 then
        panel:SetSize(maxWidth + PADDING, totalHeight + PADDING)
    else
        panel:SetSize(1, 1)
    end
end

-- ============================================================================
-- Регистрация кнопки в общий ряд
-- ============================================================================
function NSQC4.SlashPanel_RegisterButton(label, cmd, desc, callback)
    table.insert(NSQC4.SlashPanel_Buttons, {
        label = label, cmd = cmd, desc = desc, callback = callback,
    })
    RebuildButtons()
end

-- ============================================================================
-- Регистрация кнопки в раздел
-- ============================================================================
function NSQC4.SlashPanel_RegisterSectionButton(sectionName, label, cmd, desc, callback)
    NSQC4.SlashPanel_Sections[sectionName] = NSQC4.SlashPanel_Sections[sectionName] or {
        buttons = {},
    }
    table.insert(NSQC4.SlashPanel_Sections[sectionName].buttons, {
        label = label, cmd = cmd, desc = desc, callback = callback,
    })
    RebuildButtons()
end

function NSQC4.SlashPanel_ClearButtons()
    NSQC4.SlashPanel_Buttons = {}
    NSQC4.SlashPanel_Sections = {}
    RebuildButtons()
end

-- ============================================================================
-- Toggle
-- ============================================================================
function NSQC4.SlashPanel_Toggle()
    EnsurePanel()
    RebuildButtons()
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
    self:UnregisterEvent("PLAYER_LOGIN")
    EnsurePanel()
    RebuildButtons()
end)

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneFrame:SetScript("OnEvent", function()
    if panel then panel:Hide() end
end)