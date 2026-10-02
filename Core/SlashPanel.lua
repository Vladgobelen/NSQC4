-- ============================================================================
-- NSQC4 / Core / SlashPanel
-- Горизонтальная панель компактных квадратных кнопок слева от иконки аддона.
-- ЛКМ по иконке — открыть/закрыть. Модуль "ui_slashpanel".
-- ============================================================================

NSQC4 = NSQC4 or {}

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("ui_slashpanel") then return end

    local waitFrame = CreateFrame("Frame")
    waitFrame:SetScript("OnUpdate", function(self)
        if NSQC4.minimapButton then
            self:SetScript("OnUpdate", nil)
            self:Hide()

            local icon = NSQC4.minimapButton

            -- ================================================================
            -- Панель
            -- ================================================================
            local panel = CreateFrame("Frame", "NSQC4SlashPanel", UIParent)
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
            panel:Hide()

            local BTN_SIZE = 24      -- квадратные компактные
            local GAP      = 4
            local PADDING  = 4

            local totalW = 0

            for i, entry in ipairs(NSQC4.SlashCommands) do
                local btn = CreateFrame("Button", "NSQC4SlashBtn" .. i, panel, "UIPanelButtonTemplate")
                btn:SetSize(BTN_SIZE, BTN_SIZE)
                btn:SetPoint("LEFT", panel, "LEFT", PADDING + (i - 1) * (BTN_SIZE + GAP), 0)
                btn:SetText(entry.label)
                btn.entry = entry

                -- Компактный шрифт
                local fs = btn:GetFontString()
                if fs then
                    fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                end

                -- Клик — выполняем команду, закрываем панель
                btn:SetScript("OnClick", function(self)
                    local cmd = self.entry.cmd
                    local slash, args = cmd:match("^(%S+)%s*(.*)$")
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
                            ChatFrame_OpenChat(cmd, DEFAULT_CHAT_FRAME)
                        end
                    end
                    panel:Hide()
                end)

                -- Тултип
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:SetText(self.entry.desc or self.entry.label, 1, 0.82, 0)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cff808080" .. self.entry.cmd .. "|r", 0.6, 0.6, 0.6)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                totalW = totalW + BTN_SIZE + GAP
            end

            panel:SetSize(totalW - GAP + PADDING * 2, BTN_SIZE + PADDING * 2)

            -- ================================================================
            -- API
            -- ================================================================
            function NSQC4.SlashPanel_Toggle()
                if panel:IsShown() then
                    panel:Hide()
                else
                    panel:Show()
                end
            end

            function NSQC4.SlashPanel_Hide()
                panel:Hide()
            end

            function NSQC4.SlashPanel_IsShown()
                return panel:IsShown()
            end

            -- Скрытие при смене зоны
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_ENTERING_WORLD")
            f:SetScript("OnEvent", function()
                panel:Hide()
            end)
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)