-- ============================================================================
-- NSQC4 / Core / Settings / OptionsPanel
-- Панель настроек в стандартном меню: Интерфейс → Модификации → NSQC4.
-- Две колонки чекбоксов + скролл (на случай переполнения).
--
-- ВАЖНО: чекбоксы строятся ЛЕНИВО в OnShow, а не на этапе загрузки файла.
-- Причина: OptionsPanel.lua грузится из .toc РАНЬШЕ, чем большинство модулей
-- вызывают NSQC4.RegisterModule(...). Если строить список сразу при загрузке,
-- NSQC4.ModuleMeta ещё пуст (или почти пуст) — чекбоксы не создаются.
-- К моменту первого OnShow все файлы .toc уже загружены и все модули
-- зарегистрированы, поэтому GetModules() вернёт полный список.
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
local GEAR_SIZE    = 18       -- размер кнопки "*"
local GEAR_GAP     = 4        -- зазор между "*" и чекбоксом

-- ============================================================================
-- Состояние
-- ============================================================================
local checkboxes = {}
local gears = {}      -- [key] = кнопка "*"
local built = false

-- ============================================================================
-- Ленивая сборка чекбоксов
-- Вызывается один раз при первом показе панели.
-- ============================================================================
local function BuildCheckboxes()
    if built then return end
    built = true

    local row = 0
    local col = 1

    for _, mod in ipairs(NSQC4.Settings.GetModules()) do
        local xPos = (col == 1) and COL_LEFT_X or COL_RIGHT_X
        local yPos = TOP_OFFSET - row * ROW_HEIGHT

        -- Кнопка "*" — СЛЕВА от чекбокса, на всю высоту строки.
        -- Создаётся всегда, видимость синхронизируется в UpdateCheckboxes.
        local gear = CreateFrame("Button", "NSQC4ModuleGear_" .. mod.key, content, "UIPanelButtonTemplate")
        gear:SetSize(GEAR_SIZE, GEAR_SIZE)
        gear:SetPoint("TOPLEFT", xPos, yPos - (24 - GEAR_SIZE) / 2)
        gear:SetText("*")
        gear.moduleKey = mod.key
        gear:Hide()

        local gfs = gear:GetFontString()
        if gfs then gfs:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE") end

        gear:SetScript("OnClick", function(self)
            NSQC4.OpenModuleSettings(self.moduleKey)
        end)

        gear:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Настройки модуля", 1, 0.82, 0)
            GameTooltip:AddLine(mod.label, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        gear:SetScript("OnLeave", function() GameTooltip:Hide() end)

        gears[mod.key] = gear

        -- Чекбокс — СПРАВА от кнопки "*"
        local cb = CreateFrame("CheckButton", "NSQC4Module_" .. mod.key, content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", gear, "TOPRIGHT", GEAR_GAP, (24 - GEAR_SIZE) / 2)
        cb:SetSize(24, 24)

        local label = _G[cb:GetName() .. "Text"]
        if label then
            label:SetText(mod.label)
            label:SetWidth(190)
            label:SetJustifyH("LEFT")
        end

        cb.moduleKey = mod.key

        -- Тултип на чекбокс
        if mod.tooltip and mod.tooltip ~= "" then
            cb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(mod.label, 1, 0.82, 0)
                GameTooltip:AddLine(mod.tooltip, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            cb:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        cb:SetScript("OnClick", function(self)
            local enabled = self:GetChecked() and true or false
            NSQC4.Settings.SetModuleEnabled(self.moduleKey, enabled)
            print("|cff00ff00[NSQC4]|r Модуль '" .. mod.label .. "': " ..
                  (enabled and "включён" or "выключен") .. " (нужен /reload)")
        end)

        checkboxes[mod.key] = cb

        if col == 1 then
            col = 2
        else
            col = 1
            row = row + 1
        end
    end

    local totalRows = row + ((col == 2) and 1 or 0)
    content:SetHeight(math.abs(TOP_OFFSET) + totalRows * ROW_HEIGHT + 20)
end

-- ============================================================================
-- Обновление состояния галочек и видимости кнопок "*"
-- ============================================================================
local function UpdateCheckboxes()
    for key, cb in pairs(checkboxes) do
        cb:SetChecked(NSQC4.Settings.IsModuleEnabled(key))

        local gear = gears[key]
        if gear then
            if NSQC4.HasModuleSettings and NSQC4.HasModuleSettings(key) then
                gear:Show()
            else
                gear:Hide()
            end
        end
    end
end

-- ============================================================================
-- OnShow: первый раз строим, всегда синхронизируем галочки и кнопки
-- ============================================================================
panel:SetScript("OnShow", function()
    BuildCheckboxes()
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