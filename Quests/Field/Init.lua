-- ============================================================================
-- NSQC4 / Quests / Field / Init
-- Класс поля квестов 10×10 + метаданные модуля "quests".
--
-- viewMode:
--   "detail"   — обычный вид (10×10 детальных клеток) — по умолчанию.
--   "overview" — вид сверху (10×10 «больших» квадратов, наш этаж — 1 из 100).
--                Управляется через QuestsField:ShowOverview/HideOverview/ToggleOverview.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local COLS, ROWS   = 10, 10
    local CELL_GAP     = 0
    local GRID_PADDING = 40
    local DEFAULT_CELL = 32
    local MIN_CELL     = 10
    local MAX_CELL     = 64
    local SAVE_KEY     = "questsField"

    local QuestsField = {}
    QuestsField.__index = QuestsField

    NSQC4.QuestsFieldClass = QuestsField
    NSQC4.QuestsFieldConst = {
        COLS = COLS, ROWS = ROWS,
        CELL_GAP = CELL_GAP, GRID_PADDING = GRID_PADDING,
        DEFAULT_CELL = DEFAULT_CELL, MIN_CELL = MIN_CELL, MAX_CELL = MAX_CELL,
        SAVE_KEY = SAVE_KEY,
    }

    function QuestsField.new()
        local self = setmetatable({}, QuestsField)
        self.frame         = nil
        self.cells         = {}
        self.borderFrame   = nil
        self.resizeHandle  = nil
        self.closeBtn      = nil
        self.borderVisible = false
        self.cellSize      = nil
        self.saved         = nil
        self.contextMenus  = {} -- Инициализация таблицы контекстных меню

        -- Режим отображения: "detail" (обычный) | "overview" (вид сверху).
        -- Управляется через ShowOverview/HideOverview/ToggleOverview (Overview.lua).
        self.viewMode      = "detail"

        return self
    end

    NSQC4.QuestsField = QuestsField.new()

    NSQC4.SetModuleMeta("quests", {
        label   = "Квесты",
        tooltip = "Поле квестов 10×10.",
        order   = 500,
    })

    SLASH_NSFIELD1 = "/ns_field"
    SlashCmdList["NSFIELD"] = function()
        local inst = NSQC4.QuestsField
        if not inst or not inst.Toggle then
            print("|cffff0000[NSQC4]|r Модуль «Квесты» выключен или не загружен.")
            return
        end
        inst:Toggle()
    end

    if NSQC4.SlashPanel_RegisterSectionButton then
        NSQC4.SlashPanel_RegisterSectionButton(
            "Квесты",
            "П",
            "/ns_field",
            {
                { text = "Поле квестов 10×10",                   r = 1.00, g = 0.82, b = 0.00 },
                { text = " " },
                { text = "ПКМ по полю — рамка, ЛКМ — тянуть",     r = 0.85, g = 0.85, b = 0.85 },
                { text = "Хэндл справа-снизу — размер",           r = 0.85, g = 0.85, b = 0.85 },
            }
        )
    end

end)