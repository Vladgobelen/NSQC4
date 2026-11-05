-- ============================================================================
-- NSQC4 / Quests / df / Floors / UI
-- Две кнопки «вверх/вниз» на 50 пикселей ниже иконки закрытия (closeBtn).
--
-- Кнопка «вниз»: переключить на этаж current - 1.
-- Кнопка «вверх»: переключить на этаж current + 1.
-- Обе серые, если CanSwitch(to) = false.
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

    local function RefreshButtons()
        local up   = QuestsField._floorUpBtn
        local down = QuestsField._floorDownBtn
        if not up or not down then return end

        local cur = Floors:Get()

        -- вверх: cur + 1
        local canUp = Floors:CanSwitch(cur + 1) and true or false
        if canUp then up:Enable() else up:Disable() end
        up:SetAlpha(canUp and 1 or 0.4)

        -- вниз: cur - 1
        local canDown = Floors:CanSwitch(cur - 1) and true or false
        if canDown then down:Enable() else down:Disable() end
        down:SetAlpha(canDown and 1 or 0.4)
    end

    local function CreateButtons()
        local f = QuestsField.frame
        local closeBtn = QuestsField.closeBtn
        if not f or not closeBtn then return end
        if QuestsField._floorUpBtn then return end

        local up = CreateFrame("Button", "NSQC4FloorUp", f)
        up:SetSize(BTN_SIZE, BTN_SIZE)
        up:SetPoint("TOPRIGHT", closeBtn, "BOTTOMRIGHT", 0, OFFSET_Y)
        up:SetFrameLevel(f:GetFrameLevel() + 30)
        up:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        up:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
        up:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        up:SetScript("OnClick", function()
            Floors:Switch(Floors:Get() + 1)
            RefreshButtons()
        end)
        up:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Этаж вверх")
            GameTooltip:AddLine("Текущий: " .. Floors:Get(), 1, 1, 0)
            local ok, reason = Floors:CanSwitch(Floors:Get() + 1)
            if not ok then
                GameTooltip:AddLine(tostring(reason), 1, 0.3, 0.3)
            end
            GameTooltip:Show()
        end)
        up:SetScript("OnLeave", function() GameTooltip:Hide() end)
        QuestsField._floorUpBtn = up

        local down = CreateFrame("Button", "NSQC4FloorDown", f)
        down:SetSize(BTN_SIZE, BTN_SIZE)
        down:SetPoint("TOPRIGHT", up, "BOTTOMRIGHT", 0, -BTN_GAP)
        down:SetFrameLevel(f:GetFrameLevel() + 30)
        down:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        down:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        down:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        down:SetScript("OnClick", function()
            Floors:Switch(Floors:Get() - 1)
            RefreshButtons()
        end)
        down:SetScript("OnEnter", function(self2)
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Этаж вниз")
            GameTooltip:AddLine("Текущий: " .. Floors:Get(), 1, 1, 0)
            local ok, reason = Floors:CanSwitch(Floors:Get() - 1)
            if not ok then
                GameTooltip:AddLine(tostring(reason), 1, 0.3, 0.3)
            end
            GameTooltip:Show()
        end)
        down:SetScript("OnLeave", function() GameTooltip:Hide() end)
        QuestsField._floorDownBtn = down

        RefreshButtons()
    end

    -- Пытаемся создать кнопки после того, как поле создаст closeBtn.
    -- Хук на EnsureFrame (если closeBtn уже есть — создаём сразу).
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