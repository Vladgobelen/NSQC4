-- ============================================================================
-- NSQC4 / Core / Settings / Trajectory
-- Жесты-маршруты под Shift / Ctrl / Alt.
--
-- /ns_traj                — окно «Жесты-маршруты»
-- /ns_traj debug          — статус
-- /ns_traj trace          — вкл/выкл внутренние [TRAJ ...] сообщения
-- /ns_traj record         — записать новый жест (ждёт модификатор → рисование → отпускание)
-- /ns_traj test           — распознать следующий жест (показать dev)
-- /ns_traj stop           — принудительно завершить текущую запись
-- ============================================================================

NSQC4 = NSQC4 or {}

NSQC4.RegisterModule("trajectory", function()

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    local TDBG = { enabled = false }
    local function dbg(tag, ...)
        if not TDBG.enabled then return end
        local p = { "|cffaa66ff[TRAJ " .. tag .. "]|r" }
        for _, v in ipairs({...}) do p[#p + 1] = tostring(v) end
        print(unpack(p))
    end

    -- ========================================================================
    -- Модификаторы
    -- ========================================================================
    local MODS = { "shift", "ctrl", "alt" }

    local function modDown(mod)
        if not NSQC4.Modifiers then return false end
        if mod == "shift" then return NSQC4.Modifiers.ShiftDown and NSQC4.Modifiers.ShiftDown() or false end
        if mod == "ctrl"  then return NSQC4.Modifiers.CtrlDown  and NSQC4.Modifiers.CtrlDown()  or false end
        if mod == "alt"   then return NSQC4.Modifiers.AltDown   and NSQC4.Modifiers.AltDown()   or false end
        return false
    end

    local function anyDown()
        return modDown("shift") or modDown("ctrl") or modDown("alt")
    end

    -- приоритет: Shift > Ctrl > Alt
    local function currentModifier()
        if modDown("shift") then return "shift" end
        if modDown("ctrl")  then return "ctrl"  end
        if modDown("alt")   then return "alt"   end
        return nil
    end

    local function modLabel(mod)
        if mod == "shift" then return "Shift" end
        if mod == "ctrl"  then return "Ctrl"  end
        if mod == "alt"   then return "Alt"   end
        return "?"
    end

    -- ========================================================================
    -- Настройки / хранилище
    -- ========================================================================
    local function ensureOpts()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.settings = nsDbc4.settings or {}
        nsDbc4.settings.trajectory = nsDbc4.settings.trajectory or {}
        local o = nsDbc4.settings.trajectory.opts
        if not o then
            o = {
                showText        = true,
                tolerance       = 0.25,
                algorithm       = "shape",
                sampleCount     = 32,
                minStepPx       = 0.75,
                recordOnMod     = true,
                shiftStable     = 2,
                idleTimeoutMs   = 400,
                recordTimeoutMs = 15000,
            }
            nsDbc4.settings.trajectory.opts = o
        end
        if o.showText == nil then o.showText = true end
        if o.tolerance == nil then o.tolerance = 0.25 end
        if o.algorithm == nil then o.algorithm = "shape" end
        if o.sampleCount == nil then o.sampleCount = 32 end
        if o.minStepPx == nil then o.minStepPx = 0.75 end
        if o.recordOnMod == nil then
            if o.recordOnShift ~= nil then o.recordOnMod = o.recordOnShift
            else o.recordOnMod = true end
        end
        o.recordOnShift = o.recordOnMod
        if o.shiftStable == nil then o.shiftStable = 2 end
        if o.idleTimeoutMs == nil then o.idleTimeoutMs = 400 end
        if o.recordTimeoutMs == nil then o.recordTimeoutMs = 15000 end
        return o
    end

    local function ensureDb()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.settings = nsDbc4.settings or {}
        nsDbc4.settings.trajectory = nsDbc4.settings.trajectory or {}
        nsDbc4.settings.trajectory.list = nsDbc4.settings.trajectory.list or {}
        return nsDbc4.settings.trajectory.list
    end

    local function ensureGesture(g)
        g.id = g.id or ("t" .. tostring(math.random(100000, 999999)))
        g.name = g.name or ""
        g.code = g.code or ""
        g.points = g.points or {}
        g.rawLen = g.rawLen or 0
        g.modifier = g.modifier or "shift"
        return g
    end

    -- ========================================================================
    -- Математика
    -- ========================================================================
    local function resample(points, n)
        if #points < 2 then return points end
        local d = { 0 }
        local total = 0
        for i = 2, #points do
            local dx = points[i].x - points[i-1].x
            local dy = points[i].y - points[i-1].y
            total = total + math.sqrt(dx*dx + dy*dy)
            d[i] = total
        end
        if total < 1e-6 then return { { x = 0, y = 0 } } end
        local interval = total / (n - 1)
        local out = { { x = points[1].x, y = points[1].y } }
        local i = 2
        for k = 1, n - 2 do
            local target = k * interval
            while i <= #points and d[i] < target do i = i + 1 end
            if i > #points then break end
            local seg = d[i] - d[i-1]
            local t = (seg > 1e-9) and ((target - d[i-1]) / seg) or 0
            out[#out+1] = {
                x = points[i-1].x + t * (points[i].x - points[i-1].x),
                y = points[i-1].y + t * (points[i].y - points[i-1].y),
            }
        end
        out[#out+1] = { x = points[#points].x, y = points[#points].y }
        return out
    end

    local function normalize(points)
        if #points == 0 then return points end
        local ox, oy = points[1].x, points[1].y
        local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
        for _, p in ipairs(points) do
            local x, y = p.x - ox, p.y - oy
            if x < minx then minx = x end
            if y < miny then miny = y end
            if x > maxx then maxx = x end
            if y > maxy then maxy = y end
        end
        local w = math.max(maxx - minx, 1e-6)
        local h = math.max(maxy - miny, 1e-6)
        local s = math.max(w, h)
        local out = {}
        for i, p in ipairs(points) do
            out[i] = { x = (p.x - ox) / s, y = (p.y - oy) / s }
        end
        return out
    end

    local function dirDeviation(a, b)
        local n = math.min(#a, #b)
        if n < 2 then return 1 end
        local sum, count = 0, 0
        for i = 2, n do
            local ax, ay = a[i].x - a[i-1].x, a[i].y - a[i-1].y
            local bx, by = b[i].x - b[i-1].x, b[i].y - b[i-1].y
            local la = math.sqrt(ax*ax + ay*ay)
            local lb = math.sqrt(bx*bx + by*by)
            if la > 1e-6 and lb > 1e-6 then
                ax, ay = ax/la, ay/la
                bx, by = bx/lb, by/lb
                sum = sum + (1 - (ax*bx + ay*by)) / 2
                count = count + 1
            end
        end
        return count > 0 and (sum / count) or 1
    end

    local function pointDeviation(a, b)
        local n = math.min(#a, #b)
        if n == 0 then return 1 end
        local sum = 0
        for i = 1, n do
            local dx = a[i].x - b[i].x
            local dy = a[i].y - b[i].y
            sum = sum + math.sqrt(dx*dx + dy*dy)
        end
        local dev = sum / n
        if dev > 1 then dev = 1 end
        return dev
    end

    local function deviation(a, b, algo)
        if algo == "strict" then return pointDeviation(a, b) end
        return dirDeviation(a, b)
    end

    local function prepare(raw, n)
        n = n or 32
        if #raw < 2 then return nil end
        local r = resample(raw, n)
        return normalize(r)
    end

    local function recognize(rawPoints, opts, modifier)
        opts = opts or ensureOpts()
        local probe = prepare(rawPoints, opts.sampleCount)
        if not probe then return nil, 1 end
        local best, bestDev = nil, math.huge
        for _, g in ipairs(ensureDb()) do
            if g.points and #g.points >= 2 and (g.modifier or "shift") == modifier then
                local dev = deviation(probe, g.points, opts.algorithm)
                if dev < bestDev then bestDev, best = dev, g end
            end
        end
        if best and bestDev <= opts.tolerance then
            return best, bestDev
        end
        return nil, bestDev
    end

    -- ========================================================================
    -- Состояние записи
    -- ========================================================================
    local rec = {
        active       = false,
        mode         = nil,
        points       = {},
        startX       = 0,
        startY       = 0,
        lastMoveAt   = 0,
        replaceId    = nil,
        sawModDown   = false,
        startedAt    = 0,
        modifier     = nil,       -- "shift" | "ctrl" | "alt"
    }

    local function cursorPos()
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        return x / s, y / s
    end

    local function beginRecording(mode, replaceId, modifier)
        local opts = ensureOpts()
        rec.active       = true
        rec.mode         = mode or "run"
        rec.points       = {}
        rec.replaceId    = replaceId
        rec.lastMoveAt   = GetTime()
        rec.sawModDown   = false
        rec.startedAt    = GetTime()
        rec.modifier     = modifier
        local x, y = cursorPos()
        rec.startX, rec.startY = x, y
        rec.points[1] = { x = 0, y = 0 }
        dbg("REC", "start mode=" .. tostring(rec.mode)
            .. " mod=" .. tostring(rec.modifier or "?")
            .. (replaceId and (" replaceId=" .. tostring(replaceId)) or ""))
    end

    local function endRecording(reason)
        if not rec.active then return end
        rec.active = false
        local pts  = rec.points
        local mode = rec.mode
        local replaceId = rec.replaceId
        local modifier = rec.modifier or "shift"
        rec.mode = nil
        rec.replaceId = nil
        rec.modifier = nil
        rec.sawModDown = false

        dbg("REC", "end reason=" .. tostring(reason) .. " points=" .. #pts)

        if #pts < 2 then
            dbg("REC", "слишком мало точек — выходим")
            return
        end

        local opts = ensureOpts()

        if mode == "record" then
            local prepared = prepare(pts, opts.sampleCount)
            if not prepared then return end
            if replaceId then
                local g = nil
                for _, it in ipairs(ensureDb()) do
                    if it.id == replaceId then g = it; break end
                end
                if g then
                    g.points = prepared
                    g.rawLen = #pts
                    g.modifier = modifier
                    if opts.showText then
                        print("|cffaa66ff[TRAJ]|r перезаписан " .. ((g.name ~= "" and g.name) or g.id)
                            .. " [" .. modLabel(modifier) .. "] (" .. #pts .. " точек)")
                    end
                    if NSQC4.TrajectoryUI then NSQC4.TrajectoryUI:OpenEditor(g.id) end
                    return
                end
            end
            local g = ensureGesture({ name = "", code = "", points = prepared, rawLen = #pts, modifier = modifier })
            table.insert(ensureDb(), g)
            if opts.showText then
                print("|cffaa66ff[TRAJ]|r записан жест " .. g.id
                    .. " [" .. modLabel(modifier) .. "] (" .. #pts .. " точек)")
            end
            if NSQC4.TrajectoryUI then NSQC4.TrajectoryUI:OpenEditor(g.id) end
            return
        end

        local g, dev = recognize(pts, opts, modifier)
        if mode == "test" then
            if g then
                print("|cffaa66ff[TRAJ]|r совпало: " .. ((g.name ~= "" and g.name) or g.id)
                    .. " [" .. modLabel(g.modifier) .. "]  dev=" .. string.format("%.3f", dev))
            else
                print("|cffaa66ff[TRAJ]|r не найдено [" .. modLabel(modifier)
                    .. "] (лучший dev=" .. string.format("%.3f", dev) .. ")")
            end
            return
        end

        -- run
        if g then
            if opts.showText then
                print("|cffaa66ff[TRAJ]|r выполнен: " .. ((g.name ~= "" and g.name) or g.id)
                    .. " [" .. modLabel(g.modifier) .. "]  dev=" .. string.format("%.3f", dev))
            end
            if g.code and g.code ~= "" then
                local fn, err = loadstring(g.code)
                if not fn then
                    print("|cffff0000[TRAJ]|r ошибка компиляции: " .. tostring(err))
                else
                    local ok, rerr = pcall(fn)
                    if not ok then print("|cffff0000[TRAJ]|r ошибка: " .. tostring(rerr)) end
                end
            end
        else
            dbg("RUN", "нет совпадения, лучший dev=" .. string.format("%.3f", dev))
        end
    end

    -- ========================================================================
    -- Дебаунс модификатора + OnUpdate
    -- ========================================================================
    local stableFrames = 0
    local awayFrames   = 0
    local lastStable   = false

    local tracker = CreateFrame("Frame")
    tracker:SetScript("OnUpdate", function()
        local opts = ensureOpts()
        local any = anyDown()

        if any then
            stableFrames = stableFrames + 1
            awayFrames = 0
        else
            awayFrames = awayFrames + 1
            stableFrames = 0
        end

        local stable = (stableFrames >= (opts.shiftStable or 2))
        local away   = (awayFrames   >= (opts.shiftStable or 2))

        -- «Боевой» режим: старт по стабильному нажатию любого модификатора
        if stable and not lastStable then
            lastStable = true
            if opts.recordOnMod and not rec.active then
                local m = currentModifier() or "shift"
                beginRecording("run", nil, m)
            end
        elseif away and lastStable then
            lastStable = false
            if rec.active and rec.mode == "run" then
                endRecording("mod-up")
            end
        end

        if not rec.active then return end

        -- record / test
        if rec.mode == "record" or rec.mode == "test" then
            -- фиксируем модификатор, как только он стабильно нажат
            if stable and not rec.modifier then
                rec.modifier = currentModifier() or "shift"
                rec.sawModDown = true
                dbg("REC", "modifier locked: " .. tostring(rec.modifier))
            end

            if opts.recordOnMod then
                -- завершаем только после того, как модификатор был зажат и потом отпущен
                if rec.sawModDown and away then
                    endRecording("mod-up") return
                end
                -- таймаут, если модификатор так и не нажали
                local now = GetTime()
                if not rec.sawModDown
                   and (now - rec.startedAt) * 1000 >= (opts.recordTimeoutMs or 15000) then
                    endRecording("timeout-no-mod") return
                end
            else
                local now = GetTime()
                if (now - rec.lastMoveAt) * 1000 >= opts.idleTimeoutMs then
                    endRecording("idle") return
                end
            end
        end

        -- Копим точки
        local x, y = cursorPos()
        local nx, ny = x - rec.startX, y - rec.startY
        local last = rec.points[#rec.points]
        if last then
            local dx, dy = nx - last.x, ny - last.y
            if dx*dx + dy*dy >= (opts.minStepPx * opts.minStepPx) then
                rec.points[#rec.points+1] = { x = nx, y = ny }
                rec.lastMoveAt = GetTime()
            end
        end
    end)

    -- ========================================================================
    -- API
    -- ========================================================================
    NSQC4.Trajectory = NSQC4.Trajectory or {}
    local T = NSQC4.Trajectory

    function T:List() return ensureDb() end
    function T:Opts() return ensureOpts() end
    function T:Recognize(raw, modifier) return recognize(raw, ensureOpts(), modifier or "shift") end
    function T:Prepare(raw, n) return prepare(raw, n) end

    function T:Add(name, modifier)
        local g = ensureGesture({ name = name or "", code = "", points = {}, modifier = modifier or "shift" })
        table.insert(ensureDb(), g)
        return g
    end

    function T:Remove(id)
        local list = ensureDb()
        for i = #list, 1, -1 do
            if list[i].id == id then table.remove(list, i); return true end
        end
        return false
    end

    function T:Get(id)
        for _, g in ipairs(ensureDb()) do
            if g.id == id then return g end
        end
        return nil
    end

    function T:StartRecord(replaceId)
        if rec.active then endRecording("force") end
        local m = currentModifier()  -- если что-то уже зажато — берём его
        beginRecording("record", replaceId, m)
        print("|cffaa66ff[TRAJ]|r рисуй жест под Shift/Ctrl/Alt…")
    end

    function T:StartTest()
        if rec.active then endRecording("force") end
        local m = currentModifier()
        beginRecording("test", nil, m)
        print("|cffaa66ff[TRAJ]|r нарисуй жест для проверки под Shift/Ctrl/Alt…")
    end

    function T:Stop()
        if rec.active then
            endRecording("manual")
        else
            print("|cffaa66ff[TRAJ]|r нечего останавливать")
        end
    end

    function T:IsRecording() return rec.active, rec.mode, #rec.points, rec.modifier end

    function T:SetTrace(on)
        TDBG.enabled = on and true or false
        print("|cffaa66ff[TRAJ]|r trace " .. (TDBG.enabled and "ON" or "OFF"))
    end

    function T:GetDebugState()
        return {
            anyDown      = anyDown(),
            currentMod   = currentModifier(),
            stableFrames = stableFrames,
            awayFrames   = awayFrames,
            lastStable   = lastStable,
            active       = rec.active,
            mode         = rec.mode,
            modifier     = rec.modifier,
            pointCount   = #rec.points,
            replaceId    = rec.replaceId,
            sawModDown   = rec.sawModDown,
            templates    = #ensureDb(),
            trace        = TDBG.enabled,
        }
    end

    -- ========================================================================
    -- UI
    -- ========================================================================
    NSQC4.TrajectoryUI = NSQC4.TrajectoryUI or {}
    local UI = NSQC4.TrajectoryUI

    local mainFrame, editorFrame, optionsFrame
    local selectedId

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4TrajectoryFrame", UIParent)
        f:SetSize(560, 500)
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
        title:SetText("Жесты-маршруты (Shift/Ctrl/Alt)")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() f:Hide() end)

        local recBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        recBtn:SetSize(150, 26)
        recBtn:SetPoint("TOPLEFT", 20, -46)
        recBtn:SetText("Записать жест")
        recBtn:SetScript("OnClick", function() NSQC4.Trajectory:StartRecord() end)

        local testBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        testBtn:SetSize(150, 26)
        testBtn:SetPoint("LEFT", recBtn, "RIGHT", 10, 0)
        testBtn:SetText("Проверить жест")
        testBtn:SetScript("OnClick", function() NSQC4.Trajectory:StartTest() end)

        local stopBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        stopBtn:SetSize(70, 26)
        stopBtn:SetPoint("LEFT", testBtn, "RIGHT", 10, 0)
        stopBtn:SetText("Стоп")
        stopBtn:SetScript("OnClick", function() NSQC4.Trajectory:Stop() end)

        local optsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        optsBtn:SetSize(26, 26)
        optsBtn:SetPoint("TOPRIGHT", -36, -46)
        optsBtn:SetText("*")
        optsBtn:SetScript("OnClick", function() UI:OpenOptions() end)
        optsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Настройки распознавания")
            GameTooltip:Show()
        end)
        optsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 20, -82)
        hint:SetText("«Записать» → зажми Shift/Ctrl/Alt → нарисуй → отпусти.")

        local div = f:CreateTexture(nil, "OVERLAY")
        div:SetTexture(0.5, 0.5, 0.5, 0.5)
        div:SetPoint("TOPLEFT", 20, -102)
        div:SetPoint("TOPRIGHT", -20, -102)
        div:SetHeight(1)

        local listTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listTitle:SetPoint("TOPLEFT", 20, -114)
        listTitle:SetText("Шаблоны:")

        local scroll = CreateFrame("ScrollFrame", "NSQC4TrajectoryScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -136)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        local content = CreateFrame("Frame", "NSQC4TrajectoryContent", scroll)
        content:SetSize(480, 1)
        scroll:SetScrollChild(content)
        f.content = content
        f.rows = {}

        function f:Refresh()
            for _, row in ipairs(self.rows) do row:Hide() end
            self.rows = {}
            local list = ensureDb()
            local y = 0
            if #list == 0 then
                local empty = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                empty:SetPoint("TOPLEFT", 8, -8)
                empty:SetText("|cff808080Шаблонов нет. Нажми «Записать жест».|r")
                table.insert(self.rows, empty)
                self.content:SetHeight(40)
                return
            end
            for _, g in ipairs(list) do
                local row = CreateFrame("Button", nil, self.content)
                row:SetSize(480, 30)
                row:SetPoint("TOPLEFT", 0, -y)
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                row:SetBackdropColor(0.15, 0.15, 0.15, 0.6)
                local name = (g.name ~= "" and g.name) or ("(без имени)")
                local mod  = modLabel(g.modifier or "shift")
                local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                left:SetPoint("LEFT", 8, 0)
                left:SetText("|cffFFD100" .. name .. "|r  |cff66aaff[" .. mod .. "]|r")
                local info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                info:SetPoint("RIGHT", -8, 0)
                info:SetText("точек: " .. tostring(#(g.points or {})))
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

    local function CreateEditorFrame()
        if editorFrame then return editorFrame end

        local f = CreateFrame("Frame", "NSQC4TrajectoryEditorFrame", UIParent)
        f:SetSize(560, 460)
        f:SetPoint("CENTER", 140, 0)
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

        local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", 20, -44)
        nameLabel:SetText("Имя:")

        local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        nameBox:SetSize(440, 24)
        nameBox:SetPoint("TOPLEFT", 70, -40)
        nameBox:SetAutoFocus(false)
        nameBox:SetMaxLetters(40)
        f.nameBox = nameBox

        local modLabelFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modLabelFS:SetPoint("TOPLEFT", 20, -76)
        modLabelFS:SetText("Модификатор:")

        local modButtons = {}
        local function mkModBtn(x, mod)
            local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            b:SetSize(90, 24)
            b:SetPoint("TOPLEFT", x, -72)
            b:SetText(modLabel(mod))
            b:SetScript("OnClick", function()
                if not selectedId then return end
                local g = NSQC4.Trajectory:Get(selectedId)
                if not g then return end
                g.modifier = mod
                f:Refresh()
                if mainFrame then mainFrame:Refresh() end
            end)
            modButtons[mod] = b
            return b
        end
        mkModBtn(140, "shift")
        mkModBtn(240, "ctrl")
        mkModBtn(340, "alt")
        f.modButtons = modButtons

        local codeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        codeLabel:SetPoint("TOPLEFT", 20, -108)
        codeLabel:SetText("Код (Lua):")

        local codeBox = CreateFrame("EditBox", nil, f)
        codeBox:SetSize(520, 200)
        codeBox:SetPoint("TOPLEFT", 20, -128)
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

        local reRecBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        reRecBtn:SetSize(150, 26)
        reRecBtn:SetPoint("BOTTOMLEFT", 20, 18)
        reRecBtn:SetText("Перезаписать")
        reRecBtn:SetScript("OnClick", function()
            if not selectedId then return end
            NSQC4.Trajectory:StartRecord(selectedId)
        end)

        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetSize(150, 26)
        saveBtn:SetPoint("BOTTOM", 0, 18)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            if not selectedId then return end
            local g = NSQC4.Trajectory:Get(selectedId)
            if not g then return end
            g.name = f.nameBox:GetText() or ""
            g.code = f.codeBox:GetText() or ""
            if mainFrame then mainFrame:Refresh() end
            f:Hide()
        end)

        local delBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        delBtn:SetSize(150, 26)
        delBtn:SetPoint("BOTTOMRIGHT", -20, 18)
        delBtn:SetText("Удалить")
        delBtn:SetScript("OnClick", function()
            if not selectedId then return end
            NSQC4.Trajectory:Remove(selectedId)
            selectedId = nil
            if mainFrame then mainFrame:Refresh() end
            f:Hide()
        end)

        function f:Refresh()
            if not selectedId then return end
            local g = NSQC4.Trajectory:Get(selectedId)
            if not g then return end
            self.title:SetText("Жест: " .. ((g.name ~= "" and g.name) or g.id))
            self.nameBox:SetText(g.name or "")
            self.codeBox:SetText(g.code or "")
            for mod, b in pairs(self.modButtons) do
                b:SetNormalFontObject((g.modifier or "shift") == mod and GameFontNormalLarge or GameFontNormal)
            end
        end

        editorFrame = f
        return f
    end

    local function CreateOptionsFrame()
        if optionsFrame then return optionsFrame end

        local f = CreateFrame("Frame", "NSQC4TrajectoryOptionsFrame", UIParent)
        f:SetSize(420, 340)
        f:SetPoint("CENTER", 220, 80)
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
        title:SetText("Настройки распознавания")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() f:Hide() end)

        local function mkCheckbox(y, text, key, tip)
            local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 20, y)
            cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            cb.text:SetText(text)
            cb:SetScript("OnClick", function(self)
                ensureOpts()[key] = self:GetChecked() and true or false
            end)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return cb
        end

        f.cbText  = mkCheckbox(-46, "Писать в чат", "showText",
            "Выводить сообщения о записанных/распознанных жестах.")
        f.cbMod   = mkCheckbox(-84, "Требовать модификатор", "recordOnMod",
            "Если включено — запись/проверка ждёт Shift/Ctrl/Alt, завершается по отпусканию. Если выключено — запись идёт без модификатора, завершается по бездействию курсора.")

        local tolLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tolLabel:SetPoint("TOPLEFT", 20, -124)
        tolLabel:SetText("Допуск отклонения:")

        local tolValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tolValue:SetPoint("LEFT", tolLabel, "RIGHT", 8, 0)

        local slider = CreateFrame("Slider", "NSQC4TrajTolSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, -150)
        slider:SetSize(360, 16)
        slider:SetMinMaxValues(0.01, 1.0)
        slider:SetValueStep(0.01)
        _G[slider:GetName() .. "Low"]:SetText("0.01")
        _G[slider:GetName() .. "High"]:SetText("1.0")
        slider:SetScript("OnValueChanged", function(self, v)
            v = math.floor(v * 100 + 0.5) / 100
            if math.abs(self:GetValue() - v) > 1e-4 then
                self:SetValue(v)
                return
            end
            ensureOpts().tolerance = v
            tolValue:SetText(string.format("%.2f", v))
        end)
        f.slider = slider
        f.tolValue = tolValue

        local algoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        algoLabel:SetPoint("TOPLEFT", 20, -196)
        algoLabel:SetText("Алгоритм:")

        local shapeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        shapeBtn:SetSize(150, 24)
        shapeBtn:SetPoint("TOPLEFT", 20, -220)
        shapeBtn:SetText("Shape")
        shapeBtn:SetScript("OnClick", function()
            ensureOpts().algorithm = "shape"
            f:Refresh()
        end)
        f.shapeBtn = shapeBtn

        local strictBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        strictBtn:SetSize(150, 24)
        strictBtn:SetPoint("LEFT", shapeBtn, "RIGHT", 10, 0)
        strictBtn:SetText("Strict")
        strictBtn:SetScript("OnClick", function()
            ensureOpts().algorithm = "strict"
            f:Refresh()
        end)
        f.strictBtn = strictBtn

        function f:Refresh()
            local o = ensureOpts()
            self.cbText:SetChecked(o.showText and true or false)
            self.cbMod:SetChecked(o.recordOnMod and true or false)
            self.slider:SetValue(o.tolerance)
            self.tolValue:SetText(string.format("%.2f", o.tolerance))
            self.shapeBtn:SetNormalFontObject(o.algorithm == "shape" and GameFontNormalLarge or GameFontNormal)
            self.strictBtn:SetNormalFontObject(o.algorithm == "strict" and GameFontNormalLarge or GameFontNormal)
        end

        optionsFrame = f
        return f
    end

    function UI:Open()
        local f = CreateMainFrame()
        f:Show(); f:Raise(); f:Refresh()
    end
    function UI:OpenEditor(id)
        selectedId = id
        local f = CreateEditorFrame()
        f:Show(); f:Raise(); f:Refresh()
    end
    function UI:OpenOptions()
        local f = CreateOptionsFrame()
        f:Refresh(); f:Show(); f:Raise()
    end

    -- ========================================================================
    -- Слэш
    -- ========================================================================
    SLASH_NSTRAJ1 = "/ns_traj"
    SlashCmdList["NSTRAJ"] = function(msg)
        msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if msg == "debug" then
            local s = NSQC4.Trajectory:GetDebugState()
            print("|cffaa66ff[TRAJ]|r anyDown=" .. tostring(s.anyDown)
                .. " currentMod=" .. tostring(s.currentMod)
                .. " stableFrames=" .. tostring(s.stableFrames)
                .. " awayFrames=" .. tostring(s.awayFrames)
                .. " lastStable=" .. tostring(s.lastStable))
            print("  active=" .. tostring(s.active)
                .. " mode=" .. tostring(s.mode)
                .. " modifier=" .. tostring(s.modifier)
                .. " points=" .. tostring(s.pointCount)
                .. " replaceId=" .. tostring(s.replaceId)
                .. " sawModDown=" .. tostring(s.sawModDown)
                .. " templates=" .. tostring(s.templates)
                .. " trace=" .. tostring(s.trace))
            local o = ensureOpts()
            print("  tol=" .. tostring(o.tolerance)
                .. " algo=" .. tostring(o.algorithm)
                .. " samples=" .. tostring(o.sampleCount)
                .. " recordOnMod=" .. tostring(o.recordOnMod)
                .. " shiftStable=" .. tostring(o.shiftStable)
                .. " idleTimeoutMs=" .. tostring(o.idleTimeoutMs)
                .. " recordTimeoutMs=" .. tostring(o.recordTimeoutMs))
            return
        end
        if msg == "trace" then NSQC4.Trajectory:SetTrace(not TDBG.enabled); return end
        if msg == "record" then NSQC4.Trajectory:StartRecord(); return end
        if msg == "test"   then NSQC4.Trajectory:StartTest();   return end
        if msg == "stop"   then NSQC4.Trajectory:Stop();        return end
        UI:Open()
    end

    -- ========================================================================
    -- Кнопка на панели
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton(
            "Т",
            "/ns_traj",
            {
                { text = "Жесты-маршруты",                                  r = 0.66, g = 0.40, b = 1.00 },
                { text = " " },
                { text = "Запись и распознавание маршрута курсора",          r = 0.85, g = 0.85, b = 0.85 },
                { text = "под Shift / Ctrl / Alt.",                          r = 0.85, g = 0.85, b = 0.85 },
                { text = " " },
                { text = "«Записать жест» — создать шаблон.",                r = 0.85, g = 0.85, b = 0.85 },
                { text = "«Проверить жест» — показать отклонение.",          r = 0.85, g = 0.85, b = 0.85 },
                { text = "«Стоп» — принудительно завершить запись.",         r = 0.85, g = 0.85, b = 0.85 },
                { text = " " },
                { text = "Модификатор берётся из первого зажатого",          r = 0.70, g = 0.70, b = 0.70 },
                { text = "при старте записи (Shift > Ctrl > Alt).",          r = 0.70, g = 0.70, b = 0.70 },
            },
            function() UI:Open() end
        )
    end

    NSQC4.SetModuleMeta("trajectory", {
        label   = "Жесты-маршруты (Shift/Ctrl/Alt)",
        tooltip = "Запись и распознавание маршрута курсора под модификатором.",
        order   = 110,
    })

    dbg("INIT", "готов")
end)