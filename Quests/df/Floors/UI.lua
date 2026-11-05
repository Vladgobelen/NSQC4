-- ============================================================================
-- NSQC4 / Quests / df / Floors / UI
-- Две кнопки «вверх/вниз» на 50 пикселей ниже иконки закрытия (closeBtn).
--
-- ЛОГИКА:
--   «Вверх» (up):
--     - если current == 0 → QuestsField:ToggleOverview() (уменьшить масштаб)
--     - иначе            → Floors:Switch(current + 1)
--   «Вниз» (down):
--     - если overview    → QuestsField:HideOverview() (вернуться в detail)
--     - иначе            → Floors:Switch(current - 1)
--
-- В overview кнопки всегда включены (CanSwitch не применяется — это не
-- этаж, а режим отображения). В detail «вверх» на 0 всегда включена
-- (переход в overview), «вниз» — по CanSwitch.
--
-- Кнопки пересоздаются при каждом EnsureFrame (если closeBtn есть).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Floors = NSQC4.QuestsDfFloors
    if not Floors then
        print("|cffff0000[NSQC4]|r Floors/UI: Init.lua не загружен.")
        return
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Floors/UI: поле не загружено.")
        return
    end

    local BTN_SIZE  = 24
    local BTN_GAP   = 2
    local OFFSET_Y  = -50     -- на 50 пикселей ниже closeBtn

    -- ========================================================================
    -- Есть ли Overview (модуль загружен и метод доступен)
    -- ========================================================================
    local function HasOverview()
        return QuestsField.ToggleOverview ~= nil
            and QuestsField.HideOverview   ~= nil
            and QuestsField.IsOverview     ~= nil
    end

    local function IsOverview()
        if not HasOverview() then return false end
        return QuestsField:IsOverview()
    end

    -- ========================================================================
    -- Обновить серость/включённость кнопок
    -- ========================================================================
    local function RefreshButtons()
        local up   = QuestsField._floorUpBtn
        local down = QuestsField._floorDownBtn
        if not up or not down then return end

        local cur = Floors:Get()
        local inOverview = IsOverview()

        -- В overview: обе кнопки включены (возврат в detail)
        if inOverview then
            up:Enable()
            down:Enable()
            up:SetAlpha(1)
            down:SetAlpha(1)
            return
        end

        -- В detail:
        -- «вверх»: на 0 — всегда включена (переход в overview);
        --         иначе — по CanSwitch(cur + 1)
        local canUp
        if cur == 0 then
            canUp = HasOverview()   -- включена, если Overview загружен
        else
            canUp = Floors:CanSwitch(cur + 1) and true or false
        end
        if canUp then up:Enable() else up:Disable() end
        up:SetAlpha(canUp and 1 or 0.4)

        -- «вниз»: по CanSwitch(cur - 1)
        local canDown = Floors:CanSwitch(cur - 1) and true or false
        if canDown then down:Enable() else down:Disable() end
        down:SetAlpha(canDown and 1 or 0.4)
    end

    -- ========================================================================
    -- Создать кнопки (один раз)
    -- ========================================================================
    local function CreateButtons()
        local f = QuestsField.frame
        local closeBtn = QuestsField.closeBtn
        if not f or not closeBtn then return end
        if QuestsField._floorUpBtn then return end

        -- ====================================================================
        -- «Вверх»
        -- ====================================================================
        local up = CreateFrame("Button", "NSQC4FloorUp", f)
        up:SetSize(BTN_SIZE, BTN_SIZE)
        up:SetPoint("TOPRIGHT", closeBtn, "BOTTOMRIGHT", 0, OFFSET_Y)
        up:SetFrameLevel(f:GetFrameLevel() + 30)
        up:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        up:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        up:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        up:SetScript("OnClick", function()
            local cur = Floors:Get()
            if cur == 0 then
                -- 0 → overview (уменьшить масштаб)
                if HasOverview() then
                    QuestsField:ToggleOverview()
                end
            else
                -- обычный переход вверх
                Floors:Switch(cur + 1)
            end
            RefreshButtons()
        end)
        up:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            local cur = Floors:Get()
            if IsOverview() then
                GameTooltip:AddLine("Вернуться к детальному виду")
            elseif cur == 0 then
                GameTooltip:AddLine("Обзор (уменьшить масштаб)")
                if not HasOverview() then
                    GameTooltip:AddLine("Overview не загружен", 1, 0.3, 0.3)
                end
            else
                GameTooltip:AddLine("Этаж вверх")
                GameTooltip:AddLine("Текущий: " .. cur, 1, 1, 0)
                local ok, reason = Floors:CanSwitch(cur + 1)
                if not ok then
                    GameTooltip:AddLine(tostring(reason), 1, 0.3, 0.3)
                end
            end
            GameTooltip:Show()
        end)
        up:SetScript("OnLeave", function() GameTooltip:Hide() end)
        QuestsField._floorUpBtn = up

        -- ====================================================================
        -- «Вниз»
        -- ====================================================================
        local down = CreateFrame("Button", "NSQC4FloorDown", f)
        down:SetSize(BTN_SIZE, BTN_SIZE)
        down:SetPoint("TOPRIGHT", up, "BOTTOMRIGHT", 0, -BTN_GAP)
        down:SetFrameLevel(f:GetFrameLevel() + 30)
        down:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        down:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        down:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        down:SetScript("OnClick", function()
            if IsOverview() then
                -- overview → detail
                QuestsField:HideOverview()
            else
                Floors:Switch(Floors:Get() - 1)
            end
            RefreshButtons()
        end)
        down:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            if IsOverview() then
                GameTooltip:AddLine("Вернуться к детальному виду")
            else
                local cur = Floors:Get()
                GameTooltip:AddLine("Этаж вниз")
                GameTooltip:AddLine("Текущий: " .. cur, 1, 1, 0)
                local ok, reason = Floors:CanSwitch(cur - 1)
                if not ok then
                    GameTooltip:AddLine(tostring(reason), 1, 0.3, 0.3)
                end
            end
            GameTooltip:Show()
        end)
        down:SetScript("OnLeave", function() GameTooltip:Hide() end)
        QuestsField._floorDownBtn = down

        RefreshButtons()
    end

    -- ========================================================================
    -- Хук на EnsureFrame: как только поле создало closeBtn — создать кнопки
    -- ========================================================================
    local origEnsureFrame = QuestsField.EnsureFrame
    if origEnsureFrame then
        QuestsField.EnsureFrame = function(self, ...)
            local f = origEnsureFrame(self, ...)
            if self.closeBtn then
                CreateButtons()
            end
            return f
        end
    end

    -- Если поле уже создано — создать кнопки сейчас
    if QuestsField.closeBtn then
        CreateButtons()
    end

    -- Экспорт для обновления извне
    QuestsField.RefreshFloorButtons = RefreshButtons

end)