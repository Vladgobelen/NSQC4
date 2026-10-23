-- ============================================================================
-- NSQC4 / Core / Settings / Gestures
-- Жесты по 16 точкам экрана под зажатым модификатором (Shift / Ctrl / Alt).
-- ============================================================================

NSQC4 = NSQC4 or {}

NSQC4.RegisterModule("gestures", function()

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    local GDBG = { enabled = false }
    local function dbg(tag, ...)
        if not GDBG.enabled then return end
        local p = { "|cff00ddaa[GEST " .. tag .. "]|r" }
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

    local function normalizeMod(mod)
        if mod == "ctrl" or mod == "alt" then return mod end
        return "shift"
    end

    local function ensureGesture(g)
        g.id = g.id or ("g" .. tostring(math.random(100000, 999999)))
        g.name = g.name or ""
        g.code = g.code or ""
        g.corners = g.corners or {}
        g.mod = normalizeMod(g.mod)
        return g
    end

    local function migrateList()
        for _, g in ipairs(ensureDb()) do
            g.mod = normalizeMod(g.mod)
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
    -- Модификаторы
    -- ========================================================================
    local function activeModifier()
        if not NSQC4.Modifiers then return nil end
        if NSQC4.Modifiers.ShiftDown and NSQC4.Modifiers.ShiftDown() then return "shift" end
        if NSQC4.Modifiers.CtrlDown  and NSQC4.Modifiers.CtrlDown()  then return "ctrl"  end
        if NSQC4.Modifiers.AltDown   and NSQC4.Modifiers.AltDown()   then return "alt"   end
        return nil
    end

    -- ========================================================================
    -- Оверлей-подсветка с прогрессом
    -- ========================================================================
    local hl = {}

    local function getHighlighter(cornerId)
        if hl[cornerId] then return hl[cornerId] end

        local f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata("TOOLTIP") -- Поверх всех окон
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(1, 0.82, 0, 0.15)
        f:Hide()

        f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.count:SetPoint("CENTER", 0, 0)
        f.count:SetTextColor(1, 1, 1)
        f.count:SetText("")

        -- Задаём размер и позицию ОДИН РАЗ при создании
        -- Размер = 2 * RADIUS, чтобы квадрат накрывал ровно ту зону, где срабатывает точка
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
    local sessionLocked = false
    local sessionMod = nil

    local function resetSession()
        dbg("RESET", "сброс прогресса")
        visited = {}
        currentCorner = nil
        fired = {}
        sessionLocked = false
    end

    -- ========================================================================
    -- Выполнение
    -- ========================================================================
    local function runCode(code)
        if not code or code == "" then return end
        local fn, err = loadstring(code)
        if not fn then
            dbg("RUN", "ошибка компиляции:", err)
            return
        end
        local ok, runErr = pcall(fn)
        if not ok then dbg("RUN", "ошибка выполнения:", runErr) end
    end

    -- ========================================================================
    -- Подсветка
    -- ========================================================================
    local function rebuildHighlight()
        local opts = ensureOpts()
        if not (opts.highlightShift or opts.highlightHover) then hideAllHighlight(); return end
        if sessionLocked then hideAllHighlight(); return end
        if not sessionMod then hideAllHighlight(); return end

        local needed = {}
        for _, g in ipairs(ensureDb()) do
            if g.mod == sessionMod and not fired[g.id] then
                for cid, n in pairs(g.corners or {}) do
                    if n and n > 0 and GetCornerById(cid) then
                        if not needed[cid] or n > needed[cid] then
                            needed[cid] = n
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

        -- Модификатор отпущен — полный сброс
        if not mod then
            if sessionMod ~= nil then
                dbg("UPDATE", "модификатор отпущен")
                sessionMod = nil
                resetSession()
            end
            hideAllHighlight()
            return
        end

        -- Смена модификатора
        if sessionMod ~= mod then
            dbg("UPDATE", "смена модификатора на", mod)
            resetSession()
            sessionMod = mod
            -- ВАЖНО: при смене модификатора сразу сбрасываем currentCorner,
            -- чтобы текущая точка под курсором засчиталась в этом же кадре
            currentCorner = nil 
        end

        local opts = ensureOpts()

        if sessionLocked then
            hideAllHighlight()
            return
        end

        if opts.highlightShift then
            rebuildHighlight()
        elseif not opts.highlightHover then
            hideAllHighlight()
        end

        local cx, cy = cursorPos()
        local rawCorner = whichCorner(cx, cy)

        -- Выход из зоны
        if currentCorner and currentCorner ~= rawCorner then
            currentCorner = nil
        end

        -- Вход в зону
        if rawCorner and currentCorner ~= rawCorner then
            currentCorner = rawCorner
            local cid = rawCorner

            -- Проверяем, есть ли эта точка ХОТЯ БЫ В ОДНОМ жесте текущего модификатора
            local isPointInAnyGesture = false
            for _, g in ipairs(ensureDb()) do
                if g.mod == mod and (g.corners[cid] or 0) > 0 then
                    isPointInAnyGesture = true
                    break
                end
            end

            if not isPointInAnyGesture then
                dbg("IGNORE", "точка", cid, "игнорируется (нет в жестах)")
                return
            end

            -- Засчитываем заход
            visited[cid] = (visited[cid] or 0) + 1
            dbg("STEP", "зашёл в", cid, "счётчик:", visited[cid])

            if opts.showText then
                print("|cff00ffff[GESTURES]|r " .. GetCornerLabel(cid) .. " (" .. visited[cid] .. ")")
            end

            -- Проверяем: превышен ли лимит?
            local overLimitForAll = true
            for _, g in ipairs(ensureDb()) do
                if g.mod == mod then
                    local validForThis = true
                    for vcid, vcnt in pairs(visited) do
                        local need = (g.corners[vcid] or 0)
                        if vcnt > need then
                            validForThis = false
                            break
                        end
                    end
                    if validForThis then
                        overLimitForAll = false
                        break
                    end
                end
            end

            if overLimitForAll then
                dbg("FAIL", "превышен лимит по всем жестам, сброс")
                if opts.showText then print("|cff00ffff[GESTURES]|r Превышен лимит. Сброс.") end
                resetSession()
                return
            end

            if opts.highlightHover and not opts.highlightShift then
                rebuildHighlight()
            end

            -- Проверяем на срабатывание
            for _, g in ipairs(ensureDb()) do
                if g.mod == mod and not fired[g.id] then
                    local allDone = true
                    local hasAny = false
                    for gcid, need in pairs(g.corners or {}) do
                        if need and need > 0 and GetCornerById(gcid) then
                            hasAny = true
                            if (visited[gcid] or 0) < need then
                                allDone = false
                                break
                            end
                        end
                    end

                    if hasAny and allDone then
                        fired[g.id] = true
                        for gcid in pairs(g.corners or {}) do
                            visited[gcid] = 0
                        end
                        if opts.showText then
                            print("|cff00ffff[GESTURES]|r   ["
                                .. (MOD_LABELS[g.mod] or "?") .. "] "
                                .. ((g.name ~= "" and g.name) or g.id) .. ": выполнено")
                        end
                        runCode(g.code)

                        sessionLocked = true
                        hideAllHighlight()
                        break
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

    function G:Add(name, mod)
        local list = ensureDb()
        local g = ensureGesture({ name = name or "", code = "", corners = {}, mod = normalizeMod(mod) })
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
                return g
            end
        end
        return nil
    end

    function G:GetCorners() return CORNERS end
    function G:GetCornerLabel(id) return GetCornerLabel(id) end
    function G:GetRadius() return RADIUS end

    function G:GetDebugState()
        local cx, cy = cursorPos()
        local w, h = screenSize()
        local visList, firedList = {}, {}
        for id, n in pairs(visited) do visList[#visList + 1] = id .. "=" .. n end
        for id in pairs(fired) do firedList[#firedList + 1] = id end
        return {
            modifier = activeModifier(),
            sessionMod = sessionMod,
            cursorX = cx, cursorY = cy,
            screenW = w, screenH = h,
            inCorner = whichCorner(cx, cy),
            visited = visList,
            currentCorner = currentCorner,
            fired = firedList,
            sessionLocked = sessionLocked,
        }
    end

    -- ========================================================================
    -- UI
    -- ========================================================================
    NSQC4.GesturesUI = NSQC4.GesturesUI or {}
    local UI = NSQC4.GesturesUI

    local mainFrame
    local editorFrame
    local optionsFrame
    local selectedGestureId

    -- ------------------------------------------------------------------------
    -- Главное окно (MEDIUM)
    -- ------------------------------------------------------------------------
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

        f.scroll = scroll
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
                local modLabelText = MOD_LABELS[mod] or mod
                local cornersText = ""
                local n = 0
                for cid, cnt in pairs(g.corners or {}) do
                    if cnt and cnt > 0 then
                        n = n + 1
                        if n <= 3 then
                            if cornersText ~= "" then cornersText = cornersText .. ", " end
                            cornersText = cornersText .. GetCornerLabel(cid) .. "×" .. cnt
                        end
                    end
                end
                if n == 0 then cornersText = "|cff808080нет точек|r" end
                if n > 3 then cornersText = cornersText .. ", …" end

                local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                left:SetPoint("LEFT", 8, 0)
                left:SetText("|cff808080[" .. modLabelText .. "]|r |cffFFD100" .. name .. "|r")

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
    -- Редактор (DIALOG)
    -- ------------------------------------------------------------------------
    local function CreateEditorFrame()
        if editorFrame then return editorFrame end

        local f = CreateFrame("Frame", "NSQC4GestureEditorFrame", UIParent)
        f:SetSize(560, 780) -- Увеличили высоту окна с 730 до 780
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
        hint:SetText("ЛКМ — +1. ПКМ — −1. Срабатывает под выбранным модификатором.")

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
            b:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
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
                local cur = g.corners[c.id] or 0
                if button == "LeftButton" then cur = cur + 1; if cur > 99 then cur = 99 end
                elseif button == "RightButton" then cur = cur - 1; if cur < 0 then cur = 0 end end
                if cur == 0 then g.corners[c.id] = nil else g.corners[c.id] = cur end
                f:Refresh()
            end)

            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(c.label, 1, 0.82, 0)
                local g = selectedGestureId and NSQC4.Gestures and NSQC4.Gestures:Get(selectedGestureId)
                local cnt = g and g.corners and g.corners[c.id] or 0
                GameTooltip:AddLine("Счётчик: " .. tostring(cnt), 1, 1, 1)
                GameTooltip:AddLine("ID: " .. c.id, 0.6, 0.6, 0.6)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            points[c.id] = b
        end
        f.points = points

        -- СДВИНУТО ЕЩЁ НА 50 ПИКСЕЛЕЙ ВНИЗ (было -470, стало -520)
        local modTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modTitle:SetPoint("TOPLEFT", 20, -520) 
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
                b:SetPoint("TOPLEFT", 120, -516) -- было -466, стало -516
            end
            b:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
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

        -- Имя (было -515, стало -565)
        local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", 20, -565)
        nameLabel:SetText("Имя:")

        local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        nameBox:SetSize(420, 24)
        nameBox:SetPoint("TOPLEFT", 70, -561)
        nameBox:SetAutoFocus(false)
        nameBox:SetMaxLetters(40)
        f.nameBox = nameBox

        -- Код (было -545, стало -595)
        local codeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        codeLabel:SetPoint("TOPLEFT", 20, -595)
        codeLabel:SetText("Код (Lua):")

        local codeBox = CreateFrame("EditBox", nil, f)
        codeBox:SetSize(520, 100)
        codeBox:SetPoint("TOPLEFT", 20, -615)
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
            g.mod = normalizeMod(g.mod)
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
            self.title:SetText("Жест: " .. ((g.name ~= "" and g.name) or g.id)
                .. " [" .. (MOD_LABELS[mod] or mod) .. "]")
            self.nameBox:SetText(g.name or "")
            self.codeBox:SetText(g.code or "")
            for id, b in pairs(self.points) do
                local cnt = (g.corners and g.corners[id]) or 0
                if cnt > 0 then
                    b.countText:SetText(tostring(cnt))
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
        end

        editorFrame = f
        return f
    end

    -- ------------------------------------------------------------------------
    -- Настройки (DIALOG)
    -- ------------------------------------------------------------------------
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

    -- ------------------------------------------------------------------------
    -- Публичный API UI
    -- ------------------------------------------------------------------------
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
        if g then g.mod = normalizeMod(g.mod) end
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

    -- ========================================================================
    -- Слэш-команда
    -- ========================================================================
    SLASH_NSGESTURES1 = "/ns_gestures"
    SlashCmdList["NSGESTURES"] = function(msg)
        msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if msg == "debug" then
            local o = ensureOpts()
            print("|cff00ffff[GEST-DEBUG]|r opts: showText=" .. tostring(o.showText)
                .. " highlightShift=" .. tostring(o.highlightShift))
            local s = NSQC4.Gestures and NSQC4.Gestures.GetDebugState and NSQC4.Gestures:GetDebugState()
            if s then
                print("|cff00ffff[GEST-DEBUG]|r modifier=" .. tostring(s.modifier)
                    .. " sessionMod=" .. tostring(s.sessionMod)
                    .. " inCorner=" .. tostring(s.inCorner))
            end
            return
        end
        UI:Open()
    end

    -- ========================================================================
    -- Кнопка на панели
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton(
            "Ж",
            "/ns_gestures",
            {
                { text = "Жесты по точкам экрана", r = 1.00, g = 0.82, b = 0.00 },
                { text = "Shift / Ctrl / Alt — на выбор у жеста.", r = 0.85, g = 0.85, b = 0.85 },
            },
            function() UI:Open() end
        )
    end

    -- ========================================================================
    -- Метаданные
    -- ========================================================================
    NSQC4.SetModuleMeta("gestures", {
        label   = "Жесты (Shift / Ctrl / Alt)",
        tooltip = "Жесты по 16 точкам экрана под зажатым модификатором.",
        order   = 100,
    })

    migrateList()
    dbg("INIT", "готов")

end)