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
        aliases = {},
        channels = {
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
            showBorder     = true,   -- рамка окна
            showInputIdle  = true,   -- строка ввода видна в покое
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

    -- Миграция старых сохранений: если полей нет — создаём дефолты
    if not C.db.settings.offsets then
        C.db.settings.offsets = {}
    end
    if C.db.settings.showBorder == nil then
        C.db.settings.showBorder = true
    end
    if C.db.settings.showInputIdle == nil then
        C.db.settings.showInputIdle = true
    end

end)