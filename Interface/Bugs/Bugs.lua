-- ============================================================================
-- NSQC4 / Interface / Bugs
-- Баг-репортёр: запрос списка багов у сервера через гильд-чат.
-- Модуль: ui_bugs.
-- Слэш: /ns_bugs.
-- ============================================================================

NSQC4.RegisterModule("ui_bugs", function()

    -- ========================================================================
    -- Локальное состояние
    -- ========================================================================
    local bugFrame       -- главное окно (лениво)
    local bugList        -- ScrollingMessageFrame
    local bugCounter     -- FontString со счётчиком
    local bugCount = 0

    local orderFrame     -- модальное окно "-повелеваю" (лениво)

    local BUGS_PREFIX   = "ns_bugs"      -- запрос
    local BUGS_RESPONSE = "ns_bugsRe"    -- ответ

    -- ========================================================================
    -- Цвет по маркеру в начале текста
    --   "*"  → зелёный
    --   "-"  → красный (включая все виды тире)
    --   иначе → белый
    -- ========================================================================
    local function GetColorByMarker(text)
        local clean = (text or ""):gsub("^%s+", "")
        local firstChar = clean:sub(1, 1)

        if firstChar == "*" then
            return "|cff00ff00"
        elseif firstChar == "-" or firstChar == "–" or firstChar == "—" or firstChar == "‐" then
            return "|cffff0000"
        else
            return "|cffffffff"
        end
    end

    -- ========================================================================
    -- Добавление готовой (уже окрашенной) строки в список
    -- ========================================================================
    local function AddReportLine(coloredText)
        if not coloredText or coloredText == "" then return end
        if not bugList then return end

        bugList:AddMessage(coloredText)

        bugCount = bugCount + 1
        if bugCounter then
            bugCounter:SetText("Найдено: " .. bugCount)
        end
    end

    -- ========================================================================
    -- Очистка списка
    -- ========================================================================
    local function ClearList()
        if not bugList then return end
        bugList:Clear()
        bugCount = 0
        if bugCounter then
            bugCounter:SetText("Найдено: 0")
        end
    end

    -- ========================================================================
    -- Модальное окно «-повелеваю»
    -- ========================================================================
    local function CreateOrderFrame()
        if orderFrame then return orderFrame end

        local f = CreateFrame("Frame", "NSQC4BugOrderFrame", UIParent)
        f:SetSize(420, 140)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:SetBackdropColor(0, 0, 0, 1)

        -- Заголовок
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -14)
        title:SetText("Повелеваю")
        title:SetTextColor(1, 0.82, 0)

        -- Кнопка закрытия
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -6, -6)

        -- Пояснение
        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 15, -44)
        hint:SetText("Введите текст (до 240 символов), Enter — отправить в гильд-чат:")
        hint:SetTextColor(0.8, 0.8, 0.8)

        -- Поле ввода
        local inputBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        inputBox:SetSize(380, 24)
        inputBox:SetPoint("TOPLEFT", 15, -70)
        inputBox:SetAutoFocus(true)
        inputBox:SetMaxLetters(240)
        inputBox:SetText("")
        inputBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            f:Hide()
        end)
        inputBox:SetScript("OnEnterPressed", function(self)
            local text = self:GetText() or ""
            text = text:gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                SendChatMessage("-повелеваю " .. text, "GUILD")
            end
            self:SetText("")
            self:ClearFocus()
            f:Hide()
        end)

        f.inputBox = inputBox

        -- Счётчик символов
        local charCounter = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        charCounter:SetPoint("TOPRIGHT", inputBox, "BOTTOMRIGHT", 0, -4)
        charCounter:SetText("0 / 240")
        charCounter:SetTextColor(0.6, 0.6, 0.6)

        inputBox:SetScript("OnTextChanged", function(self)
            local len = string.len(self:GetText() or "")
            charCounter:SetText(len .. " / 240")
        end)

        -- Скрытие по Esc на фрейме
        f:EnableKeyboard(true)
        f:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)

        f:Hide()
        orderFrame = f
        return f
    end

    local function ShowOrderFrame()
        local f = CreateOrderFrame()
        f:Show()
        f:Raise()
        if f.inputBox then
            f.inputBox:SetText("")
            f.inputBox:SetFocus()
        end
    end

    -- ========================================================================
    -- Создание окна (лениво)
    -- ========================================================================
    local function CreateBugReportFrame()
        if bugFrame then return bugFrame end

        local f = CreateFrame("Frame", "NSQC4BugReportFrame", UIParent)
        f:SetSize(768, 600)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:SetBackdropColor(0, 0, 0, 1)

        -- Заголовок
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -16)
        title:SetText("Баг-репортёр")
        title:SetTextColor(1, 0.82, 0)

        -- Кнопка закрытия
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -6, -6)

        -- Кнопка «+» в левом верхнем углу
        local plusBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        plusBtn:SetSize(24, 24)
        plusBtn:SetPoint("TOPLEFT", 13, -13)
        plusBtn:SetText("+")
        plusBtn:SetScript("OnClick", function()
            ShowOrderFrame()
        end)
        plusBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Повелеваю", 1, 0.82, 0)
            GameTooltip:AddLine("Отправить в гильд-чат: -повелеваю <текст>", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        plusBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Кнопка «Загрузить»
        local loadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        loadBtn:SetSize(120, 24)
        loadBtn:SetPoint("TOPLEFT", 15, -44)
        loadBtn:SetText("Загрузить")

        -- Поле ввода
        local inputBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        inputBox:SetHeight(24)
        inputBox:SetPoint("LEFT", loadBtn, "RIGHT", 10, 0)
        inputBox:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
        inputBox:SetAutoFocus(false)
        inputBox:SetMaxLetters(255)
        inputBox:SetText("")
        inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        -- Список с прокруткой
        local listFrame = CreateFrame("ScrollingMessageFrame", "NSQC4BugReportList", f)
        listFrame:SetPoint("TOPLEFT", loadBtn, "BOTTOMLEFT", 5, -20)
        listFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
        listFrame:SetFontObject(ChatFontNormal)
        listFrame:SetMaxLines(2000)
        listFrame:SetFading(false)
        listFrame:SetJustifyH("LEFT")
        listFrame:EnableMouse(true)
        listFrame:EnableMouseWheel(true)
        listFrame:SetScript("OnMouseWheel", function(self, delta)
            if delta > 0 then self:ScrollUp() else self:ScrollDown() end
        end)

        -- Счётчик
        local counter = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        counter:SetPoint("BOTTOMLEFT", listFrame, "TOPLEFT", 0, 4)
        counter:SetText("Найдено: 0")

        -- Сохраняем ссылки
        bugFrame   = f
        bugList    = listFrame
        bugCounter = counter

        -- Отправка запроса
        local function SendRequest()
            local msg = inputBox:GetText() or ""
            ClearList()

            local myName = UnitName("player") or "Unknown"
            local payload = "REQ:" .. myName .. "||" .. msg

            SendAddonMessage(BUGS_PREFIX, payload, "GUILD")
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Bugs]|r Запрос отправлен: " ..
                (msg ~= "" and msg or "(пусто)"))

            inputBox:SetText("")
            inputBox:ClearFocus()
        end

        loadBtn:SetScript("OnClick", SendRequest)
        inputBox:SetScript("OnEnterPressed", function(self)
            SendRequest()
            self:ClearFocus()
        end)

        f:Hide()
        return f
    end

    -- ========================================================================
    -- Показ окна
    -- ========================================================================
    local function ShowBugReport()
        local f = CreateBugReportFrame()
        f:Show()
        f:Raise()
    end

    -- ========================================================================
    -- Приём ответа от сервера: ns_bugsRe
    -- Формат: RES:<RequesterName>||<Owner>||<WishText>
    -- Цвет всей строки — по маркеру в начале WishText:
    --   "*" → зелёный, "-" → красный, иначе → белый
    -- ========================================================================
    NSQC4.chat:Register("ADDON:ns_bugsre", {
        func = function(words, sender, text, channel, prefix)
            if not text or text == "" then return end

            local prefixTag, rest = string.match(text, "^(RES:.-)||(.+)$")
            if not prefixTag or not rest then return end

            local targetRequester = string.sub(prefixTag, 5)
            local myName = UnitName("player") or ""

            if targetRequester ~= myName then return end

            local owner, wishText = string.match(rest, "^(.-)||(.+)$")
            if not owner or not wishText then
                owner = "Неизвестно"
                wishText = rest
            end

            -- Вырезаем юникстайм из конца
            wishText = string.gsub(wishText, "%s%d+$", "")

            -- Цвет — по маркеру в начале wishText, красим ВСЮ строку
            local color = GetColorByMarker(wishText)
            local displayText = owner .. ": " .. wishText

            AddReportLine(color .. displayText .. "|r")

            -- Автопоказ окна
            if bugFrame and not bugFrame:IsShown() then
                bugFrame:Show()
                bugFrame:Raise()
            end
        end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSBUGS1 = "/ns_bugs"
    SlashCmdList["NSBUGS"] = function()
        ShowBugReport()
    end

    -- ========================================================================
    -- Кнопка на панели
    -- ========================================================================
    NSQC4.SlashPanel_RegisterButton("B", "/ns_bugs", "Баг-репортёр", function()
        ShowBugReport()
    end)

end)