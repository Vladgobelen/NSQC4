-- ============================================================================
-- NSQC4 / Interface / InfoFrame
-- Универсальные инфо-фреймы: плавающие окна с обновляемыми значениями.
-- Модуль: ui_info.
-- ============================================================================

NSQC4.RegisterModule("ui_info", function()

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local TICK_INTERVAL   = 100   -- мс, минимум между тиками
    local DEFAULT_INTERVAL = 1000 -- мс, интервал по умолчанию для новой строки
    local ROW_HEIGHT      = 18
    local FRAME_PADDING   = 10

    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    local function EnsureStorage()
        nsDbc4.ui_info = nsDbc4.ui_info or {}
        nsDbc4.ui_info.frames = nsDbc4.ui_info.frames or {}
        nsDbc4.ui_info.currentFrame = nsDbc4.ui_info.currentFrame or nil
        return nsDbc4.ui_info
    end

    EnsureStorage()

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function Trim(s)
        return (tostring(s or ""):match("^%s*(.-)%s*$"))
    end

    local function FormatNumber(value)
        if type(value) ~= "number" then
            return tostring(value)
        end

        local formatted = string.format("%.2f", value)
        if formatted:match("%.00$") then
            formatted = formatted:gsub("%.00$", "")
        end
        return formatted
    end

    local function CompileValueFunc(code)
        code = tostring(code or "")

        -- Попытка 1: код как выражение (короткая форма)
        -- Пример: GetAddOnMemoryUsage("NSQC3")
        local chunk1 = "return function() return " .. code .. " end"
        local fn1 = loadstring(chunk1)
        if fn1 then
            local ok, valueFunc = pcall(fn1)
            if ok and type(valueFunc) == "function" then
                return valueFunc
            end
        end

        -- Попытка 2: код как тело функции (полная форма)
        -- Пример: UpdateAddOnMemoryUsage() return GetAddOnMemoryUsage("NSQC3")
        local chunk2 = "return function() " .. code .. " end"
        local fn2 = loadstring(chunk2)
        if fn2 then
            local ok, valueFunc = pcall(fn2)
            if ok and type(valueFunc) == "function" then
                return valueFunc
            end
        end

        return nil, "не удалось скомпилировать код (ни как выражение, ни как тело)"
    end

    -- ========================================================================
    -- Класс InfoFrame (один фрейм)
    -- ========================================================================
    local InfoFrame = {}
    InfoFrame.__index = InfoFrame

    local activeFrames = {}   -- [name] = InfoFrame instance
    local ticker          -- единый OnUpdate

    function InfoFrame:new(name)
        local self = setmetatable({}, InfoFrame)

        self.name = name
        self.rows = {}          -- [{ name, code, valueFunc, interval, addToTop, elapsed, headerText, valueText, clickFrame, rowFrame }]
        self.isCollapsed = false
        self.collapsedRow = nil

        local data = nsDbc4.ui_info.frames[name]
        if type(data) ~= "table" then
            data = { x = 200, y = -200, rows = {} }
            nsDbc4.ui_info.frames[name] = data
        end
        self.data = data
        self.data.rows = self.data.rows or {}

        self:_CreateFrame()
        self:_RestoreRows()

        activeFrames[name] = self
        self:_EnsureTicker()

        return self
    end

    function InfoFrame:_CreateFrame()
        local f = CreateFrame("Frame", nil, UIParent)
        self.frame = f
        f:SetSize(180, 30)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetClampedToScreen(true)
        f:SetFrameStrata("MEDIUM")

        f:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 0.75)
        f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        -- Позиция
        local x = tonumber(self.data.x) or 200
        local y = tonumber(self.data.y) or -200
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)

        -- Перетаскивание
        f:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)
        f:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            local left = frame:GetLeft() or 0
            local top  = frame:GetTop()  or 0
            local uiLeft = UIParent:GetLeft() or 0
            local uiTop  = UIParent:GetTop()  or 0
            self.data.x = left - uiLeft
            self.data.y = top  - uiTop
        end)

        -- Drag & drop предмета
        f:SetScript("OnReceiveDrag", function()
            self:OnReceiveDrag()
        end)

        f:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                -- ПКМ по пустому месту — свернуть/развернуть
                self:ToggleCollapse()
            end
        end)

        f:Show()
    end

    function InfoFrame:_RestoreRows()
        for _, rowData in ipairs(self.data.rows) do
            local valueFunc, err = CompileValueFunc(rowData.code)
            if valueFunc then
                self:AddRow(rowData.name, rowData.code, rowData.interval, rowData.addToTop, true, valueFunc)
            else
                print("|cffff0000[ui_info]|r Ошибка компиляции строки '" .. tostring(rowData.name) .. "': " .. tostring(err))
            end
        end
    end

    function InfoFrame:AddRow(rowName, code, interval, addToTop, isRestore, valueFunc)
        rowName = Trim(rowName)
        if rowName == "" then
            rowName = "Строка"
        end

        valueFunc = valueFunc or CompileValueFunc(code)
        if type(valueFunc) ~= "function" then
            return false, "не удалось скомпилировать код"
        end

        interval = tonumber(interval) or DEFAULT_INTERVAL
        if interval < TICK_INTERVAL then
            interval = TICK_INTERVAL
        end

        -- Заголовок и значение
        local headerText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetJustifyH("LEFT")
        headerText:SetText(rowName .. ":")

        local valueText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        valueText:SetJustifyH("LEFT")
        valueText:SetTextColor(0.6, 0.98, 0.6)

        -- Кликабельная область
        local clickFrame = CreateFrame("Frame", nil, self.frame)
        clickFrame:SetAllPoints(headerText)
        clickFrame:EnableMouse(true)

        local row = {
            name = rowName,
            code = code,
            valueFunc = valueFunc,
            interval = interval,
            addToTop = addToTop and true or false,
            elapsed = interval,           -- сразу обновим при первом тике
            headerText = headerText,
            valueText = valueText,
            clickFrame = clickFrame,
            isCollapsed = false,
        }

        -- ЛКМ по строке — свернуть эту строку (показать только её), ПКМ — удалить
        local this = self
        clickFrame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                this:ToggleRowCollapse(row)
            elseif button == "RightButton" then
                this:RemoveRow(row)
            end
        end)

        table.insert(self.rows, row)

        -- Обновить значение сразу
        self:_UpdateRow(row)

        -- Сохранить (если не восстановление)
        if not isRestore then
            table.insert(self.data.rows, {
                name = rowName,
                code = code,
                interval = interval,
                addToTop = row.addToTop,
            })
        end

        self:_Layout()
        return true
    end

    function InfoFrame:RemoveRow(row)
        for i, r in ipairs(self.rows) do
            if r == row then
                table.remove(self.rows, i)
                break
            end
        end

        if row.clickFrame then
            row.clickFrame:Hide()
            row.clickFrame:SetScript("OnMouseDown", nil)
        end
        if row.headerText then
            row.headerText:Hide()
            row.headerText:SetText("")
        end
        if row.valueText then
            row.valueText:Hide()
            row.valueText:SetText("")
        end

        -- Удалить из saveTable
        for i, r in ipairs(self.data.rows) do
            if r.name == row.name and r.code == row.code then
                table.remove(self.data.rows, i)
                break
            end
        end

        if self.collapsedRow == row then
            self.collapsedRow = nil
            self.isCollapsed = false
            self:_UpdateRowVisibility()
        end

        self:_Layout()
        if #self.rows == 0 then
            self.frame:Hide()
        end
    end

    function InfoFrame:ClearAllRows()
        for i = #self.rows, 1, -1 do
            self:RemoveRow(self.rows[i])
        end
    end

    function InfoFrame:ToggleRowCollapse(row)
        if self.collapsedRow == row then
            self.collapsedRow = nil
            self.isCollapsed = false
        else
            self.collapsedRow = row
            self.isCollapsed = true
        end
        self:_UpdateRowVisibility()
        self:_Layout()
    end

    function InfoFrame:ToggleCollapse()
        if self.isCollapsed then
            self.isCollapsed = false
            self.collapsedRow = nil
        else
            self.isCollapsed = true
            if not self.collapsedRow and self.rows[1] then
                self.collapsedRow = self.rows[1]
            end
        end
        self:_UpdateRowVisibility()
        self:_Layout()
    end

    function InfoFrame:_UpdateRowVisibility()
        for _, row in ipairs(self.rows) do
            if self.isCollapsed then
                if row == self.collapsedRow then
                    row.headerText:Show()
                    row.valueText:Show()
                    row.clickFrame:Show()
                    row.clickFrame:SetAllPoints(row.headerText)
                else
                    row.headerText:Hide()
                    row.valueText:Hide()
                    row.clickFrame:Hide()
                end
            else
                row.headerText:Show()
                row.valueText:Show()
                row.clickFrame:Show()
                row.clickFrame:SetAllPoints(row.headerText)
            end
        end
    end

    function InfoFrame:_UpdateRow(row)
        local ok, value = pcall(row.valueFunc)
        if not ok then
            value = "err"
        end

        if type(value) == "number" then
            value = FormatNumber(value)
        end

        row.valueText:SetText(tostring(value))
    end

    function InfoFrame:Tick(dtMs)
        for _, row in ipairs(self.rows) do
            row.elapsed = row.elapsed + dtMs
            if row.elapsed >= row.interval then
                row.elapsed = row.elapsed - row.interval
                self:_UpdateRow(row)
            end
        end
    end

    function InfoFrame:_Layout()
        -- Разделяем на top и bottom
        local top, bottom = {}, {}
        for _, row in ipairs(self.rows) do
            if row.addToTop then
                table.insert(top, row)
            else
                table.insert(bottom, row)
            end
        end

        -- Свёрнутое состояние
        if self.isCollapsed and self.collapsedRow then
            local row = self.collapsedRow
            row.headerText:ClearAllPoints()
            row.headerText:SetPoint("LEFT", self.frame, "LEFT", FRAME_PADDING, 0)
            row.valueText:ClearAllPoints()
            row.valueText:SetPoint("LEFT", row.headerText, "RIGHT", 5, 0)

            local w = (row.headerText:GetStringWidth() or 0)
                    + (row.valueText:GetStringWidth() or 0)
                    + FRAME_PADDING * 2 + 5

            self.frame:SetSize(math.max(60, w), ROW_HEIGHT + 10)
            return
        end

        -- Развёрнутое состояние
        local y = -FRAME_PADDING
        local maxWidth = 0

        for _, row in ipairs(top) do
            row.headerText:ClearAllPoints()
            row.headerText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", FRAME_PADDING, y)

            row.valueText:ClearAllPoints()
            row.valueText:SetPoint("LEFT", row.headerText, "RIGHT", 5, 0)

            local w = (row.headerText:GetStringWidth() or 0)
                    + (row.valueText:GetStringWidth() or 0)
                    + FRAME_PADDING * 2 + 5
            if w > maxWidth then maxWidth = w end

            y = y - ROW_HEIGHT
        end

        local bottomHeight = #bottom * ROW_HEIGHT
        local topHeight = #top * ROW_HEIGHT

        local bottomY = -FRAME_PADDING - topHeight - bottomHeight
        -- если bottom нет, bottomY не используется

        for i, row in ipairs(bottom) do
            row.headerText:ClearAllPoints()
            if i == 1 then
                row.headerText:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", FRAME_PADDING, FRAME_PADDING)
            else
                row.headerText:SetPoint("BOTTOMLEFT", bottom[i-1].headerText, "TOPLEFT", 0, 0)
            end

            row.valueText:ClearAllPoints()
            row.valueText:SetPoint("LEFT", row.headerText, "RIGHT", 5, 0)

            local w = (row.headerText:GetStringWidth() or 0)
                    + (row.valueText:GetStringWidth() or 0)
                    + FRAME_PADDING * 2 + 5
            if w > maxWidth then maxWidth = w end
        end

        local totalHeight = topHeight + bottomHeight + FRAME_PADDING * 2
        self.frame:SetSize(math.max(80, maxWidth), math.max(ROW_HEIGHT + 10, totalHeight))
    end

    function InfoFrame:OnReceiveDrag()
        local cursorType, cursorId = GetCursorInfo()
        if cursorType == "item" then
            local name = GetItemInfo(cursorId)
            if name then
                local code = string.format("GetItemCount(%d)", cursorId)
                local rowName = name
                self:AddRow(rowName, code, DEFAULT_INTERVAL, true, false)
            end
            ClearCursor()
        end
    end

    function InfoFrame:Destroy()
        if self.frame then
            self.frame:Hide()
            self.frame:SetParent(nil)
        end
        activeFrames[self.name] = nil
    end

    -- ========================================================================
    -- Единый тикер
    -- ========================================================================
    function InfoFrame:_EnsureTicker()
        if ticker then return end

        ticker = CreateFrame("Frame")
        local accum = 0
        ticker:SetScript("OnUpdate", function(_, dt)
            accum = accum + dt * 1000
            if accum < TICK_INTERVAL then return end

            local ticks = math.floor(accum / TICK_INTERVAL)
            accum = accum - ticks * TICK_INTERVAL

            local dtMs = ticks * TICK_INTERVAL
            for _, frameObj in pairs(activeFrames) do
                if frameObj.frame and frameObj.frame:IsShown() then
                    frameObj:Tick(dtMs)
                end
            end
        end)
    end

    -- ========================================================================
    -- Публичный API модуля
    -- ========================================================================
    local Module = {}
    NSQC4.ui_info = Module

    function Module:CreateFrame(name)
        name = Trim(name)
        if name == "" then
            return nil, "пустое имя"
        end
        if activeFrames[name] then
            return activeFrames[name], "уже существует"
        end

        local f = InfoFrame:new(name)
        return f
    end

    function Module:DeleteFrame(name)
        local f = activeFrames[name]
        if f then
            f:Destroy()
        end
        nsDbc4.ui_info.frames[name] = nil
        if nsDbc4.ui_info.currentFrame == name then
            nsDbc4.ui_info.currentFrame = nil
        end
    end

    function Module:GetFrames()
        local list = {}
        for name in pairs(nsDbc4.ui_info.frames) do
            table.insert(list, name)
        end
        table.sort(list)
        return list
    end

    function Module:GetFrame(name)
        return activeFrames[name]
    end

    function Module:EnsureFrame(name)
        if activeFrames[name] then
            return activeFrames[name]
        end
        local f, err = self:CreateFrame(name)
        return f, err
    end

    function Module:RestoreAll()
        for name in pairs(nsDbc4.ui_info.frames) do
            self:EnsureFrame(name)
        end
    end

    -- ========================================================================
    -- Настроечное окно
    -- ========================================================================
    local optionsFrame = nil

    local function CreateOptionsFrame()
        if optionsFrame then return optionsFrame end

        local f = CreateFrame("Frame", "NSQC4InfoOptionsFrame", UIParent)
        optionsFrame = f
        f:SetSize(560, 620)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(fr) fr:StartMoving() end)
        f:SetScript("OnDragStop", function(fr) fr:StopMovingOrSizing() end)

        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -14)
        title:SetText("Инфо-фреймы")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)

        -- ============================================================
        -- Верхняя часть: выбор фрейма + кнопки
        -- ============================================================
        local frameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frameLabel:SetPoint("TOPLEFT", 20, -50)
        frameLabel:SetText("Фрейм:")

        local dropdown = CreateFrame("Frame", "NSQC4InfoDropDown", f, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", 70, -44)
        UIDropDownMenu_SetWidth(dropdown, 200)
        f.dropdown = dropdown

        local addFrameBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addFrameBtn:SetSize(28, 24)
        addFrameBtn:SetPoint("LEFT", dropdown, "RIGHT", 30, 0)
        addFrameBtn:SetText("+")
        addFrameBtn:SetScript("OnClick", function()
            Module:ShowNewFrameDialog()
        end)

        local deleteFrameBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        deleteFrameBtn:SetSize(28, 24)
        deleteFrameBtn:SetPoint("LEFT", addFrameBtn, "RIGHT", 6, 0)
        deleteFrameBtn:SetText("X")
        deleteFrameBtn:SetScript("OnClick", function()
            local name = UIDropDownMenu_GetText(dropdown)
            if name and name ~= "" and name ~= "— нет —" then
                Module:DeleteFrame(name)
                f:RefreshFrameList()
            end
        end)

        -- ============================================================
        -- Поля ввода строки
        -- ============================================================
        local rowNameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowNameLabel:SetPoint("TOPLEFT", 20, -90)
        rowNameLabel:SetText("Название строки:")

        local rowNameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        f.rowNameBox = rowNameBox
        rowNameBox:SetSize(300, 24)
        rowNameBox:SetPoint("TOPLEFT", 150, -86)
        rowNameBox:SetAutoFocus(false)

        local codeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        codeLabel:SetPoint("TOPLEFT", 20, -126)
        codeLabel:SetText("Код (возвращает результат):")

        -- Скрейтч-фрейм для multiline-кода
        local codeScroll = CreateFrame("ScrollFrame", "NSQC4InfoCodeScroll", f, "UIPanelScrollFrameTemplate")
        codeScroll:SetPoint("TOPLEFT", 20, -148)
        codeScroll:SetPoint("BOTTOMRIGHT", -40, 280)

        local codeBox = CreateFrame("EditBox", nil, codeScroll)
        f.codeBox = codeBox
        codeBox:SetMultiLine(true)
        codeBox:SetAutoFocus(false)
        codeBox:SetFontObject("ChatFontNormal")
        codeBox:SetWidth(490)
        codeBox:SetHeight(1000)
        codeBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        codeScroll:SetScrollChild(codeBox)

        -- placeholder-пример
        codeBox:SetText("")
        local placeholder = codeBox:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
        placeholder:SetPoint("TOPLEFT", 4, -4)
        placeholder:SetText("Пример: GetAddOnMemoryUsage('NSQC4')")
        f.codePlaceholder = placeholder

        codeBox:SetScript("OnTextChanged", function(self)
            if (self:GetText() or "") == "" then
                placeholder:Show()
            else
                placeholder:Hide()
            end
        end)

        -- Интервал
        local intervalLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        intervalLabel:SetPoint("TOPLEFT", 20, -390)
        intervalLabel:SetText("Интервал (мс):")

        local intervalBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        f.intervalBox = intervalBox
        intervalBox:SetSize(100, 24)
        intervalBox:SetPoint("TOPLEFT", 150, -386)
        intervalBox:SetAutoFocus(false)
        intervalBox:SetText(tostring(DEFAULT_INTERVAL))

        -- Радио: сверху / снизу
        local posLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        posLabel:SetPoint("TOPLEFT", 20, -426)
        posLabel:SetText("Позиция:")

        local topRadio = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
        f.topRadio = topRadio
        topRadio:SetPoint("TOPLEFT", 150, -420)
        topRadio:SetHitRectInsets(0, -60, 0, 0)
        local topRadioText = topRadio:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        topRadioText:SetPoint("LEFT", topRadio, "RIGHT", 4, 0)
        topRadioText:SetText("Сверху")
        topRadio:SetScript("OnClick", function(self)
            self:SetChecked(true)
            f.bottomRadio:SetChecked(false)
        end)
        topRadio:SetChecked(true)

        local bottomRadio = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
        f.bottomRadio = bottomRadio
        bottomRadio:SetPoint("TOPLEFT", 260, -420)
        bottomRadio:SetHitRectInsets(0, -60, 0, 0)
        local bottomRadioText = bottomRadio:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bottomRadioText:SetPoint("LEFT", bottomRadio, "RIGHT", 4, 0)
        bottomRadioText:SetText("Снизу")
        bottomRadio:SetScript("OnClick", function(self)
            self:SetChecked(true)
            f.topRadio:SetChecked(false)
        end)

        -- Кнопка «Добавить»
        local addRowBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.addRowBtn = addRowBtn
        addRowBtn:SetSize(160, 28)
        addRowBtn:SetPoint("TOPLEFT", 20, -456)
        addRowBtn:SetText("Добавить строку")
        addRowBtn:SetScript("OnClick", function()
            Module:AddRowFromOptions(f)
        end)

        -- ============================================================
        -- Список строк
        -- ============================================================
        local listLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listLabel:SetPoint("TOPLEFT", 20, -496)
        listLabel:SetText("Строки выбранного фрейма:")

        local listScroll = CreateFrame("ScrollFrame", "NSQC4InfoListScroll", f, "UIPanelScrollFrameTemplate")
        listScroll:SetPoint("TOPLEFT", 20, -518)
        listScroll:SetPoint("BOTTOMRIGHT", -40, 20)

        local listContent = CreateFrame("Frame", nil, listScroll)
        f.listContent = listContent
        listContent:SetSize(490, 10)
        listScroll:SetScrollChild(listContent)

        f.listScroll = listScroll
        f.listRows = {}

        -- ============================================================
        -- Методы окна
        -- ============================================================
        function f:RefreshFrameList()
            local frames = Module:GetFrames()
            local current = nsDbc4.ui_info.currentFrame

            local items = {}
            if #frames == 0 then
                items[1] = "— нет —"
            else
                for i, name in ipairs(frames) do
                    items[i] = name
                end
            end

            UIDropDownMenu_Initialize(dropdown, function(_, level)
                for i, name in ipairs(items) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = name
                    info.value = name
                    info.func = function()
                        if name == "— нет —" then
                            nsDbc4.ui_info.currentFrame = nil
                            UIDropDownMenu_SetText(dropdown, "— нет —")
                        else
                            nsDbc4.ui_info.currentFrame = name
                            UIDropDownMenu_SetText(dropdown, name)
                        end
                        f:RefreshRowList()
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)

            if current and nsDbc4.ui_info.frames[current] then
                UIDropDownMenu_SetText(dropdown, current)
            elseif #frames > 0 then
                nsDbc4.ui_info.currentFrame = frames[1]
                UIDropDownMenu_SetText(dropdown, frames[1])
            else
                UIDropDownMenu_SetText(dropdown, "— нет —")
            end
        end

        function f:RefreshRowList()
            for _, r in ipairs(f.listRows) do
                r:Hide()
                r:SetParent(nil)
            end
            f.listRows = {}

            local frameName = nsDbc4.ui_info.currentFrame
            if not frameName or not nsDbc4.ui_info.frames[frameName] then
                listContent:SetHeight(10)
                return
            end

            local rows = nsDbc4.ui_info.frames[frameName].rows or {}

            local y = 0
            for i, row in ipairs(rows) do
                local rowFrame = CreateFrame("Frame", nil, listContent)
                rowFrame:SetSize(480, 22)
                rowFrame:SetPoint("TOPLEFT", 0, y)

                local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(rowFrame)
                bg:SetTexture(0.1, 0.1, 0.15, 0.7)

                local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameText:SetPoint("LEFT", 6, 0)
                nameText:SetText(tostring(row.name or "?"))

                local infoText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                infoText:SetPoint("LEFT", 150, 0)
                infoText:SetText("[" .. tostring(row.interval or "?") .. " мс]")

                local delBtn = CreateFrame("Button", nil, rowFrame, "UIPanelCloseButton")
                delBtn:SetSize(20, 20)
                delBtn:SetPoint("RIGHT", -2, 0)
                delBtn:SetScript("OnClick", function()
                    local frameName2 = nsDbc4.ui_info.currentFrame
                    local data = nsDbc4.ui_info.frames[frameName2]
                    if not data then return end
                    local idx = nil
                    for j, r in ipairs(data.rows) do
                        if r == row then
                            idx = j
                            break
                        end
                    end
                    if idx then
                        table.remove(data.rows, idx)
                    end

                    -- Обновить инстанс
                    local inst = activeFrames[frameName2]
                    if inst then
                        inst:ClearAllRows()
                        inst:_RestoreRows()
                        if #inst.rows == 0 then
                            inst.frame:Hide()
                        end
                    end

                    f:RefreshRowList()
                end)

                table.insert(f.listRows, rowFrame)
                y = y - 24
            end

            listContent:SetHeight(math.max(10, -y + 4))
        end

        function f:RefreshAll()
            self:RefreshFrameList()
            self:RefreshRowList()
        end

        f:Hide()
        return f
    end

    -- ========================================================================
    -- Модальное окно создания фрейма
    -- ========================================================================
    local newFrameDialog = nil

    function Module:ShowNewFrameDialog()
        if not newFrameDialog then
            local d = CreateFrame("Frame", "NSQC4InfoNewFrameDialog", UIParent)
            newFrameDialog = d
            d:SetSize(300, 140)
            d:SetPoint("CENTER")
            d:SetFrameStrata("FULLSCREEN_DIALOG")
            d:EnableMouse(true)
            d:SetMovable(true)
            d:RegisterForDrag("LeftButton")
            d:SetScript("OnDragStart", function(f) f:StartMoving() end)
            d:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

            d:SetBackdrop({
                bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 8, right = 8, top = 8, bottom = 8 },
            })

            local title = d:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOP", 0, -14)
            title:SetText("Новый фрейм")

            local label = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("TOPLEFT", 20, -50)
            label:SetText("Название:")

            local box = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
            d.box = box
            box:SetSize(220, 24)
            box:SetPoint("TOPLEFT", 20, -70)
            box:SetAutoFocus(true)
            box:SetScript("OnEscapePressed", function() d:Hide() end)
            box:SetScript("OnEnterPressed", function()
                Module:ConfirmNewFrame(box:GetText())
            end)

            local ok = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            ok:SetSize(100, 24)
            ok:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -20, 14)
            ok:SetText("Создать")
            ok:SetScript("OnClick", function()
                Module:ConfirmNewFrame(box:GetText())
            end)

            local cancel = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
            cancel:SetSize(100, 24)
            cancel:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 20, 14)
            cancel:SetText("Отмена")
            cancel:SetScript("OnClick", function() d:Hide() end)
        end

        newFrameDialog.box:SetText("")
        newFrameDialog:Show()
        newFrameDialog.box:SetFocus()
    end

    function Module:ConfirmNewFrame(name)
        name = Trim(name)
        if name == "" then
            return
        end
        if nsDbc4.ui_info.frames[name] then
            print("|cffff8800[ui_info]|r Фрейм '" .. name .. "' уже существует")
            newFrameDialog:Hide()
            return
        end

        nsDbc4.ui_info.frames[name] = { x = 200, y = -200, rows = {} }
        nsDbc4.ui_info.currentFrame = name

        Module:EnsureFrame(name)

        newFrameDialog:Hide()

        if optionsFrame then
            optionsFrame:RefreshAll()
        end
    end

    -- ========================================================================
    -- Добавление строки из окна настроек
    -- ========================================================================
    function Module:AddRowFromOptions(f)
        local frameName = nsDbc4.ui_info.currentFrame
        if not frameName then
            print("|cffff8800[ui_info]|r Сначала создайте фрейм")
            return
        end

        local rowName = Trim(f.rowNameBox:GetText())
        local code    = Trim(f.codeBox:GetText())
        local interval = tonumber(f.intervalBox:GetText()) or DEFAULT_INTERVAL
        local addToTop = f.topRadio:GetChecked() and true or false

        if rowName == "" then
            print("|cffff8800[ui_info]|r Введите название строки")
            return
        end
        if code == "" then
            print("|cffff8800[ui_info]|r Введите код")
            return
        end

        local valueFunc, err = CompileValueFunc(code)
        if not valueFunc then
            print("|cffff8800[ui_info]|r Ошибка в коде: " .. tostring(err))
            return
        end

        local inst = Module:EnsureFrame(frameName)
        if not inst then
            print("|cffff8800[ui_info]|r Не удалось создать фрейм")
            return
        end

        local ok = inst:AddRow(rowName, code, interval, addToTop, false, valueFunc)
        if not ok then
            print("|cffff8800[ui_info]|r Не удалось добавить строку")
            return
        end

        -- Очистить поля
        f.rowNameBox:SetText("")
        f.codeBox:SetText("")
        f.intervalBox:SetText(tostring(DEFAULT_INTERVAL))

        f:RefreshRowList()
    end

    -- ========================================================================
    -- Открытие / закрытие окна
    -- ========================================================================
    function Module:ShowOptions()
        local f = CreateOptionsFrame()
        f:RefreshAll()
        f:Show()
        f:Raise()
    end

    function Module:ToggleOptions()
        if optionsFrame and optionsFrame:IsShown() then
            optionsFrame:Hide()
        else
            self:ShowOptions()
        end
    end

    -- ========================================================================
    -- Регистрация: слэш, кнопка панели, восстановление
    -- ========================================================================
    SLASH_NSINFO1 = "/ns_info"
    SlashCmdList["NSINFO"] = function(msg)
        msg = Trim(msg)
        if msg == "add" then
            -- быстрая команда: /ns_info add Name | code
            -- пока просто открываем окно
            Module:ShowOptions()
        else
            Module:ShowOptions()
        end
    end

    NSQC4.SlashPanel_RegisterButton("I", "/ns_info", "Инфо-фреймы (универсальные)", function()
        Module:ShowOptions()
    end)

    -- Восстановление при входе
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_LOGIN")
    restoreFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        Module:RestoreAll()
    end)

end)