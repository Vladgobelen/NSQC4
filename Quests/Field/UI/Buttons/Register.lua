-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Register
-- Одна логика: API RegisterButton — валидация + запись в NSDB.
-- Не рисует, не раскладывает, не создаёт текстуры.
-- Хранилище: NSDB scope "buttons", ключ "side:panelIndex:slot".
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    local NSDB        = NSQC4.NSDB
    if not QuestsField or not NSDB then return end

    local SCOPE    = "buttons"
    local MIN_SLOT = 1
    local MAX_SLOT = 9
    local SIDES    = { LEFT = true, RIGHT = true, TOP = true, BOTTOM = true }

    function QuestsField:RegisterButton(side, panelIndex, slot, icon, onClick, opts)
        if not SIDES[side] then return nil end

        slot       = tonumber(slot) or 0
        panelIndex = tonumber(panelIndex) or 1
        opts       = opts or {}

        if slot < MIN_SLOT or slot > MAX_SLOT then return nil end

        local key = side .. ":" .. panelIndex .. ":" .. slot

        if not self._callbacks then self._callbacks = {} end
        self._callbacks[key] = onClick

        if NSDB:Has(SCOPE, key) then
            return NSDB:Get(SCOPE, key)
        end

        local data = {
            side       = side,
            panelIndex = panelIndex,
            slot       = slot,
            icon       = icon,
            tooltip    = opts.tooltip,
            opts       = opts,
        }
        NSDB:Set(SCOPE, key, data)
        return data
    end

end, 460)