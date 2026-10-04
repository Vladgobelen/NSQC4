-- ============================================================================
-- NSQC4 / BS / PlayerScore
-- БС игрока. Модуль "bs_player".
-- ============================================================================

NSQC4.RegisterModule("bs_player", function()

    -- ========================================================================
    -- Сбор статов
    -- ========================================================================
    local function CollectStats(unit)
        unit = unit or "player"
        local s = {}
        s.STR = UnitStat(unit, NSQC4.BS.STAT.STR) or 0
        s.AGI = UnitStat(unit, NSQC4.BS.STAT.AGI) or 0
        s.STA = UnitStat(unit, NSQC4.BS.STAT.STA) or 0
        s.INT = UnitStat(unit, NSQC4.BS.STAT.INT) or 0
        s.SPI = UnitStat(unit, NSQC4.BS.STAT.SPI) or 0

        local baseAP, posAP = UnitAttackPower(unit)
        s.AP = (baseAP or 0) + (posAP or 0)

        s.SP = (GetSpellBonusDamage and GetSpellBonusDamage(7)) or 0
        if s.SP == 0 then s.SP = GetSpellBonusHealing() or 0 end

        s.HIT   = GetCombatRating(NSQC4.BS.RATING.HIT_MELEE) or 0
        s.HITSP = GetCombatRating(NSQC4.BS.RATING.HIT_SPELL) or 0
        s.CRIT  = GetCombatRating(NSQC4.BS.RATING.CRIT_MELEE) or 0
        s.CRITSP= GetCombatRating(NSQC4.BS.RATING.CRIT_SPELL) or 0
        s.HASTE = GetCombatRating(NSQC4.BS.RATING.HASTE_MELEE) or 0
        s.EXP   = GetCombatRating(NSQC4.BS.RATING.EXPERTISE) or 0
        s.ARP   = GetCombatRating(NSQC4.BS.RATING.ARMOR_PEN) or 0
        s.DEF   = GetCombatRating(NSQC4.BS.RATING.DEFENSE_SKILL) or 0
        s.DODGE = GetCombatRating(NSQC4.BS.RATING.DODGE) or 0
        s.PARRY = GetCombatRating(NSQC4.BS.RATING.PARRY) or 0
        s.BLOCK = GetCombatRating(NSQC4.BS.RATING.BLOCK) or 0
        s.MP5   = GetManaRegen and select(2, GetManaRegen()) or 0

        local _, class = UnitClass(unit)
        s.CLASS = class
        s.SPEC = (NSQC4.BS.SPEC_DETECT[class] and NSQC4.BS.SPEC_DETECT[class]()) or "unknown"
        s.CAP_KEY = NSQC4.BS.GetCapKey(class, s.SPEC)
        return s
    end

    -- ========================================================================
    -- БС игрока
    -- ========================================================================
    function NSQC4.BS.CalcPlayerScore(unit)
        local s = CollectStats(unit)
        local w = NSQC4.BS.WEIGHTS[s.CAP_KEY] or NSQC4.BS.WEIGHTS.unknown
        local score = 0
        score = score + s.STR  * (w.STR  or 0)
        score = score + s.AGI  * (w.AGI  or 0)
        score = score + s.STA  * (w.STA  or 0)
        score = score + s.INT  * (w.INT  or 0)
        score = score + s.SPI  * (w.SPI  or 0)
        score = score + s.AP   * (w.AP   or 0)
        score = score + s.SP   * (w.SP   or 0)
        score = score + s.HIT  * (w.HIT  or 0)
        score = score + s.HITSP * (w.HIT  or 0)
        score = score + s.CRIT * (w.CRIT or 0)
        score = score + s.CRITSP * (w.CRIT or 0)
        score = score + s.HASTE * (w.HASTE or 0)
        score = score + s.EXP  * (w.EXP  or 0)
        score = score + s.ARP  * (w.ARP  or 0)
        score = score + s.DEF  * (w.DEF  or 0)
        score = score + s.DODGE * (w.DODGE or 0)
        score = score + s.PARRY * (w.PARRY or 0)
        score = score + s.BLOCK * (w.BLOCK or 0)
        score = score + s.MP5  * (w.MP5  or 0)
        return math.floor(score), s
    end

    -- ========================================================================
    -- Строка с капами
    -- ========================================================================
    function NSQC4.BS.GetCapString(s)
        local caps = NSQC4.BS.CAPS[s.CAP_KEY] or NSQC4.BS.CAPS.unknown
        local parts = {}

        if caps.hit_hard and caps.hit_hard > 0 then
            if caps.hit_hard ~= caps.hit_soft then
                table.insert(parts, string.format("хит/кап: %d/%d/%d", s.HIT, caps.hit_soft or 0, caps.hit_hard))
            else
                table.insert(parts, string.format("хит/кап: %d/%d", s.HIT, caps.hit_soft or 0))
            end
        end

        if caps.exp_hard and caps.exp_hard > 0 then
            if caps.exp_soft == caps.exp_hard then
                table.insert(parts, string.format("маст./кап: %d/%d", s.EXP, caps.exp_soft))
            else
                table.insert(parts, string.format("маст./кап: %d/%d/%d", s.EXP, caps.exp_soft, caps.exp_hard))
            end
        end

        if caps.extra and caps.extra ~= "" then
            table.insert(parts, caps.extra)
        end

        return table.concat(parts, " ")
    end

    -- ========================================================================
    -- Полная строка БС (илвл + гс + бс + капы)
    -- Собирается из доступных модулей:
    --   - "itemlevel"  → NSQC4.BS.GetAverageItemLevel
    --   - GS_Data      → сторонний аддон GearScore
    --   - "bs_player"  → этот модуль (CalcPlayerScore, GetCapString)
    -- ========================================================================
    function NSQC4.BS.GetPlayerScoreLine(unit)
        unit = unit or "player"
        local name = UnitName(unit) or "?"
        local score, s = NSQC4.BS.CalcPlayerScore(unit)

        local parts = {}

        -- Илвл (если модуль "itemlevel" включён)
        if NSQC4.BS.GetAverageItemLevel then
            table.insert(parts, "илвл: " .. NSQC4.BS.GetAverageItemLevel(unit))
        end

        -- ГС (если сторонний аддон GS_Data доступен)
        if GS_Data
            and GS_Data[GetRealmName()]
            and GS_Data[GetRealmName()].Players
            and GS_Data[GetRealmName()].Players[name]
        then
            table.insert(parts, "гс: " .. GS_Data[GetRealmName()].Players[name].GearScore)
        end

        -- БС (всегда, это же модуль bs_player)
        table.insert(parts, "бс: " .. score)

        -- Капы
        local caps = NSQC4.BS.GetCapString(s)
        if caps ~= "" then
            table.insert(parts, caps)
        end

        return table.concat(parts, " ")
    end

end)