-- ============================================================================
-- NSQC4 / Core / Settings / Gestures
-- Жесты по 16 точкам экрана под ОДНИМ зажатым модификатором.
-- Если зажато 2+ модификатора, модуль молчит (уступает Trajectory).
--
-- Точки имеют ПРИОРИТЕТ (порядок). Жест срабатывает, только если точки
-- посещены в порядке приоритета (1 -> 2 -> 3...).
--
-- Сброс сессии происходит:
--   1) при отпускании модификатора;
--   2) при выполнении жеста (+ карантин до выхода из точки);
--   3) при возврате в уже пройденную точку текущего набора (+ карантин);
--   4) при наведении на точку не по порядку (PRIORITY-FAIL) (+ карантин).
-- Точки, не участвующие ни в одном невыполненном жесте, ИГНОРИРУЮТСЯ
-- (без сброса — это просто транзит курсора через постороннюю зону).
--
-- Действие жеста (в редакторе, второй раздел, радиокнопки):
--   • Код  — многострочный Lua (loadstring + pcall)
--   • Текст — SendChatMessage в выбранный канал
-- ============================================================================

NSQC4 = NSQC4 or {}

NSQC4.RegisterModule("gestures", function()

    -- ========================================================================
    -- Отладка (ВЫКЛЮЧЕНА)
    -- ========================================================================
    local GDBG = { enabled = false }
    local function dbg(tag, ...)
        if not GDBG.enabled then return end
        local p = { "|cff00ddaa[GEST-" .. tag .. "]|r" }
        for _, v in ipairs({...}) do p[#p + 1] = tostring(v) end
        print(unpack(p))
    end

    -- ========================================================================
    -- Настройки
    -- ========================================================================
    local function ensureOpts()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.settings = nsDbc4.settings or {}
        nsDbc4.settings.gestures = nsDbc4.settings.gestures or {}
        local o = nsDbc4.settings.gestures.opts
        if not o then
            o = { showText = true, highlightShift = true, highlightHover = false }
            nsDbc4.settings.gestures.opts = o
        end
        if o.showText == nil then o.showText = true end
        if o.highlightShift == nil then o.highlightShift = true end
        if o.highlightHover == nil then o.highlightHover = false end
        return o
    end

    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    local function ensureDb()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.settings = nsDbc4.settings or {}
        nsDbc4.settings.gestures = nsDbc4.settings.gestures or {}
        nsDbc4.settings.gestures.list = nsDbc4.settings.gestures.list or {}
        return nsDbc4.settings.gestures.list
    end

    local MOD_LABELS = { shift = "Shift", ctrl = "Ctrl", alt = "Alt" }
    local MOD_ORDER  = { "shift", "ctrl", "alt" }

    -- ========================================================================
    -- Действия: каналы чата
    -- ========================================================================
    local CHAT_TARGETS = {
        { key = "say",     chatType = nil,       label = "Сказать" },
        { key = "party",   chatType = "PARTY",   label = "Группа" },
        { key = "raid",    chatType = "RAID",    label = "Рейд" },
        { key = "guild",   chatType = "GUILD",   label = "Гильдия" },
        { key = "officer", chatType = "OFFICER", label = "Офицерский" },
    }
    local CHAT_BY_KEY = {}
    for _, t in ipairs(CHAT_TARGETS) do CHAT_BY_KEY[t.key] = t end

    local function normalizeChat(key)
        if CHAT_BY_KEY[key] then return key end
        return "say"
    end

    local function normalizeMod(mod)
        if mod == "ctrl" or mod == "alt" then return mod end
        return "shift"
    end

    local function normalizeAction(a)
        if a == "text" then return "text" end
        return "code"
    end

    local function ensureGesture(g)
        g.id = g.id or ("g" .. tostring(math.random(100000, 999999)))
        g.name = g.name or ""
        g.code = g.code or ""
        g.corners = g.corners or {}
        g.mod = normalizeMod(g.mod)
        g.action = normalizeAction(g.action)
        g.chat = normalizeChat(g.chat)
        g.text = g.text or ""
        return g
    end

    local function migrateList()
        for _, g in ipairs(ensureDb()) do
            g.mod = normalizeMod(g.mod)
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
            g.text = g.text or ""
            if g.corners then
                for cid, val in pairs(g.corners) do
                    if type(val) == "number" then
                        g.corners[cid] = { count = val, order = 1 }
                    end
                end
            end
        end
    end

    -- ========================================================================
    -- 16 точек по периметру
    -- ========================================================================
    local CORNERS = {
        { id = "TL",    label = "Левый верх",          fx = 0.0,  fy = 1.0  },
        { id = "Q_TL",  label = "Верх-лево 1/4",       fx = 0.25, fy = 1.0  },
        { id = "TC",    label = "Центр верх",          fx = 0.5,  fy = 1.0  },
        { id = "Q_TR",  label = "Верх-право 3/4",      fx = 0.75, fy = 1.0  },
        { id = "TR",    label = "Правый верх",         fx = 1.0,  fy = 1.0  },
        { id = "Q_ML",  label = "Лево-верх 1/4",       fx = 0.0,  fy = 0.75 },
        { id = "Q_MR",  label = "Право-верх 1/4",      fx = 1.0,  fy = 0.75 },
        { id = "ML",    label = "Центр слева",         fx = 0.0,  fy = 0.5  },
        { id = "MR",    label = "Центр справа",        fx = 1.0,  fy = 0.5  },
        { id = "Q_BL_M",label = "Лево-низ 1/4",        fx = 0.0,  fy = 0.25 },
        { id = "Q_BR_M",label = "Право-низ 1/4",       fx = 1.0,  fy = 0.25 },
        { id = "BL",    label = "Левый низ",           fx = 0.0,  fy = 0.0  },
        { id = "Q_BL",  label = "Низ-лево 1/4",        fx = 0.25, fy = 0.0  },
        { id = "BC",    label = "Центр низ",           fx = 0.5,  fy = 0.0  },
        { id = "Q_BR",  label = "Низ-право 3/4",       fx = 0.75, fy = 0.0  },
        { id = "BR",    label = "Правый низ",          fx = 1.0,  fy = 0.0  },
    }

    local function GetCornerLabel(id)
        for _, c in ipairs(CORNERS) do
            if c.id == id then return c.label end
        end
        return id
    end

    local function GetCornerById(id)
        for _, c in ipairs(CORNERS) do
            if c.id == id then return c end
        end
        return nil
    end

    -- ========================================================================
    -- Координаты
    -- ========================================================================
    local function screenSize()
        if GetScreenWidth and GetScreenHeight then
            return GetScreenWidth(), GetScreenHeight()
        end
        return UIParent:GetWidth(), UIParent:GetHeight()
    end

    local function cursorPos()
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        return x / s, y / s
    end

    local RADIUS = 100

    local function whichCorner(cx, cy)
        local w, h = screenSize()
        for _, c in ipairs(CORNERS) do
            local px, py = c.fx * w, c.fy * h
            if math.abs(cx - px) <= RADIUS and math.abs(cy - py) <= RADIUS then
                return c.id
            end
        end
        return nil
    end

    -- ========================================================================
    -- Модификаторы (строго один)
    -- ========================================================================
    local function activeModifier()
        if not NSQC4.Modifiers then return nil end
        local s = NSQC4.Modifiers.ShiftDown and NSQC4.Modifiers.ShiftDown() or false
        local c = NSQC4.Modifiers.CtrlDown  and NSQC4.Modifiers.CtrlDown()  or false
        local a = NSQC4.Modifiers.AltDown   and NSQC4.Modifiers.AltDown()   or false

        if s and not c and not a then return "shift" end
        if c and not s and not a then return "ctrl"  end
        if a and not s and not c then return "alt"   end
        return nil
    end

    -- ========================================================================
    -- Оверлей-подсветка с прогрессом
    -- ========================================================================
    local hl = {}

    local function getHighlighter(cornerId)
        if hl[cornerId] then return hl[cornerId] end
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata("TOOLTIP")
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(1, 0.82, 0, 0.15)
        f:Hide()

        f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.count:SetPoint("CENTER", 0, 0)
        f.count:SetTextColor(1, 1, 1)
        f.count:SetText("")

        local w, h = screenSize()
        for _, c in ipairs(CORNERS) do
            if c.id == cornerId then
                f:ClearAllPoints()
                f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", c.fx * w, c.fy * h)
                f:SetSize(RADIUS * 2, RADIUS * 2)
                break
            end
        end
        hl[cornerId] = f
        return f
    end

    local function hideAllHighlight()
        for _, f in pairs(hl) do
            if f:IsShown() then f:Hide() end
        end
    end

    local function progressColor(p)
        if p < 0 then p = 0 end
        if p > 1 then p = 1 end
        local r = 1 + (0.2 - 1) * p
        local g = 0.82 + (1 - 0.82) * p
        local b = 0 + (0.2 - 0) * p
        return r, g, b
    end

    -- ========================================================================
    -- Состояние сессии
    -- ========================================================================
    local visited = {}
    local currentCorner = nil
    local fired = {}
    local sessionMod = nil
    local hoverFrames = 0
    local lastRawCorner = nil
    local quarantineCorner = nil

    local function resetSession()
        dbg("RESET", "сброс прогресса")
        visited = {}
        currentCorner = nil
        fired = {}
        hoverFrames = 0
        lastRawCorner = nil
    end

    -- ========================================================================
    -- Выполнение действия
    -- ========================================================================
    local function runCode(code)
        if not code or code == "" then return end
        local fn, err = loadstring(code)
        if not fn then
            dbg("RUN", "ошибка компиляции:", err)
            print("|cffff0000[GESTURES]|r ошибка компиляции: " .. tostring(err))
            return
        end
        local ok, runErr = pcall(fn)
        if not ok then
            dbg("RUN", "ошибка выполнения:", runErr)
            print("|cffff0000[GESTURES]|r ошибка выполнения: " .. tostring(runErr))
        end
    end

    local function runText(g)
        local text = g.text or ""
        if text == "" then
            dbg("RUN", "текст пуст — пропуск")
            return
        end
        local target = CHAT_BY_KEY[normalizeChat(g.chat)]
        local chatType = target and target.chatType or nil
        local ok, err = pcall(SendChatMessage, text, chatType)
        if not ok then
            dbg("RUN", "ошибка SendChatMessage:", err)
            print("|cffff0000[GESTURES]|r ошибка отправки текста: " .. tostring(err))
        else
            dbg("RUN", "текст отправлен в", target and target.label or "?")
        end
    end

    local function runGestureAction(g)
        if normalizeAction(g.action) == "text" then
            runText(g)
        else
            runCode(g.code)
        end
    end

    -- ========================================================================
    -- Проверки существования/ёмкости жеста для точки
    -- ========================================================================
    local function pointStillNeeded(cid, mod)
        local curVis = visited[cid] or 0
        local declared = false
        local hasCapacity = false
        for _, g in ipairs(ensureDb()) do
            if g.mod == mod and not fired[g.id] then
                local data = g.corners and g.corners[cid]
                if data and data.count and data.count > 0 then
                    declared = true
                    if data.count > curVis then
                        hasCapacity = true
                    end
                end
            end
        end
        if hasCapacity then return true, "" end
        if declared then return false, "exhausted" end
        return false, "absent"
    end

    local function pointAllowedByPriority(cid, mod)
        local debugReason = ""
        for _, g in ipairs(ensureDb()) do
            if g.mod == mod and not fired[g.id] then
                local sorted = {}
                for gcid, data in pairs(g.corners or {}) do
                    if data.count and data.count > 0 then
                        table.insert(sorted, { id = gcid, order = data.order or 1, count = data.count })
                    end
                end
                table.sort(sorted, function(a, b) return a.order < b.order end)

                local myPos = nil
                for i, pt in ipairs(sorted) do
                    if pt.id == cid then myPos = i; break end
                end

                if myPos then
                    local previousDone = true
                    local missing = ""
                    for i = 1, myPos - 1 do
                        local prevPt = sorted[i]
                        local vis = visited[prevPt.id] or 0
                        if vis < prevPt.count then
                            previousDone = false
                            missing = GetCornerLabel(prevPt.id) .. " (" .. vis .. "/" .. prevPt.count .. ")"
                            break
                        end
                    end

                    if previousDone then
                        return true, ""
                    else
                        debugReason = "ждём: " .. missing
                    end
                end
            end
        end
        return false, debugReason
    end

    -- ========================================================================
    -- Подсветка
    -- ========================================================================
    local function rebuildHighlight()
        local opts = ensureOpts()
        if not (opts.highlightShift or opts.highlightHover) then hideAllHighlight(); return end
        if not sessionMod then hideAllHighlight(); return end

        local needed = {}
        for _, g in ipairs(ensureDb()) do
            if g.mod == sessionMod and not fired[g.id] then
                for cid, data in pairs(g.corners or {}) do
                    if data.count and data.count > 0 and GetCornerById(cid) then
                        if not needed[cid] or data.count > needed[cid] then
                            needed[cid] = data.count
                        end
                    end
                end
            end
        end

        for _, c in ipairs(CORNERS) do
            local f = getHighlighter(c.id)
            local need = needed[c.id]
            if need then
                local vis = visited[c.id] or 0
                local p = (need > 0) and (vis / need) or 0
                local r, gr, b = progressColor(p)
                f:SetBackdropColor(r, gr, b, 0.2 + 0.25 * p)
                f.count:SetText(vis .. "/" .. need)
                f.count:SetTextColor(r, gr, b)
                f:Show()
            else
                if f:IsShown() then f:Hide() end
            end
        end
    end

    -- ========================================================================
    -- OnUpdate
    -- ========================================================================
    local tracker = CreateFrame("Frame")
    tracker:SetScript("OnUpdate", function()
        local mod = activeModifier()

        if not mod then
            if sessionMod ~= nil then
                dbg("MOD-UP", "модификатор отпущен")
                sessionMod = nil
                quarantineCorner = nil
                resetSession()
            end
            hideAllHighlight()
            return
        end

        if sessionMod ~= mod then
            dbg("MOD-CHANGE", "смена модификатора на", mod)
            quarantineCorner = nil
            resetSession()
            sessionMod = mod
        end

        local opts = ensureOpts()

        if opts.highlightShift then rebuildHighlight()
        elseif not opts.highlightHover then hideAllHighlight() end

        local cx, cy = cursorPos()
        local rawCorner = whichCorner(cx, cy)

        if quarantineCorner then
            if rawCorner == quarantineCorner then
                dbg("QUARANTINE", "ждём выхода из", GetCornerLabel(quarantineCorner))
                return
            else
                dbg("QUARANTINE", "вышли из", GetCornerLabel(quarantineCorner), "— снимаем")
                quarantineCorner = nil
                hoverFrames = 0
                lastRawCorner = nil
                currentCorner = nil
            end
        end

        if rawCorner == lastRawCorner then
            hoverFrames = hoverFrames + 1
        else
            hoverFrames = 0
            lastRawCorner = rawCorner
            currentCorner = nil
        end

        if rawCorner and hoverFrames >= 3 and currentCorner ~= rawCorner then
            currentCorner = rawCorner
            local cid = rawCorner

            dbg("HOVER", "держимся 3 кадра в зоне", GetCornerLabel(cid))

            local ok, why = pointStillNeeded(cid, mod)
            if not ok then
                if why == "exhausted" then
                    dbg("IGNORE", "точка", GetCornerLabel(cid), "исчерпана — СБРОС + КАРАНТИН")
                    if opts.showText then
                        print("|cff00ffff[GESTURES]|r Сброс (повтор в пройденную точку).")
                    end
                    quarantineCorner = cid
                    resetSession()
                    hideAllHighlight()
                    return
                else
                    dbg("IGNORE", "точка", GetCornerLabel(cid), "нет в невыполненных жестах — игнор")
                    return
                end
            end

            local canProceed, reason = pointAllowedByPriority(cid, mod)
            if not canProceed then
                dbg("PRIORITY-FAIL", "заход в", GetCornerLabel(cid), "отклонён:", reason, "— СБРОС + КАРАНТИН")
                if opts.showText then
                    print("|cff00ffff[GESTURES]|r Сброс (нарушен порядок).")
                end
                quarantineCorner = cid
                resetSession()
                hideAllHighlight()
                return
            end

            visited[cid] = (visited[cid] or 0) + 1
            dbg("STEP", "ЗАСЧИТАНО", GetCornerLabel(cid), "счётчик:", visited[cid])

            if opts.showText then
                print("|cff00ffff[GESTURES]|r " .. GetCornerLabel(cid) .. " (" .. visited[cid] .. ")")
            end

            if opts.highlightHover and not opts.highlightShift then
                rebuildHighlight()
            end

            for _, g in ipairs(ensureDb()) do
                if g.mod == mod and not fired[g.id] then
                    local allDone = true
                    local hasAny = false
                    for gcid, data in pairs(g.corners or {}) do
                        if data.count and data.count > 0 then
                            hasAny = true
                            if (visited[gcid] or 0) < data.count then
                                allDone = false
                                break
                            end
                        end
                    end

                    if hasAny and allDone then
                        fired[g.id] = true
                        if opts.showText then
                            print("|cff00ffff[GESTURES]|r   [" .. (MOD_LABELS[g.mod] or "?") .. "] " .. ((g.name ~= "" and g.name) or g.id) .. ": ВЫПОЛНЕНО")
                        end
                        runGestureAction(g)

                        dbg("DONE", "жест выполнен — СБРОС + КАРАНТИН")
                        quarantineCorner = cid
                        resetSession()
                        hideAllHighlight()
                        return
                    end
                end
            end
        end
    end)

    -- ========================================================================
    -- API
    -- ========================================================================
    NSQC4.Gestures = NSQC4.Gestures or {}
    local G = NSQC4.Gestures

    function G:List() return ensureDb() end
    function G:Opts() return ensureOpts() end
    function G:ModifierLabels() return MOD_LABELS end
    function G:ModifierOrder() return MOD_ORDER end
    function G:ChatTargets() return CHAT_TARGETS end

    function G:Add(name, mod)
        local list = ensureDb()
        local g = ensureGesture({
            name = name or "",
            code = "",
            corners = {},
            mod = normalizeMod(mod),
            action = "code",
            chat = "say",
            text = "",
        })
        table.insert(list, g)
        dbg("ADD", g.id, g.name, g.mod)
        return g
    end

    function G:Remove(id)
        local list = ensureDb()
        for i = #list, 1, -1 do
            if list[i].id == id then table.remove(list, i); return true end
        end
        return false
    end

    function G:Get(id)
        for _, g in ipairs(ensureDb()) do
            if g.id == id then
                g.mod = normalizeMod(g.mod)
                g.action = normalizeAction(g.action)
                g.chat = normalizeChat(g.chat)
                g.text = g.text or ""
                return g
            end
        end
        return nil
    end

    function G:GetCorners() return CORNERS end
    function G:GetCornerLabel(id) return GetCornerLabel(id) end
    function G:GetRadius() return RADIUS end

    -- ========================================================================
    -- UI
    -- ========================================================================
    NSQC4.GesturesUI = NSQC4.GesturesUI or {}
    local UI = NSQC4.GesturesUI

    local mainFrame
    local editorFrame
    local optionsFrame
    local selectedGestureId

    local function CreateMainFrame()
        if mainFrame then return mainFrame end
        local f = CreateFrame("Frame", "NSQC4GesturesFrame", UIParent)
        f:SetSize(520, 460)
        f:SetPoint("CENTER")
        f:SetFrameStrata("MEDIUM")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -14)
        title:SetText("Жесты (модификаторы)")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() f:Hide() end)

        local optsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        optsBtn:SetSize(24, 24)
        optsBtn:SetPoint("TOPRIGHT", -36, -10)
        optsBtn:SetText("*")
        optsBtn:SetScript("OnClick", function() UI:OpenOptions() end)

        local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", 20, -48)
        nameLabel:SetText("Имя жеста:")

        local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        nameBox:SetSize(180, 24)
        nameBox:SetPoint("TOPLEFT", 110, -44)
        nameBox:SetAutoFocus(false)
        nameBox:SetMaxLetters(40)
        f.nameBox = nameBox

        local modLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modLabel:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
        modLabel:SetText("Мод:")

        local modBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        modBtn:SetSize(70, 24)
        modBtn:SetPoint("LEFT", modLabel, "RIGHT", 4, 0)
        f.newMod = "shift"
        modBtn:SetText(MOD_LABELS[f.newMod])

        local function cycleNewMod()
            local idx = 1
            for i, m in ipairs(MOD_ORDER) do
                if m == f.newMod then idx = i; break end
            end
            idx = idx + 1
            if idx > #MOD_ORDER then idx = 1 end
            f.newMod = MOD_ORDER[idx]
            modBtn:SetText(MOD_LABELS[f.newMod])
        end
        modBtn:SetScript("OnClick", cycleNewMod)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(24, 24)
        addBtn:SetPoint("LEFT", modBtn, "RIGHT", 8, 0)
        addBtn:SetText("+")
        addBtn:SetScript("OnClick", function()
            if not NSQC4.Gestures then return end
            local name = f.nameBox:GetText() or ""
            local g = NSQC4.Gestures:Add(name, f.newMod)
            f.nameBox:SetText("")
            f:Refresh()
            UI:OpenEditor(g.id)
        end)

        local div = f:CreateTexture(nil, "OVERLAY")
        div:SetTexture(0.5, 0.5, 0.5, 0.5)
        div:SetPoint("TOPLEFT", 20, -80)
        div:SetPoint("TOPRIGHT", -20, -80)
        div:SetHeight(1)

        local listTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listTitle:SetPoint("TOPLEFT", 20, -92)
        listTitle:SetText("Список жестов:")

        local scroll = CreateFrame("ScrollFrame", "NSQC4GesturesScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -115)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        local content = CreateFrame("Frame", "NSQC4GesturesContent", scroll)
        content:SetSize(440, 1)
        scroll:SetScrollChild(content)
        f.content = content
        f.rows = {}

        function f:Refresh()
            for _, row in ipairs(self.rows) do row:Hide() end
            self.rows = {}
            if not NSQC4.Gestures then return end
            migrateList()
            local list = NSQC4.Gestures:List()
            local y = 0
            if #list == 0 then
                local empty = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                empty:SetPoint("TOPLEFT", 8, -8)
                empty:SetText("|cff808080Жестов нет. Введи имя, выбери мод и нажми «+».|r")
                table.insert(self.rows, empty)
                self.content:SetHeight(40)
                return
            end

            for _, g in ipairs(list) do
                local row = CreateFrame("Button", nil, self.content)
                row:SetSize(440, 30)
                row:SetPoint("TOPLEFT", 0, -y)
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                row:SetBackdropColor(0.15, 0.15, 0.15, 0.6)

                local name = (g.name and g.name ~= "") and g.name or "(без имени)"
                local mod = normalizeMod(g.mod)
                local actionLabel = (normalizeAction(g.action) == "text") and "текст" or "код"
                local cornersText = ""
                local n = 0
                for cid, data in pairs(g.corners or {}) do
                    if data.count and data.count > 0 then
                        n = n + 1
                        if n <= 2 then
                            if cornersText ~= "" then cornersText = cornersText .. ", " end
                            cornersText = cornersText .. GetCornerLabel(cid) .. "(P" .. (data.order or 1) .. "×" .. data.count .. ")"
                        end
                    end
                end
                if n == 0 then cornersText = "|cff808080нет точек|r" end
                if n > 2 then cornersText = cornersText .. ", …" end

                local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                left:SetPoint("LEFT", 8, 0)
                left:SetText("|cff808080[" .. (MOD_LABELS[mod] or mod) .. "]|r |cffFFD100" .. name .. "|r |cff66ccff<" .. actionLabel .. ">|r")

                local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                right:SetPoint("RIGHT", -8, 0)
                right:SetText(cornersText)

                row:SetScript("OnClick", function() UI:OpenEditor(g.id) end)
                table.insert(self.rows, row)
                y = y + 32
            end
            self.content:SetHeight(math.max(40, y))
        end

        f:Refresh()
        mainFrame = f
        return f
    end

    -- ------------------------------------------------------------------------
    -- Редактор жеста
    -- ------------------------------------------------------------------------
    local function CreateEditorFrame()
        if editorFrame then return editorFrame end
        local f = CreateFrame("Frame", "NSQC4GestureEditorFrame", UIParent)
        f:SetSize(560, 840)
        f:SetPoint("CENTER", 160, 0)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -14)
        f.title = title

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() f:Hide() end)

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 20, -40)
        hint:SetText("ЛКМ — добавить точку. ПКМ — уменьшить.")

        local mapSize = 340
        local map = CreateFrame("Frame", nil, f)
        map:SetSize(mapSize, mapSize)
        map:SetPoint("TOP", 0, -112)
        map:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        map:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        map:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        f.map = map

        local points = {}
        for _, c in ipairs(CORNERS) do
            local b = CreateFrame("Button", nil, map)
            b:SetSize(70, 70)
            b:SetPoint("CENTER", map, "BOTTOMLEFT", c.fx * mapSize, c.fy * mapSize)
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            b:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
            b:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            b.cornerId = c.id

            b.countText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            b.countText:SetPoint("CENTER", 0, 0)
            b.countText:SetText("")
            b.countText:SetTextColor(1, 0.82, 0)

            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(_, button)
                if not selectedGestureId then return end
                local g = NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
                if not g then return end
                g.corners = g.corners or {}

                local data = g.corners[c.id]

                if button == "LeftButton" then
                    if not data then
                        local maxOrder = 0
                        for _, d in pairs(g.corners) do if (d.order or 0) > maxOrder then maxOrder = d.order end end
                        g.corners[c.id] = { count = 1, order = maxOrder + 1 }
                    else
                        data.count = data.count + 1
                        if data.count > 99 then data.count = 99 end
                    end
                elseif button == "RightButton" then
                    if data then
                        data.count = data.count - 1
                        if data.count <= 0 then
                            g.corners[c.id] = nil
                        end
                    end
                end
                f:Refresh()
            end)

            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(c.label, 1, 0.82, 0)
                local g = selectedGestureId and NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
                local data = g and g.corners and g.corners[c.id]
                if data then
                    GameTooltip:AddLine("Приоритет: " .. tostring(data.order or 1), 1, 1, 1)
                    GameTooltip:AddLine("Счётчик: " .. tostring(data.count or 1), 1, 1, 1)
                else
                    GameTooltip:AddLine("Не задана", 0.5, 0.5, 0.5)
                end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            points[c.id] = b
        end
        f.points = points

        local modTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modTitle:SetPoint("TOPLEFT", 20, -516)
        modTitle:SetText("Модификатор:")

        local modButtons = {}
        local function updateModButtons()
            local g = selectedGestureId and NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
            local cur = g and normalizeMod(g.mod) or "shift"
            for m, b in pairs(modButtons) do
                if m == cur then
                    b:SetBackdropColor(0.3, 0.25, 0, 0.9)
                    b:SetBackdropBorderColor(1, 0.82, 0, 1)
                else
                    b:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
                    b:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                end
            end
        end
        f.updateModButtons = updateModButtons

        local prev
        for _, m in ipairs(MOD_ORDER) do
            local b = CreateFrame("Button", nil, f)
            b:SetSize(100, 26)
            if prev then
                b:SetPoint("LEFT", prev, "RIGHT", 8, 0)
            else
                b:SetPoint("TOPLEFT", 120, -512)
            end
            b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            b:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            b:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            t:SetPoint("CENTER")
            t:SetText(MOD_LABELS[m])

            b:SetScript("OnClick", function()
                if not selectedGestureId then return end
                local g = NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
                if not g then return end
                g.mod = m
                updateModButtons()
                if mainFrame then mainFrame:Refresh() end
            end)
            modButtons[m] = b
            prev = b
        end
        f.modButtons = modButtons

        local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", 20, -555)
        nameLabel:SetText("Имя:")

        local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        nameBox:SetSize(420, 24)
        nameBox:SetPoint("TOPLEFT", 70, -551)
        nameBox:SetAutoFocus(false)
        nameBox:SetMaxLetters(40)
        f.nameBox = nameBox

        -- --------------------------------------------------------------------
        -- Второй раздел: действие (радиокнопки Код / Текст)
        -- --------------------------------------------------------------------
        local actionTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        actionTitle:SetPoint("TOPLEFT", 20, -588)
        actionTitle:SetText("Действие жеста:")

        local rbCode = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
        rbCode:SetPoint("TOPLEFT", 20, -608)
        rbCode:SetSize(22, 22)
        local rbCodeLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rbCodeLbl:SetPoint("LEFT", rbCode, "RIGHT", 4, 0)
        rbCodeLbl:SetText("Код (Lua)")
        f.rbCode = rbCode

        local rbText = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
        rbText:SetPoint("LEFT", rbCodeLbl, "RIGHT", 40, 0)
        rbText:SetSize(22, 22)
        local rbTextLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rbTextLbl:SetPoint("LEFT", rbText, "RIGHT", 4, 0)
        rbTextLbl:SetText("Текст в чат")
        f.rbText = rbText

        -- Панель кода
        local codePanel = CreateFrame("Frame", nil, f)
        codePanel:SetPoint("TOPLEFT", 20, -640)
        codePanel:SetSize(520, 130)
        f.codePanel = codePanel

        local codeLabel = codePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        codeLabel:SetPoint("TOPLEFT", 0, 0)
        codeLabel:SetText("Код (Lua):")

        local codeBox = CreateFrame("EditBox", nil, codePanel)
        codeBox:SetSize(520, 105)
        codeBox:SetPoint("TOPLEFT", 0, -18)
        codeBox:SetMultiLine(true)
        codeBox:SetAutoFocus(false)
        codeBox:SetFontObject("ChatFontNormal")
        codeBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        codeBox:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        codeBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        codeBox:SetTextInsets(4, 4, 4, 4)
        f.codeBox = codeBox

        -- Панель текста
        local textPanel = CreateFrame("Frame", nil, f)
        textPanel:SetPoint("TOPLEFT", 20, -640)
        textPanel:SetSize(520, 130)
        f.textPanel = textPanel

        local chatLabel = textPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chatLabel:SetPoint("TOPLEFT", 0, 0)
        chatLabel:SetText("Канал:")

        local chatBtn = CreateFrame("Button", nil, textPanel, "UIPanelButtonTemplate")
        chatBtn:SetSize(130, 24)
        chatBtn:SetPoint("LEFT", chatLabel, "RIGHT", 8, 0)
        f.chatBtn = chatBtn

        local function currentChatKey()
            local g = selectedGestureId and NSQC4.Gestures:Get(selectedGestureId)
            return g and normalizeChat(g.chat) or "say"
        end
        local function updateChatBtn()
            local t = CHAT_BY_KEY[currentChatKey()]
            chatBtn:SetText(t and t.label or "?")
        end
        chatBtn:SetScript("OnClick", function()
            if not selectedGestureId then return end
            local g = NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            local cur = normalizeChat(g.chat)
            local idx = 1
            for i, t in ipairs(CHAT_TARGETS) do
                if t.key == cur then idx = i; break end
            end
            idx = idx + 1
            if idx > #CHAT_TARGETS then idx = 1 end
            g.chat = CHAT_TARGETS[idx].key
            updateChatBtn()
        end)
        f.updateChatBtn = updateChatBtn

        local textLabel = textPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textLabel:SetPoint("TOPLEFT", 0, -32)
        textLabel:SetText("Текст:")

        local textBox = CreateFrame("EditBox", nil, textPanel)
        textBox:SetSize(520, 72)
        textBox:SetPoint("TOPLEFT", 0, -52)
        textBox:SetMultiLine(true)
        textBox:SetAutoFocus(false)
        textBox:SetMaxLetters(255)
        textBox:SetFontObject("ChatFontNormal")
        textBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        textBox:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        textBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        textBox:SetTextInsets(4, 4, 4, 4)
        f.textBox = textBox

        -- Переключение видимости панелей + синхронизация радиокнопок.
        local updatingAction = false
        local function updateActionPanels()
            if updatingAction then return end
            updatingAction = true

            local g = selectedGestureId and NSQC4.Gestures:Get(selectedGestureId)
            local action = g and normalizeAction(g.action) or "code"
            if action == "text" then
                f.codePanel:Hide()
                f.textPanel:Show()
                rbCode:SetChecked(false)
                rbText:SetChecked(true)
                updateChatBtn()
            else
                f.textPanel:Hide()
                f.codePanel:Show()
                rbCode:SetChecked(true)
                rbText:SetChecked(false)
            end

            updatingAction = false
        end
        f.updateActionPanels = updateActionPanels

        rbCode:SetScript("OnClick", function(self)
            if updatingAction then
                self:SetChecked(normalizeAction(NSQC4.Gestures:Get(selectedGestureId).action) == "code")
                return
            end
            if not selectedGestureId then return end
            local g = NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            g.action = "code"
            updateActionPanels()
            if mainFrame then mainFrame:Refresh() end
        end)
        rbText:SetScript("OnClick", function(self)
            if updatingAction then
                self:SetChecked(normalizeAction(NSQC4.Gestures:Get(selectedGestureId).action) == "text")
                return
            end
            if not selectedGestureId then return end
            local g = NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            g.action = "text"
            updateActionPanels()
            if mainFrame then mainFrame:Refresh() end
        end)

        -- Кнопки внизу
        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetSize(130, 26)
        saveBtn:SetPoint("BOTTOMLEFT", 20, 18)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            if not selectedGestureId then return end
            local g = NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            g.name = f.nameBox:GetText() or ""
            g.code = f.codeBox:GetText() or ""
            g.text = f.textBox:GetText() or ""
            g.mod = normalizeMod(g.mod)
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
            if mainFrame then mainFrame:Refresh() end
            f:Hide()
        end)

        local delBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        delBtn:SetSize(130, 26)
        delBtn:SetPoint("BOTTOM", 0, 18)
        delBtn:SetText("Удалить жест")
        delBtn:SetScript("OnClick", function()
            if not selectedGestureId then return end
            NSQC4.Gestures:Remove(selectedGestureId)
            selectedGestureId = nil
            if mainFrame then mainFrame:Refresh() end
            f:Hide()
        end)

        local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        clearBtn:SetSize(130, 26)
        clearBtn:SetPoint("BOTTOMRIGHT", -20, 18)
        clearBtn:SetText("Сбросить точки")
        clearBtn:SetScript("OnClick", function()
            if not selectedGestureId then return end
            local g = NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            g.corners = {}
            f:Refresh()
        end)

        function f:Refresh()
            if not selectedGestureId then return end
            local g = NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
            if not g then return end
            local mod = normalizeMod(g.mod)
            self.title:SetText("Жест: " .. ((g.name ~= "" and g.name) or g.id) .. " [" .. (MOD_LABELS[mod] or mod) .. "]")
            self.nameBox:SetText(g.name or "")
            self.codeBox:SetText(g.code or "")
            self.textBox:SetText(g.text or "")

            for id, b in pairs(self.points) do
                local data = g.corners and g.corners[id]
                if data and data.count > 0 then
                    b.countText:SetText("P" .. (data.order or 1) .. " x" .. data.count)
                    b.countText:SetTextColor(1, 0.82, 0)
                    b:SetBackdropColor(0.3, 0.25, 0, 0.9)
                    b:SetBackdropBorderColor(1, 0.82, 0, 1)
                else
                    b.countText:SetText("")
                    b:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
                    b:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                end
            end
            self.updateModButtons()
            self.updateActionPanels()
        end

        editorFrame = f
        return f
    end

    local function CreateOptionsFrame()
        if optionsFrame then return optionsFrame end
        local f = CreateFrame("Frame", "NSQC4GesturesOptionsFrame", UIParent)
        f:SetSize(400, 240)
        f:SetPoint("CENTER", 200, 100)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -14)
        title:SetText("Настройки жестов")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() f:Hide() end)

        local function mkCheckbox(y, text, key)
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 20, y)
            cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb.text:SetText(text)
            cb:SetScript("OnClick", function(self)
                ensureOpts()[key] = self:GetChecked() and true or false
            end)
            return cb
        end

        f.cb1 = mkCheckbox(-50, "Отображать текст в чате", "showText")
        f.cb2 = mkCheckbox(-90, "Подсвечивать точки под модификатором", "highlightShift")
        f.cb3 = mkCheckbox(-130, "Подсвечивать после наведения на первую точку", "highlightHover")

        function f:Refresh()
            local o = ensureOpts()
            self.cb1:SetChecked(o.showText and true or false)
            self.cb2:SetChecked(o.highlightShift and true or false)
            self.cb3:SetChecked(o.highlightHover and true or false)
        end

        optionsFrame = f
        return f
    end

    function UI:Open()
        migrateList()
        local f = CreateMainFrame()
        f:Show()
        f:Raise()
        f:Refresh()
    end

    function UI:OpenEditor(gestureId)
        selectedGestureId = gestureId
        local g = NSQC4.Gestures and NSQC4.Gestures:Get(gestureId)
        if g then
            g.mod = normalizeMod(g.mod)
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
            g.text = g.text or ""
        end
        local f = CreateEditorFrame()
        f:Show()
        f:Raise()
        f:Refresh()
    end

    function UI:OpenOptions()
        local f = CreateOptionsFrame()
        f:Refresh()
        f:Show()
        f:Raise()
    end

    SLASH_NSGESTURES1 = "/ns_gestures"
    SlashCmdList["NSGESTURES"] = function(msg)
        msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if msg == "debug" then
            local o = ensureOpts()
            print("|cff00ffff[GEST-DEBUG]|r opts: showText=" .. tostring(o.showText) .. " highlightShift=" .. tostring(o.highlightShift))
            return
        end
        UI:Open()
    end

    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton(
            "Ж",
            "/ns_gestures",
            {
                { text = "Жесты по точкам экрана", r = 1.00, g = 0.82, b = 0.00 },
                { text = "Shift / Ctrl / Alt — на выбор у жеста.", r = 0.85, g = 0.85, b = 0.85 },
                { text = "Действие: код Lua или текст в чат.", r = 0.85, g = 0.85, b = 0.85 },
            },
            function() UI:Open() end
        )
    end

    NSQC4.SetModuleMeta("gestures", {
        label   = "Жесты (Shift / Ctrl / Alt)",
        tooltip = "Жесты по 16 точкам экрана под зажатым модификатором.",
        order   = 100,
    })

    migrateList()

end)