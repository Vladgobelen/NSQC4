-- ============================================================================
-- NSQC4 / Core / Settings / Trajectory
-- Жесты-маршруты под ДВУМЯ модификаторами одновременно:
--   Shift+Ctrl, Shift+Alt, Ctrl+Alt.
-- Одиночные (только Shift/Ctrl/Alt) и все три — ИГНОРИРУЮТСЯ.
-- Это убирает конфликт с геймплеем.
--
-- ВАЖНО: старые шаблоны с одиночным модификатором ("shift", "ctrl", "alt")
-- больше не распознаются — их надо удалить и записать заново под комбинацию.
--
-- Отладка по умолчанию ВЫКЛЮЧЕНА и НЕ сохраняется.
--   /ns_traj debug         — статус (всегда)
--   /ns_traj debug on|off  — вкл/выкл отладку на сессию
--
-- prepare() инвертирует Y: вверх = −Y, вниз = +Y (экранная система для шаблона).
-- Оверлей рисует СЫРОЙ маршрут в системе UIParent (Y вверх) — как двигалась мышь.
--
-- Действие жеста (в редакторе, второй раздел, радиокнопки):
--   • Код  — многострочный Lua (loadstring + pcall)
--   • Текст — SendChatMessage в выбранный канал
--
-- Настройки:
--   drawRoute            — рисовать маршрут текстурами
--   hideOverlayInCombat  — не рисовать маршрут в бою (модуль работает)
--   disableInCombat      — не реагировать на модификаторы в бою:
--                          запись/распознавание приостанавливаются,
--                          начатая запись НЕ прерывается, ждёт выхода из боя.
-- ============================================================================

NSQC4 = NSQC4 or {}

NSQC4.RegisterModule("trajectory", function()

    -- ========================================================================
    -- Отладка (по умолчанию ВЫКЛ, не сохраняется, только на сессию)
    -- ========================================================================
    local TDBG = { enabled = false }
    local function dbg(tag, ...)
        if not TDBG.enabled then return end
        local p = { "|cffaa66ff[TRAJ " .. tag .. "]|r" }
        for _, v in ipairs({...}) do p[#p + 1] = tostring(v) end
        print(unpack(p))
    end
    local function say(...)
        if not TDBG.enabled then return end
        print(...)
    end

    -- ========================================================================
    -- Состояние
    -- ========================================================================
    local rec = {
        active         = false,
        mode           = nil,
        points         = {},
        startX         = 0,
        startY         = 0,
        lastMoveAt     = 0,
        replaceId      = nil,
        modifier       = nil,
        started        = false,
        pendingMode    = nil,
        pendingReplace = nil,
        paused         = false,
    }

    local OVERLAY = {
        enabled = true,
        every   = 10,
        maxDots = 96,
        size    = 6,
        dots    = {},
        frame   = nil,
    }

    local stableFrames = 0
    local awayFrames   = 0
    local lastStable   = false

    -- ========================================================================
    -- Модификаторы (делегируем в NSQC4.Modifiers)
    -- ========================================================================
    local function twoDown()
        if NSQC4.Modifiers and NSQC4.Modifiers.TwoOrMoreDown then
            return NSQC4.Modifiers.TwoOrMoreDown()
        end
        return false
    end

    local function currentModifiers()
        if NSQC4.Modifiers and NSQC4.Modifiers.CurrentCombo then
            return NSQC4.Modifiers.CurrentCombo()
        end
        return nil
    end

    local function modLabel(mod)
        if mod == "shift+ctrl" then return "Shift+Ctrl" end
        if mod == "shift+alt"  then return "Shift+Alt"  end
        if mod == "ctrl+alt"   then return "Ctrl+Alt"   end
        if mod == "shift+ctrl+alt" then return "Shift+Ctrl+Alt" end
        return "?"
    end

    local function inCombat()
        return UnitAffectingCombat and UnitAffectingCombat("player") or false
    end

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

    local function normalizeAction(a)
        if a == "text" then return "text" end
        return "code"
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
                tolerance           = 0.25,
                algorithm           = "strict",
                sampleCount         = 32,
                minStepPx           = 0.75,
                recordOnMod         = true,
                shiftStable         = 2,
                idleTimeoutMs       = 400,
                drawRoute           = true,
                hideOverlayInCombat = false,
                disableInCombat     = false,
            }
            nsDbc4.settings.trajectory.opts = o
        end
        if o.tolerance == nil then o.tolerance = 0.25 end
        if o.algorithm == nil then o.algorithm = "strict" end
        if o.sampleCount == nil then o.sampleCount = 32 end
        if o.minStepPx == nil then o.minStepPx = 0.75 end
        if o.recordOnMod == nil then
            if o.recordOnShift ~= nil then o.recordOnMod = o.recordOnShift
            else o.recordOnMod = true end
        end
        o.recordOnShift = o.recordOnMod
        if o.shiftStable == nil then o.shiftStable = 2 end
        if o.idleTimeoutMs == nil then o.idleTimeoutMs = 400 end
        if o.drawRoute == nil then o.drawRoute = true end
        if o.hideOverlayInCombat == nil then o.hideOverlayInCombat = false end
        if o.disableInCombat == nil then o.disableInCombat = false end

        OVERLAY.enabled = o.drawRoute and true or false
        return o
    end

    local function ensureDb()
        nsDbc4 = nsDbc4 or {}
        nsDbc4.settings = nsDbc4.settings or {}
        nsDbc4.settings.trajectory = nsDbc4.settings.trajectory or {}
        nsDbc4.settings.trajectory.list = nsDbc4.settings.trajectory.list or {}
        return nsDbc4.settings.trajectory.list
    end

    local VALID_MODS = {
        ["shift+ctrl"] = true,
        ["shift+alt"]  = true,
        ["ctrl+alt"]   = true,
        ["shift+ctrl+alt"] = true,
    }

    local function ensureGesture(g)
        g.id = g.id or ("t" .. tostring(math.random(100000, 999999)))
        g.name = g.name or ""
        g.code = g.code or ""
        g.points = g.points or {}
        g.rawLen = g.rawLen or 0
        if not VALID_MODS[g.modifier or ""] then
            g.modifier = "shift+ctrl"
        end
        g.action = normalizeAction(g.action)
        g.chat = normalizeChat(g.chat)
        g.text = g.text or ""
        return g
    end

    local function migrateList()
        for _, g in ipairs(ensureDb()) do
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
            g.text = g.text or ""
        end
    end

    -- ========================================================================
    -- Оверлей
    -- ========================================================================
    local function ensureOverlayFrame()
        if OVERLAY.frame then return OVERLAY.frame end
        local f = CreateFrame("Frame", "NSQC4TrajOverlay", UIParent)
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("TOOLTIP")
        f:EnableMouse(false)
        f:Hide()
        OVERLAY.frame = f
        return f
    end

    local function clearOverlay()
        for _, tex in ipairs(OVERLAY.dots) do
            tex:Hide()
        end
        if OVERLAY.frame then OVERLAY.frame:Hide() end
    end

    local function overlayAllowed()
        if not OVERLAY.enabled then return false end
        local o = ensureOpts()
        if o.hideOverlayInCombat and inCombat() then return false end
        if o.disableInCombat and inCombat() then return false end
        return true
    end

    local function overlayDot(idx, relX, relY, r, g, b, a)
        if not overlayAllowed() then return end
        local parent = ensureOverlayFrame()
        local tex = OVERLAY.dots[idx]
        if not tex then
            tex = parent:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            OVERLAY.dots[idx] = tex
        end
        if tex:GetParent() ~= parent then
            tex:SetParent(parent)
        end
        tex:ClearAllPoints()
        tex:SetSize(OVERLAY.size, OVERLAY.size)
        tex:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            rec.startX + relX - OVERLAY.size / 2,
            rec.startY + relY - OVERLAY.size / 2)
        tex:SetVertexColor(r, g, b, a or 1)
        tex:Show()
        parent:Show()
    end

    local function dumpPoints(pts)
        if not TDBG.enabled then return end
        if #pts < 2 then return end
        local shown = {}
        local function emit(i)
            if shown[i] or not pts[i] then return end
            shown[i] = true
            local p = pts[i]
            print(string.format("|cffaa66ff[TRAJ PT]|r i=%d raw=(%.1f,%.1f) flipped=(%.1f,%.1f)",
                i, p.x, p.y, p.x, -p.y))
        end
        for i = 1, math.min(3, #pts) do emit(i) end
        for i = 4, #pts, OVERLAY.every do emit(i) end
        for i = math.max(1, #pts - 2), #pts do emit(i) end
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
        local flipped = {}
        for i, p in ipairs(raw) do
            flipped[i] = { x = p.x, y = -p.y }
        end
        local r = resample(flipped, n)
        return normalize(r)
    end

    local function recognize(rawPoints, opts, modifier)
        opts = opts or ensureOpts()
        local probe = prepare(rawPoints, opts.sampleCount)
        if not probe then return nil, 1 end
        local best, bestDev = nil, math.huge
        for _, g in ipairs(ensureDb()) do
            if g.points and #g.points >= 2 and VALID_MODS[g.modifier or ""] and g.modifier == modifier then
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
    -- Выполнение действия
    -- ========================================================================
    local function runCode(code)
        if not code or code == "" then return end
        local fn, err = loadstring(code)
        if not fn then
            print("|cffff0000[TRAJ]|r ошибка компиляции: " .. tostring(err))
            return
        end
        local ok, runErr = pcall(fn)
        if not ok then
            print("|cffff0000[TRAJ]|r ошибка выполнения: " .. tostring(runErr))
        end
    end

    local function runText(g)
        local text = g.text or ""
        if text == "" then return end
        local target = CHAT_BY_KEY[normalizeChat(g.chat)]
        local chatType = target and target.chatType or nil
        local ok, err = pcall(SendChatMessage, text, chatType)
        if not ok then
            print("|cffff0000[TRAJ]|r ошибка отправки текста: " .. tostring(err))
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
    -- Запись
    -- ========================================================================
    local function cursorPos()
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        return x / s, y / s
    end

    local function beginRecording(mode, replaceId, modifier)
        rec.active     = true
        rec.mode       = mode or "run"
        rec.points     = {}
        rec.replaceId  = replaceId
        rec.lastMoveAt = GetTime()
        rec.modifier   = modifier
        rec.started    = false
        rec.startX, rec.startY = 0, 0
        rec.paused     = false
        clearOverlay()
        dbg("REC", "start mode=" .. tostring(rec.mode)
            .. " mod=" .. tostring(rec.modifier or "?"))
    end

    local function endRecording(reason)
        if not rec.active then return end
        rec.active = false
        local pts = rec.points
        local mode = rec.mode
        local replaceId = rec.replaceId
        local modifier = rec.modifier or "shift+ctrl"
        local wasStarted = rec.started
        rec.mode = nil
        rec.replaceId = nil
        rec.modifier = nil
        rec.started = false
        rec.paused = false

        dbg("REC", "end reason=" .. tostring(reason) .. " points=" .. #pts)

        if not wasStarted or #pts < 2 then
            clearOverlay()
            return
        end

        dumpPoints(pts)

        local opts = ensureOpts()

        if mode == "record" then
            local prepared = prepare(pts, opts.sampleCount)
            if not prepared then clearOverlay() return end
            if replaceId then
                for _, it in ipairs(ensureDb()) do
                    if it.id == replaceId then
                        it.points = prepared
                        it.rawLen = #pts
                        it.modifier = modifier
                        say("|cffaa66ff[TRAJ]|r перезаписан "
                            .. ((it.name ~= "" and it.name) or it.id)
                            .. " [" .. modLabel(modifier) .. "] (" .. #pts .. " точек)")
                        if NSQC4.TrajectoryUI then NSQC4.TrajectoryUI:OpenEditor(it.id) end
                        clearOverlay()
                        return
                    end
                end
            end
            local g = ensureGesture({ name = "", code = "", points = prepared, rawLen = #pts, modifier = modifier })
            table.insert(ensureDb(), g)
            say("|cffaa66ff[TRAJ]|r записан жест " .. g.id
                .. " [" .. modLabel(modifier) .. "] (" .. #pts .. " точек)")
            if NSQC4.TrajectoryUI then NSQC4.TrajectoryUI:OpenEditor(g.id) end
            clearOverlay()
            return
        end

        local g, dev = recognize(pts, opts, modifier)
        if mode == "test" then
            if g then
                say("|cffaa66ff[TRAJ]|r совпало: " .. ((g.name ~= "" and g.name) or g.id)
                    .. " [" .. modLabel(g.modifier) .. "]  dev=" .. string.format("%.3f", dev))
            else
                say("|cffaa66ff[TRAJ]|r не найдено [" .. modLabel(modifier)
                    .. "] (лучший dev=" .. string.format("%.3f", dev) .. ")")
            end
            clearOverlay()
            return
        end

        if g then
            say("|cffaa66ff[TRAJ]|r выполнен: " .. ((g.name ~= "" and g.name) or g.id)
                .. " [" .. modLabel(g.modifier) .. "]  dev=" .. string.format("%.3f", dev))
            runGestureAction(g)
        end

        clearOverlay()
    end

    -- ========================================================================
    -- OnUpdate
    -- ========================================================================
    local tracker = CreateFrame("Frame")
    tracker:SetScript("OnUpdate", function()
        local opts = ensureOpts()

        -- «Отключать в бою»: не реагируем на модификаторы, но НЕ прерываем начатую запись.
        if opts.disableInCombat and inCombat() then
            if rec.active and not rec.paused then
                rec.paused = true
                clearOverlay()
                dbg("REC", "paused (combat)")
            end
            if not rec.active then
                stableFrames = 0
                awayFrames   = 0
                lastStable   = false
            end
            return
        end

        if rec.paused then
            rec.paused = false
            dbg("REC", "resumed (out of combat)")
            if rec.active and rec.started then
                local x, y = cursorPos()
                rec.startX, rec.startY = x, y
                rec.lastMoveAt = GetTime()
            end
        end

        local two = twoDown()

        if two then
            stableFrames = stableFrames + 1
            awayFrames = 0
        else
            awayFrames = awayFrames + 1
            stableFrames = 0
        end

        local stable = (stableFrames >= (opts.shiftStable or 2))
        local away   = (awayFrames   >= (opts.shiftStable or 2))

        if away and lastStable then
            lastStable = false
            if rec.active then
                endRecording("mod-up")
            end
            return
        end

        if not stable then
            return
        end

        if not lastStable then
            lastStable = true
            if opts.recordOnMod and not rec.active then
                local m = currentModifiers() or "shift+ctrl"
                local mode = rec.pendingMode or "run"
                local replaceId = rec.pendingReplace
                rec.pendingMode = nil
                rec.pendingReplace = nil
                beginRecording(mode, replaceId, m)
            end
        end

        if not rec.active then return end

        if not rec.modifier then
            rec.modifier = currentModifiers() or "shift+ctrl"
        end

        local x, y = cursorPos()

        if not rec.started then
            if rec.startX == 0 and rec.startY == 0 then
                rec.startX, rec.startY = x, y
                dbg("REC", "anchor set")
                return
            end
            local dx0, dy0 = x - rec.startX, y - rec.startY
            if dx0*dx0 + dy0*dy0 >= (opts.minStepPx * opts.minStepPx) then
                rec.started = true
                rec.points = { { x = 0, y = 0 } }
                rec.lastMoveAt = GetTime()
                overlayDot(1, 0, 0, 0, 1, 0, 1)
                dbg("REC", "first move")
            end
            return
        end

        local nx, ny = x - rec.startX, y - rec.startY
        local last = rec.points[#rec.points]
        if last then
            local dx, dy = nx - last.x, ny - last.y
            if dx*dx + dy*dy >= (opts.minStepPx * opts.minStepPx) then
                rec.points[#rec.points+1] = { x = nx, y = ny }
                rec.lastMoveAt = GetTime()
                if #rec.points <= OVERLAY.maxDots then
                    local idx = #rec.points
                    local r, g, b = 1, 0.82, 0
                    if idx == 2 then r, g, b = 0.5, 1, 0.5 end
                    overlayDot(idx, nx, ny, r, g, b, 1)
                end
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
    function T:Recognize(raw, modifier) return recognize(raw, ensureOpts(), modifier or "shift+ctrl") end
    function T:Prepare(raw, n) return prepare(raw, n) end
    function T:ChatTargets() return CHAT_TARGETS end

    function T:Add(name, modifier)
        if not VALID_MODS[modifier or ""] then modifier = "shift+ctrl" end
        local g = ensureGesture({
            name = name or "",
            code = "",
            points = {},
            modifier = modifier,
            action = "code",
            chat = "say",
            text = "",
        })
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
            if g.id == id then
                g.action = normalizeAction(g.action)
                g.chat = normalizeChat(g.chat)
                g.text = g.text or ""
                return g
            end
        end
        return nil
    end

    function T:StartRecord(replaceId)
        if rec.active then endRecording("force") end
        rec.pendingMode = "record"
        rec.pendingReplace = replaceId
        say("|cffaa66ff[TRAJ]|r зажми ДВА модификатора (Shift+Ctrl / Shift+Alt / Ctrl+Alt) и рисуй…")
    end

    function T:StartTest()
        if rec.active then endRecording("force") end
        rec.pendingMode = "test"
        rec.pendingReplace = nil
        say("|cffaa66ff[TRAJ]|r зажми ДВА модификатора и нарисуй для проверки…")
    end

    function T:Stop()
        if rec.active then
            endRecording("manual")
        else
            rec.pendingMode = nil
            rec.pendingReplace = nil
            say("|cffaa66ff[TRAJ]|r нечего останавливать")
        end
    end

    function T:IsRecording() return rec.active, rec.mode, #rec.points, rec.modifier, rec.paused end

    function T:SetTrace(on)
        TDBG.enabled = on and true or false
        print("|cffaa66ff[TRAJ]|r debug " .. (TDBG.enabled and "ON (до перезахода)" or "OFF"))
    end

    function T:GetDebugState()
        return {
            twoDown      = twoDown(),
            currentMods  = currentModifiers(),
            stableFrames = stableFrames,
            awayFrames   = awayFrames,
            lastStable   = lastStable,
            active       = rec.active,
            mode         = rec.mode,
            modifier     = rec.modifier,
            pointCount   = #rec.points,
            started      = rec.started,
            pendingMode  = rec.pendingMode,
            paused       = rec.paused,
            templates    = #ensureDb(),
            trace        = TDBG.enabled,
            overlay      = OVERLAY.enabled,
            overlayEvery = OVERLAY.every,
            inCombat     = inCombat(),
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
        title:SetText("Жесты-маршруты (2 модификатора)")

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
        hint:SetText("«Записать» → зажми ДВА модификатора (Shift+Ctrl / Shift+Alt / Ctrl+Alt) → нарисуй → отпусти.")

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
            migrateList()
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
                local mod  = modLabel(g.modifier or "shift+ctrl")
                local actionLabel = (normalizeAction(g.action) == "text") and "текст" or "код"
                local left = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                left:SetPoint("LEFT", 8, 0)
                left:SetText("|cffFFD100" .. name .. "|r  |cff66aaff[" .. mod .. "]|r |cff66ccff<" .. actionLabel .. ">|r")
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
        f:SetSize(560, 720)
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
        modLabelFS:SetText("Модификаторы:")

        local modButtons = {}
        local function mkModBtn(x, mod)
            local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            b:SetSize(120, 24)
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
        mkModBtn(130, "shift+ctrl")
        mkModBtn(260, "shift+alt")
        mkModBtn(390, "ctrl+alt")
        f.modButtons = modButtons

        -- --------------------------------------------------------------------
        -- Второй раздел: действие (радиокнопки Код / Текст)
        -- --------------------------------------------------------------------
        local actionTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        actionTitle:SetPoint("TOPLEFT", 20, -108)
        actionTitle:SetText("Действие жеста:")

        local rbCode = CreateFrame("CheckButton", nil, f, "UIRadioButtonTemplate")
        rbCode:SetPoint("TOPLEFT", 20, -128)
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
        codePanel:SetPoint("TOPLEFT", 20, -160)
        codePanel:SetSize(520, 210)
        f.codePanel = codePanel

        local codeLabel = codePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        codeLabel:SetPoint("TOPLEFT", 0, 0)
        codeLabel:SetText("Код (Lua):")

        local codeBox = CreateFrame("EditBox", nil, codePanel)
        codeBox:SetSize(520, 185)
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
        textPanel:SetPoint("TOPLEFT", 20, -160)
        textPanel:SetSize(520, 210)
        f.textPanel = textPanel

        local chatLabel = textPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chatLabel:SetPoint("TOPLEFT", 0, 0)
        chatLabel:SetText("Канал:")

        local chatBtn = CreateFrame("Button", nil, textPanel, "UIPanelButtonTemplate")
        chatBtn:SetSize(130, 24)
        chatBtn:SetPoint("LEFT", chatLabel, "RIGHT", 8, 0)
        f.chatBtn = chatBtn

        local function currentChatKey()
            local g = selectedId and NSQC4.Trajectory:Get(selectedId)
            return g and normalizeChat(g.chat) or "say"
        end
        local function updateChatBtn()
            local t = CHAT_BY_KEY[currentChatKey()]
            chatBtn:SetText(t and t.label or "?")
        end
        chatBtn:SetScript("OnClick", function()
            if not selectedId then return end
            local g = NSQC4.Trajectory:Get(selectedId)
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
        textBox:SetSize(520, 155)
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

            local g = selectedId and NSQC4.Trajectory:Get(selectedId)
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
                local g = selectedId and NSQC4.Trajectory:Get(selectedId)
                self:SetChecked(g and normalizeAction(g.action) == "code" or false)
                return
            end
            if not selectedId then return end
            local g = NSQC4.Trajectory:Get(selectedId)
            if not g then return end
            g.action = "code"
            updateActionPanels()
            if mainFrame then mainFrame:Refresh() end
        end)
        rbText:SetScript("OnClick", function(self)
            if updatingAction then
                local g = selectedId and NSQC4.Trajectory:Get(selectedId)
                self:SetChecked(g and normalizeAction(g.action) == "text" or false)
                return
            end
            if not selectedId then return end
            local g = NSQC4.Trajectory:Get(selectedId)
            if not g then return end
            g.action = "text"
            updateActionPanels()
            if mainFrame then mainFrame:Refresh() end
        end)

        -- Кнопки внизу
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
            g.text = f.textBox:GetText() or ""
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
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
            self.textBox:SetText(g.text or "")
            for mod, b in pairs(self.modButtons) do
                b:SetNormalFontObject((g.modifier or "shift+ctrl") == mod and GameFontNormalLarge or GameFontNormal)
            end
            self.updateActionPanels()
        end

        editorFrame = f
        return f
    end

    local function CreateOptionsFrame()
        if optionsFrame then return optionsFrame end

        local f = CreateFrame("Frame", "NSQC4TrajectoryOptionsFrame", UIParent)
        f:SetSize(420, 400)
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
                OVERLAY.enabled = ensureOpts().drawRoute and true or false
                if not OVERLAY.enabled then clearOverlay() end
            end)
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            return cb
        end

        f.cbMod     = mkCheckbox(-46,  "Требовать модификатор", "recordOnMod",
            "Включено: запись только под ДВУМЯ модификаторами. Выключено: запись идёт без модификатора.")
        f.cbRoute   = mkCheckbox(-84,  "Рисовать маршрут", "drawRoute",
            "Пока зажат модификатор — рисовать маршрут текстурами. При отпускании всё очищается.")
        f.cbHideCom = mkCheckbox(-122, "Не отображать маршрут в бою", "hideOverlayInCombat",
            "Модуль продолжает работать в бою, но текстуры маршрута не рисуются.")
        f.cbDisCom  = mkCheckbox(-160, "Отключать в бою", "disableInCombat",
            "В бою модуль не реагирует на модификаторы: запись/распознавание приостанавливаются. Начатая запись не прерывается, а ждёт выхода из боя.")

        local tolLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tolLabel:SetPoint("TOPLEFT", 20, -200)
        tolLabel:SetText("Допуск отклонения:")

        local tolValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tolValue:SetPoint("LEFT", tolLabel, "RIGHT", 8, 0)

        local slider = CreateFrame("Slider", "NSQC4TrajTolSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, -226)
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
        algoLabel:SetPoint("TOPLEFT", 20, -272)
        algoLabel:SetText("Алгоритм:")

        local shapeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        shapeBtn:SetSize(150, 24)
        shapeBtn:SetPoint("TOPLEFT", 20, -296)
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
            self.cbMod:SetChecked(o.recordOnMod and true or false)
            self.cbRoute:SetChecked(o.drawRoute and true or false)
            self.cbHideCom:SetChecked(o.hideOverlayInCombat and true or false)
            self.cbDisCom:SetChecked(o.disableInCombat and true or false)
            self.slider:SetValue(o.tolerance)
            self.tolValue:SetText(string.format("%.2f", o.tolerance))
            self.shapeBtn:SetNormalFontObject(o.algorithm == "shape" and GameFontNormalLarge or GameFontNormal)
            self.strictBtn:SetNormalFontObject(o.algorithm == "strict" and GameFontNormalLarge or GameFontNormal)
        end

        optionsFrame = f
        return f
    end

    function UI:Open()
        migrateList()
        local f = CreateMainFrame()
        f:Show(); f:Raise(); f:Refresh()
    end
    function UI:OpenEditor(id)
        selectedId = id
        local g = NSQC4.Trajectory:Get(id)
        if g then
            g.action = normalizeAction(g.action)
            g.chat = normalizeChat(g.chat)
            g.text = g.text or ""
        end
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
            print("|cffaa66ff[TRAJ]|r debug=" .. tostring(TDBG.enabled)
                .. " twoDown=" .. tostring(s.twoDown)
                .. " currentMods=" .. tostring(s.currentMods)
                .. " stableFrames=" .. tostring(s.stableFrames)
                .. " awayFrames=" .. tostring(s.awayFrames)
                .. " lastStable=" .. tostring(s.lastStable))
            print("  active=" .. tostring(s.active)
                .. " mode=" .. tostring(s.mode)
                .. " modifier=" .. tostring(s.modifier)
                .. " started=" .. tostring(s.started)
                .. " points=" .. tostring(s.pointCount)
                .. " pendingMode=" .. tostring(s.pendingMode)
                .. " paused=" .. tostring(s.paused)
                .. " templates=" .. tostring(s.templates)
                .. " overlay=" .. tostring(s.overlay)
                .. " every=" .. tostring(s.overlayEvery)
                .. " inCombat=" .. tostring(s.inCombat))
            local o = ensureOpts()
            print("  tol=" .. tostring(o.tolerance)
                .. " algo=" .. tostring(o.algorithm)
                .. " samples=" .. tostring(o.sampleCount)
                .. " recordOnMod=" .. tostring(o.recordOnMod)
                .. " drawRoute=" .. tostring(o.drawRoute)
                .. " hideOverlayInCombat=" .. tostring(o.hideOverlayInCombat)
                .. " disableInCombat=" .. tostring(o.disableInCombat)
                .. " shiftStable=" .. tostring(o.shiftStable)
                .. " idleTimeoutMs=" .. tostring(o.idleTimeoutMs))
            return
        end

        if msg == "debug on" then
            TDBG.enabled = true
            print("|cffaa66ff[TRAJ]|r debug ON (до перезахода)")
            return
        end
        if msg == "debug off" then
            TDBG.enabled = false
            print("|cffaa66ff[TRAJ]|r debug OFF")
            return
        end

        if msg == "overlay on"  then
            ensureOpts().drawRoute = true
            OVERLAY.enabled = true
            print("|cffaa66ff[TRAJ]|r overlay ON")
            if optionsFrame then optionsFrame:Refresh() end
            return
        end
        if msg == "overlay off" then
            ensureOpts().drawRoute = false
            OVERLAY.enabled = false
            clearOverlay()
            print("|cffaa66ff[TRAJ]|r overlay OFF")
            if optionsFrame then optionsFrame:Refresh() end
            return
        end
        if msg:match("^points %d+$") then
            local n = tonumber(msg:match("^points (%d+)$")) or 10
            OVERLAY.every = math.max(1, n)
            print("|cffaa66ff[TRAJ]|r points every " .. OVERLAY.every)
            return
        end
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
            "Г",
            "/ns_traj",
            {
                { text = "Жесты-маршруты (2 модификатора)",                  r = 0.66, g = 0.40, b = 1.00 },
                { text = " " },
                { text = "Запись и распознавание маршрута курсора",          r = 0.85, g = 0.85, b = 0.85 },
                { text = "под Shift+Ctrl / Shift+Alt / Ctrl+Alt.",          r = 0.85, g = 0.85, b = 0.85 },
                { text = " " },
                { text = "«Записать жест» — создать шаблон.",                r = 0.85, g = 0.85, b = 0.85 },
                { text = "«Проверить жест» — показать отклонение.",          r = 0.85, g = 0.85, b = 0.85 },
                { text = "«Стоп» — принудительно завершить запись.",         r = 0.85, g = 0.85, b = 0.85 },
                { text = " " },
                { text = "Действие: код Lua или текст в чат.",               r = 0.85, g = 0.85, b = 0.85 },
                { text = " " },
                { text = "/ns_traj debug on|off — отладка на сессию",        r = 0.70, g = 0.70, b = 0.70 },
                { text = "/ns_traj overlay on|off — маршрут текстурами",     r = 0.70, g = 0.70, b = 0.70 },
            },
            function() UI:Open() end
        )
    end

    NSQC4.SetModuleMeta("trajectory", {
        label   = "Жесты-маршруты (2 модификатора)",
        tooltip = "Запись и распознавание маршрута курсора под двумя модификаторами.",
        order   = 110,
    })

    dbg("INIT", "готов")
end)