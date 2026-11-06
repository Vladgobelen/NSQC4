-- ============================================================================
-- NSQC4 / Quests / Field / UI / Resize
-- Хэндл ресайза в правом нижнем углу.
--
-- ИЗМЕНЕНИЯ (миграция на CellRender):
--   После ApplyCellSize зовём один self:RefreshAllCellSizes() — он
--   пересчитывает размеры лута/anchor/temp по btn:GetWidth().
--   Старые RefreshAllAnchorSizes / Drops:RefreshAllLootSizes больше не
--   нужны (остаются как прокси в CellRender, но здесь не зовутся).
--
-- ОГРАНИЧЕНИЕ РАЗМЕРА:
--   maxCell = min(MAX_CELL, MaxCellForScreen())
--   MaxCellForScreen — 90% самой узкой стороны UIParent (из Frame.lua).
--   Если cellSize > eff — обрезается при ресайзе.
--
-- ОТЛАДКА (включается через /ns_resize on):
--   При каждом apply():
--     [RESIZE] start  anchorL=.. anchorT=.. frameW=.. cellSize=..
--     [RESIZE] apply  csX=.. csY=.. raw=.. min=.. clamp=.. eff=.. fromScreen=.. frameW=..
--     [RESIZE] setSize WxH  cellSize=N
--     [RESIZE] stop (saved)
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local CONST       = NSQC4.QuestsFieldConst
    if not QuestsField or not CONST then return end

    local COLS, ROWS     = CONST.COLS, CONST.ROWS
    local CELL_GAP       = CONST.CELL_GAP
    local GRID_PADDING   = CONST.GRID_PADDING
    local MIN_CELL       = CONST.MIN_CELL
    local MAX_CELL       = CONST.MAX_CELL

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    local ResizeDebug = { DEBUG = false }
    QuestsField._ResizeDebug = ResizeDebug

    local function dbg(...)
        if ResizeDebug.DEBUG then print("|cffff8800[RESIZE]|r", ...) end
    end

    -- ========================================================================
    -- Создание хэндла
    -- ========================================================================
    function QuestsField:CreateResizeHandle()
        local f = self.frame
        local h = CreateFrame("Button", "NSQC4FieldResize", f)
        h:SetSize(16, 16)
        h:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -4)
        h:SetFrameLevel(f:GetFrameLevel() + 30)
        h:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        h:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        h:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        h:EnableMouse(true)

        local anchorL, anchorT
        local lastCell
        local inst = self

        -- ====================================================================
        -- apply — вычислить новый cellSize по позиции мыши, обрезать по eff,
        -- применить через ApplyCellSize (или вручную, если метода нет).
        -- ====================================================================
        local function apply()
            local scale = UIParent:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale

            local rawW = cx - anchorL
            local rawH = anchorT - cy

            local csX = (rawW - (COLS - 1) * CELL_GAP - GRID_PADDING * 2) / COLS
            local csY = (rawH - (ROWS - 1) * CELL_GAP - GRID_PADDING * 2) / ROWS
            local cs  = math.max(csX, csY)
            cs = math.floor(cs + 0.5)

            local beforeMin = cs
            if cs < MIN_CELL then cs = MIN_CELL end

            -- effMaxCell — из MaxCellForScreen (Frame.lua), fallback MAX_CELL
            local effMaxCell, maxFromScreen
            if inst.MaxCellForScreen then
                effMaxCell, maxFromScreen = inst:MaxCellForScreen()
            else
                effMaxCell    = MAX_CELL
                maxFromScreen = MAX_CELL
            end

            local beforeClamp = cs
            if cs > effMaxCell then cs = effMaxCell end

            dbg(string.format(
                "apply  csX=%.1f csY=%.1f raw=%.1f → min=%d → clamp=%d  eff=%d fromScreen=%d  frameW=%.1f",
                csX, csY, beforeMin, cs, beforeClamp, effMaxCell, maxFromScreen,
                f:GetWidth()))

            if cs == lastCell then return end
            lastCell = cs

            if inst.ApplyCellSize then
                inst:ApplyCellSize(cs)
            else
                inst.cellSize = cs
                local w, hh = inst._FrameSizeForCell(cs)
                f:SetSize(w, hh)
                inst:ReflowCells()
                inst:ApplyBorderAnchors()
                if inst.RefreshAllCellSizes then inst:RefreshAllCellSizes() end
            end

            dbg(string.format("setSize  %.1fx%.1f  cellSize=%d", f:GetWidth(), f:GetHeight(), cs))
        end

        -- ====================================================================
        -- OnMouseDown: старт ресайза
        -- ====================================================================
        h:SetScript("OnMouseDown", function(self2, button)
            if button ~= "LeftButton" then return end
            anchorL = f:GetLeft()
            anchorT = f:GetTop()
            lastCell = nil
            dbg(string.format("start  anchorL=%.1f anchorT=%.1f frameW=%.1f cellSize=%s",
                anchorL or -1, anchorT or -1, f:GetWidth(), tostring(inst.cellSize)))

            self2:SetScript("OnUpdate", function()
                if not IsMouseButtonDown("LeftButton") then
                    self2:SetScript("OnUpdate", nil)
                    inst:Save()
                    dbg("stop (saved)")
                    return
                end
                apply()
            end)
            apply()
        end)

        h:SetScript("OnHide", function(self2) self2:SetScript("OnUpdate", nil) end)

        self.resizeHandle = h
        return h
    end

    -- ========================================================================
    -- Слэш-команда: /ns_resize on | off | dump
    -- ========================================================================
    SLASH_NSRESIZE1 = "/ns_resize"
    SlashCmdList["NSRESIZE"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "on" then
            ResizeDebug.DEBUG = true
            print("[RESIZE] DEBUG = true")
            local F = NSQC4.QuestsField
            if F and F.MaxCellForScreen then
                local e, m = F:MaxCellForScreen()
                print(string.format("[RESIZE] eff=%d fromScreen=%d MAX_CELL=%d MIN_CELL=%d",
                    e, m, MAX_CELL, MIN_CELL))
            end
        elseif cmd == "off" then
            ResizeDebug.DEBUG = false
            print("[RESIZE] DEBUG = false")
        elseif cmd == "dump" then
            local F = NSQC4.QuestsField
            local e, m = F:MaxCellForScreen()
            print(string.format("[RESIZE] dump: cellSize=%s frameW=%s eff=%d fromScreen=%d",
                tostring(F.cellSize),
                tostring(F.frame and F.frame:GetWidth() or "nil"),
                e, m))
        else
            print("[RESIZE] /ns_resize on | off | dump")
        end
    end

end)