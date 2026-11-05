-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Hover
-- Ховер: подсветка + звук работы + авто-обновление тултипа.
--
-- ФИКС: QuestsField здесь — ИНСТАНС (NSQC4.QuestsField), а не класс.
-- Раньше было NSQC4.QuestsFieldClass — у класса нет .cells (это поле
-- инстанса), поэтому RefreshTooltip получал QuestsField.cells == nil
-- и печатал «tooltip refresh cell=N — нет btn».
--
-- ОТЛАДКА:
--   /ns_hover on            — включить
--   /ns_hover off           — выключить
--   /ns_hover test <idx>    — вручную навесить ховер на клетку
--   /ns_hover clear         — сбросить
--   /ns_hover dump          — состояние
--   /ns_hover tt <idx>      — разово перерисовать тултип клетки
--   /ns_hover ttinfo <idx>  — что в btn._tooltipFn / _onEnter / ai
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsField   -- ИНСТАНС, не класс
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Hover: NSQC4.QuestsField не создан (Field/Init.lua не загружен?)")
        return
    end

    local DEFAULT_HOVER_HIGHLIGHT = { 1.0, 0.85, 0.0, 1.0 }

    QuestsField._HoverDebug = false

    local function dbg(...)
        if QuestsField._HoverDebug then
            print("|cff00ffff[HOVER]|r", ...)
        end
    end

    -- ========================================================================
    -- Тикер
    -- ========================================================================
    local SOUND_INTERVAL   = 1.5
    local TOOLTIP_INTERVAL = 0.5

    local tickFrame    = nil
    local soundAccum   = 0
    local tooltipAccum = 0
    local hoveredWork  = {}

    local function IsWorking(entity)
        if not entity or not entity.opts then return false end
        local ai = entity.opts.ai
        return ai and ai.state == "working"
    end

    local function TerrainForSound(entity)
        if not entity or not entity.opts then return nil end
        local ai = entity.opts.ai
        return ai and ai.terrainId or nil
    end

    local function AnyHoveredWorking()
        for _ in pairs(hoveredWork) do return true end
        return false
    end

    local function RefreshTooltip(index)
        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then
            dbg("tooltip refresh cell=" .. tostring(index) .. " — нет btn")
            return
        end
        local fn = btn._tooltipFn
        if not fn then
            dbg("tooltip refresh cell=" .. tostring(index) .. " — нет _tooltipFn")
            return
        end

        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        local ok, err = pcall(fn, btn)
        if ok then
            GameTooltip:Show()
            local lines = GameTooltip:NumLines() or 0
            dbg(string.format("tooltip refresh cell=%s ok=true lines=%d", tostring(index), lines))
        else
            dbg(string.format("tooltip refresh cell=%s ERROR: %s", tostring(index), tostring(err)))
        end
    end

    local function Tick(elapsed)
        if not AnyHoveredWorking() then return end

        soundAccum = soundAccum + elapsed
        if soundAccum >= SOUND_INTERVAL then
            soundAccum = 0
            local Sound = NSQC4.QuestsDfAISound
            if Sound and Sound.PlayTerrain then
                for index, rec in pairs(hoveredWork) do
                    dbg(string.format("sound tick: cell=%s terrain=%s", tostring(index), tostring(rec.terrainId)))
                    Sound:PlayTerrain(rec.terrainId)
                end
            end
        end

        tooltipAccum = tooltipAccum + elapsed
        if tooltipAccum >= TOOLTIP_INTERVAL then
            tooltipAccum = 0
            for index in pairs(hoveredWork) do
                local btn = QuestsField.cells and QuestsField.cells[index]
                dbg(string.format("tooltip tick: cell=%s fn=%s",
                    tostring(index),
                    tostring(btn and btn._tooltipFn and "yes" or "no")))
                RefreshTooltip(index)
            end
        end
    end

    local function EnsureTickFrame()
        if tickFrame then return tickFrame end
        tickFrame = CreateFrame("Frame")
        tickFrame:SetScript("OnUpdate", function(_, elapsed)
            Tick(elapsed)
        end)
        tickFrame:Show()
        dbg("tick frame created")
        return tickFrame
    end

    local function RegisterHoverWork(index)
        local Grid = NSQC4.QuestsDfGrid
        local entity = Grid and Grid:GetEntity(index)

        dbg(string.format("register cell=%s entity=%s",
            tostring(index),
            tostring(entity and (entity.opts and entity.opts.name or entity.id))))

        if not entity then
            dbg("  → нет существа")
            return
        end
        if not entity.opts then
            dbg("  → нет opts")
            return
        end
        local ai = entity.opts.ai
        dbg(string.format("  ai.state=%s ai.terrainId=%s",
            tostring(ai and ai.state), tostring(ai and ai.terrainId)))

        if not IsWorking(entity) then
            dbg("  → не working")
            return
        end
        local t = TerrainForSound(entity)
        if not t then
            dbg("  → нет terrainId")
            return
        end

        hoveredWork[index] = { terrainId = t, entity = entity }
        soundAccum   = SOUND_INTERVAL
        tooltipAccum = TOOLTIP_INTERVAL
        EnsureTickFrame()
        dbg(string.format("  → registered cell=%s terrain=%s", tostring(index), t))
    end

    local function UnregisterHoverWork(index)
        hoveredWork[index] = nil
        dbg(string.format("unregister cell=%s", tostring(index)))
    end

    -- ========================================================================
    -- Подсветка
    -- ========================================================================
    local function EnsureHoverTexture(btn, index)
        if not btn.hoverTexture then
            btn.hoverTexture = btn:CreateTexture(nil, "OVERLAY", nil, 0)
            btn.hoverTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
            btn.hoverTexture:SetVertexColor(1, 1, 1, 0.15)
            btn.hoverTexture:ClearAllPoints()
            btn.hoverTexture:SetPoint("TOPLEFT",     btn, "TOPLEFT",     0, 0)
            btn.hoverTexture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            btn.hoverTexture:Hide()
        end
        return btn.hoverTexture
    end

    local function ApplyHover(btn, index)
        local tex = EnsureHoverTexture(btn, index)
        tex:Show()
        local hl = btn._hoverHighlight or DEFAULT_HOVER_HIGHLIGHT
        btn:SetBackdropBorderColor(hl[1] or 1.0, hl[2] or 0.85, hl[3] or 0.0, hl[4] or 1.0)
    end

    local function ResetHover(btn, index)
        if btn.hoverTexture then
            btn.hoverTexture:Hide()
        end
        if QuestsField:IsBorderless() then
            btn:SetBackdropBorderColor(0, 0, 0, 0)
        else
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end

    function QuestsFieldClass_InitCellHover(self, index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        if not btn._hoverInitialized then
            btn:SetScript("OnEnter", function(self2)
                dbg("enter cell=" .. tostring(index))
                self2._hovered = true
                ApplyHover(self2, index)
                RegisterHoverWork(index)
                if self2._onEnter then self2._onEnter(self2, index) end
            end)
            btn:SetScript("OnLeave", function(self2)
                dbg("leave cell=" .. tostring(index))
                self2._hovered = false
                ResetHover(self2, index)
                UnregisterHoverWork(index)
                if self2._onLeave then self2._onLeave(self2, index) end
            end)
            btn._hoverInitialized = true
            dbg("init hover for cell=" .. tostring(index))
        end
    end

    -- Определяем метод на классе, чтобы все инстансы получили
    local Class = NSQC4.QuestsFieldClass
    Class.InitCellHover = QuestsFieldClass_InitCellHover

    function Class:SetCellOnEnter(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onEnter = fn
        self:InitCellHover(index)
    end

    function Class:SetCellOnLeave(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onLeave = fn
        self:InitCellHover(index)
    end

    function Class:SetCellHoverHighlight(index, r, g, b, a)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._hoverHighlight = { r, g, b, a or 1 }
        self:InitCellHover(index)
    end

    -- ========================================================================
    -- Слэш
    -- ========================================================================
    SLASH_NSHOVER1 = "/ns_hover"
    SlashCmdList["NSHOVER"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(%S*)")
        cmd = (cmd or ""):lower()

        if cmd == "" or cmd == "on" then
            QuestsField._HoverDebug = true
            print("[HOVER] DEBUG = true")
            print("  tickFrame:", tickFrame and (tickFrame:IsShown() and "shown" or "hidden") or "nil")
            print("  hovered total:", (function() local n=0 for _ in pairs(hoveredWork) do n=n+1 end return n end)())

        elseif cmd == "off" then
            QuestsField._HoverDebug = false
            print("[HOVER] DEBUG = false")

        elseif cmd == "test" then
            local idx = tonumber(arg) or 1
            local btn = QuestsField.cells and QuestsField.cells[idx]
            if not btn then
                print("[HOVER] test: нет клетки " .. tostring(idx))
                return
            end
            QuestsField:InitCellHover(idx)
            ApplyHover(btn, idx)
            RegisterHoverWork(idx)
            print("[HOVER] test: клетка " .. idx)

        elseif cmd == "clear" then
            for i = 1, (QuestsField.cells and #QuestsField.cells or 0) do
                local btn = QuestsField.cells[i]
                if btn then ResetHover(btn, i) end
                UnregisterHoverWork(i)
            end
            print("[HOVER] clear: сброшено")

        elseif cmd == "dump" then
            print("[HOVER] dump:")
            print("  debug:", QuestsField._HoverDebug)
            print("  tickFrame:", tickFrame and (tickFrame:IsShown() and "shown" or "hidden") or "nil")
            print("  soundAccum:", string.format("%.2f", soundAccum))
            print("  tooltipAccum:", string.format("%.2f", tooltipAccum))
            local n = 0
            for index, rec in pairs(hoveredWork) do
                n = n + 1
                local btn = QuestsField.cells and QuestsField.cells[index]
                print(string.format("  cell=%s terrain=%s _tooltipFn=%s _onEnter=%s",
                    tostring(index), tostring(rec.terrainId),
                    tostring(btn and btn._tooltipFn and "yes" or "no"),
                    tostring(btn and btn._onEnter and "yes" or "no")))
            end
            print("  hovered total:", n)

        elseif cmd == "tt" then
            local idx = tonumber(arg) or 1
            local btn = QuestsField.cells and QuestsField.cells[idx]
            if not btn then
                print("[HOVER] tt: нет клетки " .. tostring(idx))
                return
            end
            print(string.format("[HOVER] tt cell=%s _tooltipFn=%s _onEnter=%s",
                tostring(idx),
                tostring(btn._tooltipFn and "yes" or "no"),
                tostring(btn._onEnter and "yes" or "no")))
            if btn._tooltipFn then
                local ok, err = pcall(btn._tooltipFn, btn)
                if ok then
                    print("[HOVER] tt: _tooltipFn выполнен без ошибок")
                else
                    print("[HOVER] tt: ERROR " .. tostring(err))
                end
            end
            RefreshTooltip(idx)

        elseif cmd == "ttinfo" then
            local idx = tonumber(arg) or 1
            local btn = QuestsField.cells and QuestsField.cells[idx]
            if not btn then
                print("[HOVER] ttinfo: нет клетки " .. tostring(idx))
                return
            end
            print(string.format("[HOVER] ttinfo cell=%s", tostring(idx)))
            print("  _tooltipFn:", tostring(btn._tooltipFn))
            print("  _onEnter:  ", tostring(btn._onEnter))
            print("  _onLeave:  ", tostring(btn._onLeave))
            print("  _hovered:  ", tostring(btn._hovered))
            local Grid = NSQC4.QuestsDfGrid
            local entity = Grid and Grid:GetEntity(idx)
            if entity then
                local ai = entity.opts and entity.opts.ai
                print("  entity:", tostring(entity.opts and entity.opts.name))
                print("  ai.state:", tostring(ai and ai.state))
                print("  ai.terrainId:", tostring(ai and ai.terrainId))
            else
                print("  entity: (нет)")
            end

        else
            print("[HOVER] /ns_hover on|off|test <idx>|clear|dump|tt <idx>|ttinfo <idx>")
        end
    end

    print("|cff00ffff[HOVER]|r Hover загружен (инстанс, debug off; sound+tooltip on hover work)")
end)