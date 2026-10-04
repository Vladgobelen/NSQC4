-- ============================================================================
-- NSQC4 / BS / ItemScore
-- БС предмета из тултипа. Модуль "bs_item".
-- ============================================================================

NSQC4.RegisterModule("bs_item", function()

    -- ========================================================================
    -- Паттерны
    -- ========================================================================
    local STAT_PATTERNS = {
        { pattern = "сил", key = "STR" },
        { pattern = "лов", key = "AGI" },
        { pattern = "вын", key = "STA" },
        { pattern = "инт", key = "INT" },
        { pattern = "дух", key = "SPI" },
    }

    local RATING_PATTERNS = {
        { pattern = "мет", key = "HIT" },
        { pattern = "кри", key = "CRIT" },
        { pattern = "мас", key = "EXP" },
        { pattern = "зак", key = "SP" },
        { pattern = "ата", key = "AP" },
        { pattern = "ско", key = "HASTE" },
        { pattern = "защ", key = "DEF" },
        { pattern = "укл", key = "DODGE" },
        { pattern = "пар", key = "PARRY" },
        { pattern = "бло", key = "BLOCK" },
        { pattern = "про", key = "ARP" },
    }

    -- ========================================================================
    -- Парсинг строки
    -- ========================================================================
    local function ParseLine(line)
        -- Только строки, начинающиеся с "+N" (бонусы)
        local num = line:match("^%+(%d+)")
        if not num then return nil end
        num = tonumber(num)
        if not num then return nil end

        local lower = line:lower()

        -- Frontier: позиция перед буквой после не-буквы
        -- Включает кириллицу, т.к. %a в Lua 5.1 — только латиница
        local FRONTIER = "%f[%aа-яё]"

        for _, sp in ipairs(STAT_PATTERNS) do
            if lower:find(FRONTIER .. sp.pattern) then
                return sp.key, num
            end
        end

        for _, rp in ipairs(RATING_PATTERNS) do
            if lower:find(FRONTIER .. rp.pattern) then
                return rp.key, num
            end
        end

        return nil
    end

    -- ========================================================================
    -- Сбор статов с тултипа
    -- ========================================================================
    function NSQC4.BS.CollectTooltipStats()
        local stats = {}
        local numLines = GameTooltip:NumLines()
        for i = 1, numLines do
            local text = _G["GameTooltipTextLeft" .. i]
            if text then
                local line = text:GetText()
                if line then
                    local key, value = ParseLine(line)
                    if key then
                        stats[key] = (stats[key] or 0) + value
                    end
                end
            end
        end
        return stats
    end

    -- ========================================================================
    -- БС предмета
    -- ========================================================================
    function NSQC4.BS.CalcItemScore()
        local _, class = UnitClass("player")
        local spec = (NSQC4.BS.SPEC_DETECT[class] and NSQC4.BS.SPEC_DETECT[class]()) or "unknown"
        local capKey = NSQC4.BS.GetCapKey(class, spec)
        local weights = NSQC4.BS.WEIGHTS[capKey] or NSQC4.BS.WEIGHTS.unknown
        local stats = NSQC4.BS.CollectTooltipStats()
        local score = 0
        for key, value in pairs(stats) do
            local w = weights[key] or 0
            score = score + value * w
        end
        return math.floor(score), stats
    end

    -- ========================================================================
    -- Хук на тултип
    -- ========================================================================
    GameTooltip:HookScript("OnShow", function(self)
        local score = NSQC4.BS.CalcItemScore()
        if score and score > 0 then
            self:AddLine("|cff00BFFFБС предмета: |cffFF8C00" .. score)
            self:Show()
        end
    end)

end)