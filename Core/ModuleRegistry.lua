-- ============================================================================
-- NSQC4 / Core / ModuleRegistry
-- Единая точка инициализации модулей.
-- Один ключ → список функций (несколько файлов на один модуль).
-- ============================================================================
-- Использование:
--     NSQC4.RegisterModule("ui_mail", function() ... end)
--     NSQC4.RegisterModule("gp", function() ... end)   -- можно несколько раз
--
-- Порядок запуска функций для одного ключа = порядок регистрации = порядок .toc.
-- Если ключ выключен в настройках — ни одна функция не вызывается.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Modules = NSQC4.Modules or {}   -- { [key] = { fn1, fn2, ... } }

-- ============================================================================
-- Регистрация
-- ============================================================================
function NSQC4.RegisterModule(key, initFn)
    if not key or type(initFn) ~= "function" then
        error("NSQC4.RegisterModule: нужен key и функция")
    end
    NSQC4.Modules[key] = NSQC4.Modules[key] or {}
    table.insert(NSQC4.Modules[key], initFn)
end

-- ============================================================================
-- Запуск одного модуля
-- ============================================================================
local function RunModule(key)
    local fns = NSQC4.Modules[key]
    if not fns then return end
    for _, fn in ipairs(fns) do
        local ok, err = pcall(fn)
        if not ok then
            print("|cffff0000[NSQC4]|r Ошибка модуля '"..key.."': "..tostring(err))
        end
    end
end

NSQC4.RunModule = RunModule

-- ============================================================================
-- ЕДИНСТВЕННЫЙ фрейм на весь аддон
-- ============================================================================
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, addon)
    if addon ~= "NSQC4" then return end

    self:UnregisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", nil)
    self:Hide()

    -- Запускаем включённые модули.
    -- Порядок обхода — по ключам, но внутри ключа — порядок .toc.
    -- Если нужен строгий порядок между ключами — можно сортировать,
    -- но для наших задач порядок внутри ключа важнее.
    for key, fns in pairs(NSQC4.Modules) do
        if NSQC4.Settings.IsModuleEnabled(key) then
            for _, fn in ipairs(fns) do
                local ok, err = pcall(fn)
                if not ok then
                    print("|cffff0000[NSQC4]|r Ошибка модуля '"..key.."': "..tostring(err))
                end
            end
        end
    end
end)