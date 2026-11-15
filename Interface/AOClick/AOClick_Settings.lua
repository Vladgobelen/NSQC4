-- ============================================================================
-- NSQC4 / Interface / AOClick / Settings
-- Модуль ui_ao: окно настроек hideLevel/hideGP/hideRep.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local A = NSQC4.AOClick
    if not A then return end

    local aoSettings = A.aoSettings
    local settingsFrame

    local function OpenAOClickSettings()
        if not settingsFrame then
            local f = CreateFrame("Frame", "NSQC4AOClickSettings", UIParent)
            f:SetSize(400, 260)
            f:SetPoint("CENTER")
            f:SetFrameStrata("TOOLTIP")
            f:SetToplevel(true)
            f:SetFrameLevel(100)
            f:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            f:SetBackdropColor(0, 0, 0, 1)
            f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local t = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            t:SetPoint("TOPLEFT", 12, -12)
            t:SetText("Настройки: Ссылки АО")

            local function mkCB(y, key, text)
                local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
                cb:SetPoint("TOPLEFT", 12, y)
                cb:SetSize(24, 24)
                local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
                fs:SetText(text)
                cb:SetChecked(aoSettings[key] and true or false)
                cb:SetScript("OnClick", function(self)
                    aoSettings[key] = self:GetChecked() and true or false
                end)
                return cb
            end

            mkCB(-42,  "hideLevel", "Скрыть уровень")
            mkCB(-70,  "hideGP",    "Скрыть ГП")
            mkCB(-98,  "hideRep",   "Скрыть репу")

            local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            close:SetSize(100, 24)
            close:SetPoint("BOTTOMRIGHT", -10, 10)
            close:SetText("Закрыть")
            close:SetScript("OnClick", function() f:Hide() end)

            f:SetMovable(true)
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", f.StartMoving)
            f:SetScript("OnDragStop",  f.StopMovingOrSizing)

            settingsFrame = f
        end
        settingsFrame:SetFrameStrata("TOOLTIP")
        settingsFrame:Show()
        settingsFrame:Raise()
    end
    A.OpenAOClickSettings = OpenAOClickSettings

    if NSQC4.RegisterModuleSettings then
        NSQC4.RegisterModuleSettings("ui_ao", OpenAOClickSettings)
    end

end)