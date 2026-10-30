-- ============================================================================
-- NSQC4 / nowim / Utils
-- Вспомогательные функции: UTF-8, время, цвета.
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    local U = {}
    NSQC4.Nowim.Utils = U

    -- Правильная обрезка строки по байтам (UTF-8)
    function U.TrimToBytes(str, maxBytes)
        if not str then return "" end
        local bytes = 0
        local result = {}
        
        -- Итерируемся по символам UTF-8
        for char in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            local charBytes = #char
            if bytes + charBytes > maxBytes then break end
            table.insert(result, char)
            bytes = bytes + charBytes
        end
        
        return table.concat(result)
    end

    -- Получить текущее время в формате [ЧЧ:ММ]
    function U.GetTimeString()
        return date("%H:%M")
    end

end)