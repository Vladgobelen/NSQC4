-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Hover
-- Управление поведением при наведении мыши.
--
-- OnEnter / OnLeave ставят btn._hovered = true/false.
-- Это использует AI/Work.lua, чтобы играть звук работы только когда
-- мышь на существе. Тултип тоже идёт через _onEnter/_onLeave.
--
-- BORDERLESS:
--   ResetHover (после ухода мыши) ставит рамку клетки через
--   QuestsField:IsBorderless():
--     - false (nil) → 0.25, 0.25, 0.25, 1  (рамка есть)
--     - true  (1)   → 0,    0,    0,    0  (рамки нет)
--   ApplyHover (при наведении) — если _hoverHighlight задан, ставит его
--   цвет (подсветка); иначе рамку не трогает.
--
-- ВАЖНО: QuestsField:SetCellHoverTexture — только в Textures.lua
-- (там inset зависит от IsBorderless()). Здесь дубля НЕТ — иначе
-- Hover.lua перезаписал бы версию из Textures.lua (TOC: Textures
-- до Hover) и inset был бы всегда 1 px, даже при borderless.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    local function ApplyHover(btn)
        if btn._hoverTexture and btn.hoverTexture then
            btn.hoverTexture:Show()
        end
        if btn._hoverHighlight then
            local r, g, b, a = unpack(btn._hoverHighlight)
            btn:SetBackdropBorderColor(r, g, b, a)
        end
    end

    local function ResetHover(btn)
        if btn.hoverTexture then
            btn.hoverTexture:Hide()
        end
        if btn._hoverHighlight then
            -- рамка: по умолчанию 0.25 (есть), если borderless — 0 (нет)
            if QuestsField:IsBorderless() then
                btn:SetBackdropBorderColor(0, 0, 0, 0)
            else
                btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
            end
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
    --   Если продублировать здесь — Hover.lua (в TOC после Textures.lua)
    --   перезапишет версию из Textures.lua, и inset будет всегда 1 px,
    --   даже при borderless = 1. Поэтому здесь его нет.
    -- ========================================================================
end)