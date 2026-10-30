-- ============================================================================
-- NSQC4 / nowim / Aliases
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    local C = NSQC4.Nowim.Config
    local A = {}
    NSQC4.Nowim.Aliases = A

    C.db.aliases = C.db.aliases or {}

    -- Получить "главный" ник. Если это твинк, вернет ник владельца.
    function A.GetMainName(nick)
        if not nick or nick == "" then return nil end
        local lowerNick = nick:lower()
        
        -- Проверяем, не является ли ник основным
        for mainName, alts in pairs(C.db.aliases) do
            if mainName:lower() == lowerNick then
                return mainName
            end
            -- Проверяем твинков
            for _, altName in ipairs(alts) do
                if altName:lower() == lowerNick then
                    return mainName -- Возвращаем основного (например, "ВасяПупкин")
                end
            end
        end
        
        return nick -- Если не найден в связках, возвращаем как есть
    end

    -- Добавить твинка к основному нику
    function A.AddAlt(mainName, altName)
        if not mainName or not altName then return end
        C.db.aliases[mainName] = C.db.aliases[mainName] or {}
        
        -- Проверяем, нет ли уже такого твинка
        for _, name in ipairs(C.db.aliases[mainName]) do
            if name:lower() == altName:lower() then return end
        end
        
        table.insert(C.db.aliases[mainName], altName)
    end
end)