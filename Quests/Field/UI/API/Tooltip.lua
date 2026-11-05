-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Tooltip
-- API поля: регистрация/снятие тултипа на клетке.
--
-- ФИКС: SetCellTooltip кладёт tooltipFn в btn._tooltipFn. Это позволяет
-- Hover.lua перерисовывать тултип автоматически, пока мышь на работающем
-- существе (см. Field/UI/API/Hover.lua → RefreshTooltip).
--
-- Вызывающий код знает клетку и код тултипа:
--   QuestsField:SetCellTooltip(index, function(btn)
--       GameTooltip:AddLine("Имя", 1, 1, 0)
--       ...
--   end)
--
-- API сам:
--   - делает GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
--   - зовёт tooltipFn(btn) — код тултипа только AddLine'ит
--   - делает GameTooltip:Show() на OnEnter
--   - делает GameTooltip:Hide() на OnLeave
--
-- Снятие:
--   QuestsField:ClearCellTooltip(index)
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    -- ========================================================================
    -- Повесить тултип на клетку.
    --   index     — номер клетки 1..100
    --   tooltipFn — function(btn), рисует AddLine'ы; или nil (снять)
    -- ========================================================================
    function QuestsField:SetCellTooltip(index, tooltipFn)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        if tooltipFn then
            -- сохранить в btn — Hover будет звать при авто-обновлении
            btn._tooltipFn = tooltipFn

            self:SetCellOnEnter(index, function(b)
                GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
                tooltipFn(b)
                GameTooltip:Show()
            end)
            self:SetCellOnLeave(index, function()
                GameTooltip:Hide()
            end)
        else
            btn._tooltipFn = nil
            self:SetCellOnEnter(index, nil)
            self:SetCellOnLeave(index, nil)
        end

        return true
    end

    -- ========================================================================
    -- Снять тултип с клетки.
    -- ========================================================================
    function QuestsField:ClearCellTooltip(index)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        btn._tooltipFn = nil
        self:SetCellOnEnter(index, nil)
        self:SetCellOnLeave(index, nil)

        GameTooltip:Hide()
        return true
    end

    -- ========================================================================
    -- Есть ли тултип на клетке (для диагностики / отладки).
    -- ========================================================================
    function QuestsField:HasCellTooltip(index)
        local btn = self.cells and self.cells[index]
        if not btn then return false end
        return btn._tooltipFn ~= nil
    end
end)