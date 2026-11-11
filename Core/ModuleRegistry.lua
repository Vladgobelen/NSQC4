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
--         hidden  = true,
--     })
--     NSQC4.RegisterModule("quests", function() ... end, 160)  -- индекс в группе
--
-- Третий аргумент RegisterModule:
--     * table  → meta { label, tooltip, order, hidden }
--     * number → index внутри группы "quests" (или другой группы),
--                задаёт порядок запуска функций с одинаковым key.
--
-- Панель настроек модуля (опционально):
--     NSQC4.RegisterModuleSettings("ui_mail", function() ... end)
--
-- Порядок запуска:
--     1) внутри одной группы (key) — по index (если задан), иначе порядок .toc
--     2) между группами — по meta.order, затем по имени key
-- ============================================================================

NSQC4 = NSQC4 or {}

-- Хранилища
NSQC4.Modules         = NSQC4.Modules         or {}  -- { [key] = { {fn=..., index=...}, ... } }
NSQC4.ModuleMeta      = NSQC4.ModuleMeta      or {}  -- { [key] = { key, label, tooltip, order, hidden } }
NSQC4.ModuleSettings  = NSQC4.ModuleSettings  or {}  -- { [key] = opener }

-- ============================================================================
-- Регистрация модуля
--   third = meta (table)  → метаданные
--   third = index (number) → индекс внутри группы
-- ============================================================================
function NSQC4.RegisterModule(key, initFn, third)
    if not key or type(initFn) ~= "function" then
        error("NSQC4.RegisterModule: нужен key и функция")
    end

    local meta, index
    if type(third) == "table" then
        meta = third
    elseif type(third) == "number" then
        index = third
    end

    NSQC4.Modules[key] = NSQC4.Modules[key] or {}
    table.insert(NSQC4.Modules[key], { fn = initFn, index = index })

    -- Метаданные: первый вызов с meta побеждает, повторные игнорируются.
    -- Если meta не передана — создаём дефолтную запись (label = key),
    -- чтобы модуль всё равно попал в UI настроек.
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
-- Панели настроек модулей
-- ============================================================================
function NSQC4.RegisterModuleSettings(key, opener)
    if not key or type(opener) ~= "function" then return end
    NSQC4.ModuleSettings[key] = opener
end

function NSQC4.HasModuleSettings(key)
    return NSQC4.ModuleSettings[key] ~= nil
end

function NSQC4.OpenModuleSettings(key)
    local opener = NSQC4.ModuleSettings[key]
    if opener then
        local ok, err = pcall(opener)
        if not ok then
            print("|cffff0000[NSQC4]|r Ошибка открытия настроек '"..key.."': "..tostring(err))
        end
    end
end

-- ============================================================================
-- Внутренняя сортировка функций одной группы по index.
-- Валидный компаратор + стабильность: при равных index сохраняется
-- порядок .toc (через _seq).
-- ============================================================================
local function SortFns(fns)
    for i, rec in ipairs(fns) do
        rec._seq = i
    end
    table.sort(fns, function(a, b)
        local ia = a.index or math.huge
        local ib = b.index or math.huge
        if ia ~= ib then return ia < ib end
        return a._seq < b._seq
    end)
end

-- ============================================================================
-- Запуск одного модуля
-- ============================================================================
local function RunModule(key)
    local fns = NSQC4.Modules[key]
    if not fns then return end
    SortFns(fns)
    for _, rec in ipairs(fns) do
        local ok, err = pcall(rec.fn)
        if not ok then
            print("|cffff0000[NSQC4]|r Ошибка модуля '"..key.."': "..tostring(err))
        end
    end
end

NSQC4.RunModule = RunModule

-- ============================================================================
-- Порядок запуска между группами: по meta.order, затем по имени ключа
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
-- Публичный запуск всех модулей
-- ============================================================================
local booted = false
function NSQC4.RunModules()
    if booted then return end
    booted = true
    for _, key in ipairs(GetSortedKeys()) do
        if NSQC4.Settings.IsModuleEnabled(key) then
            RunModule(key)
        end
    end
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

    NSQC4.RunModules()
end)