-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Panel
-- Одна логика: текущий panelIndex стороны (из NSDB) + смена + переключение.
--
-- Хранилище: NSDB scope "panel", ключ "side" → число (1..N).
-- НЕ рисует, НЕ регистрирует, НЕ создаёт текстуры.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB
    if not QuestsField or not NSDB then return end

    local SCOPE = "panel"
    local SIDES = { "TOP", "BOTTOM", "LEFT", "RIGHT" }

    function QuestsField:GetPanelIndex(side)
        local n = NSDB:Get(SCOPE, side)
        if n == nil then
            NSDB:Set(SCOPE, side, 1)
            return 1
        end
        return n
    end

    function QuestsField:SetPanelIndex(side, n)
        n = tonumber(n) or 1
        NSDB:Set(SCOPE, side, n)
        if self.RefreshAllButtons then self:RefreshAllButtons() end
        if self.RefreshSwitchers   then self:RefreshSwitchers()   end
    end

    function QuestsField:GetPanelCount(side)
        local maxN = 0
        local buttons = NSDB:Table("buttons")
        if buttons then
            for _, data in pairs(buttons) do
                if data.side == side and data.panelIndex and data.panelIndex > maxN then
                    maxN = data.panelIndex
                end
            end
        end
        if maxN < 1 then maxN = 1 end
        return maxN
    end

    function QuestsField:SwitchPanel(side, dir)
        local cur  = self:GetPanelIndex(side)
        local maxN = self:GetPanelCount(side)
        local n    = cur + (tonumber(dir) or 1)
        if n > maxN then n = 1    end
        if n < 1    then n = maxN end
        self:SetPanelIndex(side, n)
    end

    function QuestsField:InitPanels()
        for _, side in ipairs(SIDES) do
            if NSDB:Get(SCOPE, side) == nil then
                NSDB:Set(SCOPE, side, 1)
            end
        end
    end

end, 450)