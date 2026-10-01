-- ============================================================================
-- NSQC4 / Core / Settings / OptionsPanel
-- Панель настроек в стандартном меню: Интерфейс → Модификации → NSQC4.
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.Settings = NSQC4.Settings or {}

local panel = CreateFrame("Frame", "NSQC4OptionsPanel", InterfaceOptionsFrame)
panel.name = "NSQC4"

-- Заголовок
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("NSQC4")

-- Подзаголовок
local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Модули аддона")

-- Предупреждение про /reload
local warn = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
warn:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
warn:SetText("|cffff8080Изменения применяются после /reload|r")

-- Чекбоксы модулей
local checkboxes = {}
local yOffset = -70

for _, mod in ipairs(NSQC4.Settings.MODULES) do
    local cb = CreateFrame("CheckButton", "NSQC4Module_" .. mod.key, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, yOffset)
    cb:SetSize(24, 24)

    local label = _G[cb:GetName() .. "Text"]
    if label then
        label:SetText(mod.label)
    end

    cb.moduleKey = mod.key

    cb:SetScript("OnClick", function(self)
        local enabled = self:GetChecked() == 1
        NSQC4.Settings.SetModuleEnabled(self.moduleKey, enabled)
        print("|cff00ff00[NSQC4]|r Модуль '" .. mod.label .. "': " ..
              (enabled and "включён" or "выключен") .. " (нужен /reload)")
    end)

    checkboxes[mod.key] = cb
    yOffset = yOffset - 30
end

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

panel:SetScript("OnShow", function(self)
    UpdateCheckboxes()
end)

-- Регистрация панели
InterfaceOptions_AddCategory(panel)

-- ============================================================================
-- Открытие панели извне
-- ============================================================================
function NSQC4.Settings.OpenPanel()
    InterfaceOptionsFrame_OpenToCategory("NSQC4")
    InterfaceOptionsFrame_OpenToCategory("NSQC4")
end