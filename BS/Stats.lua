-- ============================================================================
-- NSQC4 / BS / Stats
-- Константы: ID рейтингов, ID статов, капы по спекам, веса статов.
-- Всегда загружается (не модуль).
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.BS = NSQC4.BS or {}

-- ============================================================================
-- ID рейтингов (GetCombatRating) — 3.3.5a
-- ============================================================================
NSQC4.BS.RATING = {
    DEFENSE_SKILL = 2,
    DODGE         = 3,
    PARRY         = 4,
    BLOCK         = 5,
    HIT_MELEE     = 6,
    HIT_RANGED    = 7,
    HIT_SPELL     = 8,
    CRIT_MELEE    = 9,
    CRIT_RANGED   = 10,
    CRIT_SPELL    = 11,
    HASTE_MELEE   = 18,
    HASTE_RANGED  = 19,
    HASTE_SPELL   = 20,
    EXPERTISE     = 24,
    ARMOR_PEN     = 25,
}

NSQC4.BS.STAT = { STR = 1, AGI = 2, STA = 3, INT = 4, SPI = 5 }

-- ============================================================================
-- Определение спека по талантам
-- ============================================================================
NSQC4.BS.SPEC_DETECT = {
    WARRIOR = function()
        local _, _, _, _, prot = GetTalentInfo(3, 7)
        if prot >= 1 then return "prot" end
        return "fury"
    end,
    PALADIN = function()
        local _, _, _, _, holy = GetTalentInfo(1, 26)
        local _, _, _, _, prot = GetTalentInfo(2, 26)
        local _, _, _, _, ret  = GetTalentInfo(3, 26)
        if holy >= 1 then return "holy" end
        if prot >= 1 then return "prot" end
        if ret  >= 1 then return "ret"  end
        return "unknown"
    end,
    DEATHKNIGHT = function()
        local _, _, _, _, blood  = GetTalentInfo(1, 7)
        local _, _, _, _, frost  = GetTalentInfo(2, 3)
        local _, _, _, _, unholy = GetTalentInfo(3, 3)
        if blood  >= 1 then return "blood_tank" end
        if frost  >= 1 then return "frost_dps"  end
        if unholy >= 1 then return "unholy_dps" end
        return "unknown"
    end,
    DRUID = function()
        local _, _, _, _, balance = GetTalentInfo(1, 13)
        local _, _, _, _, feral   = GetTalentInfo(2, 9)
        local _, _, _, _, resto   = GetTalentInfo(3, 27)
        local _, _, _, _, bear    = GetTalentInfo(2, 5)
        if resto   >= 1 then return "resto"   end
        if bear    >= 1 then return "bear"    end
        if feral   >= 1 then return "cat"     end
        if balance >= 1 then return "balance" end
        return "unknown"
    end,
    SHAMAN = function()
        local _, _, _, _, elem  = GetTalentInfo(1, 3)
        local _, _, _, _, enh   = GetTalentInfo(2, 9)
        local _, _, _, _, resto = GetTalentInfo(3, 1)
        if elem  >= 1 then return "elem"  end
        if enh   >= 1 then return "enh"   end
        if resto >= 1 then return "resto" end
        return "unknown"
    end,
    PRIEST = function()
        local _, _, _, _, shadow = GetTalentInfo(3, 27)
        if shadow >= 1 then return "shadow" end
        return "holy"
    end,
    ROGUE   = function() return "dps" end,
    HUNTER  = function() return "dps" end,
    MAGE    = function() return "arcane_fire" end,
    WARLOCK = function() return "affliction_demo_destro" end,
}

-- ============================================================================
-- Капы (в рейтинге, для 80 ур.)
-- ============================================================================
NSQC4.BS.CAPS = {
    -- Танки
    prot_warrior = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "" },
    prot_paladin = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "" },
    blood_tank   = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "" },
    bear         = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "" },

    -- Мили-ДД
    fury       = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },
    ret        = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "" },
    frost_dps  = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },
    unholy_dps = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },
    cat        = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },
    enh        = { hit_soft = 368, hit_hard = 368, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },
    dps        = { hit_soft = 263, hit_hard = 263, exp_soft = 214, exp_hard = 214, extra = "рпб/кап: 1400" },

    -- Кастеры
    holy_priest = { hit_soft = 289, hit_hard = 446, exp_soft = 0, exp_hard = 0, extra = "" },
    shadow      = { hit_soft = 289, hit_hard = 446, exp_soft = 0, exp_hard = 0, extra = "" },
    holy_paladin= { hit_soft = 0,   hit_hard = 0,   exp_soft = 0, exp_hard = 0, extra = "" },
    elem        = { hit_soft = 368, hit_hard = 368, exp_soft = 0, exp_hard = 0, extra = "хаст/кап: 1269" },
    balance     = { hit_soft = 263, hit_hard = 263, exp_soft = 0, exp_hard = 0, extra = "" },
    arcane_fire = { hit_soft = 376, hit_hard = 446, exp_soft = 0, exp_hard = 0, extra = "хаст/кап: 1130" },
    affliction_demo_destro = { hit_soft = 289, hit_hard = 446, exp_soft = 0, exp_hard = 0, extra = "" },

    -- Хилы
    resto_druid  = { hit_soft = 0, hit_hard = 0, exp_soft = 0, exp_hard = 0, extra = "" },
    resto_shaman = { hit_soft = 0, hit_hard = 0, exp_soft = 0, exp_hard = 0, extra = "хаст/кап: 1269" },
    holy         = { hit_soft = 0, hit_hard = 0, exp_soft = 0, exp_hard = 0, extra = "" },

    unknown = { hit_soft = 0, hit_hard = 0, exp_soft = 0, exp_hard = 0, extra = "" },
}

-- ============================================================================
-- Маппинг (class, spec) → ключ капов
-- ============================================================================
function NSQC4.BS.GetCapKey(class, spec)
    if class == "WARRIOR"     and spec == "prot"        then return "prot_warrior" end
    if class == "PALADIN"     and spec == "prot"        then return "prot_paladin" end
    if class == "PALADIN"     and spec == "holy"        then return "holy_paladin" end
    if class == "PALADIN"     and spec == "ret"         then return "ret" end
    if class == "DEATHKNIGHT" and spec == "blood_tank"  then return "blood_tank" end
    if class == "DEATHKNIGHT" and spec == "frost_dps"   then return "frost_dps" end
    if class == "DEATHKNIGHT" and spec == "unholy_dps"  then return "unholy_dps" end
    if class == "DRUID"       and spec == "resto"       then return "resto_druid" end
    if class == "DRUID"       and spec == "bear"        then return "bear" end
    if class == "DRUID"       and spec == "cat"         then return "cat" end
    if class == "DRUID"       and spec == "balance"     then return "balance" end
    if class == "SHAMAN"      and spec == "elem"        then return "elem" end
    if class == "SHAMAN"      and spec == "enh"         then return "enh" end
    if class == "SHAMAN"      and spec == "resto"       then return "resto_shaman" end
    if class == "PRIEST"      and spec == "shadow"      then return "shadow" end
    if class == "PRIEST"      and spec == "holy"        then return "holy_priest" end
    if class == "ROGUE"       then return "dps" end
    if class == "HUNTER"      then return "dps" end
    if class == "MAGE"        then return "arcane_fire" end
    if class == "WARLOCK"     then return "affliction_demo_destro" end
    return "unknown"
end

-- ============================================================================
-- Веса статов для БС
-- ============================================================================
NSQC4.BS.WEIGHTS = {
    prot_warrior = { STR=1, AGI=0.5, STA=2, DEF=1.5, DODGE=1.5, PARRY=1.5, BLOCK=1.5, HIT=1, EXP=1 },
    prot_paladin = { STR=1, AGI=0.5, STA=2, DEF=1.5, DODGE=1.5, PARRY=1.5, BLOCK=1.5, HIT=1, EXP=1 },
    blood_tank   = { STR=1, AGI=0.5, STA=2, DEF=1.5, DODGE=1.5, PARRY=1.5, HIT=1, EXP=1 },
    bear         = { STR=1, AGI=1, STA=2, DEF=1.5, DODGE=1.5, HIT=1, EXP=1 },

    fury       = { STR=2, AGI=0.5, HIT=2, CRIT=1.5, EXP=2, ARP=2, AP=1, HASTE=1 },
    ret        = { STR=2, AGI=0.5, HIT=2, CRIT=1.5, EXP=2, AP=1, HASTE=1 },
    frost_dps  = { STR=2, AGI=0.5, HIT=2, CRIT=1.5, EXP=2, ARP=2, AP=1, HASTE=1 },
    unholy_dps = { STR=2, AGI=0.5, HIT=2, CRIT=1.5, EXP=2, ARP=2, AP=1, HASTE=1 },
    cat        = { STR=2, AGI=1, HIT=2, CRIT=1.5, EXP=2, ARP=2, AP=1, HASTE=1 },
    enh        = { STR=1, AGI=2, HIT=2, CRIT=1.5, EXP=2, ARP=1, AP=1, HASTE=1 },
    dps        = { AGI=2, HIT=2, CRIT=1.5, EXP=2, ARP=2, AP=1, HASTE=1 },

    shadow      = { INT=1, SPI=0.5, HIT=2, CRIT=1.5, HASTE=1.5, SP=1.5 },
    holy_priest = { INT=1, SPI=1.5, HASTE=1.5, CRIT=0.5, SP=1.5, MP5=1 },
    holy_paladin= { INT=2, SPI=0.5, HASTE=1, CRIT=1, SP=1.5, MP5=1 },
    elem        = { INT=1, SPI=0.5, HIT=2, CRIT=1.5, HASTE=1.5, SP=1.5 },
    balance     = { INT=1, SPI=0.5, HIT=2, CRIT=1.5, HASTE=1.5, SP=1.5 },
    arcane_fire = { INT=2, SPI=0.5, HIT=2, CRIT=1.5, HASTE=1.5, SP=1.5 },
    affliction_demo_destro = { INT=1, SPI=0.5, HIT=2, CRIT=1.5, HASTE=1.5, SP=1.5 },

    resto_druid  = { INT=1, SPI=1.5, HASTE=1.5, CRIT=0.5, SP=1.5, MP5=1 },
    resto_shaman = { INT=1, SPI=0.5, HASTE=1.5, CRIT=1, SP=1.5, MP5=1 },
    holy         = { INT=1, SPI=1.5, HASTE=1.5, CRIT=0.5, SP=1.5, MP5=1 },

    unknown = { INT=1, SPI=1, STA=1, SP=1 },
}