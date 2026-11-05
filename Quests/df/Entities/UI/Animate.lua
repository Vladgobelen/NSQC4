-- ============================================================================
-- NSQC4 / Quests / df / Entities / UI / Animate
-- Плавное передвижение иконки существа между клетками.
--
-- temp — на кнопке toIndex, слой ARTWORK/7 (слой существа).
-- Anchor в fromIndex прячется на время анимации.
--
-- Stop: обрывает анимацию и перерисовывает ОБЕ клетки.
-- StopAll: обрывает ВСЕ активные анимации (нужно при переключении этажа,
-- чтобы temp-текстуры старого этажа не висели на новом).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Animate = {}
    NSQC4.QuestsDfEntitiesAnimate = Animate

    Animate.DEBUG = false

    local function dbg(...)
        if Animate.DEBUG then print("|cff00ffff[ANIM]|r", ...) end
    end

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Animate: поле не загружено.")
        return
    end

    local active = {}
    local frame  = nil

    local function CellGeom(index)
        local f = QuestsField.frame
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not f or not btn then return nil end
        local fL, fB = f:GetLeft() or 0, f:GetBottom() or 0
        local bL, bB = btn:GetLeft() or 0, btn:GetBottom() or 0
        local w, h   = btn:GetWidth() or 0, btn:GetHeight() or 0
        return (bL - fL), (bB - fB), w, h
    end

    local function LayoutFor(anchorPos, expanded, left, bottom, cellW, cellH)
        if expanded then
            return "CENTER", left + cellW / 2, bottom + cellH / 2, cellW, cellH
        end
        local w, h = cellW / 3, cellH / 3
        local point, px, py
        if anchorPos == "TOPLEFT" then
            point, px, py = "TOPLEFT", left, bottom + cellH
        elseif anchorPos == "TOPCENTER" then
            point, px, py = "TOP", left + cellW / 2, bottom + cellH
        elseif anchorPos == "TOPRIGHT" then
            point, px, py = "TOPRIGHT", left + cellW, bottom + cellH
        elseif anchorPos == "MIDLEFT" then
            point, px, py = "LEFT", left, bottom + cellH / 2
        elseif anchorPos == "CENTER" then
            point, px, py = "CENTER", left + cellW / 2, bottom + cellH / 2
        elseif anchorPos == "MIDRIGHT" then
            point, px, py = "RIGHT", left + cellW, bottom + cellH / 2
        elseif anchorPos == "BOTLEFT" then
            point, px, py = "BOTTOMLEFT", left, bottom
        elseif anchorPos == "BOTCENTER" then
            point, px, py = "BOTTOM", left + cellW / 2, bottom
        elseif anchorPos == "BOTRIGHT" then
            point, px, py = "BOTTOMRIGHT", left + cellW, bottom
        else
            point, px, py = "TOPLEFT", left, bottom + cellH
        end
        return point, px, py, w, h
    end

    local function EnsureFrame()
        if frame then return frame end
        frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function() Animate:Tick() end)
        frame:Show()
        dbg("EnsureFrame: created and shown")
        return frame
    end

    local function RenderCell(index)
        if not index then return end
        local TerrainApi = NSQC4.QuestsDfTerrainUIApi
        if TerrainApi and TerrainApi.RenderCellFromStorage then
            TerrainApi:RenderCellFromStorage(index)
        end
    end

    local function RenderBoth(fromIndex, toIndex)
        if fromIndex and toIndex and fromIndex == toIndex then
            RenderCell(toIndex)
            return
        end
        RenderCell(fromIndex)
        RenderCell(toIndex)
    end

    local function HostFor(toIndex)
        local btn = QuestsField.cells and QuestsField.cells[toIndex]
        return btn or QuestsField.frame
    end

    function Animate:Start(id, opts, fromIndex, toIndex, duration)
        if not id or not opts or not opts.icon or not toIndex then
            dbg("Start: bad args", tostring(id), tostring(opts and opts.icon), tostring(toIndex))
            return false
        end
        if not duration or duration <= 0 then duration = 1 end

        if active[id] then
            if active[id].temp then active[id].temp:Hide() end
            active[id] = nil
        end

        local fromL, fromB, fromW, fromH = CellGeom(fromIndex)
        local toL,   toB,   toW,   toH   = CellGeom(toIndex)
        if not fromL or not toL then
            dbg("Start: CellGeom nil", tostring(fromIndex), tostring(toIndex))
            return false
        end

        local anchorPos = opts.anchor or "TOPLEFT"
        local expanded  = opts.expanded and true or false

        local fromPoint, fromX, fromY, fromSizeW, fromSizeH =
            LayoutFor(anchorPos, expanded, fromL, fromB, fromW, fromH)
        local toPoint, toX, toY, toSizeW, toSizeH =
            LayoutFor(anchorPos, expanded, toL, toB, toW, toH)

        local host = HostFor(toIndex)
        local temp = host:CreateTexture(nil, "ARTWORK", nil, 7)
        temp:SetDrawLayer("ARTWORK", 7)
        temp:SetTexture(opts.icon)
        temp:SetTexCoord(0, 1, 0, 1)
        temp:SetVertexColor(1, 1, 1, 1)
        temp:SetAlpha(opts.alpha or 1)
        temp:SetSize(fromSizeW, fromSizeH)
        temp:SetPoint(fromPoint, QuestsField.frame, "BOTTOMLEFT", fromX, fromY)
        temp:Show()

        active[id] = {
            temp      = temp,
            icon      = opts.icon,
            alpha     = opts.alpha or 1,
            expanded  = expanded,
            anchorPos = anchorPos,
            point     = fromPoint,
            fromX = fromX, fromY = fromY,
            toX   = toX,   toY   = toY,
            sizeW = fromSizeW, sizeH = fromSizeH,
            toSizeW = toSizeW, toSizeH = toSizeH,
            duration  = duration,
            startedAt = GetTime(),
            fromIndex = fromIndex,
            toIndex   = toIndex,
        }

        local cell = QuestsField.cells and QuestsField.cells[fromIndex]
        if cell and cell.anchors and cell.anchors[anchorPos] then
            cell.anchors[anchorPos]:Hide()
        end

        EnsureFrame()
        dbg("Start", tostring(id), fromIndex, "->", toIndex, "dur", duration)
        return true
    end

    function Animate:SetExpanded(id, expanded)
        local a = active[id]
        if not a then return false end
        expanded = expanded and true or false
        if a.expanded == expanded then return true end

        local fromL, fromB, fromW, fromH = CellGeom(a.fromIndex)
        local toL,   toB,   toW,   toH   = CellGeom(a.toIndex)
        if not fromL or not toL then return false end

        local fromPoint, fromX, fromY, fromSizeW, fromSizeH =
            LayoutFor(a.anchorPos, expanded, fromL, fromB, fromW, fromH)
        local toPoint, toX, toY, toSizeW, toSizeH =
            LayoutFor(a.anchorPos, expanded, toL, toB, toW, toH)

        a.expanded = expanded
        a.point = fromPoint
        a.fromX, a.fromY = fromX, fromY
        a.toX,   a.toY   = toX,   toY
        a.sizeW, a.sizeH = fromSizeW, fromSizeH
        a.toSizeW, a.toSizeH = toSizeW, toSizeH

        if a.temp then a.temp:SetSize(fromSizeW, fromSizeH) end

        local t = (GetTime() - a.startedAt) / a.duration
        if t > 1 then t = 1 end
        if a.temp then
            local x = a.fromX + (a.toX - a.fromX) * t
            local y = a.fromY + (a.toY - a.fromY) * t
            a.temp:ClearAllPoints()
            a.temp:SetPoint(a.point, QuestsField.frame, "BOTTOMLEFT", x, y)
        end
        dbg("SetExpanded", tostring(id), expanded)
        return true
    end

    function Animate:Stop(id)
        local a = active[id]
        if not a then return false end
        local fromIndex, toIndex = a.fromIndex, a.toIndex
        if a.temp then
            a.temp:Hide()
            a.temp:ClearAllPoints()
            a.temp:SetTexture(nil)
        end
        active[id] = nil
        RenderBoth(fromIndex, toIndex)
        dbg("Stop", tostring(id), fromIndex, "->", toIndex)
        return true
    end

    -- ========================================================================
    -- StopAll: оборвать ВСЕ активные анимации.
    -- Нужно при переключении этажа: temp-текстуры старого этажа
    -- не должны висеть на новом.
    -- ========================================================================
    function Animate:StopAll()
        local ids = {}
        for id in pairs(active) do ids[#ids + 1] = id end
        for _, id in ipairs(ids) do
            self:Stop(id)
        end
        if Animate.DEBUG then
            print("|cff00ffff[ANIM]|r StopAll:", #ids, "анимаций остановлено")
        end
        return #ids
    end

    function Animate:IsAnimating(id)
        return id and active[id] ~= nil
    end

    function Animate:Tick()
        local now = GetTime()
        for id, a in pairs(active) do
            local t = (now - a.startedAt) / a.duration
            if t >= 1 then
                local fromIndex, toIndex = a.fromIndex, a.toIndex
                if a.temp then
                    a.temp:Hide()
                    a.temp:ClearAllPoints()
                    a.temp:SetTexture(nil)
                end
                active[id] = nil
                RenderBoth(fromIndex, toIndex)
                dbg("Tick done", tostring(id), fromIndex, "->", toIndex)
            else
                local x = a.fromX + (a.toX - a.fromX) * t
                local y = a.fromY + (a.toY - a.fromY) * t
                local w = a.sizeW + (a.toSizeW - a.sizeW) * t
                local h = a.sizeH + (a.toSizeH - a.sizeH) * t
                if a.temp then
                    a.temp:ClearAllPoints()
                    a.temp:SetPoint(a.point, QuestsField.frame, "BOTTOMLEFT", x, y)
                    a.temp:SetSize(w, h)
                end
            end
        end
    end

    function Animate:Dump()
        local n = 0
        for id, a in pairs(active) do
            n = n + 1
            print(string.format("[ANIM] %s: %s→%s  t=%.2f  temp=%s",
                tostring(id), tostring(a.fromIndex), tostring(a.toIndex),
                (GetTime() - a.startedAt) / a.duration,
                a.temp and (a.temp:IsShown() and "shown" or "hidden") or "nil"))
        end
        print("[ANIM] active:", n,
              "frame:", frame and (frame:IsShown() and "shown" or "hidden") or "nil")
    end

end)