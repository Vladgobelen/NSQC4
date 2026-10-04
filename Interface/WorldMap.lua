-- ============================================================================
-- NSQC4 / Interface / WorldMap
-- Управление картой мира: ПКМ — перемещение, СКМ — масштаб. Модуль "ui_map".
-- ============================================================================

NSQC4.RegisterModule("ui_map", function()

    -- ========================================================================
    -- Шаги масштаба
    -- ========================================================================
    local scaleSteps = { 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0 }
    local currentScaleIndex = 6   -- 100%

    -- ========================================================================
    -- Меню масштаба
    -- ========================================================================
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

    -- ========================================================================
    -- Хук на кнопку закрытия карты
    -- ========================================================================
    local function HookCloseButton()
        local btn = WorldMapFrameCloseButton
        if not btn then return false end
        if btn.nsQC4Hooked then return true end
        btn.nsQC4Hooked = true

        -- Регистрируем ПКМ и СКМ (ЛКМ уже зарегистрирован Blizzard'ом)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

        -- Сохраняем Blizzard'овский OnClick
        local oldOnClick = btn:GetScript("OnClick")

        -- Перезаписываем своим
        btn:SetScript("OnClick", function(self, button)
            -- ПКМ — активируем перемещение карты
            if button == "RightButton" then
                local w = WorldMapFrame
                if not w then return end
                w:SetMovable(true)
                w:EnableMouse(true)
                w:SetClampedToScreen(true)
                w:SetScript("OnMouseDown", function(frame, b)
                    if b == "LeftButton" then frame:StartMoving() end
                end)
                w:SetScript("OnMouseUp", function(frame, b)
                    if b == "LeftButton" then frame:StopMovingOrSizing() end
                end)
                print("|cff00ff00[NSQC4]|r Перемещение карты активировано (ЛКМ — тащить).")
                return
            end

            -- СКМ — меню масштаба
            if button == "MiddleButton" then
                ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
                return
            end

            -- ЛКМ — вызываем Blizzard'овский обработчик (закрытие карты)
            if type(oldOnClick) == "function" then
                oldOnClick(self, button)
            else
                HideUIPanel(WorldMapFrame)
            end
        end)

        -- Тултип
        btn:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 10)
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Управление картой:", 1, 1, 0)
            GameTooltip:AddLine("• ЛКМ — закрыть", 1, 1, 1)
            GameTooltip:AddLine("• ПКМ — перемещение", 1, 1, 1)
            GameTooltip:AddLine("• СКМ — масштаб", 1, 1, 1)
            GameTooltip:Show()
        end)

        btn:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return true
    end

    -- ========================================================================
    -- Триггерная инициализация: сразу, если кнопка есть;
    -- иначе — один раз на PLAYER_ENTERING_WORLD.
    -- ========================================================================
    if not HookCloseButton() then
        local ev = CreateFrame("Frame")
        ev:RegisterEvent("PLAYER_ENTERING_WORLD")
        ev:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            HookCloseButton()
        end)
    end
end)