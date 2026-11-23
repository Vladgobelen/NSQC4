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
    -- Отладка
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

    local function IsProtectedFrame(frame)
        if not frame then return false end
        if frame == UIParent or frame == WorldFrame then return true end
        if frame.GetName then
            local n = frame:GetName()
            if n == "MainMenuBar" or n == "UIParent" or n == "WorldFrame" then return true end
        end
        if frame.IsProtected and frame:IsProtected() then return true end
        return false
    end

    -- Стабильный ключ: имя, либо путь по ТИПАМ детей от именованного родителя.
    -- Индекс в GetChildren() НЕ используется, т.к. порядок нестабилен.
    local function GetObjectKey(frame)
        if not frame then return nil end

        if frame.GetName then
            local name = frame:GetName()
            if name and name ~= "" then return name end
        end

        -- Для анонимных — строим путь вида ParentName|FCChild|Frame|Frame|Texture
        local chain = {}
        local current = frame
        local guard = 0
        while current do
            guard = guard + 1
            if guard > 20 then return nil end

            local otype = current.GetObjectType and current:GetObjectType() or "?"
            if current.GetName then
                local cname = current:GetName()
                if cname and cname ~= "" then
                    if #chain == 0 then
                        return cname
                    end
                    return cname .. "|FCChild|" .. table.concat(chain, "|")
                end
            end
            table.insert(chain, 1, otype)
            current = current.GetParent and current:GetParent() or nil
        end
        return nil
    end

    -- Резолв по пути типов: проходим по детям, ищем первый с нужным типом,
    -- которого ещё нет в visited (чтобы не зациклиться и корректно различать siblings).
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

        local visited = {}
        for typeName in path:gmatch("([^|]+)") do
            local children = { current:GetChildren() }
            local found
            for _, child in ipairs(children) do
                if not visited[child]
                   and child.GetObjectType
                   and child:GetObjectType() == typeName then
                    found = child
                    break
                end
            end
            if not found then
                -- Иногда путь короче, чем фактический (например, фрейм вложен глубже).
                -- Тогда ищем рекурсивно среди всех потомков.
                local function deepFind(node)
                    local kids = { node:GetChildren() }
                    for _, k in ipairs(kids) do
                        if not visited[k] and k.GetObjectType and k:GetObjectType() == typeName then
                            return k
                        end
                        local r = deepFind(k)
                        if r then return r end
                    end
                    return nil
                end
                found = deepFind(current)
            end
            if not found then return nil end
            visited[found] = true
            current = found
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

    -- ========================================================================
    -- Утилиты геометрии
    -- ========================================================================
    local function CaptureGeometry(frame)
        if not frame then return nil end
        local g = { points = {} }
        
        -- Получаем абсолютную позицию на экране
        local left = frame:GetLeft()
        local top = frame:GetTop()
        local width = frame:GetWidth()
        local height = frame:GetHeight()
        
        -- Пересчитываем в координаты от TOPLEFT UIParent
        local uiLeft = UIParent:GetLeft()
        local uiTop = UIParent:GetTop()
        
        local absX = 0
        local absY = 0
        
        if left and top and uiLeft and uiTop then
            absX = left - uiLeft
            absY = top - uiTop
        end
        
        -- Если фрейм не отображается на экране, берем сохраненные данные
        -- Но для этого метода мы сохраняем только абсолютные координаты от UIParent
        table.insert(g.points, {
            point = "TOPLEFT",
            relToKey = "UIParent",
            relToName = "UIParent",
            relToType = "Frame",
            relPoint = "TOPLEFT",
            x = absX,
            y = absY,
        })

        g.width  = frame.GetWidth  and math.floor(width  + 0.5) or nil
        g.height = frame.GetHeight and math.floor(height + 0.5) or nil
        g.scale  = frame.GetScale  and frame:GetScale()
        
        L("CAPTURE %s -> absolute TOPLEFT UIParent (%f, %f), size=%sx%s",
            NameOf(frame), absX, absY, tostring(g.width), tostring(g.height))
            
        return g
    end

    local function FormatGeometry(g)
        if not g then return "nil" end
        local parts = {}
        if g.points then
            for i, pt in ipairs(g.points) do
                parts[#parts+1] = string.format(
                    "pt[%d]=%s->%s[%s].%s(%.1f,%.1f)",
                    i, tostring(pt.point),
                    tostring(pt.relToName or "<anon>"),
                    tostring(pt.relToKey or "?"),
                    tostring(pt.relPoint), pt.x, pt.y)
            end
        end
        if g.width or g.height then
            parts[#parts+1] = string.format("size=%.0fx%.0f", g.width or 0, g.height or 0)
        end
        if g.scale then
            parts[#parts+1] = "scale=" .. tostring(g.scale)
        end
        return table.concat(parts, " | ")
    end

    local function GeometryEqual(a, b)
        if not a or not b then return false end
        if #a.points ~= #b.points then return false end
        for i = 1, #a.points do
            local x, y = a.points[i], b.points[i]
            if x.point ~= y.point or x.relPoint ~= y.relPoint then return false end
            if x.relToKey ~= y.relToKey then return false end
            if math.abs((x.x or 0) - (y.x or 0)) > 0.5 then return false end
            if math.abs((x.y or 0) - (y.y or 0)) > 0.5 then return false end
        end
        if (a.width or 0) ~= (b.width or 0) then return false end
        if (a.height or 0) ~= (b.height or 0) then return false end
        if math.abs((a.scale or 1) - (b.scale or 1)) > 0.001 then return false end
        return true
    end

    -- ========================================================================
    -- Применение / восстановление геометрии
    -- ========================================================================
    -- Возвращает frame или nil. Больше НЕ падает в UIParent молча.
    local function ResolveRelTo(pt)
        if pt.relToKey then
            local byKey = GetFrameByKey(pt.relToKey)
            if byKey then return byKey end
            L("  !! relToKey NOT resolved: %s", tostring(pt.relToKey))
        end
        if pt.relToName then
            local byName = _G[pt.relToName]
            if byName then
                local f = NormalizeToFrame(byName)
                if f then return f end
            end
        end
        if IsProtectedFrame(pt) then
            return UIParent
        end
        return nil
    end

    local function ApplyGeometry(frame, g, ctx)
        if not frame or not g then return false end
        
        L("APPLY[%s] START for %s", tostring(ctx), NameOf(frame))
        
        -- Защита от боя: если в бою, двигаем только безопасные фреймы
        if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
            L("  !! abort: protected frame in combat")
            return false
        end

        local wasMovable = frame.IsMovable and frame:IsMovable()
        if frame.SetMovable and not InCombatLockdown() then 
            frame:SetMovable(true) 
        end

        if g.points and #g.points > 0 and frame.ClearAllPoints and frame.SetPoint then
            frame:ClearAllPoints()
            for i, pt in ipairs(g.points) do
                local relTo = _G[pt.relToName] or UIParent -- fallback
                if pt.relToKey == "UIParent" then relTo = UIParent end
                
                if relTo then
                    frame:SetPoint(pt.point, relTo, pt.relPoint, pt.x, pt.y)
                    L("  SetPoint[%d] %s -> %s.%s (%.1f, %.1f)", i, pt.point, NameOf(relTo), pt.relPoint, pt.x, pt.y)
                end
            end
        end

        if g.width and g.height and frame.SetSize then
            frame:SetSize(g.width, g.height)
        end

        if g.scale and frame.SetScale and frame:GetScale() ~= g.scale then
            frame:SetScale(g.scale)
        end

        if frame.SetMovable and wasMovable ~= nil and not InCombatLockdown() then
            frame:SetMovable(wasMovable)
        end

        L("APPLY[%s] DONE", tostring(ctx))
        return true
    end

    local function ApplyPositionByKey(key, silent)
        L("APPLY key=%s", tostring(key))
        local frame = GetFrameByKey(key)
        if not frame then
            if not silent then L("  !! frame NOT FOUND for key=%s", tostring(key)) end
            return false
        end
        local data = db.frames[key]
        if not data or not data.geometry then
            if not silent then L("  !! no saved geometry for key=%s", tostring(key)) end
            return false
        end
        return ApplyGeometry(frame, data.geometry, "apply:" .. tostring(key))
    end

    local function ResetFrameByKey(key)
        L("RESET key=%s", tostring(key))
        local frame = GetFrameByKey(key)
        local data  = db.frames[key]
        if frame and data and data.defaultGeometry then
            ApplyGeometry(frame, data.defaultGeometry, "reset:" .. tostring(key))
        end
        db.frames[key] = nil
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ResetAll()
        L("RESET ALL")
        for key, data in pairs(db.frames) do
            local frame = GetFrameByKey(key)
            if frame and data.defaultGeometry then
                ApplyGeometry(frame, data.defaultGeometry, "resetall:" .. tostring(key))
            end
        end
        db.frames = {}
        if NSQC4.FramesMove_RefreshList then NSQC4.FramesMove_RefreshList() end
    end

    local function ApplyAllSaved(reason)
        local total, ok, fail = 0, 0, 0
        for _ in pairs(db.frames) do total = total + 1 end
        for key in pairs(db.frames) do
            if ApplyPositionByKey(key, true) then ok = ok + 1 else fail = fail + 1 end
        end
        L("===== APPLY ALL (%s): total=%d ok=%d fail=%d =====",
            tostring(reason or "?"), total, ok, fail)
    end

    -- ========================================================================
    -- Краткий отчёт "сохранено vs реально"
    -- ========================================================================
    local function ShortPoint(pt)
        return string.format("%s[%s]%s(%.1f,%.1f)",
            tostring(pt.point),
            tostring(pt.relToKey or pt.relToName or "?"),
            tostring(pt.relPoint),
            pt.x or 0, pt.y or 0)
    end

    local function ReportKey(key)
        local data = db.frames[key]
        local frame = GetFrameByKey(key)
        print(LOG_PREFIX .. "key=" .. tostring(key))

        if not frame then
            print(LOG_PREFIX .. "  |cFFFF6060frame НЕ найден|r (объект отсутствует в UI)")
            if data then
                print(LOG_PREFIX .. "  saved:   " .. FormatGeometry(data.geometry))
            end
            return
        end

        print(LOG_PREFIX .. "  now:     " .. FormatGeometry(CaptureGeometry(frame)))
        if data and data.geometry then
            print(LOG_PREFIX .. "  saved:   " .. FormatGeometry(data.geometry))
            local nowG = CaptureGeometry(frame)
            if GeometryEqual(nowG, data.geometry) then
                print(LOG_PREFIX .. "  |cFF00FF00OK (совпадает)|r")
            else
                print(LOG_PREFIX .. "  |cFFFFFF00MISMATCH|r")
                for i = 1, math.max(#nowG.points, #data.geometry.points) do
                    local a = data.geometry.points[i]
                    local b = nowG.points[i]
                    if a and b then
                        if math.abs((a.x or 0) - (b.x or 0)) > 0.5
                           or math.abs((a.y or 0) - (b.y or 0)) > 0.5
                           or a.point ~= b.point
                           or a.relPoint ~= b.relPoint then
                            print(LOG_PREFIX .. "    pt[" .. i .. "] saved=" .. ShortPoint(a)
                                .. " now=" .. ShortPoint(b))
                        end
                    elseif a then
                        print(LOG_PREFIX .. "    pt[" .. i .. "] saved=" .. ShortPoint(a) .. " now=<missing>")
                    elseif b then
                        print(LOG_PREFIX .. "    pt[" .. i .. "] saved=<missing> now=" .. ShortPoint(b))
                    end
                end
            end
        else
            print(LOG_PREFIX .. "  saved:   |cFFFF6060nil|r (позиция не сохранена)")
        end
        if data and data.defaultGeometry then
            print(LOG_PREFIX .. "  default: " .. FormatGeometry(data.defaultGeometry))
        end
    end

    local function ReportAll()
        local keys = {}
        for k in pairs(db.frames) do table.insert(keys, k) end
        table.sort(keys)
        print(LOG_PREFIX .. "===== REPORT: " .. #keys .. " фрейм(ов) =====")
        for _, key in ipairs(keys) do ReportKey(key) end
        print(LOG_PREFIX .. "===== END =====")
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
        L("SAVE key=%s geom=%s", tostring(key), FormatGeometry(data.geometry))
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
        local key = GetObjectKey(target)
        L("  key=%s", tostring(key))
        if not key then
            print("|cFFFFFF00NSQC4:|r объект без имени — перемещение не сохранится.")
        end

        if key then
            db.frames[key] = db.frames[key] or {}
            local data = db.frames[key]
            if not data.defaultGeometry then
                data.defaultGeometry = CaptureGeometry(target)
                L("DEFAULT captured: key=%s", tostring(key))
            end
        end

        if moveOverlay then
            moveOverlay:Hide()
            moveOverlay:SetParent(nil)
        end

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
                if target.SetMovable then target:SetMovable(true) end
                target:EnableMouse(true)
                target:StartMoving()
            elseif button == "RightButton" then
                target:StopMovingOrSizing()
                if key then ApplyPositionByKey(key) end
                StopMoveMode()
            end
        end)

        ov:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                target:StopMovingOrSizing()
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
                        callback(frame)
                    else
                        txt:SetText("Фрейм не найден!")
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
                end
                print("|cFF00FF00NSQC4:|r родитель добавлен: " .. GetObjectDisplayName(parent))
                StartMoveForFrame(parent)
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
            ApplyAllSaved("slash:apply")
            print("|cFF00FF00NSQC4:|r позиции применены.")
        elseif msg == "debug" or msg == "verify" then
            local prev = debugEnabled
            debugEnabled = true
            ReportAll()
            debugEnabled = prev
        elseif msg == "list" then
            local prev = debugEnabled
            debugEnabled = true
            ReportAll()
            debugEnabled = prev
        elseif msg == "applynow" then
            local prev = debugEnabled
            debugEnabled = true
            ApplyAllSaved("slash:applynow")
            ReportAll()
            debugEnabled = prev
        elseif msg == "on" then
            debugEnabled = true
            print("|cFF00FF00NSQC4:|r отладка включена.")
        elseif msg == "off" then
            debugEnabled = false
            print("|cFF00FF00NSQC4:|r отладка выключена.")
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
    -- Восстановление при входе в мир (несколько волн)
    -- ========================================================================
    local function DelayedApply(seconds, reason)
        local t = CreateFrame("Frame")
        local elapsed = 0
        t:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= seconds then
                self:SetScript("OnUpdate", nil)
                ApplyAllSaved(reason .. "+" .. seconds .. "s")
            end
        end)
    end

    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    restoreFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
        self:UnregisterEvent(event)
        L("PLAYER_ENTERING_WORLD (login=%s reload=%s)",
            tostring(isInitialLogin), tostring(isReloadingUi))
        ApplyAllSaved("PEW:immediate")
        DelayedApply(0.5, "PEW")
        DelayedApply(2,   "PEW")
        DelayedApply(5,   "PEW")
    end)

    -- Универсальный "переприменить после события" — для событий, которые меняют UI
    local function OnRelevantEvent(event)
        DelayedApply(0.3, event)
        DelayedApply(1.5, event)
    end

    local scaleWatch = CreateFrame("Frame")
    scaleWatch:RegisterEvent("UI_SCALE_CHANGED")
    scaleWatch:RegisterEvent("DISPLAY_SIZE_CHANGED")
    scaleWatch:SetScript("OnEvent", function(self, event)
        L("%s -> delayed apply", tostring(event))
        OnRelevantEvent(event)
    end)

    -- Пересоздание тотемов / смена спектра / смена action bar
    local uiWatch = CreateFrame("Frame")
    uiWatch:RegisterEvent("ADDON_LOADED")
    uiWatch:RegisterEvent("PLAYER_TOTEM_UPDATE")
    uiWatch:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    uiWatch:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    uiWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
    uiWatch:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then return end -- уже обработано выше
        L("%s (%s) -> delayed apply", tostring(event), tostring(arg1))
        OnRelevantEvent(event)
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