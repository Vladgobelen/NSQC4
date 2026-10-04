NSQC4.RegisterModule("gp", function()   

GpDb = {}
GpDb.__index = GpDb

function GpDb:new(input_table)
    local new_object = {
        gp_data = {},
        sort_column = "nick",
        sort_ascending = true,
        visible_rows = 20,
        selected_indices = {},
        last_selected_index = nil,
        logData = {},
        filterText = "",
        showOnlyNotes = false,
        updateTimer = nil,
        lastCheckedPlayer = nil,
        confirmed_rl_nicks = {},
        rl_tooltip_nicks = {},
        _rl_tooltip_list = nil,
        external_gp_cache = {},
    }
    setmetatable(new_object, self)
    new_object:_CreateWindow()
    new_object:_CreateRaidSelectionWindow()
    new_object:_CreateLogWindow()
    return new_object
end

-- Начинает сборку списка РЛов. Принимает первый ник (text).
function GpDb:BeginRlTooltipList(text)
    if not text or type(text) ~= "string" or text == "" then return end
    self._rl_tooltip_list = { text }
end

-- Добавляет следующий ник и завершает сборку, обновляя тултип чекбокса.
function GpDb:EndRlTooltipList(text)
    if not text or type(text) ~= "string" or text == "" then
        -- Если нет последнего, но есть начальный — завершаем без добавления.
        if not self._rl_tooltip_list then return end
    else
        -- Добавляем последний ник, если список уже начат
        if self._rl_tooltip_list then
            table.insert(self._rl_tooltip_list, text)
        else
            -- Или начинаем и сразу завершаем
            self._rl_tooltip_list = { text }
        end
    end

    -- Обновляем тултип чекбокса (если он существует)
    if self.raidWindow and self.raidWindow.playerInfoCheckbox then
        -- Просто перерисовка произойдёт при наведении, но можно принудительно скрыть,
        -- чтобы пользователь увидел обновлённый тултип при следующем наведении.
        GameTooltip:Hide()
    end

    -- Уничтожаем переменную сборки
    self._rl_tooltip_list = nil
end

function GpDb:AddRawLogEntry(rawLogString)
    if not self.logWindow then
        self:_CreateLogWindow()
    end

    -- Парсим: "1760908142 Шеф Тест 5 1Ic"
    local words = {}
    for word in rawLogString:gmatch("%S+") do
        table.insert(words, word)
    end

    if #words < 4 then return end

    local unixTime = tonumber(words[1])
    local rl = words[2]
    local raid = words[3]
    local gpValue = tonumber(words[4]) or 0

    -- Цели — всё, что после 4-го слова
    local targets = {}
    for i = 5, #words do
        table.insert(targets, words[i])
    end
    local targetsStr = table.concat(targets, " ")

    -- Форматируем время из unixtime
    local formattedTime = "|cFFA0A0A0" .. date("%d %H:%M:%S", unixTime) .. "|r"

    -- Получаем цвет класса для РЛ
    local function GetClassColor(name)
        if not name or type(name) ~= "string" or name == "" then 
            return "|cFFFFFFFF" 
        end
        for i = 1, GetNumGuildMembers() do
            local guildName, _, _, _, _, _, _, _, _, _, classFileName = GetGuildRosterInfo(i)
            if guildName and guildName == name then
                local color = RAID_CLASS_COLORS[classFileName]
                if color then
                    return string.format("|cFF%02x%02x%02x", color.r*255, color.g*255, color.b*255)
                end
                break
            end
        end
        return "|cFFFFFFFF"
    end

    local formattedRl = GetClassColor(rl) .. (rl or "Неизвестно") .. "|r"
    local gpColor = gpValue >= 0 and "|cFF00FF00" or "|cFFFF0000"
    local formattedGp = gpColor .. tostring(gpValue) .. "|r"
    local formattedRaid = "|cFFFFFF00" .. (raid or "Неизвестно") .. "|r"

    -- Декодируем цели (если есть NSQS_dict)
    local formattedTargets = {}
    for _, code in ipairs(targets) do
        local playerName = code
        if NSQS_dict then
            for name, info in pairs(NSQS_dict) do
                if info[2] == code then
                    playerName = name
                    break
                end
            end
        end
        table.insert(formattedTargets, GetClassColor(playerName) .. playerName .. "|r")
    end
    local formattedTargetsText = table.concat(formattedTargets, " ")

    local logText = string.format("%s | %s | %s | %s | %s",
        formattedTime,
        formattedRl,
        formattedGp,
        formattedRaid,
        formattedTargetsText)

    table.insert(self.logData, {
        text = logText,
        raw = {
            time = unixTime,
            rl = rl,
            gp = gpValue,
            raid = raid,
            targets = targetsStr
        }
    })

    if #self.logData > 2000 then
        table.remove(self.logData, 1)
    end

    if self.logWindow and self.logWindow:IsShown() then
        self:UpdateLogDisplay()
        self.logWindow.scrollFrame:SetVerticalScroll(self.logWindow.scrollFrame:GetVerticalScrollRange())
    end
end

function GpDb:_CreateLogWindow()
    -- Основное окно логов
    self.logWindow = CreateFrame("Frame", "GpDbLogWindow", self.window)
    self.logWindow:SetFrameStrata("DIALOG")
    self.logWindow:SetSize(600, self.window:GetHeight())
    self.logWindow:SetPoint("TOPLEFT", self.window, "TOPRIGHT", 5, 0)
    self.logWindow:SetMovable(false)
    self.logWindow:Hide()
    -- Фон окна
    self.logWindow.background = self.logWindow:CreateTexture(nil, "BACKGROUND")
    self.logWindow.background:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.logWindow.background:SetVertexColor(0.1, 0.1, 0.1)
    self.logWindow.background:SetAlpha(0.9)
    self.logWindow.background:SetAllPoints(true)
    -- Граница окна
    self.logWindow.borderFrame = CreateFrame("Frame", nil, self.logWindow)
    self.logWindow.borderFrame:SetPoint("TOPLEFT", -3, 3)
    self.logWindow.borderFrame:SetPoint("BOTTOMRIGHT", 3, -3)
    self.logWindow.borderFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    -- Кнопка закрытия
    self.logWindow.closeButton = CreateFrame("Button", nil, self.logWindow, "UIPanelCloseButton")
    self.logWindow.closeButton:SetPoint("TOPRIGHT", -5, -5)
    self.logWindow.closeButton:SetScript("OnClick", function() 
        self.logWindow:Hide() 
    end)
    -- Фильтры
    self.logWindow.filters = CreateFrame("Frame", nil, self.logWindow)
    self.logWindow.filters:SetPoint("TOPLEFT", 10, -5)
    self.logWindow.filters:SetPoint("RIGHT", -10, 0)
    self.logWindow.filters:SetHeight(30)
    -- Поле "Количество"
    self.logWindow.countFilter = CreateFrame("EditBox", "EditKolvo", self.logWindow.filters, "InputBoxTemplate")
    self.logWindow.countFilter:SetSize(60, 20)
    self.logWindow.countFilter:SetPoint("LEFT", self.logWindow.filters, "LEFT")
    self.logWindow.countFilter:SetAutoFocus(false)
    self.logWindow.countFilter:SetText("Кол-во")
    self.logWindow.countFilter:SetScript("OnEscapePressed", function() self.logWindow.countFilter:ClearFocus() end)
    self.logWindow.countFilter:SetScript("OnEnterPressed", function() 
        self.logWindow.countFilter:ClearFocus() 
        self:UpdateLogDisplay()
    end)
    -- Поле "День" (вместо "Время")
    self.logWindow.timeFilter = CreateFrame("EditBox", "EditDay", self.logWindow.filters, "InputBoxTemplate")
    self.logWindow.timeFilter:SetSize(70, 20)
    self.logWindow.timeFilter:SetPoint("LEFT", self.logWindow.countFilter, "RIGHT", 5, 0)
    self.logWindow.timeFilter:SetAutoFocus(false)
    self.logWindow.timeFilter:SetText("День")
    self.logWindow.timeFilter:SetScript("OnEscapePressed", function() self.logWindow.timeFilter:ClearFocus() end)
    self.logWindow.timeFilter:SetScript("OnEnterPressed", function() 
        self.logWindow.timeFilter:ClearFocus() 
        self:UpdateLogDisplay()
    end)
    -- Поле "РЛ"
    self.logWindow.rlFilter = CreateFrame("EditBox", "EditRL", self.logWindow.filters, "InputBoxTemplate")
    self.logWindow.rlFilter:SetSize(70, 20)
    self.logWindow.rlFilter:SetPoint("LEFT", self.logWindow.timeFilter, "RIGHT", 5, 0)
    self.logWindow.rlFilter:SetAutoFocus(false)
    self.logWindow.rlFilter:SetText("РЛ")
    self.logWindow.rlFilter:SetScript("OnEscapePressed", function() self.logWindow.rlFilter:ClearFocus() end)
    self.logWindow.rlFilter:SetScript("OnEnterPressed", function() 
        self.logWindow.rlFilter:ClearFocus() 
        self:UpdateLogDisplay()
    end)
    -- Поле "Рейд"
    self.logWindow.raidFilter = CreateFrame("EditBox", "EditRaid", self.logWindow.filters, "InputBoxTemplate")
    self.logWindow.raidFilter:SetSize(100, 20)
    self.logWindow.raidFilter:SetPoint("LEFT", self.logWindow.rlFilter, "RIGHT", 5, 0)
    self.logWindow.raidFilter:SetAutoFocus(false)
    self.logWindow.raidFilter:SetText("Рейд")
    self.logWindow.raidFilter:SetScript("OnEscapePressed", function() self.logWindow.raidFilter:ClearFocus() end)
    self.logWindow.raidFilter:SetScript("OnEnterPressed", function() 
        self.logWindow.raidFilter:ClearFocus() 
        self:UpdateLogDisplay()
    end)
    -- Поле "Ник"
    self.logWindow.nameFilter = CreateFrame("EditBox", "EditNik", self.logWindow.filters, "InputBoxTemplate")
    self.logWindow.nameFilter:SetSize(100, 20)
    self.logWindow.nameFilter:SetPoint("LEFT", self.logWindow.raidFilter, "RIGHT", 5, 0)
    self.logWindow.nameFilter:SetAutoFocus(false)
    self.logWindow.nameFilter:SetText("Ник")
    self.logWindow.nameFilter:SetScript("OnEscapePressed", function() self.logWindow.nameFilter:ClearFocus() end)
    self.logWindow.nameFilter:SetScript("OnEnterPressed", function() 
        self.logWindow.nameFilter:ClearFocus() 
        self:UpdateLogDisplay()
    end)
    -- Кнопка "Показать"
    self.logWindow.showButton = CreateFrame("Button", nil, self.logWindow.filters, "UIPanelButtonTemplate")
    self.logWindow.showButton:SetSize(80, 22)
    self.logWindow.showButton:SetPoint("LEFT", self.logWindow.nameFilter, "RIGHT", 5, 0)
    self.logWindow.showButton:SetText("Показать")
    self.logWindow.showButton:SetScript("OnClick", function()
        local function processFilterText(text, placeholder)
            if text == placeholder or text == "" then
                return "_"
            end
            if text:find("%s") then
                text = text:gsub("%s+", "_")
            end
            return text
        end

        local count = processFilterText(self.logWindow.countFilter:GetText(), "Кол-во")
        local time = processFilterText(self.logWindow.timeFilter:GetText(), "День")
        local rl = processFilterText(self.logWindow.rlFilter:GetText(), "РЛ")
        local raid = processFilterText(self.logWindow.raidFilter:GetText(), "Рейд")
        
        -- === Преобразуем имя → код через officerNote ===
        local nameInput = self.logWindow.nameFilter:GetText()
        local name = "_"
        if nameInput ~= "" and nameInput ~= "Ник" then
            local foundCode = nil
            -- Ищем игрока по имени в гильдии
            for i = 1, GetNumGuildMembers() do
                local guildName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
                if guildName and officerNote then
                    -- Убираем серверную часть из имени (если есть)
                    local plainName = guildName:match("^(.-)-") or guildName
                    if plainName == nameInput then
                        -- Парсим officerNote: ожидаем формат "что-то КОД ..."
                        local words = {}
                        for w in officerNote:gmatch("%S+") do
                            table.insert(words, w)
                        end
                        if #words >= 2 then
                            foundCode = words[2]
                            break
                        end
                    end
                end
            end
            name = foundCode or nameInput  -- если не нашли — отправляем как есть (на случай ручного ввода кода)
        end

        local request = count .. " " .. time .. " " .. rl .. " " .. raid .. " " .. name
        print("|cFF00FF00[Клиент] Запрос логов:|r", request)
        self:ClearLog()
        SendAddonMessage("NSShowMeLogs", request, "GUILD")
    end)
    -- Область с прокруткой для логов
    self.logWindow.scrollFrame = CreateFrame("ScrollFrame", "GpDbLogScrollFrame", self.logWindow, "UIPanelScrollFrameTemplate")
    self.logWindow.scrollFrame:SetPoint("TOPLEFT", 0, -35)
    self.logWindow.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 10)
    self.logWindow.scrollChild = CreateFrame("Frame")
    self.logWindow.scrollChild:SetSize(580, 1000)
    self.logWindow.scrollFrame:SetScrollChild(self.logWindow.scrollChild)
    -- Создаем строки для отображения логов
    self.logRows = {}
    for i = 1, 2000 do
        local row = CreateFrame("Frame", "GpDbLogRow"..i, self.logWindow.scrollChild)
        row:SetSize(580, 40)
        row:SetPoint("TOPLEFT", 0, -((i-1)*40))
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.text:SetAllPoints(true)
        row.text:SetJustifyH("LEFT")
        row.text:SetJustifyV("TOP")
        row.text:SetWordWrap(true)
        row.text:SetText("")
        self.logRows[i] = row
    end
end

function GpDb:ClearLog()
    -- Очищаем данные лога
    self.logData = {}
    
    -- Очищаем фильтры
    self.logWindow.countFilter:SetText("Кол-во")
    self.logWindow.timeFilter:SetText("День")
    self.logWindow.rlFilter:SetText("РЛ")
    self.logWindow.raidFilter:SetText("Рейд")
    self.logWindow.nameFilter:SetText("Ник")
    
    -- Обновляем отображение
    self:UpdateLogDisplay()
    
    print("|cFFFF0000ГП:|r Лог успешно очищен")
end

function GpDb:_CreateWindow()
    -- Создаем основной фрейм окна
    self.window = CreateFrame("Frame", "GpTrackerWindow", UIParent)
    self.window:SetFrameStrata("DIALOG")
    self.window:SetSize(400, 600) -- Увеличена высота для размещения фильтра
    self.window:SetPoint("LEFT", 5, 100)
    self.window:SetMovable(true)
    self.window:EnableMouse(true)
    self.window:RegisterForDrag("LeftButton")
    self.window:SetScript("OnDragStart", self.window.StartMoving)
    self.window:SetScript("OnDragStop", self.window.StopMovingOrSizing)
    self.window:Hide()
    -- 1. Непрозрачный чёрный фон
    self.window.background = self.window:CreateTexture(nil, "BACKGROUND")
    self.window.background:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.window.background:SetVertexColor(0, 0, 0)
    self.window.background:SetAlpha(1)
    self.window.background:SetAllPoints(true)
    -- 2. Граница окна
    self.window.borderFrame = CreateFrame("Frame", nil, self.window)
    self.window.borderFrame:SetPoint("TOPLEFT", -3, 3)
    self.window.borderFrame:SetPoint("BOTTOMRIGHT", 3, -3)
    self.window.borderFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    -- 3. Заголовок окна
    self.window.title = self.window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.title:SetPoint("TOP", 0, -15)
    self.window.title:SetText("")
    -- 4. Кнопка закрытия
    self.window.closeButton = CreateFrame("Button", nil, self.window, "UIPanelCloseButton")
    self.window.closeButton:SetPoint("TOPRIGHT", -5, -5)
    self.window.closeButton:SetScript("OnClick", function() self.window:Hide() end)
    -- 4.1 Кнопка логов (справа от кнопки закрытия)
    self.window.logButton = CreateFrame("Button", nil, self.window, "UIPanelButtonTemplate")
    self.window.logButton:SetSize(24, 24)
    self.window.logButton:SetPoint("RIGHT", self.window.closeButton, "LEFT", -5, 0)
    self.window.logButton:SetText("L")
    self.window.logButton:SetScript("OnClick", function() 
        self:ToggleLogWindow() 
    end)
    -- 5. Чекбокс "Только рейд"
    self.window.raidOnlyCheckbox = CreateFrame("CheckButton", nil, self.window, "UICheckButtonTemplate")
    self.window.raidOnlyCheckbox:SetPoint("TOPLEFT", 10, -15)
    self.window.raidOnlyCheckbox:SetSize(24, 24)
    self.window.raidOnlyCheckbox.text = self.window.raidOnlyCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.raidOnlyCheckbox.text:SetPoint("LEFT", self.window.raidOnlyCheckbox, "RIGHT", 5, 0)
    self.window.raidOnlyCheckbox.text:SetText("Только рейд")
    self.window.raidOnlyCheckbox:SetScript("OnClick", function()
        if self.window.raidOnlyCheckbox:GetChecked() then
            self.window.guildCheckbox:SetChecked(false)
            self.window.guildCheckbox:Disable()
            self.window.offCheckbox:SetChecked(false)
            self.window.offCheckbox:Disable()
        else
            self.window.guildCheckbox:Enable()
        end
        self:_UpdateFromGuild()
        self:UpdateWindow()
    end)
    -- 5.0.5 Чекбокс "Гильдия"
    self.window.guildCheckbox = CreateFrame("CheckButton", nil, self.window, "UICheckButtonTemplate")
    self.window.guildCheckbox:SetPoint("LEFT", self.window.raidOnlyCheckbox.text, "RIGHT", 10, 0)
    self.window.guildCheckbox:SetSize(24, 24)
    self.window.guildCheckbox.text = self.window.guildCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.guildCheckbox.text:SetPoint("LEFT", self.window.guildCheckbox, "RIGHT", 5, 0)
    self.window.guildCheckbox.text:SetText("Гильдия")
    self.window.guildCheckbox:SetScript("OnClick", function()
        if self.window.guildCheckbox:GetChecked() then
            self.window.offCheckbox:Enable()
        else
            self.window.offCheckbox:SetChecked(false)
            self.window.offCheckbox:Disable()
        end
        self:_UpdateFromGuild()
        self:UpdateWindow()
    end)
    -- 5.0.6 Чекбокс "Off"
    self.window.offCheckbox = CreateFrame("CheckButton", nil, self.window, "UICheckButtonTemplate")
    self.window.offCheckbox:SetPoint("LEFT", self.window.guildCheckbox.text, "RIGHT", 10, 0)
    self.window.offCheckbox:SetSize(24, 24)
    self.window.offCheckbox.text = self.window.offCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.offCheckbox.text:SetPoint("LEFT", self.window.offCheckbox, "RIGHT", 5, 0)
    self.window.offCheckbox.text:SetText("Off")
    self.window.offCheckbox:Disable()
    self.window.offCheckbox:SetScript("OnClick", function()
        self:_UpdateFromGuild()
        self:UpdateWindow()
    end)
    -- 5.1 Чекбокс "Заметки"
    self.window.notesCheckbox = CreateFrame("CheckButton", nil, self.window, "UICheckButtonTemplate")
    self.window.notesCheckbox:SetPoint("TOPLEFT", self.window.raidOnlyCheckbox, "BOTTOMLEFT", 0, -10)
    self.window.notesCheckbox:SetSize(24, 24)
    self.window.notesCheckbox.text = self.window.notesCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.notesCheckbox.text:SetPoint("LEFT", self.window.notesCheckbox, "RIGHT", 5, 0)
    self.window.notesCheckbox.text:SetText("Заметки")
    self.window.notesCheckbox:SetScript("OnClick", function()
        self.showOnlyNotes = self.window.notesCheckbox:GetChecked()
    end)
    -- 5.2 Поле фильтрации по нику (без надписи "Фильтр:")
    self.window.filterEditBox = CreateFrame("EditBox", "fdsfdsa3333", self.window, "InputBoxTemplate")
    self.window.filterEditBox:SetPoint("TOPLEFT", self.window.notesCheckbox.text, "BOTTOMLEFT", 0, -5)
    self.window.filterEditBox:SetPoint("RIGHT", self.window.closeButton, "LEFT", -40, 0)
    self.window.filterEditBox:SetHeight(20)
    self.window.filterEditBox:SetAutoFocus(false)
    self.window.filterEditBox:SetText("")
    self.window.filterEditBox:SetScript("OnTextChanged", function(editBox)
        self.filterText = editBox:GetText():lower()
        self:_UpdateFromGuild()
    end)
    self.window.filterEditBox:SetScript("OnEscapePressed", function() 
        self.window.filterEditBox:SetText("")
        self.window.filterEditBox:ClearFocus() 
    end)
    self.window.filterEditBox:SetScript("OnEnterPressed", function() 
        self.window.filterEditBox:ClearFocus() 
    end)
    -- 5.3 Кнопка очистки фильтра
    self.window.filterClearButton = CreateFrame("Button", nil, self.window, "UIPanelButtonTemplate")
    self.window.filterClearButton:SetSize(80, 22)
    self.window.filterClearButton:SetPoint("TOPRIGHT", self.window.filterEditBox, "BOTTOMRIGHT", 60, 20)
    self.window.filterClearButton:SetText("Очистить")
    self.window.filterClearButton:SetScript("OnClick", function()
        self.window.filterEditBox:SetText("")
        self.filterText = ""
        self:_UpdateFromGuild()
    end)
    -- 6. Область с прокруткой
    self.window.scrollFrame = CreateFrame("ScrollFrame", "ScrollFrame", self.window, "UIPanelScrollFrameTemplate")
    self.window.scrollFrame:SetPoint("TOPLEFT", 0, -85)  -- Больший отступ сверху
    self.window.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 60)  -- Больший отступ снизу
    self.window.scrollChild = CreateFrame("Frame")
    self.window.scrollChild:SetSize(380, 500)
    self.window.scrollFrame:SetScrollChild(self.window.scrollChild)
    -- 7. Ползунок прокрутки
    self.window.scrollBar = _G[self.window.scrollFrame:GetName().."ScrollBar"]
    self.window.scrollBar:SetPoint("TOPLEFT", self.window.scrollFrame, "TOPRIGHT", -20, -16)
    self.window.scrollBar:SetPoint("BOTTOMLEFT", self.window.scrollFrame, "BOTTOMRIGHT", -20, 16)
    -- 8. Строка с количеством отображаемых игроков
    self.window.countText = self.window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.countText:SetPoint("BOTTOMLEFT", 10, 40)
    self.window.countText:SetPoint("BOTTOMRIGHT", -10, 40)
    self.window.countText:SetJustifyH("LEFT")
    self.window.countText:SetText("")
    -- 9. Строка с общим количеством игроков с ГП
    self.window.totalText = self.window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.window.totalText:SetPoint("BOTTOMLEFT", 10, 20)
    self.window.totalText:SetPoint("BOTTOMRIGHT", -10, 20)
    self.window.totalText:SetJustifyH("LEFT")
    self.window.totalText:SetText("")
    -- 10. Настройка таблицы
    self:_SetupTable()
end

function GpDb:_SetupTable()
    -- Исправляем заголовки для правильной сортировки
    local headers = {
        {text = "Ник", column = "nick"},
        {text = "ГП", column = "gp"}
    }
    
    for i, header in ipairs(headers) do
        local btn = CreateFrame("Button", nil, self.window.scrollChild)
        btn:SetSize(i == 1 and 290 or 50, 20)
        btn:SetPoint("TOPLEFT", (i-1)*290 + (i == 2 and 10 or 0), -5) -- Добавляем отступ сверху
        btn:SetNormalFontObject("GameFontNormal")
        btn:SetHighlightFontObject("GameFontHighlight")
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetAllPoints(true)
        text:SetText(header.text)
        btn:SetScript("OnClick", function()
            self:SortData(header.column)
            self:UpdateWindow()
        end)
    end

    -- Создаем строки таблицы с системой выделения
    self.rows = {}
    for i = 1, 999 do
        local row = CreateFrame("Button", "GpDbRow"..i, self.window.scrollChild)
        row:SetSize(350, 20)
        row:SetPoint("TOPLEFT", 0, -25 - (i-1)*25)
        
        -- Настройки для кликов
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
        -- Текстура для выделения
        row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        row:GetHighlightTexture():SetVertexColor(0.4, 0.4, 0.8, 0.4)
        
        -- Текстура для выбранного состояния
        row.selection = row:CreateTexture(nil, "BACKGROUND")
        row.selection:SetAllPoints(true)
        row.selection:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.selection:SetVertexColor(0.3, 0.3, 0.7, 0.7)
        row.selection:Hide()
        
        -- Поля текста
        row.nick = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nick:SetPoint("LEFT", 10, 0)
        row.nick:SetWidth(290)
        row.nick:SetJustifyH("LEFT")

        row.gp = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.gp:SetPoint("RIGHT", 5, 0)
        row.gp:SetWidth(50)
        row.gp:SetJustifyH("RIGHT")

        -- Переменная для отслеживания времени последнего клика
        row.lastClickTime = 0
        
        -- Обработчик кликов
        row:SetScript("OnClick", function(_, button, down)
            local offset = FauxScrollFrame_GetOffset(self.window.scrollFrame)
            local dataIndex = i + offset
            -- Проверяем валидность данных
            if not self.gp_data or not self.gp_data[dataIndex] then return end
            -- Получаем текущее время
            local currentTime = GetTime()

            ------------------ проверка наличия заметок ------------------
            SendAddonMessage("NSShowMeZametki", self.gp_data[dataIndex].original_nick, "GUILD")
            ------------------ проверка наличия заметок ------------------

            -- Проверяем двойной клик (только ЛКМ и только если в рейде)
            if button == "LeftButton" and IsInRaid() and (currentTime - row.lastClickTime) < 0.5 then
                -- Двойной клик - выделяем все элементы
                self:ClearSelection()
                for idx = 1, #self.gp_data do
                    self.selected_indices[idx] = true
                end
                self.last_selected_index = dataIndex
                -- Обновляем интерфейс
                self:_UpdateSelectionCount()
                self:RefreshRowHighlights()
                self:UpdateRaidWindowVisibility()
                -- Обновляем список выбранных игроков
                if self.raidWindow and self.raidWindow:IsShown() then
                    self:_UpdateSelectedPlayersText()
                end
                -- Сбрасываем время клика
                row.lastClickTime = 0
                return
            end
            -- Запоминаем время клика для проверки двойного клика
            row.lastClickTime = currentTime
            if button == "LeftButton" then
                local wasSelected = self.selected_indices[dataIndex]
                -- SHIFT+ЛКМ - выделение диапазона
                if IsShiftKeyDown() then
                    if not self.last_selected_index then
                        self:ClearSelection()
                        self.selected_indices[dataIndex] = true
                        self.last_selected_index = dataIndex
                    else
                        local startIdx = math.min(self.last_selected_index, dataIndex)
                        local endIdx = math.max(self.last_selected_index, dataIndex)
                        if not IsControlKeyDown() then
                            self:ClearSelection()
                        end
                        for idx = startIdx, endIdx do
                            if self.gp_data[idx] then
                                self.selected_indices[idx] = true
                            end
                        end
                    end
                -- CTRL+ЛКМ - добавление/удаление из выделения
                elseif IsControlKeyDown() then
                    -- Изменяем состояние выделения
                    self.selected_indices[dataIndex] = not wasSelected
                    -- Очищаем несуществующие выделения
                    for idx in pairs(self.selected_indices) do
                        if not self.gp_data[idx] then
                            self.selected_indices[idx] = nil
                        end
                    end
                    -- Обновляем last_selected_index
                    if self.selected_indices[dataIndex] then
                        self.last_selected_index = dataIndex
                    else
                        self.last_selected_index = nil
                        for idx in pairs(self.selected_indices) do
                            if self.selected_indices[idx] then
                                self.last_selected_index = idx
                                break
                            end
                        end
                    end
                -- Обычный клик
                else
                    if wasSelected then
                        self:ClearSelection()
                    else
                        self:ClearSelection()
                        self.selected_indices[dataIndex] = true
                        self.last_selected_index = dataIndex
                    end
                end
                -- Принудительное обновление интерфейса
                self:_UpdateSelectionCount()
                self:RefreshRowHighlights()
                self:UpdateRaidWindowVisibility()
                -- Обновляем список выбранных игроков
                if self.raidWindow and self.raidWindow:IsShown() then
                    self:_UpdateSelectedPlayersText()
                end
            end
        end)

        self.rows[i] = row
    end

    -- Модифицируем обработчик скрытия окна
    self.window:SetScript("OnHide", function()
        -- Сбрасываем выделение
        self:ClearSelection()
        -- Скрываем окно рейда, если оно было открыто
        if self.raidWindow and self.raidWindow:IsShown() then
            self.raidWindow:Hide()
        end
        -- Скрываем окно логов, если оно было открыто
        if self.logWindow and self.logWindow:IsShown() then
            self.logWindow:Hide()
        end
    end)
end

function GpDb:ToggleLogWindow()
    if not self.logWindow then
        self:_CreateLogWindow()
    end
    if self.logWindow:IsShown() then
        self.logWindow:Hide()
    else
        self.logWindow:Show()
        local selectedCodes = {}
        for index in pairs(self.selected_indices) do
            if self.gp_data[index] and self.gp_data[index].playerID then
                table.insert(selectedCodes, self.gp_data[index].playerID)
            end
        end
        if #selectedCodes > 0 then
            local codeFilter = table.concat(selectedCodes, "_")
            print("|cFF00FF00[Клиент] Запрос логов по кодам игроков:|r", codeFilter)
            self:ClearLog()
            local function processFilterText(text, placeholder)
                if text == placeholder or text == "" then
                    return "_"
                end
                if text:find("%s") then
                    text = text:gsub("%s+", "_")
                end
                return text
            end
            local request = processFilterText("", "Кол-во") .. " " ..
                            processFilterText("", "День") .. " " ..
                            processFilterText("", "РЛ") .. " " ..
                            processFilterText("", "Рейд") .. " " ..
                            codeFilter
            SendAddonMessage("NSShowMeLogs", request, "GUILD")
        else
            -- Применяем фильтр "Заметки", если он включён
            if self.window.notesCheckbox and self.window.notesCheckbox:GetChecked() then
                local filteredLogData = {}
                for _, entry in ipairs(self.logData) do
                    if entry.raw and entry.raw.raid and entry.raw.raid:find(">>", 1, true) then
                        table.insert(filteredLogData, entry)
                    end
                end
                local originalLogData = self.logData
                self.logData = filteredLogData
                self:UpdateLogDisplay()
                self.logData = originalLogData
            else
                self:UpdateLogDisplay()
            end
        end
        if self.raidWindow and self.raidWindow:IsShown() then
            self.logWindow:SetHeight(self.window:GetHeight() / 2)
        else
            self.logWindow:SetHeight(self.window:GetHeight())
        end
    end
end

function GpDb:UpdateLogDisplay()
    if not self.logWindow or not self.logWindow:IsShown() then return end
    
    -- Вычисляем общую высоту
    local totalHeight = 0
    local rowHeights = {}
    
    -- Сначала вычисляем высоту всех строк
    for i, entry in ipairs(self.logData) do
        local tempText = self.logWindow.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tempText:SetWidth(580)
        tempText:SetText(entry.text)
        tempText:SetWordWrap(true)
        local textHeight = tempText:GetStringHeight() + 5
        rowHeights[i] = textHeight
        totalHeight = totalHeight + textHeight
        tempText:Hide()
    end

    -- Позиционируем строки (старые сверху, новые снизу)
    local currentY = 0
    for i = 1, #self.logRows do
        local dataIndex = i -- Отображаем записи по порядку (1=самая старая)
        if dataIndex <= #self.logData then
            local entry = self.logData[dataIndex]
            local textHeight = rowHeights[dataIndex]
            
            self.logRows[i]:SetHeight(textHeight)
            self.logRows[i]:SetPoint("TOPLEFT", 0, -currentY)
            self.logRows[i].text:SetText(entry.text)
            self.logRows[i]:Show()
            
            currentY = currentY + textHeight
        else
            self.logRows[i]:Hide()
        end
    end

    -- Обновляем высоту контента
    self.logWindow.scrollChild:SetHeight(totalHeight)
    self.logWindow.scrollFrame:UpdateScrollChildRect()
end

function GpDb:_UpdateSelectionCount()
    local count = 0
    -- Считаем ТОЛЬКО действительно выделенные и существующие элементы
    for idx, selected in pairs(self.selected_indices) do
        if selected and self.gp_data[idx] then
            count = count + 1
        else
            self.selected_indices[idx] = nil -- Очищаем невалидные
        end
    end
    
    -- Обновляем текст
    self.window.countText:SetText(string.format("Выделено: %d", count))
    
    -- Если нет выделений - сбрасываем last_selected_index
    if count == 0 then
        self.last_selected_index = nil
    end
    
    return count
end

function GpDb:IsValidIndex(index)
    return index and type(index) == "number" and self.gp_data and self.gp_data[index]
end

function GpDb:RefreshRowHighlights()
    local offset = FauxScrollFrame_GetOffset(self.window.scrollFrame)
    
    for i, row in ipairs(self.rows) do
        local dataIndex = i + offset
        if dataIndex <= #self.gp_data then
            if self.selected_indices[dataIndex] then
                row.selection:Show()
                row:GetHighlightTexture():SetAlpha(0.2) -- Снижаем прозрачность ховера при выделении
            else
                row.selection:Hide()
                row:GetHighlightTexture():SetAlpha(0.4) -- Возвращаем стандартную прозрачность
            end
        end
    end
    
    -- Обновляем счетчик выделенных
    local selectedCount = 0
    for _ in pairs(self.selected_indices) do selectedCount = selectedCount + 1 end
    self.window.countText:SetText(string.format("Выделено: %d", selectedCount))
end

function GpDb:ClearSelection()
    self.selected_indices = {}
    self.last_selected_index = nil
    self:_UpdateSelectionCount()
    self:RefreshRowHighlights()
    self:UpdateRaidWindowVisibility()
end

function GpDb:GetSelectedEntries()
    local selected = {}
    for index, _ in pairs(self.selected_indices) do
        if index <= #self.gp_data then
            table.insert(selected, self.gp_data[index])
        end
    end
    return selected
end

function GpDb:AddLogEntry(timeStr, gpValue, rl, raid, targets, isDecoded)
    -- Проверяем наличие окна логов
    if not self.logWindow then
        self:_CreateLogWindow()
    end

    local function GetClassColor(name)
        if not name or type(name) ~= "string" or name == "" then 
            return "|cFFFFFFFF" 
        end
        for i = 1, GetNumGuildMembers() do
            local guildName, _, _, _, _, _, _, _, _, _, classFileName = GetGuildRosterInfo(i)
            if guildName and guildName == name then
                local color = RAID_CLASS_COLORS[classFileName]
                if color then
                    return string.format("|cFF%02x%02x%02x", color.r*255, color.g*255, color.b*255)
                end
                break
            end
        end
        return "|cFFFFFFFF"
    end

    local gpNumValue = tonumber(gpValue) or 0
    local formattedTime = "|cFFA0A0A0" .. (timeStr or "??:??") .. "|r"
    local formattedRl = GetClassColor(rl) .. (rl or "Неизвестно") .. "|r"
    local gpColor = gpNumValue >= 0 and "|cFF00FF00" or "|cFFFF0000"
    local formattedGp = gpColor .. tostring(gpNumValue) .. "|r"
    local formattedRaid = "|cFFFFFF00" .. (raid or "Неизвестно") .. "|r"

    -- Форматируем цели
    local formattedTargets = {}
    if type(targets) == "string" then
        for word in targets:gmatch("%S+") do
            local playerName = word
            -- Декодируем ТОЛЬКО если это не серверная запись (isDecoded == nil или false)
            if not isDecoded then
                -- Пытаемся найти имя по коду в officerNote
                for i = 1, GetNumGuildMembers() do
                    local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
                    if name and officerNote then
                        local words = {}
                        for w in officerNote:gmatch("%S+") do
                            table.insert(words, w)
                        end
                        if #words >= 2 and words[2] == word then
                            playerName = name
                            break
                        end
                    end
                end
            end
            table.insert(formattedTargets, GetClassColor(playerName) .. playerName .. "|r")
        end
    end
    local formattedTargetsText = table.concat(formattedTargets, " ")

    local logText = string.format("%s | %s | %s | %s | %s", 
        formattedTime, 
        formattedRl,
        formattedGp,
        formattedRaid, 
        formattedTargetsText)

    table.insert(self.logData, {
        text = logText,
        raw = {
            time = timeStr,
            rl = rl,
            gp = gpNumValue,
            raid = raid,
            targets = targets
        }
    })

    if #self.logData > 2000 then
        table.remove(self.logData, 1)
    end

    if self.logWindow and self.logWindow:IsShown() then
        self:UpdateLogDisplay()
        self.logWindow.scrollFrame:SetVerticalScroll(self.logWindow.scrollFrame:GetVerticalScrollRange())
    end
end

function GpDb:UpdateRaidWindowVisibility()
    if not self.raidWindow then return end
    -- Проверяем звание игрока
    local hasOfficerRank = self:_CheckOfficerRank()
    if not hasOfficerRank then
        if self.raidWindow:IsShown() then
            self.raidWindow:Hide()
            -- Восстанавливаем полный размер окна логов
            if self.logWindow and self.logWindow:IsShown() then
                self.logWindow:SetHeight(self.window:GetHeight())
            end
        end
        return
    end
    local hasSelection = next(self.selected_indices) ~= nil
    if not hasSelection then
        if self.raidWindow:IsShown() then
            self.raidWindow:Hide()
            -- Восстанавливаем полный размер окна логов
            if self.logWindow and self.logWindow:IsShown() then
                self.logWindow:SetHeight(self.window:GetHeight())
            end
        end
        return
    end
    local inRaid = IsInRaid()
    local raidOnlyChecked = self.window.raidOnlyCheckbox:GetChecked()
    local shouldShow = not inRaid or raidOnlyChecked
    if shouldShow and inRaid then
        local raidMembers = {}
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                raidMembers[name] = true
            end
        end
        for index in pairs(self.selected_indices) do
            local entry = self.gp_data[index]
            if entry and not raidMembers[entry.original_nick] then
                shouldShow = false
                print("|cFFFF0000ГП:|r Некоторые выделенные игроки не в рейде")
                break
            end
        end
    end
    if shouldShow then
        if not self.raidWindow:IsShown() then
            self.raidWindow:Show()
            self:RestoreRaidWindowState() -- Восстанавливаем состояния при показе
            self:_UpdateSelectedPlayersText() -- Обновляем список игроков
            -- Корректируем размер окна логов
            if self.logWindow and self.logWindow:IsShown() then
                self.logWindow:SetHeight(self.window:GetHeight() / 2)
            end
        end
    else
        if self.raidWindow:IsShown() then
            self.raidWindow:Hide()
        end
        -- Корректируем размер окна логов
        if self.logWindow and self.logWindow:IsShown() then
            self.logWindow:SetHeight(self.window:GetHeight())
        end
    end
    -- Обновляем информацию об игроке
    if self.raidWindow and self.raidWindow:IsShown() then
        self:_UpdatePlayerInfo()
    end
end

function GpDb:UpdateWindow()
    if not self.window or not self.rows then return end

    local offset = FauxScrollFrame_GetOffset(self.window.scrollFrame)
    
    -- Уменьшаем количество отображаемых строк
    local visibleRows = math.floor((self.window.scrollFrame:GetHeight() - 30) / 25)
    self.visible_rows = visibleRows
    
    for i = 1, self.visible_rows do
        local row = self.rows[i]
        local dataIndex = i + offset
        
        if dataIndex <= #self.gp_data then
            local entry = self.gp_data[dataIndex]
            
            -- Обновляем текст
            row.nick:SetText(entry.nick)
            row.gp:SetText(tostring(entry.gp))
            
            -- Цвета текста
            if entry.classColor then
                row.nick:SetTextColor(entry.classColor.r, entry.classColor.g, entry.classColor.b)
            else
                row.nick:SetTextColor(1, 1, 1)
            end
            
            row:Show()
        else
            row:Hide()
        end
    end

    -- Обновляем выделения
    self:RefreshRowHighlights()
    
    -- Обновление скролла
    FauxScrollFrame_Update(self.window.scrollFrame, #self.gp_data, self.visible_rows, 25)
    self:UpdateRaidWindowVisibility()
end

function GpDb:GetNumSelected()
    local count = 0
    for idx in pairs(self.selected_indices) do
        if self.gp_data[idx] then  -- Проверяем что элемент существует
            count = count + 1
        else
            self.selected_indices[idx] = nil  -- Очищаем несуществующие
        end
    end
    print(string.format("GetNumSelected: найдено %d элементов", count))
    return count
end

function GpDb:Hide()
    self.window:Hide()
end

function GpDb:_UpdateFromGuild()
    -- Временная отладка.
    -- Поставь false, когда найдём причину.
    local DEBUG_GP = false

    self.gp_data = {}
    local totalWithGP = 0

    local inRaid = IsInRaid()
    self.window.raidOnlyCheckbox:SetChecked(inRaid)

    local raidOnlyMode = inRaid and self.window.raidOnlyCheckbox:GetChecked()
    local showAllGuild = self.window.guildCheckbox:GetChecked()
    local showOfflineOnly = showAllGuild and self.window.offCheckbox:GetChecked()

    if raidOnlyMode then
        self.window.guildCheckbox:SetChecked(false)
        self.window.guildCheckbox:Disable()

        self.window.offCheckbox:SetChecked(false)
        self.window.offCheckbox:Disable()
    else
        self.window.guildCheckbox:Enable()

        if not showAllGuild then
            self.window.offCheckbox:SetChecked(false)
            self.window.offCheckbox:Disable()
        else
            self.window.offCheckbox:Enable()
        end
    end

    if not IsInGuild() then
        print("|cFFFF0000ГП:|r Вы не состоите в гильдии")
        self:UpdateWindow()
        return
    end

    GuildRoster()

    local db = self

    if not db.external_gp_cache then
        db.external_gp_cache = {}
    end

    local timerFrame = CreateFrame("Frame")

    timerFrame:SetScript("OnUpdate", function(selfFrame, elapsed)
        selfFrame.elapsed = (selfFrame.elapsed or 0) + elapsed

        if selfFrame.elapsed >= 0.01 then
            selfFrame:SetScript("OnUpdate", nil)

            local guildRosterInfo = {}
            local debugCount = 0

            if DEBUG_GP then
                print(string.format(
                    tostring(raidOnlyMode),
                    tostring(showAllGuild),
                    tostring(showOfflineOnly),
                    tostring(inRaid)
                ))

                print(string.format(
                    GetNumGuildMembers()
                ))
            end

            for j = 1, GetNumGuildMembers() do
                local name, _, _, _, class5, _, publicNote, officerNote, online, _, class11 = GetGuildRosterInfo(j)

                if name then
                    local plainName = name:match("^(.-)-") or name
                    local classFileName = class11 or class5

                    local words = {}

                    if officerNote then
                        for word in officerNote:gmatch("%S+") do
                            table.insert(words, word)
                        end
                    end

                    local playerID = words[2]
                    local gp = tonumber(words[3]) or 0

                    if DEBUG_GP then
                        local nickMatch = true

                        if db.filterText and db.filterText ~= "" then
                            nickMatch = plainName:lower():find(db.filterText, 1, true) ~= nil
                        end

                        if nickMatch then
                            local noteForLog = officerNote or "<nil>"

                            print(string.format(
                                plainName,
                                noteForLog,
                                #words,
                                tostring(playerID),
                                tostring(words[3]),
                                gp
                            ))

                            debugCount = debugCount + 1
                        end
                    end

                    guildRosterInfo[plainName] = {
                        fullName = name,
                        publicNote = publicNote,
                        officerNote = officerNote,
                        classFileName = classFileName,
                        playerID = playerID,
                        gp = gp,
                        online = online
                    }
                end
            end

            if DEBUG_GP then
                print(string.format(
                    debugCount
                ))
            end

            if raidOnlyMode then
                local numRaidMembers = GetNumGroupMembers()

                for i = 1, numRaidMembers do
                    local raidName, _, _, _, _, classFileName = GetRaidRosterInfo(i)

                    if raidName then
                        local plainName = raidName:match("^(.-)-") or raidName
                        local guildInfo = guildRosterInfo[plainName]

                        if guildInfo then
                            local gp = guildInfo.gp or 0
                            local publicNote = guildInfo.publicNote or ""

                            if gp > 0 then
                                totalWithGP = totalWithGP + 1
                            end

                            local displayName = raidName

                            if publicNote and publicNote ~= "" then
                                displayName = raidName .. " |cFFFFFF00(" .. publicNote .. ")|r"
                            end

                            if DEBUG_GP then
                                print(string.format(
                                    plainName,
                                    gp,
                                    tostring(guildInfo.playerID)
                                ))
                            end

                            table.insert(db.gp_data, {
                                nick = displayName,
                                original_nick = plainName,
                                gp = gp,
                                classColor = RAID_CLASS_COLORS[classFileName]
                                    or RAID_CLASS_COLORS[guildInfo.classFileName]
                                    or { r = 1, g = 1, b = 1 },
                                classFileName = classFileName or guildInfo.classFileName,
                                playerID = guildInfo.playerID,
                                isGuildMember = true
                            })
                        else
                            local cachedGp = db.external_gp_cache[plainName] or 0

                            if cachedGp > 0 then
                                totalWithGP = totalWithGP + 1
                            end

                            if DEBUG_GP then
                                print(string.format(
                                    plainName,
                                    cachedGp
                                ))
                            end

                            table.insert(db.gp_data, {
                                nick = raidName,
                                original_nick = plainName,
                                gp = cachedGp,
                                classColor = RAID_CLASS_COLORS[classFileName] or { r = 1, g = 1, b = 1 },
                                classFileName = classFileName,
                                playerID = nil,
                                isGuildMember = false
                            })
                        end
                    end
                end

            elseif showAllGuild then
                for plainName, guildInfo in pairs(guildRosterInfo) do
                    if not showOfflineOnly and not guildInfo.online then
                        -- Пропускаем офлайн, если не включена галочка Off
                    else
                        local gp = guildInfo.gp or 0

                        if gp > 0 then
                            totalWithGP = totalWithGP + 1
                        end

                        local displayName = guildInfo.fullName

                        if guildInfo.publicNote and guildInfo.publicNote ~= "" then
                            displayName = guildInfo.fullName .. " |cFFFFFF00(" .. guildInfo.publicNote .. ")|r"
                        end

                        if DEBUG_GP then
                            print(string.format(
                                plainName,
                                gp,
                                tostring(guildInfo.online)
                            ))
                        end

                        table.insert(db.gp_data, {
                            nick = displayName,
                            original_nick = plainName,
                            gp = gp,
                            classColor = RAID_CLASS_COLORS[guildInfo.classFileName] or { r = 1, g = 1, b = 1 },
                            classFileName = guildInfo.classFileName,
                            playerID = guildInfo.playerID,
                            isGuildMember = true
                        })
                    end
                end

            else
                for plainName, guildInfo in pairs(guildRosterInfo) do
                    if guildInfo.officerNote and guildInfo.officerNote ~= "" then
                        local gp = guildInfo.gp or 0

                        if gp ~= 0 then
                            totalWithGP = totalWithGP + 1

                            local displayName = guildInfo.fullName

                            if guildInfo.publicNote and guildInfo.publicNote ~= "" then
                                displayName = guildInfo.fullName .. " |cFFFFFF00(" .. guildInfo.publicNote .. ")|r"
                            end

                            if DEBUG_GP then
                                print(string.format(
                                    plainName,
                                    gp
                                ))
                            end

                            table.insert(db.gp_data, {
                                nick = displayName,
                                original_nick = plainName,
                                gp = gp,
                                classColor = RAID_CLASS_COLORS[guildInfo.classFileName] or { r = 1, g = 1, b = 1 },
                                classFileName = guildInfo.classFileName,
                                playerID = guildInfo.playerID,
                                isGuildMember = true
                            })
                        end
                    end
                end
            end

            if db.filterText and db.filterText ~= "" then
                local filteredData = {}

                for _, entry in ipairs(db.gp_data) do
                    local nickMatch = string.find(entry.original_nick:lower(), db.filterText, 1, true)
                    local displayMatch = string.find(entry.nick:lower(), db.filterText, 1, true)

                    if nickMatch or displayMatch then
                        table.insert(filteredData, entry)
                    end
                end

                db.gp_data = filteredData
            end

            db.window.countText:SetText(string.format("Отображается игроков: %d", #db.gp_data))
            db.window.totalText:SetText(string.format(
                "Всего игроков с ГП: %d (из %d в гильдии)",
                totalWithGP,
                GetNumGuildMembers()
            ))

            db:ClearSelection()
            db:SortData()
            db:UpdateWindow()
        end
    end)
end

-- Сохраняет ГП игрока не из гильдии в кэш класса
-- Доступно извне: gpDb:SetExternalGp("Никколо", 50)
function GpDb:SetExternalGp(nick, gp)
    if not nick or type(nick) ~= "string" or nick == "" then return end
    local cleanNick = nick:match("^(.-)-") or nick
    local gpNumber = tonumber(gp) or 0
    
    if not self.external_gp_cache then
        self.external_gp_cache = {}
    end
    
    self.external_gp_cache[cleanNick] = gpNumber
end

function GpDb:GetExternalGp(nick)
    if not nick or type(nick) ~= "string" or nick == "" then return nil end
    local cleanNick = nick:match("^(.-)-") or nick
    
    if not self.external_gp_cache then return nil end
    
    return self.external_gp_cache[cleanNick]
end

function GpDb:GetAllExternalGp()
    if not self.external_gp_cache then
        self.external_gp_cache = {}
    end
    return self.external_gp_cache
end

function GpDb:Show()
    self.window:Show()
    
    -- Автоматически включаем режим "Только рейд", если мы в рейде
    if IsInRaid() then
        self.window.raidOnlyCheckbox:SetChecked(true)
    else
        self.window.raidOnlyCheckbox:SetChecked(false)
    end
    
    -- Принудительно обновляем данные гильдии перед показом
    GuildRoster()
    
    -- === ВЫЗОВ НОВОЙ ФУНКЦИИ ПРИ ОТКРЫТИИ ОКНА ===
    self:RequestNonGuildGP()
    -- ==============================================
    
    -- Сохраняем ссылку на оригинальный объект, так как внутри OnUpdate `self` будет указывать на фрейм таймера
    local ctx = self
    local timerFrame = CreateFrame("Frame")
    timerFrame:Hide()
    local elapsed = 0
    local delay = 0.1
    
    timerFrame:SetScript("OnUpdate", function(frame, dt)
        elapsed = elapsed + dt
        if elapsed >= delay then
            -- Полная остановка и очистка таймера
            frame:SetScript("OnUpdate", nil)
            frame:Hide()
            
            -- Выполнение отложенных методов в контексте оригинального объекта
            ctx:_UpdateFromGuild()
            ctx:UpdateWindow()
        end
    end)
end

function GpDb:AddGpEntry(nick, gp, playerID)
    table.insert(self.gp_data, {
        nick = nick,
        original_nick = nick,
        gp = tonumber(gp) or 0,
        playerID = playerID -- Добавляем ID игрока
    })
    self:SortData()
    self:UpdateWindow()
end

function GpDb:UpdateGpEntry(nick, new_gp)
    for _, entry in ipairs(self.gp_data) do
        if entry.original_nick == nick then
            entry.gp = tonumber(new_gp) or 0
            break
        end
    end
    self:SortData()
    self:UpdateWindow()
end

function GpDb:RemoveGpEntry(nick)
    for i, entry in ipairs(self.gp_data) do
        if entry.original_nick == nick then
            table.remove(self.gp_data, i)
            break
        end
    end
    self:UpdateWindow()
end

function GpDb:FindGpEntry(nick)
    for _, entry in ipairs(self.gp_data) do
        if entry.original_nick == nick then
            return entry.gp
        end
    end
    return nil
end

function GpDb:ClearAll()
    self.gp_data = {}
    self:UpdateWindow()
end

function GpDb:SortData(column)
    if column then
        if self.sort_column == column then
            self.sort_ascending = not self.sort_ascending
        else
            self.sort_column = column
            self.sort_ascending = true
        end
    end

    table.sort(self.gp_data, function(a, b)
        local valA, valB
        
        if self.sort_column == "nick" then
            -- Используем оригинальное имя для сортировки
            valA = string.lower(a.original_nick or "")
            valB = string.lower(b.original_nick or "")
        else
            valA = a.gp or 0
            valB = b.gp or 0
        end

        if self.sort_ascending then
            return valA < valB
        else
            return valA > valB
        end
    end)
    self:ClearSelection()
    self:UpdateWindow()
end

function GpDb:UpdateWindow()
    if not self.window or not self.rows then return end
    
    for i, row in ipairs(self.rows) do
        local entry = self.gp_data[i]
        if entry then
            row.nick:SetText(entry.nick)
            if entry.classColor then
                -- Применяем цвет класса только к имени (до скобок)
                local plainName = entry.nick:match("^[^|]+") or entry.nick
                row.nick:SetText(plainName)
                row.nick:SetTextColor(entry.classColor.r, entry.classColor.g, entry.classColor.b)
                
                -- Добавляем публичную заметку с желтым цветом
                local notePart = entry.nick:match("|c.+$")
                if notePart then
                    local fullText = row.nick:GetText() .. " " .. notePart
                    row.nick:SetText(fullText)
                end
            else
                row.nick:SetTextColor(1, 1, 1)
            end
            
            row.gp:SetText(tostring(entry.gp))
            row.gp:SetTextColor(1, 1, 1)
            
            row:Show()
        else
            row:Hide()
        end
    end
    
    self.window.scrollChild:SetHeight(#self.gp_data * 25)
    self.window.scrollFrame:UpdateScrollChildRect()
end

function GpDb:SaveToNsDb()
    for _, entry in ipairs(self.gp_data) do
        self.ns_db:addStaticStr("GP_DATA", entry.original_nick, nil, tostring(entry.gp))
    end
end

function GpDb:LoadFromNsDb()
    self.gp_data = {}
    local data = self.ns_db.input_table["GP_DATA"]
    if data then
        for nick, gp in pairs(data) do
            table.insert(self.gp_data, {
                nick = nick,
                original_nick = nick,
                gp = tonumber(gp) or 0
            })
        end
    end
    self:SortData()
    self:UpdateWindow()
end

function GpDb:_CreateRaidSelectionWindow()
    -- Создаем основное окно
    self.raidWindow = CreateFrame("Frame", "GpDbRaidWindow", self.window)
    self.raidWindow:SetFrameStrata("DIALOG")
    self.raidWindow:SetSize(500, self.window:GetHeight() * 0.5)
    self.raidWindow:SetPoint("BOTTOMLEFT", self.window, "BOTTOMRIGHT", 5, 0)
    self.raidWindow:SetMovable(false)
    
    -- Фон окна
    self.raidWindow.background = self.raidWindow:CreateTexture(nil, "BACKGROUND")
    self.raidWindow.background:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.raidWindow.background:SetVertexColor(0, 0, 0)
    self.raidWindow.background:SetAlpha(1)
    self.raidWindow.background:SetAllPoints(true)
    
    -- Граница окна
    self.raidWindow.borderFrame = CreateFrame("Frame", nil, self.raidWindow)
    self.raidWindow.borderFrame:SetPoint("TOPLEFT", -3, 3)
    self.raidWindow.borderFrame:SetPoint("BOTTOMRIGHT", 3, -3)
    self.raidWindow.borderFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    
    -- Кнопка закрытия
    self.raidWindow.closeButton = CreateFrame("Button", nil, self.raidWindow, "UIPanelCloseButton")
    self.raidWindow.closeButton:SetPoint("TOPRIGHT", -5, -5)
    self.raidWindow.closeButton:SetScript("OnClick", function()
        self.raidWindow:Hide()
    end)
    
    -- Выпадающий список рейдов
    self.raidWindow.dropdown = CreateFrame("Frame", "GpDbRaidDropdown", self.raidWindow, "UIDropDownMenuTemplate")
    self.raidWindow.dropdown:SetPoint("TOPLEFT", 10, -10)
    self.raidWindow.dropdown:SetPoint("RIGHT", -260, 0)
    self.raidWindow.dropdown:SetHeight(32)
    
    local function UpdateDropdownText()
        if self.raidWindow.selectedRaidId then
            for i = 1, GetNumSavedInstances() do
                local name, id = GetSavedInstanceInfo(i)
                if id == self.raidWindow.selectedRaidId then
                    UIDropDownMenu_SetText(self.raidWindow.dropdown, string.format("%d: %s", id, name))
                    return
                end
            end
        else
            UIDropDownMenu_SetText(self.raidWindow.dropdown, "Выберите рейд")
        end
    end
    
    local function InitializeDropdown(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for i = 1, GetNumSavedInstances() do
            local name, id, _, _, _, _, _, _, players = GetSavedInstanceInfo(i)
            if name and id then
                info.text = string.format("%d: %s (%d)", id, name, players)
                info.arg1 = {id = id, name = name, players = players}
                info.func = function(_, arg1)
                    self.raidWindow.selectedRaidId = arg1.id
                    self.raidWindow.selectedRaidName = arg1.name
                    self.raidWindow.selectedRaidPlayers = arg1.players
                    if self.saveSelectionEnabled then
                        self.lastSelectionType = "raid"
                        self.lastRaidId = arg1.id
                        self.lastRaidName = arg1.name
                        self.lastRaidPlayers = arg1.players
                    end
                    UpdateDropdownText()
                    self.raidWindow.editBox:SetText("")
                end
                info.checked = (self.raidWindow.selectedRaidId == id)
                UIDropDownMenu_AddButton(info)
            end
        end
        info.text = "Очистить выбор"
        info.func = function()
            self.raidWindow.selectedRaidId = nil
            self.raidWindow.selectedRaidName = nil
            if self.saveSelectionEnabled then
                self.lastSelectionType = nil
                self.lastRaidId = nil
                self.lastRaidName = nil
                self.lastRaidPlayers = 0
            end
            UpdateDropdownText()
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(self.raidWindow.dropdown, InitializeDropdown)
    UIDropDownMenu_SetWidth(self.raidWindow.dropdown, 200)
    UIDropDownMenu_SetButtonWidth(self.raidWindow.dropdown, 224)
    UIDropDownMenu_JustifyText(self.raidWindow.dropdown, "LEFT")
    UpdateDropdownText()
    
    -- Текст "Другое"
    self.raidWindow.otherText = self.raidWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.raidWindow.otherText:SetPoint("TOPLEFT", self.raidWindow.dropdown, "BOTTOMLEFT", 0, -10)
    self.raidWindow.otherText:SetText("Другое:")
    
    -- Поле ввода "Другое"
    self.raidWindow.editBox = CreateFrame("EditBox", "fdsfsda111111", self.raidWindow, "InputBoxTemplate")
    self.raidWindow.editBox:SetPoint("TOPLEFT", self.raidWindow.otherText, "BOTTOMLEFT", 0, -5)
    self.raidWindow.editBox:SetPoint("RIGHT", -260, 0)
    self.raidWindow.editBox:SetHeight(20)
    self.raidWindow.editBox:SetAutoFocus(false)
    self.raidWindow.editBox:SetScript("OnTextChanged", function(editBox)
        if editBox:GetText() ~= "" then
            if self.saveSelectionEnabled then
                self.lastSelectionType = "other"
                self.lastOtherText = editBox:GetText()
            end
            self.raidWindow.selectedRaidId = nil
            self.raidWindow.selectedRaidName = nil
            UpdateDropdownText()
        end
    end)
    
    -- Галочка "Сохранить выбор"
    self.raidWindow.saveCheckbox = CreateFrame("CheckButton", nil, self.raidWindow, "UICheckButtonTemplate")
    self.raidWindow.saveCheckbox:SetPoint("TOPLEFT", self.raidWindow.editBox, "BOTTOMLEFT", 0, -10)
    self.raidWindow.saveCheckbox:SetSize(24, 24)
    self.raidWindow.saveCheckbox.text = self.raidWindow.saveCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.raidWindow.saveCheckbox.text:SetPoint("LEFT", self.raidWindow.saveCheckbox, "RIGHT", 5, 0)
    self.raidWindow.saveCheckbox.text:SetText("Сохранить выбор")
    self.raidWindow.saveCheckbox:SetChecked(true)
    self.saveSelectionEnabled = true
    self.raidWindow.saveCheckbox:SetScript("OnClick", function()
        self.saveSelectionEnabled = self.raidWindow.saveCheckbox:GetChecked()
    end)
    
    -- Текст с выбранными игроками
    self.raidWindow.selectedPlayersText = self.raidWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.raidWindow.selectedPlayersText:SetPoint("TOPLEFT", self.raidWindow.saveCheckbox, "BOTTOMLEFT", 0, -5)
    self.raidWindow.selectedPlayersText:SetPoint("RIGHT", -260, 0)
    self.raidWindow.selectedPlayersText:SetHeight(70)
    self.raidWindow.selectedPlayersText:SetJustifyH("LEFT")
    self.raidWindow.selectedPlayersText:SetJustifyV("TOP")
    self.raidWindow.selectedPlayersText:SetWordWrap(true)
    
    -- Кнопки быстрого ввода ГП
    local quickGPValues = {5, 10, 20, 25, 50, 100}
    local lastQuickButton
    for i, value in ipairs(quickGPValues) do
        local btn = CreateFrame("Button", nil, self.raidWindow, "UIPanelButtonTemplate")
        btn:SetSize(27, 20)
        btn:SetText(tostring(value))
        if i == 1 then
            btn:SetPoint("BOTTOMLEFT", self.raidWindow.selectedPlayersText, "BOTTOMLEFT", 0, -20)
        else
            btn:SetPoint("LEFT", lastQuickButton, "RIGHT", 2, 0)
        end
        btn:SetScript("OnClick", function()
            self.raidWindow.gpEditBox:SetText(tostring(value))
            self.raidWindow.gpEditBox:HighlightText()
        end)
        lastQuickButton = btn
    end
    
    -- Кнопка минуса
    local minusBtn = CreateFrame("Button", nil, self.raidWindow, "UIPanelButtonTemplate")
    minusBtn:SetSize(40, 22)
    minusBtn:SetText("-/+")
    minusBtn:SetPoint("LEFT", lastQuickButton, "RIGHT", 2, 0)
    minusBtn:SetScript("OnClick", function()
        local currentValue = tonumber(self.raidWindow.gpEditBox:GetText()) or 0
        self.raidWindow.gpEditBox:SetText(tostring(-currentValue))
        self.raidWindow.gpEditBox:HighlightText()
    end)
    lastQuickButton = minusBtn
    
    -- Кнопка процента
    local percentBtn = CreateFrame("Button", nil, self.raidWindow, "UIPanelButtonTemplate")
    percentBtn:SetSize(27, 20)
    percentBtn:SetText("%")
    percentBtn:SetPoint("LEFT", lastQuickButton, "RIGHT", 2, 0)
    percentBtn:SetScript("OnClick", function()
        local inputText = self.raidWindow.gpEditBox:GetText()
        local percentValue = tonumber(inputText)
        if not percentValue or percentValue <= 0 then
            print("|cFFFF0000ГП:|r Укажите положительное число для процента")
            return
        end
        local selected = self:GetSelectedEntries()
        if #selected ~= 1 then
            print("|cFFFF0000ГП:|r Процент можно применить только к одному игроку")
            return
        end
        local playerGp = selected[1].gp or 0
        local newGp = math.floor(playerGp * percentValue / 100)
        self.raidWindow.gpEditBox:SetText(tostring(newGp))
        self.raidWindow.gpEditBox:HighlightText()
    end)
    
    -- Поле ввода ГП
    self.raidWindow.gpEditBox = CreateFrame("EditBox", "fdjkjfkjkj33333", self.raidWindow, "InputBoxTemplate")
    self.raidWindow.gpEditBox:SetPoint("BOTTOMLEFT", 10, 5)
    self.raidWindow.gpEditBox:SetSize(100, 20)
    self.raidWindow.gpEditBox:SetAutoFocus(false)
    self.raidWindow.gpEditBox:SetScript("OnEscapePressed", function() self.raidWindow.gpEditBox:ClearFocus() end)
    self.raidWindow.gpEditBox:SetScript("OnEnterPressed", function() self.raidWindow.gpEditBox:ClearFocus() end)
    
    -- Кнопка "Начислить"
    self.raidWindow.awardButton = CreateFrame("Button", nil, self.raidWindow, "UIPanelButtonTemplate")
    self.raidWindow.awardButton:SetPoint("BOTTOMRIGHT", -10, 5)
    self.raidWindow.awardButton:SetSize(100, 22)
    self.raidWindow.awardButton:SetText("Начислить")
    self.raidWindow.awardButton:SetScript("OnClick", function()
        if not self:_CheckOfficerRank() then
            print("|cFFFF0000ГП:|r Только офицеры могут начислять ГП")
            self.raidWindow:Hide()
            return
        end
        if next(self.selected_indices) == nil then
            print("|cFFFF0000ГП:|r Нет выделенных игроков")
            self.raidWindow:Hide()
            return
        end
        local gpValue = tonumber(self.raidWindow.gpEditBox:GetText())
        if not gpValue then
            print("|cFFFF0000ГП:|r Укажите значение ГП")
            return
        end
        if not self.raidWindow.selectedRaidId and not (self.lastOtherText or ""):match("%S") then
            print("|cFFFF0000ГП:|r Нужно выбрать рейд или указать причину")
            return
        end
        if not self.saveSelectionEnabled then
            self.lastSelectionType = nil
            self.lastRaidId = nil
            self.lastRaidName = nil
            self.lastRaidPlayers = 0
            self.lastOtherText = nil
            self.lastGPValue = 0
        else
            self.lastGPValue = gpValue
        end
        
        local logStr
        if self.raidWindow.selectedRaidId then
            local cleanRaidName = (self.raidWindow.selectedRaidName or ""):gsub("%s+", "_")
            logStr = string.format("%04d_%s_%d %d",
                self.raidWindow.selectedRaidId,
                cleanRaidName,
                self.raidWindow.selectedRaidPlayers or 0,
                gpValue)
        else
            local cleanOtherText = (self.lastOtherText or ""):gsub("%s+", "_")
            logStr = string.format("%s %d", cleanOtherText, gpValue)
        end
        
        local nonGuildNicks = {}
        
        for index in pairs(self.selected_indices) do
            if self.gp_data[index] then
                local entry = self.gp_data[index]
                local nick = entry.original_nick
                
                local prefix = entry.isGuildMember and "nsGP1" or "nsGP1A"
                
                SendAddonMessage(prefix .. " " .. gpValue, nick, "GUILD")
                
                if prefix == "nsGP1A" then
                    table.insert(nonGuildNicks, nick)
                end
                
                local logIdentifier = entry.playerID or ("N:" .. nick)
                logStr = logStr .. " " .. logIdentifier
                
                self:AddLogEntry(gpValue, date("%H:%M"), UnitName("player"),
                    self.raidWindow.selectedRaidName or self.raidWindow.editBox:GetText(), nick)
            end
        end
        
        SendAddonMessage("nsGPlog", logStr, "GUILD")
        
        for _, entry in ipairs(self:GetSelectedEntries()) do
            entry.gp = (entry.gp or 0) + gpValue
        end
        self:UpdateWindow()
        self.raidWindow:Hide()
        
        if #nonGuildNicks > 0 then
        end
        
        if #nonGuildNicks > 0 then
            local timerFrame = CreateFrame("Frame")
            -- УБРАЛИ timerFrame:Hide() — фрейм остаётся видимым
            local elapsed = 0
            local initialDelay = 1.0
            local betweenDelay = 0.05
            local currentIndex = 1
            local phase = "waiting"
            
            timerFrame:SetScript("OnUpdate", function(frame, dt)
                elapsed = elapsed + dt
                
                if phase == "waiting" then
                    if elapsed >= initialDelay then
                        phase = "sending"
                        elapsed = 0
                        SendAddonMessage("GetGPA", nonGuildNicks[currentIndex], "GUILD")
                        currentIndex = currentIndex + 1
                    end
                elseif phase == "sending" then
                    if elapsed >= betweenDelay then
                        elapsed = 0
                        if currentIndex <= #nonGuildNicks then
                            SendAddonMessage("GetGPA", nonGuildNicks[currentIndex], "GUILD")
                            currentIndex = currentIndex + 1
                        else
                            frame:SetScript("OnUpdate", nil)
                            frame:Hide()
                        end
                    end
                end
            end)
        else
        end
    end)
    
    self.raidWindow:SetScript("OnHide", function()
        if self.logWindow and self.logWindow:IsShown() then
            self.logWindow:SetHeight(self.window:GetHeight())
        end
    end)
    self.raidWindow:Hide()
end

function GpDb:RequestNonGuildGP()
    -- Проверяем, находимся ли мы в рейде, так как запрос имеет смысл только для рейда
    if not IsInRaid() then 
        return 
    end
    
    -- Собираем имена всех членов гильдии (без суффикса сервера) в таблицу для быстрого поиска
    local guildNames = {}
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name then
            local plainName = name:match("^(.-)-") or name
            guildNames[plainName] = true
        end
    end
    
    -- Проходим по всем участникам рейда
    for i = 1, GetNumGroupMembers() do
        local raidName = GetRaidRosterInfo(i)
        if raidName then
            local plainName = raidName:match("^(.-)-") or raidName
            
            -- Если игрока нет в списке гильдии, отправляем запрос данных
            if not guildNames[plainName] then
                -- Отправляем префикс "GetGPA" и ник игрока в теле сообщения в канал гильдии
                SendAddonMessage("GetGPA", plainName, "GUILD")
            end
        end
    end
end

function GpDb:_UpdatePlayerInfo()
    if not self.raidWindow or not self.raidWindow:IsShown() then return end
    local selected = self:GetSelectedEntries()
    if #selected ~= 1 then
        if self.raidWindow.playerInfoContainer then
            self.raidWindow.playerInfoContainer:Hide()
        end
        return
    end
    local nick = selected[1].original_nick
    local found = false
    local playerData = nil
    local rosterIndex = nil
    for i = 1, GetNumGuildMembers() do
        local name, rankName, rankIndex, level, classFileName, zone, publicNote, officerNote, online = GetGuildRosterInfo(i)
        if name then
            local plainName = name:match("^(.-)-") or name
            if plainName == nick then
                found = true
                rosterIndex = i
                playerData = {
                    name = name,
                    rankName = rankName,
                    rankIndex = rankIndex,
                    level = level,
                    classFileName = classFileName,
                    publicNote = publicNote or "",
                    officerNote = officerNote or "",
                    online = online,
                    index = i
                }
                break
            end
        end
    end
    if not found then
        if self.raidWindow.playerInfoContainer then
            self.raidWindow.playerInfoContainer:Hide()
        end
        return
    end
    -- === ОТПРАВКА ЗАПРОСА НА ПРОВЕРКУ ПРАВ РЛ ===
    if self.lastCheckedPlayer ~= nick then
        self.lastCheckedPlayer = nick
        local myName = UnitName("player")
        SendAddonMessage("ns_get_rl", myName .. " " .. nick, "GUILD")
    end
    -- === СОЗДАНИЕ КОНТЕЙНЕРА И ЭЛЕМЕНТОВ ОДИН РАЗ ===
    if not self.raidWindow.playerInfoContainer then
        self.raidWindow.playerInfoContainer = CreateFrame("Frame", nil, self.raidWindow)
        self.raidWindow.playerInfoContainer:SetPoint("TOPRIGHT", -10, -30)
        self.raidWindow.playerInfoContainer:SetSize(230, 240)

        -- === ЧЕКБОКС ПОД КНОПКОЙ ЗАКРЫТИЯ ===
        local checkboxName = "GpDbPlayerInfoCheckbox"
        local checkbox = CreateFrame("CheckButton", checkboxName, self.raidWindow, "ChatConfigCheckButtonTemplate")
        checkbox:SetSize(24, 24)
        checkbox:SetPoint("TOPRIGHT", self.raidWindow.closeButton, "BOTTOMRIGHT", 0, -5)
        checkbox:Disable()
        checkbox.targetNick = nick
        checkbox:SetScript("OnClick", function(self_cb)
            local isChecked = self_cb:GetChecked()
            local boolStr = isChecked and "1" or "nil"
            SendAddonMessage("ns_its_rl", self_cb.targetNick .. " " .. boolStr, "GUILD")
        end)

        -- === ОБНОВЛЁННЫЙ ТУЛТИП ===
        checkbox:SetScript("OnEnter", function(self_cb)
            GameTooltip:SetOwner(self_cb, "ANCHOR_RIGHT")
            local baseText = "Назначить игрока РЛом"
            if #self.rl_tooltip_nicks > 0 then
                local listStr = table.concat(self.rl_tooltip_nicks, ", ")
                baseText = baseText .. "\n\nТекущие РЛы:\n" .. listStr
            end
            GameTooltip:SetText(baseText)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.raidWindow.playerInfoCheckbox = checkbox
        local textRegion = _G[checkboxName .. "Text"]
        if textRegion then
            textRegion:SetText("")
        end
        local myName = UnitName("player")
        if self.confirmed_rl_nicks and self.confirmed_rl_nicks[myName] then
            self.raidWindow.playerInfoCheckbox:Enable()
        end

        -- === ЭЛЕМЕНТЫ ИНТЕРФЕЙСА ===
        self.raidWindow.classText = self.raidWindow.playerInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self.raidWindow.classText:SetPoint("TOPLEFT", 0, -5)
        self.raidWindow.classText:SetWidth(230)
        self.raidWindow.levelText = self.raidWindow.playerInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self.raidWindow.levelText:SetPoint("TOPLEFT", 0, -25)
        self.raidWindow.levelText:SetWidth(230)
        self.raidWindow.offlineText = self.raidWindow.playerInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self.raidWindow.offlineText:SetPoint("TOPLEFT", 0, -45)
        self.raidWindow.offlineText:SetWidth(230)
        self.raidWindow.rankFrame = CreateFrame("Frame", nil, self.raidWindow.playerInfoContainer)
        self.raidWindow.rankFrame:SetSize(230, 20)
        self.raidWindow.rankFrame:SetPoint("TOPLEFT", 0, -65)
        self.raidWindow.minusBtn = CreateFrame("Button", nil, self.raidWindow.rankFrame, "UIPanelButtonTemplate")
        self.raidWindow.minusBtn:SetSize(20, 20)
        self.raidWindow.minusBtn:SetPoint("LEFT", 0, 0)
        self.raidWindow.minusBtn:SetText("-")
        self.raidWindow.rankText = self.raidWindow.rankFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self.raidWindow.rankText:SetPoint("LEFT", self.raidWindow.minusBtn, "RIGHT", 5, 0)
        self.raidWindow.rankText:SetPoint("RIGHT", -25, 0)
        self.raidWindow.plusBtn = CreateFrame("Button", nil, self.raidWindow.rankFrame, "UIPanelButtonTemplate")
        self.raidWindow.plusBtn:SetSize(20, 20)
        self.raidWindow.plusBtn:SetPoint("RIGHT", 0, 0)
        self.raidWindow.plusBtn:SetText("+")
        self.raidWindow.publicBtn = CreateFrame("Button", nil, self.raidWindow.playerInfoContainer, "UIPanelButtonTemplate")
        self.raidWindow.publicBtn:SetSize(230, 20)
        self.raidWindow.publicBtn:SetPoint("TOPLEFT", 0, -90)
        self.raidWindow.officerBtn = CreateFrame("Button", nil, self.raidWindow.playerInfoContainer, "UIPanelButtonTemplate")
        self.raidWindow.officerBtn:SetSize(230, 20)
        self.raidWindow.officerBtn:SetPoint("TOPLEFT", 0, -115)

        -- === КНОПКА "ЗАМЕТКИ РЛОВ" ===
        self.raidWindow.rlNotesBtn = CreateFrame("Button", nil, self.raidWindow.playerInfoContainer, "UIPanelButtonTemplate")
        self.raidWindow.rlNotesBtn:SetSize(230, 20)
        self.raidWindow.rlNotesBtn:SetPoint("TOPLEFT", 0, -140)
        self.raidWindow.rlNotesBtn:SetText("Заметки РЛов")
    else
        self.raidWindow.playerInfoContainer:Show()
        if self.raidWindow.playerInfoCheckbox then
            self.raidWindow.playerInfoCheckbox.targetNick = nick
        end
    end

    -- === ОБНОВЛЕНИЕ ДАННЫХ ИГРОКА ===
    local db = self
    local className = "Класс: ?"
    if playerData.classFileName then
        local color = RAID_CLASS_COLORS[playerData.classFileName]
        if color then
            local hex = string.format("|cFF%02x%02x%02x", color.r*255, color.g*255, color.b*255)
            className = hex .. playerData.classFileName .. "|r"
        else
            className = "|cFFFFFFFF" .. playerData.classFileName .. "|r"
        end
    end
    self.raidWindow.classText:SetText(className)
    self.raidWindow.levelText:SetText("Уровень: " .. (playerData.level or "?"))
    local offlineStr = "Офлайн: "
    if playerData.online then
        offlineStr = offlineStr .. "в сети"
    else
        local years, months, days, hours = GetGuildRosterLastOnline(rosterIndex)
        if years ~= nil then
            if years > 0 then
                offlineStr = string.format("Офлайн: %dг %dм %dд %dч", years, months, days, hours)
            elseif months > 0 then
                offlineStr = string.format("Офлайн: %dм %dд %dч", months, days, hours)
            else
                offlineStr = string.format("Офлайн: %dд %dч", days, hours)
            end
        else
            offlineStr = offlineStr .. "—"
        end
    end
    self.raidWindow.offlineText:SetText(offlineStr)
    self.raidWindow.rankText:SetText("Звание: " .. (playerData.rankName or "?"))
    self.raidWindow.minusBtn:SetScript("OnClick", function()
        if not db:_CheckOfficerRank() then
            print("|cFFFF0000ГП:|r Только офицеры могут менять звания")
            return
        end
        GuildDemote(playerData.name)
        -- Сохраняем ссылку на объект, чтобы гарантировать доступ внутри замыкания OnUpdate
        local dbRef = db
        local timerFrame = CreateFrame("Frame")
        timerFrame:Hide()

        local elapsed = 0
        local delay = 0.5

        timerFrame:SetScript("OnUpdate", function(frame, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                -- Полная остановка и "очистка" таймера
                frame:SetScript("OnUpdate", nil)
                frame:Hide()
                
                -- Вызов отложенного метода в правильном контексте
                dbRef:_UpdatePlayerInfo()
            end
        end)
    end)
    self.raidWindow.plusBtn:SetScript("OnClick", function()
        if not db:_CheckOfficerRank() then
            print("|cFFFF0000ГП:|r Только офицеры могут менять звания")
            return
        end
        GuildPromote(playerData.name)
        -- Сохраняем ссылку на объект, чтобы гарантировать доступ внутри замыкания OnUpdate
        local dbRef = db
        local timerFrame = CreateFrame("Frame")
        timerFrame:Hide()

        local elapsed = 0
        local delay = 0.5

        timerFrame:SetScript("OnUpdate", function(frame, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                -- Полная остановка и "очистка" таймера
                frame:SetScript("OnUpdate", nil)
                frame:Hide()
                
                -- Вызов отложенного метода в правильном контексте
                dbRef:_UpdatePlayerInfo()
            end
        end)
    end)
    self.raidWindow.publicBtn:SetText("Публ.: " .. (playerData.publicNote ~= "" and playerData.publicNote or "—"))
    self.raidWindow.publicBtn:SetScript("OnClick", function()
        StaticPopupDialogs["GP_EDIT_PUBLIC_NOTE"] = {
            text = "Изменить публичную заметку для " .. playerData.name,
            button1 = "OK",
            button2 = "Отмена",
            hasEditBox = true,
            editBoxWidth = 200,
            OnShow = function(self)
                self.editBox:SetText(playerData.publicNote)
                self.editBox:SetFocus()
            end,
            OnAccept = function(self)
                local newNote = self.editBox:GetText()
                if not db:_CheckOfficerRank() then
                    print("|cFFFF0000ГП:|r Только офицеры могут редактировать заметки")
                    return
                end
                GuildRosterSetPublicNote(playerData.index, newNote)
                GuildRoster()
                local frame = CreateFrame("Frame")
                frame:SetScript("OnEvent", function()
                    db:_UpdatePlayerInfo()
                    frame:UnregisterEvent("GUILD_ROSTER_UPDATE")
                end)
                frame:RegisterEvent("GUILD_ROSTER_UPDATE")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("GP_EDIT_PUBLIC_NOTE")
    end)
    self.raidWindow.officerBtn:SetText("Оф.: " .. (playerData.officerNote ~= "" and playerData.officerNote or "—"))
    self.raidWindow.officerBtn:SetScript("OnClick", function()
        StaticPopupDialogs["GP_EDIT_OFFICER_NOTE"] = {
            text = "Изменить офицерскую заметку для " .. playerData.name,
            button1 = "OK",
            button2 = "Отмена",
            hasEditBox = true,
            editBoxWidth = 200,
            OnShow = function(self)
                self.editBox:SetText(playerData.officerNote)
                self.editBox:SetFocus()
            end,
            OnAccept = function(self)
                local newNote = self.editBox:GetText()
                if not db:_CheckOfficerRank() then
                    print("|cFFFF0000ГП:|r Только офицеры могут редактировать заметки")
                    return
                end
                GuildRosterSetOfficerNote(playerData.index, newNote)
                GuildRoster()
                local frame = CreateFrame("Frame")
                frame:SetScript("OnEvent", function()
                    db:_UpdatePlayerInfo()
                    frame:UnregisterEvent("GUILD_ROSTER_UPDATE")
                end)
                frame:RegisterEvent("GUILD_ROSTER_UPDATE")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true
        }
        StaticPopup_Show("GP_EDIT_OFFICER_NOTE")
    end)

    -- === ОБНОВЛЕНИЕ ONCLICK ДЛЯ КНОПКИ "ЗАМЕТКИ РЛОВ" ===
    self.raidWindow.rlNotesBtn:SetScript("OnClick", function()
        local selectedEntries = self:GetSelectedEntries()
        if #selectedEntries == 1 then
            local targetNick = selectedEntries[1].original_nick
            if self.raidWindow.playerInfoContainer then
                self.raidWindow.playerInfoContainer:Hide()
            end
            SendAddonMessage("ns_get_rl_notes", targetNick, "GUILD")
        else
            print("|cFFFF0000[DEBUG]|r ОШИБКА: выделено не 1 игрок (выделено:", #selectedEntries, ")")
        end
    end)

    -- Показываем кнопку, только если чекбокс активен (мы — РЛ)
    if self.raidWindow.playerInfoCheckbox:IsEnabled() then
        self.raidWindow.rlNotesBtn:Show()
    else
        self.raidWindow.rlNotesBtn:Hide()
    end
end

function GpDb:_UpdateSelectedPlayersText()
    if not self.raidWindow then return end
    
    local selected = self:GetSelectedEntries()
    local names = {}
    
    for _, entry in ipairs(selected) do
        table.insert(names, entry.original_nick)
    end
    
    local text = table.concat(names, ", ")
    
    -- Создаем или обновляем текстовый элемент
    if not self.raidWindow.selectedPlayersText then
        self.raidWindow.selectedPlayersText = self.raidWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        self.raidWindow.selectedPlayersText:SetPoint("TOPLEFT", self.raidWindow.saveCheckbox, "BOTTOMLEFT", 0, -5)
        self.raidWindow.selectedPlayersText:SetPoint("RIGHT", -10, 0)
        self.raidWindow.selectedPlayersText:SetHeight(80)
        self.raidWindow.selectedPlayersText:SetJustifyH("LEFT")
        self.raidWindow.selectedPlayersText:SetJustifyV("TOP")
        self.raidWindow.selectedPlayersText:SetWordWrap(true)
        
        -- Создаем фрейм-контейнер для обработки событий мыши
        self.raidWindow.selectedPlayersTextContainer = CreateFrame("Frame", nil, self.raidWindow)
        self.raidWindow.selectedPlayersTextContainer:SetAllPoints(self.raidWindow.selectedPlayersText)
        self.raidWindow.selectedPlayersTextContainer:SetScript("OnEnter", function()
            if self.raidWindow.selectedPlayersText.tooltip then
                GameTooltip:SetOwner(self.raidWindow.selectedPlayersTextContainer, "ANCHOR_RIGHT")
                GameTooltip:SetText("Выбранные игроки:")
                GameTooltip:AddLine(self.raidWindow.selectedPlayersText.tooltip, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        self.raidWindow.selectedPlayersTextContainer:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- Устанавливаем текст с обрезкой если нужно
    if #text > 60 then
        local shortText = string.sub(text, 1, 600) .. "..."
        self.raidWindow.selectedPlayersText:SetText(shortText)
        self.raidWindow.selectedPlayersText.tooltip = text
    else
        self.raidWindow.selectedPlayersText:SetText(text)
        self.raidWindow.selectedPlayersText.tooltip = nil
    end
end

function GpDb:RestoreRaidWindowState()
    if not self.raidWindow then return end
    
    -- Восстанавливаем значения из сохраненных состояний
    if self.lastSelectionType == "raid" and self.lastRaidId then
        UIDropDownMenu_SetText(self.raidWindow.dropdown, string.format("%d: %s", self.lastRaidId, self.lastRaidName))
        self.raidWindow.editBox:SetText("")
        self.raidWindow.selectedRaidId = self.lastRaidId
        self.raidWindow.selectedRaidName = self.lastRaidName
        self.raidWindow.selectedRaidPlayers = self.lastRaidPlayers
    elseif self.lastSelectionType == "other" and self.lastOtherText then
        UIDropDownMenu_SetText(self.raidWindow.dropdown, "Выберите рейд")
        self.raidWindow.editBox:SetText(self.lastOtherText)
        self.raidWindow.selectedRaidId = nil
        self.raidWindow.selectedRaidName = nil
    else
        UIDropDownMenu_SetText(self.raidWindow.dropdown, "Выберите рейд")
        self.raidWindow.editBox:SetText("")
        self.raidWindow.selectedRaidId = nil
        self.raidWindow.selectedRaidName = nil
    end
    
    -- Всегда отображаем lastGPValue, даже если 0
    if not self.lastGPValue then
        self.lastGPValue = 0
    end
    self.raidWindow.gpEditBox:SetText(tostring(self.lastGPValue))
    self.raidWindow.saveCheckbox:SetChecked(self.saveSelectionEnabled)
    
    -- Обновляем список выбранных игроков
    self:_UpdateSelectedPlayersText()
end

function GpDb:_CheckOfficerRank()
    if not IsInGuild() then return false end
    
    local playerName = UnitName("player")
    for i = 1, GetNumGuildMembers() do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if name and name == playerName then
            -- Получаем информацию о звании
            local rankName = GuildControlGetRankName(rankIndex + 1) -- rankIndex начинается с 0
            -- Проверяем, является ли звание офицерским (Капитан или Лейтенант)
            if rankName == "Капитан" or rankName == "Лейтенант" then
                return true
            end
            break
        end
    end
    return false
end

-- Добавляем метод для показа/скрытия окна
function GpDb:ToggleRaidWindow()
    -- Проверяем звание игрока
    if not self:_CheckOfficerRank() then
        print("|cFFFF0000ГП:|r Только офицеры могут начислять ГП")
        if self.raidWindow and self.raidWindow:IsShown() then
            self.raidWindow:Hide()
        end
        return
    end
    
    if not self.raidWindow then
        self:_CreateRaidSelectionWindow()
    end
    
    local inRaid = IsInRaid()
    local raidOnlyChecked = self.window.raidOnlyCheckbox:GetChecked()
    local hasSelection = next(self.selected_indices) ~= nil
    
    if not hasSelection and not self.raidWindow:IsShown() then
        self.raidWindow:Show()
        UIDropDownMenu_Initialize(self.raidWindow.dropdown, nil)
        return
    end
    
    if hasSelection then
        if inRaid and not raidOnlyChecked then
            print("|cFFFF0000ГП:|r Для начисления ГП в рейде включите 'Только рейд'")
            self.raidWindow:Hide()
            return
        end
        
        if self.raidWindow:IsShown() then
            self.raidWindow:Hide()
        else
            self.raidWindow:Show()
            UIDropDownMenu_Initialize(self.raidWindow.dropdown, nil)
        end
    end
end

function GpDb:ShowRlNotesEditor(targetNick, noteText)
    -- === 1. Эмулируем нажатие на крестик raidWindow, если он открыт ===
    if self.raidWindow and self.raidWindow:IsShown() and self.raidWindow.closeButton then
        local script = self.raidWindow.closeButton:GetScript("OnClick")
        if script then
            script(self.raidWindow.closeButton)
        end
    end
    -- === 2. Открываем редактор заметок ===
    if not self.rlNotesEditor then
        self:_CreateRlNotesEditor()
    end
    self.rlNotesEditor.targetNick = targetNick
    self.rlNotesEditor.editBox:SetText(noteText or "")
    self.rlNotesEditor.title:SetText("Заметки РЛов: " .. targetNick)
    self.rlNotesEditor:Show()
    self.rlNotesEditor.editBox:SetFocus()
end

function GpDb:_CreateRlNotesEditor()
    self.rlNotesEditor = CreateFrame("Frame", "GpDbRlNotesEditor", UIParent)
    self.rlNotesEditor:SetSize(400, 300)
    self.rlNotesEditor:SetPoint("CENTER", UIParent, "CENTER")
    self.rlNotesEditor:SetFrameStrata("FULLSCREEN_DIALOG")
    self.rlNotesEditor:EnableMouse(true)
    self.rlNotesEditor:SetMovable(true)
    self.rlNotesEditor:RegisterForDrag("LeftButton")
    self.rlNotesEditor:SetScript("OnDragStart", self.rlNotesEditor.StartMoving)
    self.rlNotesEditor:SetScript("OnDragStop", self.rlNotesEditor.StopMovingOrSizing)
    local bg = self.rlNotesEditor:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    bg:SetAllPoints()
    self.rlNotesEditor.border = CreateFrame("Frame", nil, self.rlNotesEditor)
    self.rlNotesEditor.border:SetPoint("TOPLEFT", -3, 3)
    self.rlNotesEditor.border:SetPoint("BOTTOMRIGHT", 3, -3)
    self.rlNotesEditor.border:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.rlNotesEditor.title = self.rlNotesEditor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.rlNotesEditor.title:SetPoint("TOP", 0, -10)
    self.rlNotesEditor.title:SetText("Заметки РЛов")
    -- Кнопка закрытия
    self.rlNotesEditor.closeBtn = CreateFrame("Button", nil, self.rlNotesEditor, "UIPanelCloseButton")
    self.rlNotesEditor.closeBtn:SetPoint("TOPRIGHT", -5, -5)
    self.rlNotesEditor.closeBtn:SetScript("OnClick", function()
        if self.rlNotesEditor.targetNick then
            _rlNotesReassembly[self.rlNotesEditor.targetNick] = nil
        end
        self.rlNotesEditor:Hide()
    end)
    -- Кнопка "Сохранить" (S)
    self.rlNotesEditor.saveBtn = CreateFrame("Button", nil, self.rlNotesEditor, "UIPanelButtonTemplate")
    self.rlNotesEditor.saveBtn:SetSize(24, 24)
    self.rlNotesEditor.saveBtn:SetPoint("TOPLEFT", 8, -8)
    self.rlNotesEditor.saveBtn:SetText("S")
    self.rlNotesEditor.saveBtn:SetScript("OnClick", function()
        if not self.rlNotesEditor.targetNick then
            print("|cFFFF0000[NSRL DEBUG]|r Ошибка: нет targetNick при сохранении")
            self.rlNotesEditor:Hide()
            return
        end
        local noteText = self.rlNotesEditor.editBox:GetText()
        local targetNick = self.rlNotesEditor.targetNick
        local prefix = "ns_RL_notes"
        local MAX_BODY_BYTES = 240
        local header = targetNick .. " "
        local headerByteLen = #header
        if headerByteLen >= MAX_BODY_BYTES then
            print("|cFFFF0000[NSRL DEBUG]|r Ошибка: ник слишком длинный (байт:", headerByteLen, "):", targetNick)
            self.rlNotesEditor:Hide()
            return
        end
        local maxNoteBytes = MAX_BODY_BYTES - headerByteLen
        local maxChars = math.floor(maxNoteBytes / 2)
        if maxChars < 1 then maxChars = 1 end
        local noteLen = utf8myLen(noteText) or 0
        local chunks = {}
        local startPos = 1
        while startPos <= noteLen do
            local endPos = startPos + maxChars - 1
            if endPos > noteLen then
                endPos = noteLen
            end
            local chunk = utf8mySub(noteText, startPos, endPos)
            if not chunk or chunk == "" then
                startPos = startPos + 1
            else
                table.insert(chunks, header .. chunk)
                startPos = endPos + 1
            end
            if startPos > 100000 then break end
        end
        if #chunks == 0 then
            table.insert(chunks, header)
        end
        local i = 1
        -- Создаём фрейм таймера один раз для всей последовательности
        local sendTimer = CreateFrame("Frame")
        sendTimer:Hide()
        local sendElapsed = 0
        local sendDelay = 0.15
        local ctx = self -- Захватываем внешний self, т.к. внутри OnUpdate self будет указывать на фрейм таймера

        local function sendNext()
            if i > #chunks then
                _rlNotesReassembly[targetNick] = nil
                ctx.rlNotesEditor:Hide()
                sendTimer:SetScript("OnUpdate", nil)
                sendTimer:Hide()
                return
            end

            SendAddonMessage(prefix, chunks[i], "GUILD")
            i = i + 1

            -- Сбрасываем счётчик и запускаем отложенный вызов
            sendElapsed = 0
            sendTimer:SetScript("OnUpdate", function(frame, dt)
                sendElapsed = sendElapsed + dt
                if sendElapsed >= sendDelay then
                    -- Полная остановка и "очистка" таймера
                    frame:SetScript("OnUpdate", nil)
                    frame:Hide()
                    sendNext()
                end
            end)
        end
        sendNext()
    end)
    -- Тултип для "Сохранить"
    self.rlNotesEditor.saveBtn:SetScript("OnEnter", function(self_btn)
        GameTooltip:SetOwner(self_btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Сохранить")
        GameTooltip:Show()
    end)
    self.rlNotesEditor.saveBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    -- Кнопка "Получить историю правок" (F)
    self.rlNotesEditor.fullBtn = CreateFrame("Button", nil, self.rlNotesEditor, "UIPanelButtonTemplate")
    self.rlNotesEditor.fullBtn:SetSize(24, 24)
    self.rlNotesEditor.fullBtn:SetPoint("LEFT", self.rlNotesEditor.saveBtn, "RIGHT", 2, 0)
    self.rlNotesEditor.fullBtn:SetText("F")
    self.rlNotesEditor.fullBtn:SetScript("OnClick", function()
        if not self.rlNotesEditor.targetNick then
            print("|cFFFF0000[NSRL DEBUG]|r Ошибка: нет targetNick при запросе истории")
            return
        end
        local targetNick = self.rlNotesEditor.targetNick
        SendAddonMessage("ns_RL_notes_full", targetNick, "GUILD")
    end)
    -- Тултип для "Получить историю правок"
    self.rlNotesEditor.fullBtn:SetScript("OnEnter", function(self_btn)
        GameTooltip:SetOwner(self_btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Получить историю правок")
        GameTooltip:Show()
    end)
    self.rlNotesEditor.fullBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    -- Скроллируемый контейнер для текста
    local scrollFrame = CreateFrame("ScrollFrame", "GpDbRlNotesScrollFrame", self.rlNotesEditor, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", 0, -40)
    scrollFrame:SetPoint("BOTTOM", 0, 40)
    scrollFrame:SetPoint("LEFT", 10, 0)
    scrollFrame:SetPoint("RIGHT", -30, 0)
    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(360)
    scrollChild:SetHeight(1000)
    scrollFrame:SetScrollChild(scrollChild)
    -- EditBox внутри скролла
    self.rlNotesEditor.editBox = CreateFrame("EditBox", "jjjj1111", scrollChild, "InputBoxTemplate")
    self.rlNotesEditor.editBox:SetSize(360, 220)
    self.rlNotesEditor.editBox:SetPoint("TOPLEFT")
    self.rlNotesEditor.editBox:SetMultiLine(true)
    self.rlNotesEditor.editBox:SetMaxLetters(1000)
    self.rlNotesEditor.editBox:SetAutoFocus(false)
    self.rlNotesEditor.editBox:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            local text = self.rlNotesEditor.editBox:GetText()
            local lines = 1
            for _ in text:gmatch("\n") do lines = lines + 1 end
            local height = math.max(220, lines * 20)
            scrollChild:SetHeight(height)
            scrollFrame:UpdateScrollChildRect()
        end
    end)
    self.rlNotesEditor.editBox:SetScript("OnEscapePressed", function()
        if self.rlNotesEditor.targetNick then
            _rlNotesReassembly[self.rlNotesEditor.targetNick] = nil
        end
        self.rlNotesEditor:Hide()
    end)
    -- Фон только внутри EditBox
    local editBg = self.rlNotesEditor.editBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    editBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    editBg:SetAllPoints()
end




    -- ========================================================================
    -- СОЗДАНИЕ ЭКЗЕМПЛЯРА GpDb (сразу, без таймера)
    -- ========================================================================
    if not gpDb then
        gpDb = GpDb:new({})
    end

    print("|cff00ff00[NSQC4-TEST]|r GP.lua выполняется до конца. NSQC4_GP_TEST зарегистрирована.")

end)