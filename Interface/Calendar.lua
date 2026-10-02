-- ============================================================================
-- NSQC4 / Interface / Calendar
-- Календарь: кнопка «Создать» + контекстное меню события. Модуль "ui_calendar".
-- ============================================================================

NSQC4 = NSQC4 or {}

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("ui_calendar") then return end

    -- ========================================================================
    -- Локальный таймер (замена C_Timer.After)
    -- ========================================================================
    local localTimer = CreateFrame("Frame")
    localTimer.timers = {}
    localTimer:Hide()

    localTimer:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local i = #self.timers
        while i >= 1 do
            local t = self.timers[i]
            if now - t.startTime >= t.delay then
                t.callback()
                table.remove(self.timers, i)
            end
            i = i - 1
        end
        if #self.timers == 0 then
            self:Hide()
        end
    end)

    local function After(delay, callback)
        table.insert(localTimer.timers, {
            startTime = GetTime(),
            delay = delay,
            callback = callback,
        })
        localTimer:Show()
    end

    local menuHooked = false

    -- ========================================================================
    -- Утилита: отправка чанками
    -- ========================================================================
    local function SendAddonMessageChunked(prefix, payload, channel)
        if not payload or payload == "" then return end
        local MAX_CHUNK_SIZE = 200
        local chunks = {}
        local i = 1
        while i <= #payload do
            table.insert(chunks, payload:sub(i, i + MAX_CHUNK_SIZE - 1))
            i = i + MAX_CHUNK_SIZE
        end
        local total = #chunks
        for idx = 1, total do
            local msg = string.format("%d/%d|%s", idx, total, chunks[idx])
            if #msg <= 254 then
                SendAddonMessage(prefix, msg, channel)
            end
        end
    end

    -- ========================================================================
    -- ЧАСТЬ 1: Кнопка «Создать» в форме события
    -- ========================================================================
    local function CreateCustomButton()
        if _G.CustomCalendarCreateButton then return end

        local origButton = _G.CalendarCreateEventCreateButton
        if not origButton then return end

        local calEventFrame = _G.CalendarCreateEventFrame
        if not calEventFrame or not calEventFrame:IsVisible() then return end

        local btn = CreateFrame("Button", "CustomCalendarCreateButton", calEventFrame, "UIPanelButtonTemplate")
        btn:SetPoint("CENTER", origButton, "CENTER")
        btn:SetSize(origButton:GetWidth(), origButton:GetHeight())
        btn:SetText(origButton:GetText() or "Создать")

        origButton:Hide()

        btn:SetScript("OnClick", function(self, mouseButton)
            local title = (_G.CalendarCreateEventTitleEdit and _G.CalendarCreateEventTitleEdit:GetText()) or ""
            local desc = (_G.CalendarCreateEventDescriptionEdit and _G.CalendarCreateEventDescriptionEdit:GetText()) or ""
            local hour = (_G.CalendarCreateEventHourDropDown and _G.CalendarCreateEventHourDropDown.selectedValue) or 0
            local min = (_G.CalendarCreateEventMinuteDropDown and _G.CalendarCreateEventMinuteDropDown.selectedValue) or 0

            local calFrame = _G.CalendarFrame
            local selYear = calFrame and calFrame.selectedYear
            local selMonth = calFrame and calFrame.selectedMonth
            local selDay = calFrame and calFrame.selectedDay
            if not (selYear and selMonth and selDay) then
                local t = date("*t")
                selYear, selMonth, selDay = t.year, t.month, t.day
            end
            local eventDateStr = string.format("%04d-%02d-%02d", selYear, selMonth, selDay)
            local timeStr = string.format("%02d%02d", hour, min)

            if title == "" then return end

            local payload = eventDateStr .. "|" .. timeStr .. "|" .. title .. "|" .. desc
            SendAddonMessageChunked("ns_calendar", payload, "GUILD")

            local origOnClick = origButton:GetScript("OnClick")
            if origOnClick then
                origOnClick(origButton, mouseButton)
            elseif _G.CalendarCreateEventButton_Click then
                _G.CalendarCreateEventButton_Click()
            end
        end)
    end

    -- ========================================================================
    -- Монитор появления формы создания
    -- ========================================================================
    local monitor = CreateFrame("Frame")
    monitor.t = 0
    monitor:SetScript("OnUpdate", function(self, elapsed)
        self.t = self.t + elapsed
        if self.t > 0.3 then
            local f = _G.CalendarCreateEventFrame
            if f and not f.ns_hooked then
                f.ns_hooked = true
                f:HookScript("OnShow", function()
                    After(0.05, CreateCustomButton)
                end)
            end
            self.t = 0
        end
    end)

    -- ========================================================================
    -- ЧАСТЬ 2: Контекстное меню события
    -- ========================================================================
    local function TryHookContextMenu()
        if not _G.CalendarContextMenu then
            After(0.1, TryHookContextMenu)
            return
        end

        if menuHooked then return end

        _G.CalendarContextMenu:HookScript("OnShow", function(self)
            After(0.02, function()
                -- Кнопка 1: Удалить с сервера
                local btnDel = _G["CalendarContextMenuButton7"]
                if btnDel then
                    btnDel:SetText("Удалить с сервера")
                    btnDel:Show()

                    if not btnDel.ns_hooked_del then
                        btnDel:SetScript("OnClick", function()
                            local createFrame = _G.CalendarCreateEventFrame
                            if not (createFrame and createFrame:IsVisible()) then
                                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[NSQC4] Окно редактирования не открыто.|r")
                                HideUIPanel(_G.CalendarContextMenu)
                                return
                            end

                            local title = (_G.CalendarCreateEventTitleEdit and _G.CalendarCreateEventTitleEdit:GetText()) or ""
                            if title == "" then
                                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[NSQC4] Название пусто.|r")
                                HideUIPanel(_G.CalendarContextMenu)
                                return
                            end

                            local calFrame = _G.CalendarFrame
                            local year, month, day = calFrame.selectedYear, calFrame.selectedMonth, calFrame.selectedDay
                            if not (year and month and day) then
                                local t = date("*t")
                                year, month, day = t.year, t.month, t.day
                            end
                            local dateStr = string.format("%04d-%02d-%02d", year, month, day)

                            SendAddonMessage("ns_calendar_del", dateStr .. "|" .. title, "GUILD")
                            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NSQC4] Удалено: " .. dateStr .. " | " .. title .. "|r")
                            HideUIPanel(_G.CalendarContextMenu)
                        end)
                        btnDel.ns_hooked_del = true
                    end
                end

                -- Кнопка 2: Добавить чужое
                local btnAlien = _G["CalendarContextMenuButton8"]
                local eventButton = self.eventButton
                if btnAlien and eventButton and eventButton.eventIndex then
                    btnAlien:SetText("Добавить чужое")
                    btnAlien:Show()

                    if not btnAlien.ns_hooked_alien then
                        btnAlien:SetScript("OnClick", function()
                            local eventIndex = eventButton.eventIndex
                            local eventInfo = { CalendarGetEventInfo(eventIndex) }
                            if #eventInfo < 11 then
                                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[NSQC4] Недостаточно данных события.|r")
                                HideUIPanel(_G.CalendarContextMenu)
                                return
                            end

                            local title = eventInfo[1] or ""
                            local desc = eventInfo[2] or ""
                            local creator = eventInfo[3] or ""
                            local month = eventInfo[9]
                            local day = eventInfo[10]
                            local year = eventInfo[11]
                            local hour = eventInfo[12] or 0
                            local min = eventInfo[13] or 0

                            if title == "" or not (year and month and day) then
                                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[NSQC4] Некорректные данные события.|r")
                                HideUIPanel(_G.CalendarContextMenu)
                                return
                            end

                            local dateStr = string.format("%04d-%02d-%02d", year, month, day)
                            local timeStr = string.format("%02d%02d", hour, min)
                            local payload = dateStr .. "|" .. timeStr .. "|" .. title .. "|" .. desc .. "|" .. creator

                            SendAddonMessageChunked("ns_alien_event", payload, "GUILD")
                            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NSQC4] Отправлено чужое событие: " .. title .. "|r")
                            HideUIPanel(_G.CalendarContextMenu)
                        end)
                        btnAlien.ns_hooked_alien = true
                    end
                else
                    if btnAlien then btnAlien:Hide() end
                end

                self:SetHeight(158)
            end)
        end)

        menuHooked = true
    end

    TryHookContextMenu()
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)