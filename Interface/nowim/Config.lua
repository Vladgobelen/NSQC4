-- ============================================================================
-- NSQC4 / nowim / Config
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    NSQC4.Nowim = NSQC4.Nowim or {}
    local C = {}
    NSQC4.Nowim.Config = C

    C.MAX_BYTES        = 250
    C.SEND_DELAY       = 1.0
    C.MAX_HISTORY      = 500
    C.ADDON_PREFIX     = "NSMSG"
    C.DEFAULT_W        = 500
    C.DEFAULT_H        = 450
    C.MIN_W            = 200
    C.MIN_H            = 150

    C.COLOR_BG         = {0.05, 0.05, 0.05, 0.95}
    C.COLOR_BORDER     = {0.4, 0.4, 0.4, 1}
    C.COLOR_MY_MSG     = "|cff00ff00"
    C.COLOR_OTHER_MSG  = "|cffffffff"
    C.COLOR_TIME       = "|cff808080"
    C.COLOR_ALT_CHAR   = "|cffFF8C00"

    nsDbc4 = nsDbc4 or {}
    nsDbc4.nowim = nsDbc4.nowim or {
        dialogs = {},
        archives = {},
        aliases = {},
        channels = {
            ["GENERAL"] = { type = "GENERAL", name = "Общий" },
            ["GUILD"]   = { type = "GUILD",   name = "Гильдия" },
            ["OFFICER"] = { type = "OFFICER", name = "Офицерский" },
            ["RAID"]    = { type = "RAID",    name = "Рейд" },
        },
        settings = {
            mergeChats     = false,
            playSound      = true,
            fontSize       = 12,
            autoScroll     = true,
            interceptEnter = false,
            offsets        = {},
            showBorder     = true,
            showInputIdle  = true,
            showOfficerInGuild = false, -- НОВАЯ НАСТРОЙКА
            filters        = {
                GUILD = true, RAID = true, PARTY = true, WHISPER = true,
                SYSTEM = true, SAY = true, YELL = true
            },
        },
        window = {
            point = "CENTER", relPoint = "CENTER",
            x = 0, y = 0,
            w = C.DEFAULT_W, h = C.DEFAULT_H
        },
        openTabs = {},
        activeTab = nil,
        savedScroll = {},
    }

    C.db = nsDbc4.nowim

    -- Миграция старых сохранений
    if not C.db.settings.offsets then C.db.settings.offsets = {} end
    if C.db.settings.showBorder == nil then C.db.settings.showBorder = true end
    if C.db.settings.showInputIdle == nil then C.db.settings.showInputIdle = true end
    if C.db.settings.showOfficerInGuild == nil then C.db.settings.showOfficerInGuild = false end
    if not C.db.archives then C.db.archives = {} end

    -- НОВОЕ: где сейчас фокус ввода ("nowim" | "blizz")
    if C.db.settings.lastChatFocus == nil then C.db.settings.lastChatFocus = "nowim" end
end)