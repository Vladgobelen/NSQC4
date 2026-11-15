-- ============================================================================
-- NSQC4 / Interface / AOClick / Core
-- Модуль ui_ao: константы, настройки, утилиты.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    NSQC4.AOClick = NSQC4.AOClick or {}
    local A = NSQC4.AOClick

    -- Константы цветов классов
    A.CLASS_COLORS = {
        ["WARRIOR"] = "|cffC79C6E",  ["PALADIN"] = "|cffF58CBA",
        ["HUNTER"] = "|cffABD473",   ["ROGUE"] = "|cfffff569",
        ["PRIEST"] = "|cffffffff",   ["DEATHKNIGHT"] = "|cffC41F3B",
        ["SHAMAN"] = "|cff0070DE",   ["MAGE"] = "|cff69CCF0",
        ["WARLOCK"] = "|cff9482C9",  ["DRUID"] = "|cffFF7D0A",
        ["1"] = "|cffC79C6E", ["2"] = "|cffF58CBA", ["3"] = "|cffABD473",
        ["4"] = "|cfffff569", ["5"] = "|cffffffff", ["6"] = "|cffC41F3B",
        ["7"] = "|cff0070DE", ["8"] = "|cff69CCF0", ["9"] = "|cff9482C9",
        ["0"] = "|cffFF7D0A",
    }

    A.DEFAULT_COLOR    = "|cFFC0C0C0"
    A.NICK_COLOR_RESET = "|r"
    A.PREFIX_Q         = "nsInfoQ"
    A.OFFICER_COLOR    = "|cff00a000"
    A.OFFICER_R, A.OFFICER_G, A.OFFICER_B = 0.00, 0.63, 0.00

    -- Настройки
    nsDbc4 = nsDbc4 or {}
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.aoClick = nsDbc4.settings.aoClick or {
        hideLevel = false,
        hideGP    = false,
        hideRep   = false,
    }
    if nsDbc4.settings.aoClick.hideRep == nil then
        nsDbc4.settings.aoClick.hideRep = false
    end

    -- Игнор-лист (используется модулем ui_ao_ignore)
    nsDbc4.settings.ignoreList = nsDbc4.settings.ignoreList or {}

    A.aoSettings = nsDbc4.settings.aoClick
    A.aoNames    = {}

    -- Утилиты
    function A.mysplit(inputstr, sep)
        if sep == nil then sep = "%s" end
        local t = {}
        for str in string.gmatch(inputstr or "", "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end

    function A.CleanName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    function A.GuildRGB()
        local t = ChatTypeInfo and ChatTypeInfo["GUILD"]
        if t then return t.r or 0.25, t.g or 0.75, t.b or 0.25 end
        return 0.25, 0.75, 0.25
    end

    function A.GuildTag(letter)
        return "|Hchannel:GUILD|h[G" .. (letter or "") .. "]|h"
    end

    function A.OfficerTag(letter)
        return A.OFFICER_COLOR .. "|Hnsqcofficer|h[O" .. (letter or "") .. "]|h|r"
    end

    function A.OpenOfficerChat()
        local eb = ChatFrame1EditBox
        if not eb then return end
        if not eb:IsShown() then eb:Show() end
        eb:SetText("/o ")
        eb:SetFocus()
    end

end)