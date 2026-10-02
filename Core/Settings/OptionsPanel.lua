-- ============================================================================
-- NSQC4 / Core / Settings / OptionsPanel
-- Панель настроек в стандартном меню: Интерфейс → Модификации → NSQC4.
-- Две колонки чекбоксов + скролл (на случай переполнения).
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Settings = NSQC4.Settings or {}

-- ============================================================================
-- Внешняя панель (регистрируется в InterfaceOptionsFrame)
-- ============================================================================
local panel = CreateFrame("Frame", "NSQC4OptionsPanel", InterfaceOptionsFrame)
panel.name = "NSQC4"

-- ============================================================================
-- Заголовок и предупреждение (вне скролла, всегда видны)
-- ============================================================================
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("NSQC4")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Модули аддона")

local warn = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
warn:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -4)
warn:SetText("|cffff8080Изменения применяются после /reload|r")

-- ============================================================================
-- Скролл с контентом
-- ============================================================================
local scrollFrame = CreateFrame("ScrollFrame", "NSQC4OptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -70)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(500, 10)
scrollFrame:SetScrollChild(content)

-- ============================================================================
-- Параметры раскладки
-- ============================================================================
local COL_LEFT_X   = 10       -- отступ первой колонки
local COL_RIGHT_X  = 250      -- отступ второй колонки
local ROW_HEIGHT   = 30       -- высота строки (чекбокс + отступ)
local TOP_OFFSET   = -10      -- стартовый отступ сверху

-- ============================================================================
-- Создание чекбоксов
-- ============================================================================
local checkboxes = {}
local row = 0
local col = 1

for _, mod in ipairs(NSQC4.Settings.MODULES) do
    local xPos = (col == 1) and COL_LEFT_X or COL_RIGHT_X
    local yPos = TOP_OFFSET - row * ROW_HEIGHT

    local cb = CreateFrame("CheckButton", "NSQC4Module_" .. mod.key, content, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", xPos, yPos)
    cb:SetSize(24, 24)

    local label = _G[cb:GetName() .. "Text"]
    if label then
        label:SetText(mod.label)
        -- ограничим ширину, чтобы длинные названия не наезжали на вторую колонку
        label:SetWidth(200)
        label:SetJustifyH("LEFT")
    end

    cb.moduleKey = mod.key

    cb:SetScript("OnClick", function(self)
        local enabled = self:GetChecked() == 1
        NSQC4.Settings.SetModuleEnabled(self.moduleKey, enabled)
        print("|cff00ff00[NSQC4]|r Модуль '" .. mod.label .. "': " ..
              (enabled and "включён" or "выключен") .. " (нужен /reload)")
    end)

    checkboxes[mod.key] = cb

    -- переход на следующую позицию
    if col == 1 then
        col = 2
    else
        col = 1
        row = row + 1
    end
end

-- Если последний ряд был неполным — увеличим row для правильной высоты
-- (у нас чётное число модулей, но на будущее)
local totalRows = row + ((col == 2) and 1 or 0)
content:SetHeight(math.abs(TOP_OFFSET) + totalRows * ROW_HEIGHT + 20)

-- ============================================================================
-- Обновление состояния галочек при показе панели
-- ============================================================================
local function UpdateCheckboxes()
    for _, mod in ipairs(NSQC4.Settings.MODULES) do
        local cb = checkboxes[mod.key]
        if cb then
            cb:SetChecked(NSQC4.Settings.IsModuleEnabled(mod.key))
        end
    end
end

panel:SetScript("OnShow", function()
    UpdateCheckboxes()
end)

-- ============================================================================
-- Регистрация панели в стандартном меню модификаций
-- ============================================================================
InterfaceOptions_AddCategory(panel)

-- ============================================================================
-- Открытие панели извне (ПКМ по иконке и т.п.)
-- ============================================================================
function NSQC4.Settings.OpenPanel()
    InterfaceOptionsFrame_OpenToCategory("NSQC4")
    InterfaceOptionsFrame_OpenToCategory("NSQC4")   -- второй раз — фикс Blizzard UI
end