-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Hover
-- Управление поведением при наведении мыши.
--
-- OnEnter / OnLeave ставят btn._hovered = true/false.
-- Это использует AI/Work.lua, чтобы играть звук работы только когда
-- мышь на существе. Тултип тоже идёт через _onEnter/_onLeave.
--
-- ПОДСВЕТКА ПРИ НАВЕДЕНИИ:
--   ApplyHover ставит рамку клетки:
--     - если btn._hoverHighlight задан (SetCellHoverHighlight) — его цвет;
--     - иначе — DEFAULT_HOVER_HIGHLIGHT (жёлтый 1.0, 0.85, 0.0, 1.0).
--   ResetHover возвращает базовый цвет рамки:
--     - borderless = nil → 0.25, 0.25, 0.25, 1
--     - borderless = 1   → 0,    0,    0,    0
--
-- ВАЖНО: QuestsField:SetCellHoverTexture — только в Textures.lua
-- (там inset зависит от IsBorderless()). Здесь дубля НЕТ.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Дефолтная подсветка при наведении (если _hoverHighlight не задан).
    --   { R, G, B, A } — цвет рамки клетки.
    -- ========================================================================
    local DEFAULT_HOVER_HIGHLIGHT = { 1.0, 0.85, 0.0, 1.0 }   -- жёлтый

    local function ApplyHover(btn)
        if btn._hoverTexture and btn.hoverTexture then
            btn.hoverTexture:Show()
        end

        -- рамка: либо заданный _hoverHighlight, либо дефолтный
        local hl = btn._hoverHighlight or DEFAULT_HOVER_HIGHLIGHT
        local r = hl[1] or 1.0
        local g = hl[2] or 0.85
        local b = hl[3] or 0.0
        local a = hl[4] or 1.0
        btn:SetBackdropBorderColor(r, g, b, a)
    end

    local function ResetHover(btn)
        if btn.hoverTexture then
            btn.hoverTexture:Hide()
        end

        -- рамка: вернуть базовый цвет (0.25 или 0 при borderless)
        if QuestsField:IsBorderless() then
            btn:SetBackdropBorderColor(0, 0, 0, 0)
        else
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end

    function QuestsField:InitCellHover(index)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        if not btn._hoverInitialized then
            btn:SetScript("OnEnter", function(self2)
                self2._hovered = true
                ApplyHover(self2)
                if self2._onEnter then self2._onEnter(self2, index) end
            end)
            btn:SetScript("OnLeave", function(self2)
                self2._hovered = false
                ResetHover(self2)
                if self2._onLeave then self2._onLeave(self2, index) end
            end)
            btn._hoverInitialized = true
        end
    end

    function QuestsField:SetCellOnEnter(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onEnter = fn
        self:InitCellHover(index)
    end

    function QuestsField:SetCellOnLeave(index, fn)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end
        btn._onLeave = fn
        self:InitCellHover(index)
    end

    function QuestsField:SetCellHoverHighlight(index, r, g, b, a)
        self:EnsureFrame()
        local btn = self.cells[index]
        if not btn then return end

        btn._hoverHighlight = { r, g, b, a or 1 }
        self:InitCellHover(index)
    end

    -- ========================================================================
    -- SetCellHoverTexture — НЕ здесь.
    --   Определён в Textures.lua (inset зависит от IsBorderless()).
    -- ========================================================================
end)