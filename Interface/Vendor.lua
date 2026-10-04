-- ============================================================================
-- NSQC4 / Interface / Vendor
-- Быстрая покупка эмблем у вендора. Модуль "ui_vendor".
-- Работает для ЛЮБОГО вендора: сканирует окно торговли, находит эмблемы
-- (кроме Эмблемы льда и Эмблемы триумфа), рисует столбцы кнопок справа.
-- ============================================================================

NSQC4.RegisterModule("ui_vendor", function()

    local QUANTITIES = { 1, 5, 10, 50 }
    local IGNORE_PATTERNS = { "Эмблема льда", "Эмблема триумфа" }
    local COLUMN_WIDTH = 44
    local ROW_HEIGHT = 36
    local BUTTON_SIZE = 32

    -- Цепочка эмблем: что покупаем → чем платим
    local EMBLEM_CHAIN = {
        ["Эмблема завоевания"] = "Эмблема триумфа",
        ["Эмблема доблести"]   = "Эмблема завоевания",
        ["Эмблема героизма"]   = "Эмблема доблести",
    }

    local container
    local buttons = {}

    -- ========================================================================
    -- Сколько у нас валюты по имени
    -- ========================================================================
    local function GetCurrencyCount(emblemName)
        if not emblemName then return 0 end
        local size = GetCurrencyListSize and GetCurrencyListSize() or 0
        for i = 1, size do
            local name, _, _, _, _, count = GetCurrencyListInfo(i)
            if name and name:find(emblemName, 1, true) then
                return count or 0
            end
        end
        return 0
    end

    -- ========================================================================
    -- Тултип
    -- ========================================================================
    local function ShowButtonTooltip(btn, slot, quantity)
        local name = GetMerchantItemInfo(slot)
        if not name then return end

        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        local payment = EMBLEM_CHAIN[name]

        -- Что покупаем
        GameTooltip:AddLine("|cffFFD100" .. name .. "|r")

        if not payment then
            GameTooltip:AddLine("|cffBBBBBBКупить:|r |cffffffff" .. quantity .. "|r шт.")
            GameTooltip:Show()
            return
        end

        local have = GetCurrencyCount(payment)

        -- Чем платим
        GameTooltip:AddLine("|cffBBBBBBПотратится:|r |cffffffff" .. quantity .. "|r " .. payment)

        -- Сколько у нас
        if have >= quantity then
            GameTooltip:AddLine("|cffBBBBBBУ вас:|r |cff00FF00" .. have .. "|r " .. payment)
        else
            GameTooltip:AddLine("|cffBBBBBBУ вас:|r |cffff0000" .. have .. "|r " .. payment)
            GameTooltip:AddLine("|cffff0000Не хватает: " .. (quantity - have) .. "|r")
        end

        GameTooltip:Show()
    end

    -- ========================================================================
    -- Создание контейнера
    -- ========================================================================
    local function CreateContainer()
        if container then return container end
        container = CreateFrame("Frame", "NSQC4VendorContainer", MerchantFrame)
        container:SetPoint("LEFT", MerchantFrame, "RIGHT", -25, 0)
        container:SetSize(1, 1)
        return container
    end

    -- ========================================================================
    -- Скрыть / сбросить кнопки
    -- ========================================================================
    local function ClearButtons()
        for _, col in ipairs(buttons) do
            for _, btn in ipairs(col) do
                btn:Hide()
                btn:SetParent(nil)
            end
        end
        buttons = {}
        if container then container:Hide() end
    end

    -- ========================================================================
    -- Создать одну кнопку
    -- ========================================================================
    local function CreateButton(parent, slot, quantity, x, y, icon)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(true)
        tex:SetTexture(icon)

        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        border:SetAllPoints(true)
        border:SetVertexColor(0.4, 0.4, 0.4)

        local countText = btn:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE")
        countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
        countText:SetTextColor(1, 1, 0.4, 1)
        countText:SetText(tostring(quantity))

        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        btn:SetScript("OnClick", function()
            BuyMerchantItem(slot, quantity)
        end)

        btn:SetScript("OnEnter", function(self)
            ShowButtonTooltip(self, slot, quantity)
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return btn
    end

    -- ========================================================================
    -- Проверка «игнорировать ли эмблему»
    -- ========================================================================
    local function IsIgnored(name)
        if not name then return true end
        for _, pat in ipairs(IGNORE_PATTERNS) do
            if pat and name:find(pat, 1, true) then
                return true
            end
        end
        return false
    end

    -- ========================================================================
    -- Построить кнопки по содержимому мерчанта
    -- ========================================================================
    local function BuildButtons()
        ClearButtons()

        local parent = CreateContainer()
        parent:Show()

        local n = GetMerchantNumItems()
        if not n or n == 0 then return end

        local columnIndex = 0
        local maxColumnHeight = 0

        for slot = 1, n do
            local info = { GetMerchantItemInfo(slot) }
            local name = info[1]
            local icon = info[2]

            if name and icon then
                if not IsIgnored(name) then
                    if name:find("Эмблема", 1, true) then
                        columnIndex = columnIndex + 1
                        buttons[columnIndex] = {}

                        local xOffset = (columnIndex - 1) * COLUMN_WIDTH
                        local yOffset = 0

                        for _, qty in ipairs(QUANTITIES) do
                            local btn = CreateButton(parent, slot, qty, xOffset, -yOffset, icon)
                            btn:Show()
                            table.insert(buttons[columnIndex], btn)
                            yOffset = yOffset + ROW_HEIGHT
                        end

                        if yOffset > maxColumnHeight then
                            maxColumnHeight = yOffset
                        end
                    end
                end
            end
        end

        if columnIndex > 0 then
            parent:SetSize(columnIndex * COLUMN_WIDTH, maxColumnHeight)
        else
            parent:Hide()
        end
    end

    -- ========================================================================
    -- Триггеры
    -- ========================================================================
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:SetScript("OnEvent", function(_, event)
        if event == "MERCHANT_SHOW" then
            BuildButtons()
        else
            ClearButtons()
        end
    end)

end)