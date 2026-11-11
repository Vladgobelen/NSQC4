-- ============================================================================
-- NSQC4 / Interface / ui_frames / Move
-- Перемещение фреймов. Модуль "ui_frames_move".
-- Сохраняет и восстанавливает полную геометрию фрейма.
-- ============================================================================

SLASH_NS_FCMOVE1 = "/ns_fcmove"
SLASH_NS_FCMOVE2 = "/nsfcm"
SlashCmdList["NS_FCMOVE"] = function(msg)
    msg = (msg or ""):lower()
    if not NSQC4 or not NSQC4._FramesMoveDispatch then
        print("|cFFFFFF00NSQC4:|r модуль перемещения ещё не инициализирован.")
        return
    end
    NSQC4._FramesMoveDispatch(msg)
end

NSQC4.RegisterModule("ui_frames_move", function()

    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    nsDbc4.settings.framesMove = nsDbc4.settings.framesMove or {
        frames = {},
        captureDelay = 5,
    }
    local db = nsDbc4.settings.framesMove
    db.frames = db.frames or {}
    db.captureDelay = db.captureDelay or 5

    -- ========================================================================
    -- Отладка: подробный лог
    -- ========================================================================
    local debugEnabled = false
    local LOG_PREFIX = "|cFF66CCFF[FCMOVE]|r "

    local function L(fmt, ...)
        if debugEnabled then
            print(LOG_PREFIX .. string.format(fmt, ...))
        end
    end

    local function NameOf(obj)
        if not obj then return "nil" end
        if obj.GetName then
            local n = obj:GetName()
            if n and n ~= "" then return n end
        end
        if obj.GetObjectType then
            return "<" .. tostring(obj:GetObjectType()) .. ">"
        end
        return "<obj>"
    end

    -- ========================================================================
    -- Утилиты геометрии
    -- ========================================================================
    local function CaptureGeometry(frame)
        if not frame then return nil end
        local g = { points = {} }
        local n = frame.GetNumPoints and frame:GetNumPoints() or 0
        for i = 1, n do
            local p, relTo, rp, x, y = frame:GetPoint(i)
            if p then
                table.insert(g.points, {
                    point      = p,
                    relToName  = (relTo and relTo.GetName and relTo:GetName()) or nil,
                    relToType  = (relTo and relTo.GetObjectType and relTo:GetObjectType()) or nil,
                    relPoint   = rp or "CENTER",
                    x          = x or 0,
                    y          = y or 0,
                })
            end
        end
        -- дублируем первую точку для совместимости со старым форматом
        local first = g.points[1]
        if first then
            g.point     = first.point
            g.relToName = first.relToName
            g.relPoint  = first.relPoint
            g.x         = first.x
            g.y         = first.y
        end
        g.width  = frame.GetWidth  and frame:GetWidth()
        g.height = frame.GetHeight and frame:GetHeight()
        g.scale  = frame.GetScale  and frame:GetScale()
        L("CaptureGeometry: %s -> %d point(s), size=%sx%s scale=%s",
            NameOf(frame), #g.points, tostring(g.width), tostring(g.height), tostring(g.scale))
        return g
    end

    local function FormatGeometry(g)
        if not g then return "nil" end
        local parts = {}
        if g.points then
            for i, pt in ipairs(g.points) do
                parts[#parts+1] = string.format(
                    "pt[%d]=%s->%s.%s(%.1f,%.1f)",
                    i, tostring(pt.point), tostring(pt.relToName or "<anon>"),
                    tostring(pt.relPoint), pt.x, pt.y)
            end
        end
        if g.width or g.height then
            parts[#parts+1] = string.format("size=%sx%s", tostring(g.width), tostring(g.height))
        end
        if g.scale then
            parts[#parts+1] = "scale=" .. tostring(g.scale)
        end
        return table.concat(parts, " | ")
    end

    local function DumpGeometry(frame, label)
        if not frame then
            L("%s: frame=nil", label); return
        end
        L("%s: object=%s key=%s", label, NameOf(frame), tostring(GetObjectKey(frame)))
        L("  size=%sx%s scale=%s",
            tostring(frame:GetWidth()), tostring(frame:GetHeight()), tostring(frame:GetScale()))
        local n = frame.GetNumPoints and frame:GetNumPoints() or 0
        L("  numPoints=%d", n)
        for i = 1, n do
            local p, relTo, rp, x, y = frame:GetPoint(i)
            L("    pt[%d]: %s -> %s.%s  x=%.1f y=%.1f",
                i, tostring(p), NameOf(relTo), tostring(rp), x or 0, y or 0)
        end
    end

    local function DebugCompare(frame, key, where)
        if not debugEnabled or not frame then return end
        local nowG  = CaptureGeometry(frame)
        local data  = key and db.frames[key]
        local savedG = data and data.geometry or nil
        L("%s | %s", where or "?", NameOf(frame))
        L("  now:   %s", FormatGeometry(nowG))
        L("  saved: %s", FormatGeometry(savedG))
    end

    -- ========================================================================
    -- Общие утилиты
    -- ========================================================================
    local function IsUsableRegion(region)
        if not region then return false end
        if region.IsForbidden and region:IsForbidden() then return false end
        return true
    end

    local function NormalizeToFrame(region)
        if not IsUsableRegion(region) then return nil end
        if region.IsObjectType and region:IsObjectType("Frame") then return region end
        if region.GetParent then return NormalizeToFrame(region:GetParent()) end
        return nil
    end

    local function GetMouseFrame()
        local focus
        if GetMouseFoci then
            local foci = GetMouseFoci()
            if foci and foci[1] then focus = foci[1] end
        elseif GetMouseFocus then
            focus = GetMouseFocus()
        end
        local frame = NormalizeToFrame(focus)
        if not frame then return nil end
        if frame == WorldFrame or frame == UIParent then return nil end
        return frame
    end

    local function DebugFrame(frame, label)
        if not debugEnabled or not frame then return end
        local name    = frame.GetName and frame:GetName() or "nil"
        local otype   = frame.GetObjectType and frame:GetObjectType() or "?"
        local movable = frame.IsMovable and tostring(frame:IsMovable()) or "?"
        L("%s: name=%s type=%s movable=%s",
            label or "frame", tostring(name), tostring(otype), movable)
    end

    local function DebugChain(frame)
        if not debugEnabled or not frame then return end
        local i, cur = 0, frame
        while cur and i < 10 do
            local name    = cur.GetName and cur:GetName() or "nil"
            local otype   = cur.GetObjectType and cur:GetObjectType() or "?"
            local movable = cur.IsMovable and tostring(cur:IsMovable()) or "?"
            L("  chain[%d]: %s (%s) movable=%s",
                i, tostring(name), tostring(otype), movable)
            cur = cur.GetParent and cur:GetParent() or nil
            i = i + 1
        end
    end

    local function GetObjectKey(frame)
        if not frame then return nil end
        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        local path = {}
        local current = frame
        while current do
            local parent = current.GetParent and current:GetParent()
            if not parent then break end
            local children = { parent:GetChildren() }
            local index
            for i, child in ipairs(children) do
                if child == current then index = i; break end
            end
            if not index then return nil end
            table.insert(path, 1, index)
            if parent.GetName then
                local pname = parent:GetName()
                if pname and pname ~= "" then
                    return pname .. "|FCChild|" .. table.concat(path, ",")
                end
            end
            current = parent
        end
        return nil
    end

    local function GetFrameByKey(key)
        if not key or type(key) ~= "string" then return nil end
        local direct = _G[key]
        if direct then
            local frame = NormalizeToFrame(direct)
            if frame then return frame end
        end
        local base, path = key:match("^(.-)|FCChild|(.+)$")
        if not base or not path then return nil end
        local current = _G[base]
        if not current or not current.GetChildren then return nil end
        for indexText in path:gmatch("([^,]+)") do
            local index = tonumber(indexText)
            if not index then return nil end
            local children = { current:GetChildren() }
            current = children[index]
            if not current then return nil end
        end
        return NormalizeToFrame(current)
    end

    local function GetObjectDisplayName(frame)
        if not frame then return "нет объекта" end
        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end
        local otype  = frame.GetObjectType and frame:GetObjectType() or "Frame"
        local parent = frame.GetParent and frame:GetParent()
        if parent and parent.GetName then
            local pname = parent:GetName()
            if pname and pname ~= "" then return otype .. " внутри " .. pname end
        end
        return otype
    end

    -- ========================================================================
    -- Применение / восстановление геометрии
    -- ========================================================================
    local function ResolveRelTo(pt)
        if pt.relToName and _G[pt.relToName] then return _G[pt.relToName] end
        return UIParent
    end

    local function ApplyGeometry(frame, g, ctx)
        if not frame or not g then
            L("ApplyGeometry[%s]: frame/g is nil (frame=%s g=%s)",
                tostring(ctx), tostring(frame ~= nil), tostring(g ~= nil))
            return
        end
        L("ApplyGeometry[%s] START for %s", tostring(ctx), NameOf(frame))
        DumpGeometry(frame, "  before")

        -- 1) сначала точки привязки
        if g.points and #g.points > 0 and frame.ClearAllPoints and frame.SetPoint then
            frame:ClearAllPoints()
            for i, pt in ipairs(g.points) do
                local relTo = ResolveRelTo(pt)
                frame:SetPoint(pt.point, relTo, pt.relPoint, pt.x, pt.y)
                L("  SetPoint[%d] %s -> %s.%s (%.1f, %.1f)",
                    i, pt.point, NameOf(relTo), pt.relPoint, pt.x, pt.y)
            end
        elseif g.point and frame.ClearAllPoints and frame.SetPoint then
            -- старый формат без points
            local relTo = (g.relToName and _G[g.relToName]) or UIParent
            frame:ClearAllPoints()
            frame:SetPoint(g.point, relTo, g.relPoint, g.x, g.y)
            L("  SetPoint (legacy) %s -> %s.%s (%.1f, %.1f)",
                g.point, NameOf(relTo), g.relPoint, g.x, g.y)
        else
            L("  no points to apply")
        end

        -- 2) размер
        if g.width and g.height and frame.SetSize then
            frame:SetSize(g.width, g.height)
            L("  SetSize(%s, %s)", g.width, g.height)
        end

        -- 3) scale — только если отличается от текущего!
        if g.scale and frame.SetScale and frame:GetScale() ~= g.scale then
            frame:SetScale(g.scale)
            L("  SetScale(%s)", g.scale)
        end

        DumpGeometry(frame, "  after")
    end

    local function ApplyPositionByKey(key)
        L("ApplyPositionByKey: key=%s", tostring(key))
        local frame = GetFrameByKey(key)
        if not frame then
            L("  !! frame NOT FOUND for key=%s", tostring(key))
            return false
        end
        local data = db.frames[key]
        if not data or not data.geometry then
            L("  !! no saved geometry for key=%s", tostring(key))
            return false
        end
        ApplyGeometry(frame, data.geometry, "apply:" .. tostring(key))
        return true
    end

    local function ResetFrameByKey(key)
        L("ResetFrameByKey: key=%s", tostring(key))
        local frame = GetFrameByKey(key)
        local data  = db.frames[key]
        if frame and data and data.defaultGeometry then
            ApplyGeometry(frame, data.defaultGeometry, "reset:" .. tostring(key))
        else
            L("  !! reset skipped (frame=%s data=%s defaultGeom=%s)",
                tostring(frame ~= nil), tostring(data ~= nil),
                tostring(data and data.defaultGeometry ~= nil))
        end
        db.frames[key] = nil
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ResetAll()
        for key in pairs(db.frames) do
            local frame = GetFrameByKey(key)
            local data  = db.frames[key]
            if frame and data and data.defaultGeometry then
                ApplyGeometry(frame, data.defaultGeometry, "resetall:" .. tostring(key))
            else
                L("ResetAll: skip %s (frame=%s defaultGeom=%s)",
                    tostring(key), tostring(frame ~= nil),
                    tostring(data and data.defaultGeometry ~= nil))
            end
        end
        db.frames = {}
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ApplyAllSaved()
        local total = 0
        for _ in pairs(db.frames) do total = total + 1 end
        L("===== ApplyAllSaved: %d frame(s) =====", total)
        local ok, fail = 0, 0
        for key in pairs(db.frames) do
            if ApplyPositionByKey(key) then ok = ok + 1 else fail = fail + 1 end
        end
        L("===== ApplyAllSaved DONE: ok=%d fail=%d =====", ok, fail)
    end

    -- ========================================================================
    -- Режим перемещения
    -- ========================================================================
    local moveOverlay

    local function SaveCurrentPosition(frame, key)
        if not frame or not key then return end
        local data = db.frames[key]
        if not data then return end
        data.geometry = CaptureGeometry(frame)
        L("SaveCurrentPosition: key=%s geometry=%s", tostring(key), FormatGeometry(data.geometry))
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function StopMoveMode()
        if moveOverlay then
            moveOverlay:Hide()
            moveOverlay:SetParent(nil)
            moveOverlay = nil
        end
        L("StopMoveMode")
        print("|cFF00FF00NSQC4:|r режим перемещения выключен.")
    end

    local function StartMoveForFrame(frame)
        if not frame then return end

        local target = frame

        L("=== StartMoveForFrame ===")
        DebugFrame(frame, "выбранный")
        DebugChain(frame)

        local key = GetObjectKey(target)
        if not key then
            print("|cFFFFFF00NSQC4:|r объект без имени — перемещение не сохранится.")
        end

        if key then
            db.frames[key] = db.frames[key] or {}
            local data = db.frames[key]
            if not data.defaultGeometry then
                data.defaultGeometry = CaptureGeometry(target)
                L("defaultGeometry captured: key=%s geom=%s",
                    tostring(key), FormatGeometry(data.defaultGeometry))
            end
        end

        if moveOverlay then
            moveOverlay:Hide()
            moveOverlay:SetParent(nil)
        end

        DebugCompare(target, key, "StartMoveForFrame BEFORE overlay: " .. tostring(key))

        local ov = CreateFrame("Frame", nil, target)
        ov:SetAllPoints(target)
        ov:EnableMouse(true)
        ov:SetFrameStrata("TOOLTIP")
        ov:SetFrameLevel(200)

        local hl = ov:CreateTexture(nil, "OVERLAY")
        hl:SetAllPoints(true)
        hl:SetTexture(0.2, 1, 0.2, 0.2)

        local tip = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        tip:SetPoint("TOP", ov, "BOTTOM", 0, -5)
        tip:SetText("|cFF00FF00Тяни ЛКМ|r |cFFFFFF00/|r |cFFFF8080ПКМ отмена|r")
        tip:SetTextColor(1, 1, 1)

        ov:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                DebugCompare(target, key, "OnMouseDown BEFORE: " .. tostring(key))
                target:SetMovable(true)
                target:EnableMouse(true)
                target:StartMoving()
                DebugCompare(target, key, "OnMouseDown AFTER StartMoving: " .. tostring(key))
            elseif button == "RightButton" then
                target:StopMovingOrSizing()
                DebugCompare(target, key, "OnMouseDown RB AFTER Stop: " .. tostring(key))
                if key then ApplyPositionByKey(key) end
                StopMoveMode()
            end
        end)

        ov:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                target:StopMovingOrSizing()
                DebugCompare(target, key, "OnMouseUp AFTER Stop: " .. tostring(key))
                SaveCurrentPosition(target, key)
                StopMoveMode()
            end
        end)

        moveOverlay = ov
        print("|cFF00FF00NSQC4:|r перемещение активно. Тяни ЛКМ, ПКМ — отмена.")
    end

    -- ========================================================================
    -- Счётчик и захват
    -- ========================================================================
    local countdownFrame
    local countdownTicker
    local countdownValue = 0
    local captureToken = 0

    local function StartCountdown(callback)
        if countdownTicker then
            countdownTicker:SetScript("OnUpdate", nil)
            countdownTicker = nil
        end
        if countdownFrame then
            countdownFrame:Hide()
            countdownFrame = nil
        end

        captureToken = captureToken + 1
        local token = captureToken
        local delay = db.captureDelay or 5

        local f = CreateFrame("Frame", "NSQC4MoveCountdown", UIParent)
        f:SetSize(400, 50)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("TOOLTIP")

        local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        txt:SetPoint("CENTER")
        txt:SetText("Наведите мышь на фрейм: " .. delay)

        countdownValue = delay
        countdownFrame = f

        local ticker = CreateFrame("Frame")
        ticker.last = GetTime()
        ticker:SetScript("OnUpdate", function(self)
            if token ~= captureToken then
                self:SetScript("OnUpdate", nil)
                if countdownFrame then countdownFrame:Hide() end
                return
            end
            if GetTime() - self.last >= 1 then
                self.last = GetTime()
                countdownValue = countdownValue - 1
                if countdownValue > 0 then
                    txt:SetText("Наведите мышь на фрейм: " .. countdownValue)
                else
                    self:SetScript("OnUpdate", nil)
                    local frame = GetMouseFrame()
                    if frame then
                        txt:SetText("Захвачено: " .. GetObjectDisplayName(frame))
                        L("Countdown captured frame: %s", NameOf(frame))
                        callback(frame)
                    else
                        txt:SetText("Фрейм не найден!")
                        L("Countdown: frame NOT FOUND")
                    end
                    local hideTimer = CreateFrame("Frame")
                    hideTimer.last = GetTime()
                    hideTimer:SetScript("OnUpdate", function(self2)
                        if GetTime() - self2.last >= 1.5 then
                            self2:SetScript("OnUpdate", nil)
                            if countdownFrame then countdownFrame:Hide() end
                            countdownFrame = nil
                        end
                    end)
                end
            end
        end)
        countdownTicker = ticker
    end

    -- ========================================================================
    -- Главное окно
    -- ========================================================================
    local mainFrame

    local function CreateMainFrame()
        if mainFrame then return mainFrame end

        local f = CreateFrame("Frame", "NSQC4FramesMoveFrame", UIParent)
        f:SetSize(480, 420)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
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
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)
        f:Hide()

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Перемещение фреймов")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local settingsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        settingsBtn:SetSize(24, 24)
        settingsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -5, 0)
        settingsBtn:SetText("*")
        settingsBtn:SetScript("OnClick", function() NSQC4.FramesMove_OpenSettings() end)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(160, 22)
        addBtn:SetPoint("TOPLEFT", 20, -45)
        addBtn:SetText("Добавить фрейм")
        addBtn:SetScript("OnClick", function()
            StartCountdown(function(frame) StartMoveForFrame(frame) end)
        end)

        local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        resetBtn:SetSize(140, 22)
        resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 5, 0)
        resetBtn:SetText("Сбросить всё")
        resetBtn:SetScript("OnClick", function() ResetAll() end)

        local scroll = CreateFrame("ScrollFrame", "NSQC4FramesMoveScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -80)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        f.scroll = scroll

        local child = CreateFrame("Frame", "NSQC4FramesMoveList", scroll)
        child:SetSize(400, 10)
        scroll:SetScrollChild(child)
        f.list = child

        mainFrame = f
        return f
    end

    function NSQC4.FramesMove_RefreshList()
        local f = mainFrame
        if not f or not f.list then return end

        local child, scroll = f.list, f.scroll

        for _, c in ipairs({ child:GetChildren() }) do
            c:Hide()
        end

        local keys = {}
        for k in pairs(db.frames) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        local ENTRY_H = 26
        child:SetHeight(math.max(#keys * ENTRY_H, 10))

        for i, key in ipairs(keys) do
            local data    = db.frames[key]
            local frame   = GetFrameByKey(key)
            local display = frame and GetObjectDisplayName(frame) or key

            local row = CreateFrame("Frame", nil, child)
            row:SetWidth(400)
            row:SetHeight(ENTRY_H)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * ENTRY_H))
            row:EnableMouse(true)

            local nameLbl = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            nameLbl:SetPoint("LEFT", 5, 0)
            nameLbl:SetWidth(260)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetText(display)

            local xBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            xBtn:SetSize(24, 22)
            xBtn:SetPoint("RIGHT", -5, 0)
            xBtn:SetText("X")
            xBtn:SetScript("OnClick", function() ResetFrameByKey(key) end)

            local moveBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            moveBtn:SetSize(60, 22)
            moveBtn:SetPoint("RIGHT", xBtn, "LEFT", -5, 0)
            moveBtn:SetText("Двигать")
            moveBtn:SetScript("OnClick", function()
                if frame then StartMoveForFrame(frame) end
            end)

            local upBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            upBtn:SetSize(24, 22)
            upBtn:SetPoint("RIGHT", moveBtn, "LEFT", -5, 0)
            upBtn:SetText("^")
            upBtn:SetScript("OnClick", function()
                local base = frame or GetFrameByKey(key)
                local parent = base and base.GetParent and base:GetParent()
                if not parent or parent == UIParent or parent == WorldFrame then
                    print("|cFFFFFF00NSQC4:|r у объекта нет подходящего родителя.")
                    return
                end
                local pkey = GetObjectKey(parent)
                if not pkey then
                    print("|cFFFFFF00NSQC4:|r родитель без имени — не сохранить.")
                    return
                end
                db.frames[pkey] = db.frames[pkey] or {}
                local pdata = db.frames[pkey]
                if not pdata.defaultGeometry then
                    pdata.defaultGeometry = CaptureGeometry(parent)
                    L("parent defaultGeometry captured: key=%s geom=%s",
                        tostring(pkey), FormatGeometry(pdata.defaultGeometry))
                end
                print("|cFF00FF00NSQC4:|r родитель добавлен в список: " .. GetObjectDisplayName(parent))
                DebugCompare(parent, pkey, "^ parent BEFORE: " .. pkey)
                StartMoveForFrame(parent)
                DebugCompare(parent, pkey, "^ parent AFTER: " .. pkey)
                NSQC4.FramesMove_RefreshList()
            end)

            row:SetScript("OnEnter", function()
                nameLbl:SetTextColor(1, 1, 0)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText("Объект: " .. key, 1, 1, 1)
                if data and data.geometry then
                    GameTooltip:AddLine("Сохранено: " .. FormatGeometry(data.geometry), 0, 1, 0)
                end
                if data and data.defaultGeometry then
                    GameTooltip:AddLine("По умолчанию: " .. FormatGeometry(data.defaultGeometry), 0.7, 0.7, 1)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                nameLbl:SetTextColor(1, 1, 1)
                GameTooltip:Hide()
            end)
        end

        scroll:UpdateScrollChildRect()
    end

    -- ========================================================================
    -- Настройки
    -- ========================================================================
    local settingsFrame

    function NSQC4.FramesMove_OpenSettings()
        if settingsFrame then
            settingsFrame:Raise()
            settingsFrame:Show()
            return
        end

        local f = CreateFrame("Frame", "NSQC4FramesMoveSettings", UIParent)
        f:SetSize(320, 180)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
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
        f:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self:StopMovingOrSizing() end
        end)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -15)
        title:SetText("Настройки: Перемещение")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 20, -50)
        lbl:SetText("Время до применения: " .. (db.captureDelay or 5) .. " сек")

        local slider = CreateFrame("Slider", "NSQC4MoveSettingsSlider", f, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 20, -80)
        slider:SetWidth(250)
        slider:SetHeight(20)
        slider:SetMinMaxValues(3, 15)
        slider:SetValueStep(1)
        slider:SetValue(db.captureDelay or 5)

        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value)
            lbl:SetText("Время до применения: " .. value .. " сек")
        end)

        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetSize(100, 22)
        saveBtn:SetPoint("BOTTOM", 0, 15)
        saveBtn:SetText("Сохранить")
        saveBtn:SetScript("OnClick", function()
            db.captureDelay = math.floor(slider:GetValue())
            L("Settings saved: captureDelay=%d", db.captureDelay)
            f:Hide()
        end)

        settingsFrame = f
        f:Raise()
        f:Show()
    end

    -- ========================================================================
    -- Диспетчер слэш-команды
    -- ========================================================================
    NSQC4._FramesMoveDispatch = function(msg)
        msg = (msg or ""):lower()

        if msg == "cancel" then
            captureToken = captureToken + 1
            if countdownFrame then countdownFrame:Hide(); countdownFrame = nil end
            StopMoveMode()
            print("|cFFFFFF00NSQC4:|r захват отменён.")
        elseif msg == "apply" then
            ApplyAllSaved()
            print("|cFF00FF00NSQC4:|r позиции применены.")
        elseif msg == "debug" then
            debugEnabled = not debugEnabled
            print("|cFF00FF00NSQC4:|r отладка " .. (debugEnabled and "включена" or "выключена") .. ".")
            if debugEnabled then
                local total = 0
                for k in pairs(db.frames) do
                    total = total + 1
                    local d = db.frames[k]
                    L("db entry: key=%s", tostring(k))
                    L("  saved:   %s", FormatGeometry(d.geometry))
                    L("  default: %s", FormatGeometry(d.defaultGeometry))
                end
                L("db total entries: %d", total)
            end
        elseif msg == "list" then
            debugEnabled = true
            print(LOG_PREFIX .. "===== DB DUMP =====")
            local total = 0
            for k, d in pairs(db.frames) do
                total = total + 1
                print(LOG_PREFIX .. "key=" .. tostring(k))
                print(LOG_PREFIX .. "  saved:   " .. FormatGeometry(d.geometry))
                print(LOG_PREFIX .. "  default: " .. FormatGeometry(d.defaultGeometry))
            end
            print(LOG_PREFIX .. "total: " .. total)
        elseif msg == "applynow" then
            -- принудительно применить с полной отладкой
            debugEnabled = true
            ApplyAllSaved()
        else
            local f = CreateMainFrame()
            if f:IsShown() then
                f:Hide()
            else
                f:Raise()
                f:Show()
                NSQC4.FramesMove_RefreshList()
            end
        end
    end

    -- ========================================================================
    -- Кнопка на панели слэшей
    -- ========================================================================
    if NSQC4.SlashPanel_RegisterButton then
        NSQC4.SlashPanel_RegisterButton("M", "/ns_fcmove", "Перемещение фреймов", function()
            SlashCmdList["NS_FCMOVE"]("")
        end)
    end

    -- ========================================================================
    -- Восстановление при входе в мир
    -- ========================================================================
    -- Модули грузятся уже после логина, поэтому PLAYER_LOGIN не нужен.
    -- Применяем на PLAYER_ENTERING_WORLD и повторно с задержкой,
    -- чтобы перебить поздний layout от Blizzard/аддонов.
    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    restoreFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
        self:UnregisterEvent(event)
        L("PLAYER_ENTERING_WORLD (login=%s reload=%s) -> schedule apply",
            tostring(isInitialLogin), tostring(isReloadingUi))

        -- Мгновенная попытка — вдруг всё готово
        ApplyAllSaved()

        -- Плюс повторы: Blizzard/аддоны могут перестроить фреймы позже
        local delays = { 0.5, 2, 5 }
        for _, d in ipairs(delays) do
            local t = CreateFrame("Frame")
            local elapsed = 0
            t:SetScript("OnUpdate", function(self2, dt)
                elapsed = elapsed + dt
                if elapsed >= d then
                    self2:SetScript("OnUpdate", nil)
                    L("delayed apply (+%.1fs)", d)
                    ApplyAllSaved()
                end
            end)
        end
    end)

    -- На случай смены масштаба UI / разрешения
    local scaleWatch = CreateFrame("Frame")
    scaleWatch:RegisterEvent("UI_SCALE_CHANGED")
    scaleWatch:RegisterEvent("DISPLAY_SIZE_CHANGED")
    scaleWatch:SetScript("OnEvent", function(self, event)
        L("%s -> delayed apply", tostring(event))
        local t = CreateFrame("Frame")
        local elapsed = 0
        t:SetScript("OnUpdate", function(self2, dt)
            elapsed = elapsed + dt
            if elapsed >= 1 then
                self2:SetScript("OnUpdate", nil)
                ApplyAllSaved()
            end
        end)
    end)

    -- ========================================================================
    -- Метаданные
    -- ========================================================================
    NSQC4.SetModuleMeta("ui_frames_move", {
        label   = "Перемещение",
        tooltip = "Перемещение любых фреймов. Команда /ns_fcmove.",
        order   = 300,
    })

end)