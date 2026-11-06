-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Anchors
-- @deprecated Обёртки над QuestsField:RenderCell для «якоря существа».
--
-- В новой модели единственный визуал существа — spec.entity (см.
-- Field/UI/API/CellRender.lua). Отдельного реестра btn.anchors /
-- btn._anchorExpanded / btn._anchorBorders БОЛЬШЕ НЕТ.
--
-- Эти методы оставлены для совместимости со старым кодом
-- (df/Actions/Terrain/*, df/Entities/*). Внутри:
--   - читают btn._crSpec
--   - меняют spec.entity (anchor/expanded/texture/alpha)
--   - зовут RenderCell
--
-- GetAnchorPos — остаётся (его использует Move:BeginStep / Move:Advance
-- для расчёта штатных точек). Реализация прежняя: свёрнутая — TOPLEFT +
-- ins + size/2, развёрнутая — центр клетки. Единственное отличие —
-- размер считается через CellRender.EntitySize (btn:GetWidth()/3 - 1
-- или btn:GetWidth()*0.9).
--
-- RefreshAnchorSizes / RefreshAllAnchorSizes — прокси в
-- RefreshCellSize / RefreshAllCellSizes.
--
-- SetAnchorBorder — no-op (бордер только у лута, не у существа).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Anchors: ядро поля не загружено.")
        return
    end

    if not QuestsField.RenderCell then
        print("|cffff0000[NSQC4]|r Anchors: QuestsField:RenderCell не найден " ..
              "(CellRender.lua не загружен?). Обёртки работать не будут.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    local ANCHOR_INSET = CONST and CONST.ANCHOR_INSET or 0

    -- ========================================================================
    -- GetAnchorPos(index, expanded) → cx, cy, w, h, apos
    --   Используется Move:BeginStep / Move:Advance / RebaseStepForExpanded.
    --   Оставляем ту же сигнатуру и логику.
    -- ========================================================================
    function QuestsField:GetAnchorPos(index, expanded)
        local btn = self.cells and self.cells[index]
        if not btn then return nil end
        local left   = btn:GetLeft()
        local bottom = btn:GetBottom()
        local cw     = btn:GetWidth()
        local ch     = btn:GetHeight()
        if not left or not bottom or not cw or not ch then return nil end

        if expanded then
            local w, h = cw * 0.9, ch * 0.9
            return left + cw / 2, bottom + ch / 2, w, h, "CENTER"
        else
            local size = cw / 3 - 1
            local ins  = ANCHOR_INSET
            local cx   = left + ins + size / 2
            local cy   = bottom + ch - ins - size / 2
            return cx, cy, size, size, "TOPLEFT"
        end
    end

    -- ========================================================================
    -- @deprecated
    -- SetAnchorTexture(index, pos, texture)
    --   pos игнорируется: в новой модели у существа ОДИН якорь
    --   (opts.anchor или "TOPLEFT"). pos оставлен для совместимости
    --   старого кода, но в spec.entity.anchor кладётся "TOPLEFT" /
    --   "CENTER" по expanded (см. EntitiesUIApi:BuildEntitySpec).
    -- ========================================================================
    function QuestsField:SetAnchorTexture(index, pos, texture)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = btn._crSpec or {}

        if texture then
            local expanded = spec.entity and spec.entity.expanded or false
            spec.entity = {
                anchor   = expanded and "CENTER" or "TOPLEFT",
                expanded = expanded,
                texture  = texture,
                alpha    = 1,
                moving   = false,
            }
        else
            spec.entity = nil
        end

        btn._crLastEntity = spec.entity
        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- SetAnchorExpanded(index, pos, texture, expanded)
    -- ========================================================================
    function QuestsField:SetAnchorExpanded(index, pos, texture, expanded)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = btn._crSpec or {}

        if texture then
            expanded = expanded and true or false
            spec.entity = {
                anchor   = expanded and "CENTER" or "TOPLEFT",
                expanded = expanded,
                texture  = texture,
                alpha    = 1,
                moving   = false,
            }
        else
            spec.entity = nil
        end

        btn._crLastEntity = spec.entity
        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- ClearAnchorTexture(index, pos) — снять якорь существа.
    -- ========================================================================
    function QuestsField:ClearAnchorTexture(index, pos)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = btn._crSpec or {}
        spec.entity = nil
        btn._crLastEntity = nil
        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- ClearAnchorTextures(index) — то же, что ClearAnchorTexture.
    -- ========================================================================
    function QuestsField:ClearAnchorTextures(index)
        return self:ClearAnchorTexture(index)
    end

    -- ========================================================================
    -- @deprecated
    -- RefreshAnchorSizes(index) → RefreshCellSize(index).
    -- ========================================================================
    function QuestsField:RefreshAnchorSizes(index)
        if self.RefreshCellSize then
            return self:RefreshCellSize(index)
        end
        return false
    end

    -- ========================================================================
    -- @deprecated
    -- RefreshAllAnchorSizes() → RefreshAllCellSizes().
    -- ========================================================================
    function QuestsField:RefreshAllAnchorSizes()
        if self.RefreshAllCellSizes then
            return self:RefreshAllCellSizes()
        end
        return false
    end

    -- ========================================================================
    -- @deprecated
    -- SetAnchorBorder(index, pos, visible) — no-op.
    --   Бордер есть только у лута (см. CellRender.ApplyLootBorder).
    --   У существа бордера нет.
    -- ========================================================================
    function QuestsField:SetAnchorBorder(index, pos, visible)
        -- no-op: см. комментарий в шапке
        return false
    end

    print("|cff00ffff[ANCH]|r Anchors загружен (обёртки над CellRender, единый btn._cr.anchor)")

end)