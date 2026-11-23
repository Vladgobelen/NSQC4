-- ============================================================================
-- NSQC4 / Interface / ui_frames / Move
-- Перемещение фреймов. Модуль "ui_frames_move".
-- Клиент: WoW 3.3.5a (12340). Без C_Timer и retail-API.
-- Сохранение/восстановление: GetPoint(1) -> SetPoint, без вычислений.
-- ============================================================================
SLASH_NS_FCMOVE1 = "/ns_fcmove"
SLASH_NS_FCMOVE2 = "/nsfcm"
SlashCmdList["NS_FCMOVE"] = function(msg)
    if not NSQC4 or not NSQC4._FramesMoveDispatch then
        print("|cFFFFFF00NSQC4:|r модуль перемещения ещё не инициализирован.")
        return
    end
    NSQC4._FramesMoveDispatch(msg or "")
end

NSQC4.RegisterModule("ui_frames_move", function()
    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    if type(nsDbc4) ~= "table" then nsDbc4 = {} end
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.framesMove = nsDbc4.settings.framesMove or {}
    local globalMove = nsDbc4.settings.framesMove
    globalMove.chars = globalMove.chars or {}
    local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
    globalMove.chars[charKey] = globalMove.chars[charKey] or {}
    local db = globalMove.chars[charKey]
    db.frames = db.frames or {}
    db.captureDelay = tonumber(db.captureDelay) or 5
    if db.reapplyOnShow == nil then db.reapplyOnShow = true end

    local debugEnabled = false
    local LOG_PREFIX = "|cFF66CCFF[FCMOVE]|r "

    local function L(fmt, ...)
        if not debugEnabled then return end
        if select("#", ...) > 0 then
            print(LOG_PREFIX .. string.format(fmt, ...))
        else
            print(LOG_PREFIX .. tostring(fmt))
        end
    end

    local function Msg(text) print("|cFF00FF00NSQC4:|r " .. text) end
    local function Warn(text) print("|cFFFFFF00NSQC4:|r " .. text) end

    -- ========================================================================
    -- Фиксация дефолтной привязки (до любых наших SetPoint)
    -- ========================================================================
    local function EnsureDefault(frameName)
        local frame = _G[frameName]
        if not frame then return end
        local data = db.frames[frameName]
        if not data then
            data = {}
            db.frames[frameName] = data
        end
        if data.defaultPoint then return end
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
        if not point then return end
        relativeTo = relativeTo or UIParent
        local relName = (relativeTo.GetName and relativeTo:GetName()) or nil
        data.defaultPoint         = point
        data.defaultRelativeTo    = relName
        data.defaultRelativePoint = relativePoint
        data.defaultX             = x
        data.defaultY             = y
        L("дефолт зафиксирован для %s: %s -> %s.%s ofs(%.1f, %.1f)",
            frameName, tostring(point), tostring(relName or "UIParent"),
            tostring(relativePoint), x or 0, y or 0)
    end

    -- Фиксируем дефолт у всех известных фреймов, которые сейчас в игре
    local function EnsureAllDefaults()
        for key in pairs(db.frames) do
            EnsureDefault(key)
        end
    end

    -- ========================================================================
    -- Сохранение / применение (без вычислений)
    -- ========================================================================
    function NSQC4.MoveSave(frameName)
        if not frameName or frameName == "" then
            print("|cFFFF0000[FCMOVE]|r укажи имя фрейма")
            return false
        end
        local frame = _G[frameName]
        if not frame then
            print("|cFFFF0000[FCMOVE]|r фрейм '" .. frameName .. "' не найден")
            return false
        end

        -- Дефолт фиксируем ДО того, как что-либо меняем.
        EnsureDefault(frameName)

        local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
        if not point then
            print("|cFFFF0000[FCMOVE]|r у фрейма нет точки привязки")
            return false
        end
        relativeTo = relativeTo or UIParent
        local relName = (relativeTo.GetName and relativeTo:GetName()) or nil

        local data = db.frames[frameName]
        data.point         = point
        data.relativeTo    = relName
        data.relativePoint = relativePoint
        data.x             = x
        data.y             = y

        print("|cFF00FF00[FCMOVE]|r сохранено " .. frameName ..
              ": " .. tostring(point) ..
              " -> " .. tostring(relName or "UIParent") .. ":" .. tostring(relativePoint) ..
              " (" .. tostring(x) .. ", " .. tostring(y) .. ")")
        return true
    end

    function NSQC4.MoveApply(frameName)
        if not frameName or frameName == "" then
            print("|cFFFF0000[FCMOVE]|r укажи имя фрейма")
            return false
        end
        local frame = _G[frameName]
        if not frame then
            print("|cFFFF0000[FCMOVE]|r фрейм '" .. frameName .. "' не найден")
            return false
        end

        -- До применения сохранёнки фиксируем дефолт, если его ещё нет.
        EnsureDefault(frameName)

        local saved = db.frames and db.frames[frameName]
        if not saved or not saved.point then
            print("|cFFFF0000[FCMOVE]|r нет данных для '" .. frameName .. "'")
            return false
        end

        local rel = (saved.relativeTo and _G[saved.relativeTo]) or UIParent

        frame:ClearAllPoints()
        frame:SetPoint(saved.point, rel, saved.relativePoint, saved.x, saved.y)

        print("|cFF00FF00[FCMOVE]|r применено " .. frameName ..
              ": " .. tostring(saved.point) ..
              " -> " .. tostring(saved.relativeTo or "UIParent") .. ":" .. tostring(saved.relativePoint) ..
              " (" .. tostring(saved.x) .. ", " .. tostring(saved.y) .. ")")
        return true
    end

    -- Применить дефолтную привязку к фрейму (той же SetPoint-операцией).
    local function ApplyDefaultByKey(frameName)
        local frame = _G[frameName]
        local data = db.frames and db.frames[frameName]
        if not frame or not data or not data.defaultPoint then return false end
        local rel = (data.defaultRelativeTo and _G[data.defaultRelativeTo]) or UIParent
        frame:ClearAllPoints()
        frame:SetPoint(data.defaultPoint, rel, data.defaultRelativePoint, data.defaultX, data.defaultY)
        return true
    end

    -- ========================================================================
    -- Планировщик
    -- ========================================================================
    local scheduler = CreateFrame("Frame")
    local queue = {}
    local schedulerRunning = false

    local function SchedulerOnUpdate(self, elapsed)
        local i = 1
        while i <= #queue do
            local item = queue[i]
            item.left = item.left - elapsed
            if item.left <= 0 then
                table.remove(queue, i)
                item.func()
            else
                i = i + 1
            end
        end
        if #queue == 0 then
            schedulerRunning = false
            self:SetScript("OnUpdate", nil)
        end
    end

    local function After(delay, func)
        if type(func) ~= "function" then return end
        queue[#queue + 1] = { left = tonumber(delay) or 0, func = func }
        if not schedulerRunning then
            schedulerRunning = true
            scheduler:SetScript("OnUpdate", SchedulerOnUpdate)
        end
    end

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local own = {}
    local mainFrame, settingsFrame
    local moveOverlay, moveTarget, moveKey, moveWasMovable, moveWasMouse
    local RefreshList, StartMoveForFrame, StopMoveMode

    local function NameOf(obj)
        if not obj then return "nil" end
        if obj.GetName then
            local n = obj:GetName()
            if n and n ~= "" then return n end
        end
        return "<без имени>"
    end

    local function NormalizeToFrame(region)
        local guard = 0
        while type(region) == "table" and guard < 32 do
            if region == UIParent or region == WorldFrame then return nil end
            if region.IsObjectType and region:IsObjectType("Frame") then return region end
            region = region.GetParent and region:GetParent() or nil
            guard = guard + 1
        end
        return nil
    end

    local function IsOwnFrame(obj)
        local guard = 0
        while type(obj) == "table" and guard < 32 do
            if own[obj] then return true end
            obj = obj.GetParent and obj:GetParent() or nil
            guard = guard + 1
        end
        return false
    end

    local function GetObjectKey(frame)
        if frame and frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        return nil
    end

    local function GetFrameByKey(key)
        if not key then return nil end
        return NormalizeToFrame(_G[key])
    end

    local function GetMouseFrame()
        local frame = NormalizeToFrame(GetMouseFocus and GetMouseFocus() or nil)
        if not frame or IsOwnFrame(frame) then return nil end
        return frame
    end

    local function SortedKeys()
        local keys = {}
        for k in pairs(db.frames) do keys[#keys + 1] = k end
        table.sort(keys)
        return keys
    end

    -- ========================================================================
    -- Геометрия: только для отладочного вывода
    -- ========================================================================
    local function CaptureGeometry(frame)
        if not frame then return nil end
        local left = frame:GetLeft()
        local bottom = frame:GetBottom()
        if not left or not bottom then return nil end
        return {
            x = left,
            y = bottom,
            width = frame:GetWidth(),
            height = frame:GetHeight(),
            scale = frame:GetScale(),
        }
    end

    local function FormatGeometry(g)
        if not g then return "нет данных" end
        return string.format("pos(%.1f, %.1f) size=%.0fx%.0f scale=%.2f",
            g.x or 0, g.y or 0, g.width or 0, g.height or 0, g.scale or 1)
    end

    local function FormatSaved(s)
        if not s or not s.point then return "нет данных" end
        return string.format("%s -> %s.%s ofs(%.1f, %.1f)",
            tostring(s.point), tostring(s.relativeTo or "UIParent"),
            tostring(s.relativePoint), s.x or 0, s.y or 0)
    end

    local function FormatDefault(s)
        if not s or not s.defaultPoint then return "нет данных" end
        return string.format("%s -> %s.%s ofs(%.1f, %.1f)",
            tostring(s.defaultPoint), tostring(s.defaultRelativeTo or "UIParent"),
            tostring(s.defaultRelativePoint), s.defaultX or 0, s.defaultY or 0)
    end

    -- ========================================================================
    -- Применение / ожидание / возврат при показе
    -- ========================================================================
    local pending = {}
    local hooked = {}

    local function HookOnShow(frame, key)
        if not frame or hooked[frame] or not frame.HookScript then return end
        hooked[frame] = true
        frame:HookScript("OnShow", function(self)
            if not db.reapplyOnShow then return end
            if self == moveTarget then return end
            local data = db.frames[key]
            if not data or not data.point then return end
            NSQC4.MoveApply(key)
        end)
    end

    local function ApplyPositionByKey(key)
        local data = db.frames[key]
        if not data or not data.point then return true end
        if moveKey and key == moveKey then return true end
        local frame = GetFrameByKey(key)
        if not frame then return false end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            L("бой: отложено применение %s", NameOf(frame))
            return false
        end
        local ok = NSQC4.MoveApply(key)
        if ok then HookOnShow(frame, key) end
        return ok
    end

    local function ApplyAllSaved()
        for k in pairs(pending) do pending[k] = nil end
        local left = 0
        for key in pairs(db.frames) do
            if not ApplyPositionByKey(key) then
                pending[key] = true
                left = left + 1
            end
        end
        L("применение: осталось %d", left)
        return left
    end

    local function RetryPending()
        local left = 0
        for key in pairs(pending) do
            if ApplyPositionByKey(key) then
                pending[key] = nil
            else
                left = left + 1
            end
        end
        return left
    end

    local restoreWaves = { 0.5, 2, 5, 10, 20, 30 }
    local function ScheduleRestore()
        EnsureAllDefaults()
        ApplyAllSaved()
        for _, delay in ipairs(restoreWaves) do
            After(delay, function()
                EnsureAllDefaults()
                RetryPending()
            end)
        end
    end

    -- ========================================================================
    -- Сохранение / сброс
    -- ========================================================================
    local function SaveCurrentPosition(frame, key)
        if not frame or not key then return false end
        if not NSQC4.MoveSave(key) then
            Warn("не удалось сохранить " .. key)
            return false
        end
        HookOnShow(frame, key)
        if RefreshList then RefreshList() end
        return true
    end

    -- Сброс одного фрейма: применить дефолт и удалить запись целиком.
    local function ResetFrameByKey(key)
        local restored = ApplyDefaultByKey(key)
        db.frames[key] = nil
        pending[key] = nil
        if RefreshList then RefreshList() end
        if restored then
            Msg("сброшено: " .. key)
        else
            Msg("удалено из списка: " .. key)
        end
    end

    -- Сброс всего: применить дефолты ко всем и очистить список.
    local function ResetAll()
        local keys = SortedKeys()
        local restored = 0
        for _, key in ipairs(keys) do
            if ApplyDefaultByKey(key) then restored = restored + 1 end
        end
        for k in pairs(db.frames) do db.frames[k] = nil end
        for k in pairs(pending) do pending[k] = nil end
        if RefreshList then RefreshList() end
        Msg("сброшено фреймов: " .. restored .. " из " .. #keys .. ", список очищен")
    end

    -- ========================================================================
    -- ОТЛАДКА
    -- ========================================================================
    local function ReportAll()
        local keys = SortedKeys()
        print(LOG_PREFIX .. "===== ОТЧЁТ: " .. #keys .. " фреймов =====")
        print(LOG_PREFIX .. string.format("экран %.0fx%.0f, UIParent scale %.3f",
            GetScreenWidth() or 0, GetScreenHeight() or 0, UIParent:GetEffectiveScale() or 0))
        print(LOG_PREFIX .. string.format("задержка %d c, возврат при показе: %s, лог: %s",
            db.captureDelay or 5, tostring(db.reapplyOnShow), tostring(debugEnabled)))
        for _, key in ipairs(keys) do
            local frame = GetFrameByKey(key)
            local data = db.frames[key]
            print(LOG_PREFIX .. "|cFFFFFFFF" .. key .. "|r" .. (frame and "" or " |cFFFF6060(нет в игре)|r"))
            if frame then
                local cur = CaptureGeometry(frame)
                local numPts = frame.GetNumPoints and frame:GetNumPoints() or 0
                local pt, rt, rp, xo, yo = numPts > 0 and frame:GetPoint(1) or nil
                print(LOG_PREFIX .. "  сейчас:    " .. FormatGeometry(cur))
                print(LOG_PREFIX .. string.format("  привязка: %d точек, %s -> %s.%s ofs(%.1f, %.1f)",
                    numPts, tostring(pt), NameOf(rt), tostring(rp), xo or 0, yo or 0))
                print(LOG_PREFIX .. string.format("  eff=%.2f", frame:GetEffectiveScale() or 0))
            end
            print(LOG_PREFIX .. "  сохранено: " .. FormatSaved(data))
            print(LOG_PREFIX .. "  исходное:  " .. FormatDefault(data))
        end
        local left = 0
        for _ in pairs(pending) do left = left + 1 end
        print(LOG_PREFIX .. "не применено: " .. left)
        print(LOG_PREFIX .. "===== КОНЕЦ =====")
    end

    -- ========================================================================
    -- Режим перемещения
    -- ========================================================================
    StopMoveMode = function(quiet)
        if moveOverlay then
            moveOverlay:Hide()
            moveOverlay:EnableMouse(false)
        end
        if moveTarget then
            moveTarget:StopMovingOrSizing()
            if moveWasMovable ~= nil then moveTarget:SetMovable(moveWasMovable) end
            if moveWasMouse ~= nil then moveTarget:EnableMouse(moveWasMouse) end
        end
        moveTarget, moveKey, moveWasMovable, moveWasMouse = nil, nil, nil, nil
        if not quiet then Msg("режим перемещения выключен.") end
    end

    local function CancelMove()
        local target, key = moveTarget, moveKey
        if target then
            target:StopMovingOrSizing()
            if key and db.frames[key] and db.frames[key].point then
                NSQC4.MoveApply(key)
            else
                ApplyDefaultByKey(key)
            end
        end
        StopMoveMode(true)
        if RefreshList then RefreshList() end
        Msg("перемещение отменено.")
    end

    local function GetMoveOverlay()
        if moveOverlay then return moveOverlay end
        local ov = CreateFrame("Frame", "NSQC4MoveOverlay", UIParent)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(10)
        ov:Hide()
        local hl = ov:CreateTexture(nil, "OVERLAY")
        hl:SetAllPoints(ov)
        hl:SetTexture(0.2, 1, 0.2, 0.25)
        local label = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", ov, "CENTER", 0, 0)
        ov.label = label
        ov:SetScript("OnMouseDown", function(_, button)
            if not moveTarget then return end
            if button == "LeftButton" then
                if InCombatLockdown() and moveTarget.IsProtected and moveTarget:IsProtected() then
                    Warn("защищённый фрейм, в бою двигать нельзя.")
                    return
                end
                moveTarget:StartMoving()
            elseif button == "RightButton" then
                CancelMove()
            end
        end)
        ov:SetScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton" or not moveTarget then return end
            moveTarget:StopMovingOrSizing()
            local name = moveKey
            if SaveCurrentPosition(moveTarget, name) then
                Msg("сохранено: " .. name)
            end
            StopMoveMode(true)
        end)
        own[ov] = true
        moveOverlay = ov
        return ov
    end

    StartMoveForFrame = function(frame)
        frame = NormalizeToFrame(frame)
        if not frame then
            Warn("фрейм не найден.")
            return
        end
        if IsOwnFrame(frame) then
            Warn("окна самого NSQC4 не перемещаем.")
            return
        end
        local key = GetObjectKey(frame)
        if not key then
            Warn("у фрейма нет имени — сохранить некуда.")
            return
        end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            Warn("защищённый фрейм, в бою двигать нельзя.")
            return
        end
        StopMoveMode(true)

        -- До включения режима фиксируем дефолт, если его ещё нет.
        EnsureDefault(key)

        if not db.frames[key] then db.frames[key] = {} end
        moveTarget, moveKey = frame, key
        moveWasMovable = frame:IsMovable() and true or false
        moveWasMouse = frame:IsMouseEnabled() and true or false
        frame:SetMovable(true)
        frame:EnableMouse(true)
        local ov = GetMoveOverlay()
        ov:SetParent(frame)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(10)
        ov:ClearAllPoints()
        ov:SetAllPoints(frame)
        ov.label:SetText(key)
        ov:EnableMouse(true)
        ov:Show()
        if RefreshList then RefreshList() end
        Msg(key .. ": тяни ЛКМ, ПКМ — отмена.")
    end

    -- ========================================================================
    -- Счётчик захвата
    -- ========================================================================
    local countdownFrame, countdownLeft, countdownAcc, countdownCallback, countdownActive

    local function StopCountdown()
        countdownActive = false
        countdownCallback = nil
        if countdownFrame then
            countdownFrame:SetScript("OnUpdate", nil)
            countdownFrame:Hide()
        end
    end

    local function StartCountdown(callback)
        if not countdownFrame then
            local f = CreateFrame("Frame", "NSQC4MoveCountdown", UIParent)
            f:SetWidth(460)
            f:SetHeight(56)
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
            f:SetFrameStrata("TOOLTIP")
            f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            f.text:SetPoint("TOP", 0, -10)
            f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            f.hint:SetPoint("TOP", f.text, "BOTTOM", 0, -4)
            own[f] = true
            countdownFrame = f
        end
        StopCountdown()
        local f = countdownFrame
        countdownLeft = math.max(1, math.min(30, math.floor(db.captureDelay or 5)))
        countdownAcc = 0
        countdownCallback = callback
        countdownActive = true
        f.acc = 0
        f.text:SetText("Наведите мышь: " .. countdownLeft)
        f.hint:SetText("Под курсором: —")
        f:Show()
        f:SetScript("OnUpdate", function(self, elapsed)
            self.acc = self.acc + elapsed
            if self.acc >= 0.25 then
                self.acc = 0
                local hover = GetMouseFrame()
                self.hint:SetText("Под курсором: " .. (hover and NameOf(hover) or "—"))
            end
            countdownAcc = countdownAcc + elapsed
            if countdownAcc < 1 then return end
            countdownAcc = countdownAcc - 1
            countdownLeft = countdownLeft - 1
            if countdownLeft > 0 then
                self.text:SetText("Наведите мышь: " .. countdownLeft)
                return
            end
            self:SetScript("OnUpdate", nil)
            countdownActive = false
            local frame = GetMouseFrame()
            local cb = countdownCallback
            countdownCallback = nil
            if frame then
                self.text:SetText("Захвачено: " .. NameOf(frame))
                self.hint:SetText("")
                if cb then cb(frame) end
            else
                self.text:SetText("Фрейм не найден!")
                self.hint:SetText("Курсор был над пустотой или окном NSQC4.")
            end
            After(1.5, function()
                if not countdownActive then countdownFrame:Hide() end
            end)
        end)
    end

    -- ========================================================================
    -- Главное окно
    -- ========================================================================
    local rows = {}
    local ENTRY_H = 26
    local LIST_W = 420

    local function ScrollWheel(self, delta)
        local child = self:GetScrollChild()
        local maxv = math.max(0, (child and child:GetHeight() or 0) - self:GetHeight())
        local value = math.max(0, math.min(maxv, self:GetVerticalScroll() - delta * ENTRY_H * 3))
        self:SetVerticalScroll(value)
        local bar = _G[self:GetName() .. "ScrollBar"]
        if bar then bar:SetValue(value) end
    end

    local function GetRow(i)
        if rows[i] then return rows[i] end
        local row = CreateFrame("Frame", nil, mainFrame.list)
        row:SetWidth(LIST_W)
        row:SetHeight(ENTRY_H)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
        row:EnableMouse(true)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            ScrollWheel(mainFrame.scroll, delta)
        end)
        local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameLbl:SetPoint("LEFT", 5, 0)
        nameLbl:SetWidth(275)
        nameLbl:SetJustifyH("LEFT")
        row.name = nameLbl
        local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        xBtn:SetWidth(24)
        xBtn:SetHeight(22)
        xBtn:SetPoint("RIGHT", -5, 0)
        xBtn:SetText("X")
        xBtn:SetScript("OnClick", function(self)
            local key = self:GetParent().key
            if key then ResetFrameByKey(key) end
        end)
        xBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Сбросить фрейм")
            GameTooltip:AddLine("Возвращает фрейм в дефолтную привязку и удаляет строку из списка.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        xBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local moveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        moveBtn:SetWidth(66)
        moveBtn:SetHeight(22)
        moveBtn:SetPoint("RIGHT", xBtn, "LEFT", -5, 0)
        moveBtn:SetText("Двигать")
        moveBtn:SetScript("OnClick", function(self)
            StartMoveForFrame(GetFrameByKey(self:GetParent().key))
        end)
        moveBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Двигать фрейм")
            GameTooltip:AddLine("Включает режим перемещения: тяни ЛКМ, ПКМ — отмена. По отпусканию ЛКМ позиция сохраняется.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        moveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.move = moveBtn
        local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        upBtn:SetWidth(24)
        upBtn:SetHeight(22)
        upBtn:SetPoint("RIGHT", moveBtn, "LEFT", -5, 0)
        upBtn:SetText("^")
        upBtn:SetScript("OnClick", function(self)
            local base = GetFrameByKey(self:GetParent().key)
            local parent = base and base:GetParent()
            if not parent or parent == UIParent or parent == WorldFrame then
                Warn("у объекта нет подходящего родителя.")
                return
            end
            StartMoveForFrame(parent)
        end)
        upBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Двигать родителя")
            GameTooltip:AddLine("Позволяет двигать родительский контейнер этого фрейма (например, всю панель Bartender).", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        upBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnEnter", function(self)
            self.name:SetTextColor(1, 1, 0)
            local key = self.key
            local data = key and db.frames[key]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Объект: " .. tostring(key), 1, 1, 1)
            GameTooltip:AddLine("Сейчас: " .. FormatGeometry(CaptureGeometry(GetFrameByKey(key))), 1, 1, 1)
            if data then
                GameTooltip:AddLine("Сохранено: " .. FormatSaved(data), 0, 1, 0)
                GameTooltip:AddLine("Исходное: " .. FormatDefault(data), 0.7, 0.7, 1)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self.name:SetTextColor(1, 1, 1)
            GameTooltip:Hide()
        end)
        rows[i] = row
        return row
    end

    RefreshList = function()
        if not mainFrame or not mainFrame.list then return end
        local keys = SortedKeys()
        for i = 1, #rows do rows[i]:Hide() end
        for i, key in ipairs(keys) do
            local row = GetRow(i)
            local frame = GetFrameByKey(key)
            local data = db.frames[key]
            row.key = key
            row.name:SetText((frame and "|cFFFFFFFF" or "|cFFFF6060") .. key .. "|r"
                .. ((data and data.point) and "" or " |cFFFFFF00*|r"))
            if frame then row.move:Enable() else row.move:Disable() end
            row:Show()
        end
        mainFrame.list:SetHeight(math.max(#keys * ENTRY_H, 10))
        mainFrame.scroll:UpdateScrollChildRect()
        mainFrame.count:SetText("Фреймов: " .. #keys .. "   (* — позиция не сохранена)")
    end

    NSQC4.FramesMove_RefreshList = function()
        if RefreshList then RefreshList() end
    end

    local function CreateMainFrame()
        if mainFrame then return mainFrame end
        local f = CreateFrame("Frame", "NSQC4FramesMoveFrame", UIParent)
        f:SetWidth(480)
        f:SetHeight(420)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
        f:Hide()
        own[f] = true
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Перемещение (" .. (UnitName("player") or "?") .. ")")
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetWidth(24)
        settingsBtn:SetHeight(24)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesMove_OpenSettings() end)
        settingsBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Настройки")
            GameTooltip:AddLine("Задержка захвата, возврат позиции при показе фрейма.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        settingsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetWidth(150)
        addBtn:SetHeight(22)
        addBtn:SetPoint("TOPLEFT", 20, -45)
        addBtn:SetText("Добавить фрейм")
        addBtn:SetScript("OnClick", function()
            StartCountdown(function(frame) StartMoveForFrame(frame) end)
        end)
        addBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Добавить фрейм")
            GameTooltip:AddLine("Запускает отсчёт: наведи мышь на нужный фрейм и подожди. После захвата включится режим перемещения.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        addBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetWidth(130)
        resetBtn:SetHeight(22)
        resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        resetBtn:SetText("Сбросить всё")
        resetBtn:SetScript("OnClick", function() ResetAll() end)
        resetBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Сбросить всё")
            GameTooltip:AddLine("Возвращает все фреймы в дефолтные привязки и полностью очищает список.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.count = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.count:SetPoint("TOPLEFT", 20, -74)
        f.count:SetText("Фреймов: 0")
        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesMoveScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -92)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", ScrollWheel)
        local child = CreateFrame("Frame", "NSQC4FramesMoveList", scroll)
        child:SetWidth(LIST_W)
        child:SetHeight(10)
        scroll:SetScrollChild(child)
        f.scroll, f.list = scroll, child
        mainFrame = f
        if UISpecialFrames then table.insert(UISpecialFrames, "NSQC4FramesMoveFrame") end
        return f
    end

    -- ========================================================================
    -- Настройки
    -- ========================================================================
    function NSQC4.FramesMove_OpenSettings()
        if settingsFrame then
            settingsFrame.slider:SetValue(db.captureDelay)
            settingsFrame.label:SetText("Время до захвата: " .. db.captureDelay .. " сек")
            settingsFrame.check:SetChecked(db.reapplyOnShow and true or false)
            settingsFrame:Raise()
            settingsFrame:Show()
            return
        end
        local f = CreateFrame("Frame", "NSQC4FramesMoveSettings", UIParent)
        f:SetWidth(340)
        f:SetHeight(230)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self:StartMoving() end
        end)
        f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
        own[f] = true
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Настройки: Перемещение")
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 20, -50)
        lbl:SetText("Время до захвата: " .. db.captureDelay .. " сек")
        f.label = lbl
        local slider = CreateFrame("Slider", "NSQC4MoveSettingsSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 25, -85)
        slider:SetWidth(280)
        slider:SetHeight(18)
        slider:SetMinMaxValues(3, 15)
        slider:SetValueStep(1)
        slider:SetValue(db.captureDelay)
        local sname = slider:GetName()
        if _G[sname .. "Text"] then _G[sname .. "Text"]:SetText("Задержка захвата") end
        if _G[sname .. "Low"] then _G[sname .. "Low"]:SetText("3") end
        if _G[sname .. "High"] then _G[sname .. "High"]:SetText("15") end
        slider:SetScript("OnValueChanged", function(_, value)
            lbl:SetText("Время до захвата: " .. math.floor(value) .. " сек")
        end)
        f.slider = slider
        local check = CreateFrame("CheckButton", "NSQC4MoveGuardCheck", f, "UICheckButtonTemplate")
        check:SetWidth(24)
        check:SetHeight(24)
        check:SetPoint("TOPLEFT", 20, -130)
        check:SetChecked(db.reapplyOnShow and true or false)
        check:SetScript("OnClick", function(self)
            db.reapplyOnShow = self:GetChecked() and true or false
            L("reapplyOnShow = %s", tostring(db.reapplyOnShow))
        end)
        f.check = check
        local checkLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkLbl:SetPoint("LEFT", check, "RIGHT", 6, 0)
        checkLbl:SetWidth(270)
        checkLbl:SetJustifyH("LEFT")
        checkLbl:SetText("Возвращать позицию при показе фрейма")
        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetWidth(110)
        saveBtn:SetHeight(22)
        saveBtn:SetPoint("BOTTOM", 0, 15)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            db.captureDelay = math.max(3, math.min(15, math.floor(slider:GetValue())))
            Msg("задержка захвата: " .. db.captureDelay .. " сек")
            f:Hide()
        end)
        saveBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Сохранить настройки")
            GameTooltip:Show()
        end)
        saveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        settingsFrame = f
        if UISpecialFrames then table.insert(UISpecialFrames, "NSQC4FramesMoveSettings") end
        f:Raise()
        f:Show()
    end

    -- ========================================================================
    -- Диспетчер команд
    -- ========================================================================
    NSQC4._FramesMoveDispatch = function(msg)
        local raw = (msg or ""):match("^%s*(.-)%s*$")
        local cmd, arg = raw:match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()
        arg = arg or ""
        if cmd == "" then
            local f = CreateMainFrame()
            if f:IsShown() then
                f:Hide()
            else
                f:Raise()
                f:Show()
                RefreshList()
            end
        elseif cmd == "add" then
            StartCountdown(function(frame) StartMoveForFrame(frame) end)
        elseif cmd == "move" then
            StartMoveForFrame(_G[arg])
        elseif cmd == "stop" then
            StopCountdown()
            StopMoveMode()
        elseif cmd == "apply" or cmd == "applynow" then
            Msg("позиции применены, не найдено: " .. ApplyAllSaved())
        elseif cmd == "reset" then
            if arg ~= "" then ResetFrameByKey(arg) else ResetAll() end
        elseif cmd == "delay" then
            db.captureDelay = math.max(3, math.min(15, math.floor(tonumber(arg) or 5)))
            Msg("задержка захвата: " .. db.captureDelay .. " сек")
        elseif cmd == "guard" then
            if arg == "on" then
                db.reapplyOnShow = true
            elseif arg == "off" then
                db.reapplyOnShow = false
            else
                db.reapplyOnShow = not db.reapplyOnShow
            end
            Msg("возврат при показе: " .. (db.reapplyOnShow and "вкл" or "выкл"))
        elseif cmd == "debug" or cmd == "verify" or cmd == "list" then
            ReportAll()
        elseif cmd == "on" then
            debugEnabled = true
            Msg("отладка включена.")
        elseif cmd == "off" then
            debugEnabled = false
            Msg("отладка выключена.")
        else
            print(LOG_PREFIX .. "/nsfcm — окно, add — захват мышью")
            print(LOG_PREFIX .. "move <Имя> | stop | apply | reset [Имя]")
            print(LOG_PREFIX .. "delay <3-15> | guard on/off | debug | on/off")
        end
    end

    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("M", "/ns_fcmove", "Перемещение фреймов", function()
            SlashCmdList["NS_FCMOVE"]("")
        end)
    end

    -- ========================================================================
    -- Восстановление при входе + смена масштаба/разрешения
    -- ========================================================================
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    restoreFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    restoreFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            ScheduleRestore()
        else
            EnsureAllDefaults()
            RetryPending()
        end
    end)
    local watchAcc, lastScale, lastW, lastH = 0, nil, nil, nil
    restoreFrame:SetScript("OnUpdate", function(_, elapsed)
        watchAcc = watchAcc + elapsed
        if watchAcc < 0.5 then return end
        watchAcc = 0
        local scale = UIParent:GetEffectiveScale()
        local w, h = GetScreenWidth(), GetScreenHeight()
        if lastScale and (math.abs(scale - lastScale) > 0.0001 or w ~= lastW or h ~= lastH) then
            L("смена масштаба/разрешения, применяю позиции")
            After(0.2, ApplyAllSaved)
        end
        lastScale, lastW, lastH = scale, w, h
    end)
    ScheduleRestore()

    NSQC4.SetModuleMeta("ui_frames_move", {
        label   = "Перемещение",
        tooltip = "Перемещение любых фреймов. /ns_fcmove.",
        order   = 300,
    })
end)