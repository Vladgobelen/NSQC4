-- ============================================================================
-- NSQC4 / Interface / ui_frames / Move
-- Перемещение фреймов. Модуль "ui_frames_move".
-- Клиент: WoW 3.3.5a (12340). Таймеры только на фреймах, без C_Timer.
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
    -- 1. База персонажа
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

    -- ========================================================================
    -- 2. Лог
    -- ========================================================================
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

    local function Msg(text)
        print("|cFF00FF00NSQC4:|r " .. text)
    end

    local function Warn(text)
        print("|cFFFFFF00NSQC4:|r " .. text)
    end

    -- ========================================================================
    -- 3. Планировщик на фреймах (замена C_Timer.After)
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
    -- 4. Утилиты работы с объектами
    -- ========================================================================
    local ownFrames = {}

    local function NameOf(obj)
        if not obj then return "nil" end
        if obj.GetName then
            local n = obj:GetName()
            if n and n ~= "" then return n end
        end
        return "<без имени>"
    end

    local function GetObjectKey(frame)
        if frame and frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        return nil
    end

    local function NormalizeToFrame(region)
        if type(region) ~= "table" then return nil end
        local guard = 0
        while region and guard < 32 do
            guard = guard + 1
            if region == UIParent or region == WorldFrame then return nil end
            if region.IsObjectType then
                if region:IsObjectType("Frame") then return region end
            elseif region.StartMoving then
                return region
            end
            region = region.GetParent and region:GetParent() or nil
        end
        return nil
    end

    local function GetFrameByKey(key)
        if not key then return nil end
        return NormalizeToFrame(_G[key])
    end

    local function IsOwnFrame(frame)
        local f = frame
        local guard = 0
        while f and guard < 32 do
            if ownFrames[f] then return true end
            f = f.GetParent and f:GetParent() or nil
            guard = guard + 1
        end
        return false
    end

    local function GetMouseFrame()
        local focus = GetMouseFocus and GetMouseFocus() or nil
        local frame = NormalizeToFrame(focus)
        if not frame then return nil end
        if IsOwnFrame(frame) then return nil end
        return frame
    end

    local function SortedKeys()
        local keys = {}
        for k in pairs(db.frames) do keys[#keys + 1] = k end
        table.sort(keys)
        return keys
    end

    -- ========================================================================
    -- 5. Геометрия
    -- x, y хранятся в системе координат UIParent (от левого верхнего угла).
    -- При применении пересчитываются в собственную систему фрейма.
    -- ========================================================================
    local function OffsetRatio(frame)
        local fs = frame:GetEffectiveScale()
        local us = UIParent:GetEffectiveScale()
        if not fs or fs <= 0 or not us or us <= 0 then return 1 end
        return us / fs
    end

    local function CaptureGeometry(frame)
        if not frame then return nil end
        local left, top = frame:GetLeft(), frame:GetTop()
        local uiLeft, uiTop = UIParent:GetLeft(), UIParent:GetTop()
        if not left or not top or not uiLeft or not uiTop then return nil end
        return {
            x = left - uiLeft,
            y = top - uiTop,
            width = frame:GetWidth(),
            height = frame:GetHeight(),
            scale = frame:GetScale(),
        }
    end

    local function FormatGeometry(g)
        if not g then return "|cFFFF6060нет данных|r" end
        return string.format("x=%.1f y=%.1f size=%.0fx%.0f scale=%.2f",
            g.x or 0, g.y or 0, g.width or 0, g.height or 0, g.scale or 1)
    end

    -- Размер НЕ восстанавливаем: у半数 фреймов он задан якорями, SetSize ломает вёрстку.
    local function ApplyGeometry(frame, g)
        if not frame or not g then return false end
        if not frame.SetPoint or not frame.ClearAllPoints then return false end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            L("бой: применение %s отложено", NameOf(frame))
            return false
        end

        if g.scale and frame.SetScale then
            local cur = frame:GetScale()
            if not cur or math.abs(cur - g.scale) > 0.001 then
                frame:SetScale(g.scale)
            end
        end

        local k = OffsetRatio(frame)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (g.x or 0) * k, (g.y or 0) * k)
        L("применено %s -> x=%.1f y=%.1f (k=%.3f)", NameOf(frame), g.x or 0, g.y or 0, k)
        return true
    end

    -- ========================================================================
    -- 6. Объявления наперёд
    -- ========================================================================
    local RefreshList, StartMoveForFrame, StopMoveMode
    local moveOverlay, moveTarget, moveKey
    local moveWasMovable, moveWasMouse
    local pending = {}
    local hooked = {}

    -- ========================================================================
    -- 7. Применение / восстановление
    -- ========================================================================
    local function HookFrame(frame, key)
        if hooked[frame] then return end
        if not frame.HookScript then return end
        hooked[frame] = true
        frame:HookScript("OnShow", function(self)
            if not db.reapplyOnShow then return end
            if self == moveTarget then return end
            local data = db.frames[key]
            if not data or not data.geometry then return end
            if InCombatLockdown() and self.IsProtected and self:IsProtected() then return end
            ApplyGeometry(self, data.geometry)
        end)
    end

    local function ApplySavedKey(key)
        local data = db.frames[key]
        if not data or not data.geometry then return true end
        if moveKey and key == moveKey then return true end
        local frame = GetFrameByKey(key)
        if not frame then
            L("фрейм %s ещё не создан", key)
            return false
        end
        local ok = ApplyGeometry(frame, data.geometry)
        if ok then HookFrame(frame, key) end
        return ok
    end

    local function ApplyAllSaved()
        pending = {}
        local total, done = 0, 0
        for key in pairs(db.frames) do
            total = total + 1
            if ApplySavedKey(key) then
                done = done + 1
            else
                pending[key] = true
            end
        end
        L("применено %d из %d", done, total)
        return done, total
    end

    local function RetryPending()
        for key in pairs(pending) do
            if ApplySavedKey(key) then pending[key] = nil end
        end
    end

    local RESTORE_WAVES = { 0.5, 1, 2, 5, 10, 20, 30 }

    local function ScheduleRestore()
        ApplyAllSaved()
        for _, delay in ipairs(RESTORE_WAVES) do
            After(delay, RetryPending)
        end
    end

    -- ========================================================================
    -- 8. Сохранение / сброс
    -- ========================================================================
    local function SaveCurrentPosition(frame, key)
        if not frame or not key then return false end
        local g = CaptureGeometry(frame)
        if not g then
            Warn("не удалось прочитать координаты " .. key)
            return false
        end
        local data = db.frames[key]
        if not data then
            data = {}
            db.frames[key] = data
        end
        data.geometry = g
        pending[key] = nil
        HookFrame(frame, key)
        L("сохранено %s: %s", key, FormatGeometry(g))
        RefreshList()
        return true
    end

    local function ResetFrameByKey(key)
        if not key then return end
        local data = db.frames[key]
        local frame = GetFrameByKey(key)
        if frame and data and data.defaultGeometry then
            ApplyGeometry(frame, data.defaultGeometry)
        end
        db.frames[key] = nil
        pending[key] = nil
        RefreshList()
        Msg("сброшено: " .. key)
    end

    local function ResetAll()
        local keys = SortedKeys()
        for _, key in ipairs(keys) do
            local data = db.frames[key]
            local frame = GetFrameByKey(key)
            if frame and data and data.defaultGeometry then
                ApplyGeometry(frame, data.defaultGeometry)
            end
            db.frames[key] = nil
            pending[key] = nil
        end
        RefreshList()
        Msg("сброшено фреймов: " .. #keys)
    end

    local function CleanMissing()
        local removed = 0
        for key in pairs(db.frames) do
            if not GetFrameByKey(key) then
                db.frames[key] = nil
                pending[key] = nil
                removed = removed + 1
            end
        end
        RefreshList()
        Msg("удалено записей без фрейма: " .. removed)
    end

    -- ========================================================================
    -- 9. Отладка
    -- ========================================================================
    local function ReportAll()
        local keys = SortedKeys()
        local wait = 0
        for _ in pairs(pending) do wait = wait + 1 end

        print(LOG_PREFIX .. "===== ОТЧЁТ: " .. #keys .. " фреймов =====")
        print(LOG_PREFIX .. string.format("экран %.0fx%.0f, UIParent scale=%.3f, задержка=%d сек",
            GetScreenWidth() or 0, GetScreenHeight() or 0,
            UIParent:GetEffectiveScale() or 0, db.captureDelay or 5))

        for _, key in ipairs(keys) do
            local data = db.frames[key]
            local frame = GetFrameByKey(key)
            print(LOG_PREFIX .. "|cFFFFFFFF" .. key .. "|r")
            if frame then
                print(LOG_PREFIX .. "  в игре: " .. FormatGeometry(CaptureGeometry(frame))
                    .. string.format(" movable=%s protected=%s",
                        tostring(frame.IsMovable and frame:IsMovable() or false),
                        tostring(frame.IsProtected and frame:IsProtected() or false)))
            else
                print(LOG_PREFIX .. "  в игре: |cFFFF6060НЕ НАЙДЕН|r")
            end
            print(LOG_PREFIX .. "  в базе: " .. FormatGeometry(data and data.geometry))
            print(LOG_PREFIX .. "  исходно: " .. FormatGeometry(data and data.defaultGeometry))
        end

        print(LOG_PREFIX .. string.format("ожидают применения: %d, OnShow-возврат: %s, лог: %s",
            wait, db.reapplyOnShow and "вкл" or "выкл", debugEnabled and "вкл" or "выкл"))
        print(LOG_PREFIX .. "===== КОНЕЦ =====")
    end

    -- ========================================================================
    -- 10. Режим перемещения (один переиспользуемый оверлей)
    -- ========================================================================
    StopMoveMode = function(silent)
        if moveOverlay then
            moveOverlay:Hide()
        end
        if moveTarget then
            if moveTarget.StopMovingOrSizing then moveTarget:StopMovingOrSizing() end
            if moveTarget.SetMovable and moveWasMovable ~= nil then
                moveTarget:SetMovable(moveWasMovable)
            end
            if moveTarget.EnableMouse and moveWasMouse ~= nil then
                moveTarget:EnableMouse(moveWasMouse)
            end
        end
        moveTarget, moveKey = nil, nil
        moveWasMovable, moveWasMouse = nil, nil
        if not silent then Msg("режим перемещения выключен.") end
    end

    local function CancelMove()
        local target, key = moveTarget, moveKey
        if target and target.StopMovingOrSizing then target:StopMovingOrSizing() end
        if target and key then
            local data = db.frames[key]
            local g = data and (data.geometry or data.defaultGeometry)
            if g then ApplyGeometry(target, g) end
            if data and not data.geometry then
                db.frames[key] = nil
                pending[key] = nil
            end
        end
        StopMoveMode(true)
        RefreshList()
        Msg("перемещение отменено, позиция возвращена.")
    end

    local function GetMoveOverlay()
        if moveOverlay then return moveOverlay end

        local ov = CreateFrame("Frame", "NSQC4MoveOverlay", UIParent)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(10)
        ov:EnableMouse(true)
        ov:Hide()

        local hl = ov:CreateTexture(nil, "OVERLAY")
        hl:SetAllPoints(ov)
        hl:SetTexture(0.2, 1, 0.2, 0.25)

        local label = ov:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", ov, "CENTER", 0, 0)
        label:SetTextColor(1, 1, 1)
        ov.label = label

        ov:SetScript("OnMouseDown", function(self, button)
            local target = moveTarget
            if not target then return end
            if button == "LeftButton" then
                if InCombatLockdown() and target.IsProtected and target:IsProtected() then
                    Warn("фрейм защищён: перемещение в бою запрещено.")
                    return
                end
                target:StartMoving()
            elseif button == "RightButton" then
                CancelMove()
            end
        end)

        ov:SetScript("OnMouseUp", function(self, button)
            if button ~= "LeftButton" then return end
            local target, key = moveTarget, moveKey
            if not target or not key then return end
            target:StopMovingOrSizing()
            if SaveCurrentPosition(target, key) then
                Msg("сохранено: " .. key)
            end
            StopMoveMode(true)
        end)

        ownFrames[ov] = true
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
            Warn("окна самого NSQC4 перемещать нельзя.")
            return
        end
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            Warn("защищённый фрейм нельзя двигать в бою.")
            return
        end

        local key = GetObjectKey(frame)
        if not key then
            Warn("у фрейма нет имени — сохранить позицию нельзя.")
            return
        end

        StopMoveMode(true)

        local data = db.frames[key]
        if not data then
            data = {}
            db.frames[key] = data
        end
        if not data.defaultGeometry then
            data.defaultGeometry = CaptureGeometry(frame)
        end

        moveTarget, moveKey = frame, key
        moveWasMovable = frame.IsMovable and frame:IsMovable() or false
        moveWasMouse = frame.IsMouseEnabled and frame:IsMouseEnabled() or false
        if frame.SetMovable then frame:SetMovable(true) end
        if frame.EnableMouse then frame:EnableMouse(true) end

        local ov = GetMoveOverlay()
        ov:SetParent(frame)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(10)
        ov:ClearAllPoints()
        ov:SetAllPoints(frame)
        ov.label:SetText(key)
        ov:Show()

        RefreshList()
        Msg("перемещение " .. key .. ": ЛКМ — тянуть, ПКМ — отмена.")
    end

    -- ========================================================================
    -- 11. Захват фрейма под мышью (счётчик на фрейме)
    -- ========================================================================
    local countdownFrame
    local countdownValue, countdownElapsed = 0, 0
    local countdownCallback, countdownActive = nil, false

    local function StopCountdown()
        countdownActive = false
        countdownCallback = nil
        if countdownFrame then
            countdownFrame:SetScript("OnUpdate", nil)
            countdownFrame:Hide()
        end
    end

    local function StartCountdown(callback)
        StopCountdown()

        local delay = math.floor(tonumber(db.captureDelay) or 5)
        delay = math.max(3, math.min(15, delay))

        local f = countdownFrame
        if not f then
            f = CreateFrame("Frame", "NSQC4MoveCountdown", UIParent)
            f:SetWidth(460)
            f:SetHeight(64)
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
            f:SetFrameStrata("TOOLTIP")
            f:SetFrameLevel(20)
            f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 },
            })

            f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            f.text:SetPoint("TOP", f, "TOP", 0, -12)

            f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            f.hint:SetPoint("TOP", f.text, "BOTTOM", 0, -6)
            f.hint:SetWidth(430)
            f.hint:SetJustifyH("CENTER")

            f.acc = 0
            ownFrames[f] = true
            countdownFrame = f
        end

        countdownValue = delay
        countdownElapsed = 0
        countdownCallback = callback
        countdownActive = true
        f.acc = 0
        f.text:SetText("Наведите мышь на фрейм: " .. delay)
        f.hint:SetText("Под курсором: —")
        f:Show()

        f:SetScript("OnUpdate", function(self, elapsed)
            countdownElapsed = countdownElapsed + elapsed
            self.acc = self.acc + elapsed

            if self.acc >= 0.25 then
                self.acc = 0
                local hover = GetMouseFrame()
                self.hint:SetText("Под курсором: " .. (hover and NameOf(hover) or "—"))
            end

            if countdownElapsed < 1 then return end
            countdownElapsed = countdownElapsed - 1
            countdownValue = countdownValue - 1

            if countdownValue > 0 then
                self.text:SetText("Наведите мышь на фрейм: " .. countdownValue)
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
                After(1.2, function()
                    if countdownFrame == self and not countdownActive then self:Hide() end
                end)
                if cb then cb(frame) end
            else
                self.text:SetText("Фрейм не найден!")
                self.hint:SetText("Курсор был над пустым местом или окном NSQC4.")
                After(1.5, function()
                    if countdownFrame == self and not countdownActive then self:Hide() end
                end)
            end
        end)
    end

    -- ========================================================================
    -- 12. Главное окно (строки списка переиспользуются)
    -- ========================================================================
    local mainFrame
    local rows = {}
    local ENTRY_H = 26
    local LIST_W = 440

    local function ScrollWheel(self, delta)
        if not self or not self.GetScrollChild then return end
        local child = self:GetScrollChild()
        if not child then return end
        local maxScroll = math.max(0, (child:GetHeight() or 0) - (self:GetHeight() or 0))
        local new = math.max(0, math.min(maxScroll, (self:GetVerticalScroll() or 0) - delta * ENTRY_H * 3))
        self:SetVerticalScroll(new)
        local bar = _G[(self:GetName() or "") .. "ScrollBar"]
        if bar then bar:SetValue(new) end
    end

    local function GetRow(i)
        local row = rows[i]
        if row then return row end

        local parent = mainFrame.list
        row = CreateFrame("Frame", nil, parent)
        row:SetWidth(LIST_W)
        row:SetHeight(ENTRY_H)
        row:EnableMouse(true)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            ScrollWheel(mainFrame.scroll, delta)
        end)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture(1, 1, 1, 0.04)
        row.bg = bg

        local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameLbl:SetPoint("LEFT", row, "LEFT", 5, 0)
        nameLbl:SetWidth(290)
        nameLbl:SetJustifyH("LEFT")
        nameLbl:SetWordWrap(false)
        row.name = nameLbl

        local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        xBtn:SetWidth(24)
        xBtn:SetHeight(22)
        xBtn:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        xBtn:SetText("X")
        xBtn:SetScript("OnClick", function(self)
            local key = self:GetParent().key
            if key then ResetFrameByKey(key) end
        end)

        local moveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        moveBtn:SetWidth(66)
        moveBtn:SetHeight(22)
        moveBtn:SetPoint("RIGHT", xBtn, "LEFT", -5, 0)
        moveBtn:SetText("Двигать")
        moveBtn:SetScript("OnClick", function(self)
            local key = self:GetParent().key
            if key then StartMoveForFrame(GetFrameByKey(key)) end
        end)
        row.moveBtn = moveBtn

        local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        upBtn:SetWidth(24)
        upBtn:SetHeight(22)
        upBtn:SetPoint("RIGHT", moveBtn, "LEFT", -5, 0)
        upBtn:SetText("^")
        upBtn:SetScript("OnClick", function(self)
            local key = self:GetParent().key
            local base = key and GetFrameByKey(key)
            local parentFrame = base and base.GetParent and base:GetParent()
            if not parentFrame or parentFrame == UIParent or parentFrame == WorldFrame then
                Warn("у объекта нет подходящего родителя.")
                return
            end
            StartMoveForFrame(parentFrame)
        end)

        row:SetScript("OnEnter", function(self)
            self.name:SetTextColor(1, 1, 0)
            local key = self.key
            local data = key and db.frames[key]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Объект: " .. tostring(key), 1, 1, 1)
            if data and data.geometry then
                GameTooltip:AddLine("Сохранено: " .. FormatGeometry(data.geometry), 0, 1, 0)
            else
                GameTooltip:AddLine("Позиция ещё не сохранена", 1, 0.8, 0)
            end
            if data and data.defaultGeometry then
                GameTooltip:AddLine("Исходно: " .. FormatGeometry(data.defaultGeometry), 0.7, 0.7, 1)
            end
            if key and not GetFrameByKey(key) then
                GameTooltip:AddLine("Фрейм сейчас не существует", 1, 0.4, 0.4)
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
        local f = mainFrame
        if not f or not f.list then return end

        local keys = SortedKeys()
        for i = 1, #rows do rows[i]:Hide() end

        for i, key in ipairs(keys) do
            local row = GetRow(i)
            row.key = key
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.list, "TOPLEFT", 0, -((i - 1) * ENTRY_H))

            local frame = GetFrameByKey(key)
            local data = db.frames[key]
            local text = key
            if not frame then
                text = "|cFFFF6060" .. key .. "|r"
            elseif not data or not data.geometry then
                text = "|cFFFFFF00" .. key .. "|r"
            end
            row.name:SetText(text)
            row.moveBtn:SetEnabled(frame ~= nil)
            row:Show()
        end

        f.list:SetHeight(math.max(#keys * ENTRY_H, 10))
        f.scroll:UpdateScrollChildRect()
        f.count:SetText("Фреймов: " .. #keys)
    end

    NSQC4.FramesMove_RefreshList = RefreshList
    NSQC4.FramesMove_ApplyAll = ApplyAllSaved

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesMoveFrame", UIParent)
        f:SetWidth(500)
        f:SetHeight(440)
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
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        f:Hide()
        ownFrames[f] = true

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -15)
        title:SetText("Перемещение (" .. (UnitName("player") or "?") .. ")")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetWidth(24)
        settingsBtn:SetHeight(22)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesMove_OpenSettings() end)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetWidth(150)
        addBtn:SetHeight(22)
        addBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -45)
        addBtn:SetText("Добавить фрейм")
        addBtn:SetScript("OnClick", function()
            StartCountdown(function(frame) StartMoveForFrame(frame) end)
        end)

        local applyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        applyBtn:SetWidth(110)
        applyBtn:SetHeight(22)
        applyBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        applyBtn:SetText("Применить")
        applyBtn:SetScript("OnClick", function()
            local done, total = ApplyAllSaved()
            Msg(string.format("применено %d из %d.", done, total))
        end)

        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetWidth(130)
        resetBtn:SetHeight(22)
        resetBtn:SetPoint("LEFT", applyBtn, "RIGHT", 5, 0)
        resetBtn:SetText("Сбросить всё")
        resetBtn:SetScript("OnClick", function() ResetAll() end)

        local count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        count:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -74)
        count:SetJustifyH("LEFT")
        f.count = count

        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesMoveScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -95)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, 20)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", ScrollWheel)

        local child = CreateFrame("Frame", "NSQC4FramesMoveList", scroll)
        child:SetWidth(LIST_W)
        child:SetHeight(10)
        scroll:SetScrollChild(child)

        f.scroll = scroll
        f.list = child
        mainFrame = f

        if UISpecialFrames then
            table.insert(UISpecialFrames, "NSQC4FramesMoveFrame")
        end
        return f
    end

    -- ========================================================================
    -- 13. Настройки
    -- ========================================================================
    local settingsFrame

    function NSQC4.FramesMove_OpenSettings()
        if settingsFrame then
            settingsFrame.slider:SetValue(db.captureDelay or 5)
            settingsFrame.label:SetText("Время до захвата: " .. (db.captureDelay or 5) .. " сек")
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
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        ownFrames[f] = true

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -15)
        title:SetText("Настройки: Перемещение")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -50)
        lbl:SetText("Время до захвата: " .. (db.captureDelay or 5) .. " сек")
        f.label = lbl

        local slider = CreateFrame("Slider", "NSQC4MoveSettingsSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -80)
        slider:SetWidth(290)
        slider:SetHeight(18)
        slider:SetMinMaxValues(3, 15)
        slider:SetValueStep(1)
        slider:SetValue(db.captureDelay or 5)
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value + 0.5)
            lbl:SetText("Время до захвата: " .. value .. " сек")
        end)
        f.slider = slider

        local sname = slider:GetName()
        if sname then
            local t = _G[sname .. "Text"]
            if t then t:SetText("Захват фрейма под мышью") end
            local lo = _G[sname .. "Low"]
            if lo then lo:SetText("3") end
            local hi = _G[sname .. "High"]
            if hi then hi:SetText("15") end
        end

        local check = CreateFrame("CheckButton", "NSQC4MoveGuardCheck", f, "UICheckButtonTemplate")
        check:SetWidth(24)
        check:SetHeight(24)
        check:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -120)
        check:SetChecked(db.reapplyOnShow and true or false)
        check:SetScript("OnClick", function(self)
            db.reapplyOnShow = self:GetChecked() and true or false
            L("OnShow-возврат: %s", tostring(db.reapplyOnShow))
        end)
        f.check = check

        local checkLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        checkLbl:SetPoint("LEFT", check, "RIGHT", 6, 0)
        checkLbl:SetWidth(270)
        checkLbl:SetJustifyH("LEFT")
        checkLbl:SetText("Возвращать позицию при показе фрейма")

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -152)
        hint:SetWidth(300)
        hint:SetJustifyH("LEFT")
        hint:SetText("Спасает, если аддон сам переставляет свой фрейм.")

        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetWidth(110)
        saveBtn:SetHeight(22)
        saveBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            db.captureDelay = math.max(3, math.min(15, math.floor(slider:GetValue() + 0.5)))
            Msg("задержка захвата: " .. db.captureDelay .. " сек")
            f:Hide()
        end)

        settingsFrame = f
        if UISpecialFrames then
            table.insert(UISpecialFrames, "NSQC4FramesMoveSettings")
        end
        f:Raise()
        f:Show()
    end

    -- ========================================================================
    -- 14. Диспетчер команд
    -- ========================================================================
    local function PrintHelp()
        print("|cFF66CCFF[FCMOVE]|r команды:")
        print("  /nsfcm — окно списка")
        print("  /nsfcm add — захват фрейма под мышью")
        print("  /nsfcm move <Имя> — двигать фрейм по имени")
        print("  /nsfcm stop — выйти из режима перемещения")
        print("  /nsfcm apply — применить сохранённые позиции")
        print("  /nsfcm reset [Имя] — сброс одного или всех")
        print("  /nsfcm clean — удалить записи отсутствующих фреймов")
        print("  /nsfcm delay <3-15> — задержка захвата")
        print("  /nsfcm guard on|off — возврат позиции при показе")
        print("  /nsfcm debug — полный отчёт по геометрии")
        print("  /nsfcm on|off — лог отладки")
    end

    NSQC4._FramesMoveDispatch = function(msg)
        local raw = tostring(msg or ""):match("^%s*(.-)%s*$")
        local cmd, arg = raw:match("^(%S+)%s*(.-)$")
        cmd = string.lower(cmd or "")
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

        elseif cmd == "help" or cmd == "?" then
            PrintHelp()

        elseif cmd == "debug" or cmd == "verify" or cmd == "list" then
            ReportAll()

        elseif cmd == "on" then
            debugEnabled = true
            Msg("отладка включена.")

        elseif cmd == "off" then
            debugEnabled = false
            Msg("отладка выключена.")

        elseif cmd == "apply" or cmd == "applynow" then
            local done, total = ApplyAllSaved()
            Msg(string.format("применено %d из %d.", done, total))

        elseif cmd == "add" or cmd == "capture" then
            StartCountdown(function(frame) StartMoveForFrame(frame) end)

        elseif cmd == "stop" then
            StopCountdown()
            StopMoveMode()

        elseif cmd == "move" then
            if arg == "" then
                Warn("usage: /nsfcm move <ИмяФрейма>")
                return
            end
            StartMoveForFrame(GetFrameByKey(arg))

        elseif cmd == "reset" then
            if arg == "" then
                ResetAll()
            elseif db.frames[arg] then
                ResetFrameByKey(arg)
            else
                Warn("нет записи: " .. arg)
            end

        elseif cmd == "clean" then
            CleanMissing()

        elseif cmd == "delay" then
            local n = tonumber(arg)
            if not n then
                Warn("usage: /nsfcm delay <3-15>")
                return
            end
            db.captureDelay = math.max(3, math.min(15, math.floor(n)))
            Msg("задержка захвата: " .. db.captureDelay .. " сек")

        elseif cmd == "guard" then
            if arg == "on" then
                db.reapplyOnShow = true
            elseif arg == "off" then
                db.reapplyOnShow = false
            else
                Warn("usage: /nsfcm guard on|off")
                return
            end
            Msg("возврат при показе: " .. (db.reapplyOnShow and "вкл" or "выкл"))

        else
            Warn("неизвестная команда: " .. cmd .. " (см. /nsfcm help)")
        end
    end

    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("M", "/ns_fcmove", "Перемещение фреймов", function()
            SlashCmdList["NS_FCMOVE"]("")
        end)
    end

    -- ========================================================================
    -- 15. Восстановление при входе, после боя и при смене масштаба
    -- ========================================================================
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    restoreFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    restoreFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            RetryPending()
        else
            ScheduleRestore()
        end
    end)

    local watchAcc, lastScale, lastW, lastH = 0, nil, nil, nil
    restoreFrame:SetScript("OnUpdate", function(self, elapsed)
        watchAcc = watchAcc + elapsed
        if watchAcc < 0.5 then return end
        watchAcc = 0

        local scale = UIParent:GetEffectiveScale() or 0
        local w, h = GetScreenWidth() or 0, GetScreenHeight() or 0
        if lastScale and (math.abs(scale - lastScale) > 0.0001 or w ~= lastW or h ~= lastH) then
            L("смена масштаба/разрешения: переприменяю позиции")
            After(0.2, ApplyAllSaved)
        end
        lastScale, lastW, lastH = scale, w, h
    end)

    NSQC4.SetModuleMeta("ui_frames_move", {
        label   = "Перемещение",
        tooltip = "Перемещение любых фреймов. /ns_fcmove.",
        order   = 300,
    })
end)