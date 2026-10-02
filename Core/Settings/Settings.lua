-- ============================================================================
-- NSQC4 / Core / Settings / Settings
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Settings = NSQC4.Settings or {}

-- Всегда гарантируем существование структуры
local function EnsureSettings()
    nsDbc4 = nsDbc4 or {}
    nsDbc4.settings = nsDbc4.settings or {}
    nsDbc4.settings.disabled = nsDbc4.settings.disabled or {}
    return nsDbc4.settings
end

EnsureSettings()

-- ============================================================================
-- API
-- ============================================================================

function NSQC4.Settings.IsModuleEnabled(name)
    local s = EnsureSettings()
    return not s.disabled[name]
end

function NSQC4.Settings.SetModuleEnabled(name, enabled)
    local s = EnsureSettings()
    if enabled then
        s.disabled[name] = nil
    else
        s.disabled[name] = true
    end
end

NSQC4.Settings.MODULES = {
    { key = "gp",        label = "ГП / Аукцион / Лут" },
    { key = "promote",   label = "Повышение" },
    { key = "demote",    label = "Понижение" },
    { key = "kick",      label = "Кик неактивных" },
    { key = "boobs",     label = "Сиськи" },
    { key = "bs_player", label = "БС: игрока" },
    { key = "bs_item",   label = "БС: на предметах" },
    { key = "bs_chat",   label = "БС: команда -илвл" },
    { key = "itemlevel", label = "Средний илвл" },
}