-- ============================================================================
-- NSQC4 / Interface / WorldMap
-- Управление картой мира: ПКМ — перемещение, СКМ — масштаб. Модуль "ui_map".
-- ============================================================================

NSQC4 = NSQC4 or {}

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("ui_map") then return end

    local hooked = false

    -- ========================================================================
    -- Хук на кнопку закрытия карты (через HookScript — не ломает Blizzard)
    -- ========================================================================
    local function HookWorldMapCloseButton()
        local btn = WorldMapFrameCloseButton
        if not btn then return false end
        if hooked then return true end

        hooked = true

        -- Регистрируем ПКМ и СКМ (Blizzard уже зарегистрировал ЛКМ)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

        -- === Тултип через HookScript (не затираем Blizzard'овский) ===
        btn:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 10)
            GameTooltip:AddLine("Управление картой мира:", 1, 1, 0)
            GameTooltip:AddLine("• ЛКМ — закрыть карту", 1, 1, 1)
            GameTooltip:AddLine("• ПКМ — активировать перемещение", 1, 1, 1)
            GameTooltip:AddLine("• Колесо — выбрать масштаб", 1, 1, 1)
            GameTooltip:Show()
        end)

        btn:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- === Масштабы ===
        local scaleSteps = { 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0 }
        local currentScaleIndex = 6

        local dropdown = CreateFrame("Frame", "NSQC4WorldMapScaleDropdown", UIParent, "UIDropDownMenuTemplate")
        dropdown.displayMode = "MENU"

        local function OnScaleSelected(self)
            local w = WorldMapFrame
            if not w then return end
            currentScaleIndex = self.value
            w:SetScale(scaleSteps[currentScaleIndex])
            CloseDropDownMenus()
        end

        local function InitializeScaleMenu(_, level)
            for i, scale in ipairs(scaleSteps) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = math.floor(scale * 100) .. "%"
                info.value = i
                info.func = OnScaleSelected
                info.checked = (i == currentScaleIndex)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(dropdown, InitializeScaleMenu, "MENU")

        -- === HookScript на OnClick — не затирает Blizzard'овский ===
        btn:HookScript("OnClick", function(self, button)
            local w = WorldMapFrame
            if not w then return end

            if button == "RightButton" then
                w:SetMovable(true)
                w:EnableMouse(true)
                w:SetClampedToScreen(true)
                w:HookScript("OnMouseDown", function(frame, btn)
                    if btn == "LeftButton" then frame:StartMoving() end
                end)
                w:HookScript("OnMouseUp", function(frame, btn)
                    if btn == "LeftButton" then frame:StopMovingOrSizing() end
                end)

            elseif button == "MiddleButton" then
                ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)

            -- ЛКМ — Blizzard сам обработает (закроет карту)
            end
        end)

        return true
    end

    -- ========================================================================
    -- Инициализация: ждём, пока кнопка появится
    -- ========================================================================
    if not HookWorldMapCloseButton() then
        local waitFrame = CreateFrame("Frame")
        waitFrame:SetScript("OnUpdate", function(self)
            if HookWorldMapCloseButton() then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)