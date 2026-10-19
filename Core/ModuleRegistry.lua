-- ============================================================================
-- NSQC4 / Core / ModuleRegistry
-- Единая точка инициализации модулей.
-- Один ключ → список функций (несколько файлов на один модуль).
-- ============================================================================
-- Использование:
--     NSQC4.RegisterModule("ui_mail", function() ... end)
--     NSQC4.RegisterModule("gp", function() ... end)   -- можно несколько раз
--     NSQC4.RegisterModule("roll_relay", function() ... end, {
--         label   = "Ролл в офицер-чат",
--         tooltip = "Дублирует все /roll 1-100 в офицерский чат.",
--         order   = 60,
--         hidden  = true, -- если нужно скрыть из UI
--     })
--
-- Порядок запуска функций для одного ключа = порядок регистрации = порядок .toc.
-- Если ключ выключен в настройках — ни одна функция не вызывается.
-- Порядок запуска МЕЖДУ ключами — по meta.order (если задан), иначе по имени ключа.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Modules = NSQC4.Modules or {}       -- { [key] = { fn1, fn2, ... } }
NSQC4.ModuleMeta = NSQC4.ModuleMeta or {}  -- { [key] = { key, label, tooltip, order, hidden } }

-- ============================================================================
-- Регистрация
-- ============================================================================
function NSQC4.RegisterModule(key, initFn, meta)
    if not key or type(initFn) ~= "function" then
        error("NSQC4.RegisterModule: нужен key и функция")
    end

    NSQC4.Modules[key] = NSQC4.Modules[key] or {}
    table.insert(NSQC4.Modules[key], initFn)

    -- Метаданные: первый вызов с meta побеждает, повторные игнорируются.
    -- Если meta не передана — создаём дефолтную запись, чтобы модуль
    -- всё равно попал в UI (с label = key).
    if not NSQC4.ModuleMeta[key] then
        meta = meta or {}
        NSQC4.ModuleMeta[key] = {
            key     = key,
            label   = meta.label   or key,
            tooltip = meta.tooltip or "",
            order   = meta.order   or 1000,
            hidden  = meta.hidden  or false,
        }
    end
end

-- ============================================================================
-- Явная установка/перезапись метаданных модуля.
-- В отличие от RegisterModule (первый вызов побеждает), эта функция
-- мержит и перезаписывает meta. Не зависит от порядка .toc.
-- ============================================================================
function NSQC4.SetModuleMeta(key, meta)
    if not key or type(meta) ~= "table" then return end
    local cur = NSQC4.ModuleMeta[key] or { key = key, order = 1000, hidden = false }
    cur.key     = key
    cur.label   = meta.label   or cur.label   or key
    cur.tooltip = meta.tooltip or cur.tooltip or ""
    cur.order   = meta.order   or cur.order   or 1000
    cur.hidden  = (meta.hidden ~= nil) and meta.hidden or (cur.hidden or false)
    NSQC4.ModuleMeta[key] = cur
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
-- Порядок запуска: по meta.order, затем по имени ключа
-- ============================================================================
local function GetSortedKeys()
    local keys = {}
    for key in pairs(NSQC4.Modules) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        local ma = NSQC4.ModuleMeta[a]
        local mb = NSQC4.ModuleMeta[b]
        local oa = ma and ma.order or 1000
        local ob = mb and mb.order or 1000
        if oa ~= ob then return oa < ob end
        return a < b
    end)
    return keys
end

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

    for _, key in ipairs(GetSortedKeys()) do
        if NSQC4.Settings.IsModuleEnabled(key) then
            local fns = NSQC4.Modules[key]
            for _, fn in ipairs(fns) do
                local ok, err = pcall(fn)
                if not ok then
                    print("|cffff0000[NSQC4]|r Ошибка модуля '"..key.."': "..tostring(err))
                end
            end
        end
    end
end)