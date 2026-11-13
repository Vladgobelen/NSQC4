-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Init
-- Одна логика: создание свитчеров панелей.
-- БЕЗ таймеров, без OnUpdate.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB

    if not QuestsField then return end
    if not NSDB then return end

    local SCOPE       = "switchers"
    local SWITCH_SLOT = 1
    local SIDES       = { "TOP", "BOTTOM", "LEFT", "RIGHT" }

    local function Key(side)
        return side .. ":" .. SWITCH_SLOT
    end

    local function Defaults(side)
        return {
            icon    = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
            color   = { 1, 1, 1, 1 },
            press   = 2,
            visible = 1,
            tooltip = "Панель " .. side .. ": ЛКМ вперёд, ПКМ назад",
        }
    end

    local function Ensure(side)
        local key = Key(side)
        local existing = NSDB:Get(SCOPE, key)
        if existing then return existing end
        local defaults = Defaults(side)
        NSDB:Set(SCOPE, key, defaults)
        return defaults
    end

    function QuestsField:HasPanelButtons(side)
        local buttons = NSDB:Table("buttons")
        if not buttons then return false end
        local cur = self:GetPanelIndex(side)
        for _, data in pairs(buttons) do
            if data.side == side and data.panelIndex == cur then
                return true
            end
        end
        return false
    end

    function QuestsField:CreateSwitchers()
        if self._switchers then
            return self._switchers
        end
        if not self.frame then
            return nil
        end

        self._switchers = {}
        local bs = self:GetButtonSize()

        for _, side in ipairs(SIDES) do
            local settings = Ensure(side)
            local tex = self.frame:CreateTexture(nil, "OVERLAY", nil, 11)
            tex:SetTexture(settings.icon)
            tex:SetSize(bs, bs)
            tex:Hide()

            self._switchers[#self._switchers + 1] = {
                texture    = tex,
                side       = side,
                slot       = SWITCH_SLOT,
                settings   = settings,
                isSwitcher = true,
            }
        end

        if self.RefreshSwitchers then
            self:RefreshSwitchers()
        end

        return self._switchers
    end

    local inst = NSQC4.Field
    if inst and inst.frame and not inst._switchers then
        inst:CreateSwitchers()
    end

end, 605)