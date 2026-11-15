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
--     NSQC4.RegisterModule("quests", function() ... end, 160)  -- глобальный индекс
--
-- Третий аргумент RegisterModule:
--     * table  → meta { label, tooltip, order, hidden }
--     * number → ГЛОБАЛЬНЫЙ индекс запуска (не внутри группы!),
--                задаёт порядок ВСЕХ функций всех групп.
--
-- Порядок запуска (единый для всех групп):
--     1) по index (если задан), иначе math.huge (в конец)
--     2) при равных index — по meta.order группы
--     3) при равных order — по .toc-порядку (_seq)
--
-- Диагностика:
--     NSQC4.MODULE_DEBUG = true  → печатает план запуска в чат
-- ============================================================================

NSQC4 = NSQC4 or {}

-- Хранилища
NSQC4.Modules        = NSQC4.Modules        or {}  -- { [key] = { {fn=..., index=...}, ... } }
NSQC4.ModuleMeta     = NSQC4.ModuleMeta     or {}  -- { [key] = { key, label, tooltip, order, hidden } }
NSQC4.ModuleSettings = NSQC4.ModuleSettings or {}  -- { [key] = opener }

-- ============================================================================
-- Регистрация модуля
--   third = meta (table)  → метаданные группы
--   third = index (number) → глобальный индекс запуска этой функции
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
    local rec = { fn = initFn, index = index, key = key }
    table.insert(NSQC4.Modules[key], rec)

    -- Метаданные: первый вызов с meta побеждает, повторные игнорируются.
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
-- Сбор ВСЕХ функций всех групп в единый список и сортировка.
--
-- Ключевое отличие от старой версии:
--   - раньше SortFns работал внутри одной группы;
--   - теперь все функции всех групп сортируются единым списком.
--
-- Порядок:
--   1) index (число; nil → math.huge, т.е. в конец)
--   2) meta.order группы (при равных index)
--   3) _seq (.toc-порядок регистрации, при равных index и order)
-- ============================================================================
local function CollectAllFns()
    local all = {}
    local seq = 0

    -- Стабильный обход: сначала по ключам (сортировка), потом по записям.
    -- Это даёт детерминированный _seq, если порядок .toc менялся.
    local keys = {}
    for key in pairs(NSQC4.Modules) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        local fns = NSQC4.Modules[key]
        for _, rec in ipairs(fns) do
            seq = seq + 1
            rec._seq = seq
            rec._groupOrder = (NSQC4.ModuleMeta[key] and NSQC4.ModuleMeta[key].order) or 1000
            all[#all + 1] = rec
        end
    end

    return all
end

local function SortAll(all)
    table.sort(all, function(a, b)
        local ia = a.index or math.huge
        local ib = b.index or math.huge
        if ia ~= ib then return ia < ib end

        local oa = a._groupOrder or 1000
        local ob = b._groupOrder or 1000
        if oa ~= ob then return oa < ob end

        return (a._seq or 0) < (b._seq or 0)
    end)
end

-- ============================================================================
-- Запуск одного модуля (по ключу) — сохраняется для совместимости.
-- Сортировка теперь глобальная, поэтому RunModule("quests") вызовет
-- только функции группы quests в их относительном порядке (по index).
-- ============================================================================
local function RunModule(key)
    local fns = NSQC4.Modules[key]
    if not fns then return end

    -- Локальная сортировка группы (для случаев, когда RunModule зовут вручную).
    for i, rec in ipairs(fns) do
        rec._localSeq = i
    end
    table.sort(fns, function(a, b)
        local ia = a.index or math.huge
        local ib = b.index or math.huge
        if ia ~= ib then return ia < ib end
        return (a._localSeq or 0) < (b._localSeq or 0)
    end)

    for _, rec in ipairs(fns) do
        local ok, err = pcall(rec.fn)
        if not ok then
            print(string.format(
                "|cffff0000[NSQC4]|r Ошибка модуля '%s' (index=%s): %s",
                tostring(key), tostring(rec.index), tostring(err)
            ))
        end
    end
end

NSQC4.RunModule = RunModule

-- ============================================================================
-- Публичный запуск ВСЕХ модулей в едином порядке (глобальная сортировка).
-- ============================================================================
local booted = false
function NSQC4.RunModules()
    if booted then return end
    booted = true

    -- 1. Собрать всё, отсортировать глобально.
    local all = CollectAllFns()
    SortAll(all)

    -- 2. Диагностика: план запуска.
    if NSQC4.MODULE_DEBUG then
        print("|cff00ffff[NSQC4]|r План запуска модулей (index | order | key):")
        for i, rec in ipairs(all) do
            print(string.format("  %3d) %6s | %4s | %s",
                i,
                tostring(rec.index or "nil"),
                tostring(rec._groupOrder),
                tostring(rec.key)
            ))
        end
    end

    -- 3. Запустить в глобальном порядке, с учётом включённости модуля.
    for _, rec in ipairs(all) do
        local key = rec.key
        if NSQC4.Settings and NSQC4.Settings.IsModuleEnabled
           and not NSQC4.Settings.IsModuleEnabled(key) then
            -- Модуль выключен — пропустить все его функции.
            -- (Проверяем один раз на функцию, чтобы не зависеть от порядка.)
        else
            local ok, err = pcall(rec.fn)
            if not ok then
                print(string.format(
                    "|cffff0000[NSQC4]|r Ошибка модуля '%s' (index=%s): %s",
                    tostring(key), tostring(rec.index), tostring(err)
                ))
            end
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