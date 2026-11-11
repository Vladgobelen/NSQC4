-- ============================================================================
-- NSQC4 / Quests / Field / Switcher / Init
-- Одна логика: создание свитчеров панелей.
-- БЕЗ таймеров, без OnUpdate. Полная отладка на каждой строке.
-- ============================================================================

print("|cff00ff00[SW-FILE]|r Switcher/Init.lua: файл начал выполняться")

NSQC4.RegisterModule("quests", function()
    print("|cff00ff00[SW-FILE]|r RegisterModule fn: вход")

    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB
    print("|cff00ff00[SW-FILE]|r QuestsFieldClass=", tostring(QuestsField), " NSDB=", tostring(NSDB))

    if not QuestsField then
        print("|cffff0000[SW-FILE]|r ОТМЕНА: NSQC4.QuestsFieldClass == nil")
        return
    end
    if not NSDB then
        print("|cffff0000[SW-FILE]|r ОТМЕНА: NSQC4.NSDB == nil")
        return
    end

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

    print("|cff00ff00[SW-FILE]|r определяю HasPanelButtons")
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

    print("|cff00ff00[SW-FILE]|r определяю CreateSwitchers")
    function QuestsField:CreateSwitchers()
        print("|cff00ff00[SW-CREATE]|r CreateSwitchers: вход")
        if self._switchers then
            print("|cff00ff00[SW-CREATE]|r уже есть, n=", #self._switchers)
            return self._switchers
        end
        if not self.frame then
            print("|cffff0000[SW-CREATE]|r ОТМЕНА: self.frame == nil")
            return nil
        end

        self._switchers = {}
        local bs = self:GetButtonSize()
        print("|cff00ff00[SW-CREATE]|r bs=", tostring(bs))

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
            print("|cff00ff00[SW-CREATE]|r создан свитчер side=", side)
        end

        print("|cff00ff00[SW-CREATE]|r всего=", #self._switchers)

        if self.RefreshSwitchers then
            print("|cff00ff00[SW-CREATE]|r вызываю RefreshSwitchers")
            self:RefreshSwitchers()
        else
            print("|cffff0000[SW-CREATE]|r RefreshSwitchers НЕ ОПРЕДЕЛЁН")
        end

        return self._switchers
    end

    print("|cff00ff00[SW-FILE]|r CreateSwitchers ОПРЕДЕЛЁН. Проверяю экземпляр поля.")
    local inst = NSQC4.Field
    print("|cff00ff00[SW-FILE]|r NSQC4.Field=", tostring(inst))
    if inst then
        print("|cff00ff00[SW-FILE]|r inst.frame=", tostring(inst.frame))
        if inst.frame and not inst._switchers then
            print("|cff00ff00[SW-FILE]|r frame есть — создаю свитчеры немедленно")
            inst:CreateSwitchers()
        end
    end

    print("|cff00ff00[SW-FILE]|r RegisterModule fn: выход")
end, 605)

print("|cff00ff00[SW-FILE]|r Switcher/Init.lua: файл закончил выполняться (RegisterModule вызван)")