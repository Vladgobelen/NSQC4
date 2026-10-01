local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("gp") then return end















NSQC4 = NSQC4 or {}
if not NSQC4.Settings.IsModuleEnabled("gp") then return end

-- ============================================================================
-- NSQC4 Boss Loot → GP assign
-- При открытии лута с босса РЛом — вывод предметов в чат и кнопки начисления ГП.
-- ============================================================================

local BOSS_LOOT_GP_VALUES = { 5, 10, 20, 50 }
local BOSS_LOOT_BUTTON_TIMEOUT = 15
local BOSS_LOOT_FRAME_HEIGHT = 55

bossLootDone = bossLootDone or {}
local bossLootFrame
local bossLootTimer
local bossLootEditBox

-- ============================================================================
-- Проверка «в гильдии ли игрок»
-- ============================================================================
local function IsInMyGuild(playerName)
    if not playerName then return false end
    local shortTarget = playerName:match("^([^%-]+)") or playerName
    for i = 1, GetNumGuildMembers(true) do
        local gname = GetGuildRosterInfo(i)
        if gname then
            local gshort = gname:match("^([^%-]+)") or gname
            if gshort == shortTarget then return true end
        end
    end
    return false
end

-- ============================================================================
-- Рассылка ГП всему рейду
-- ============================================================================
local function AssignGpToRaid(value)
    value = tonumber(value)
    if not value or value == 0 then return end

    local inRaid = IsInRaid()
    local numMembers = GetNumGroupMembers()
    local logStr = "Рейд " .. value
    local count = 0

    for i = 1, numMembers do
        local unit
        if inRaid then
            unit = "raid" .. i
        else
            unit = (i == 1) and "player" or ("party" .. (i - 1))
        end

        local nick = UnitName(unit)
        if nick then
            local shortNick = nick:match("^([^%-]+)") or nick
            local isGuild = IsInMyGuild(shortNick)
            local prefix = isGuild and "nsGP1" or "nsGP1A"
            SendAddonMessage(prefix .. " " .. value, shortNick, "GUILD")
            logStr = logStr .. " " .. shortNick
            count = count + 1
        end
    end

    SendAddonMessage("nsGPlog", logStr, "GUILD")
    print("|cff00ff00[NSQC4]|r Начислено " .. value .. " ГП " .. count .. " игрокам рейда")
end

-- ============================================================================
-- Скрытие панели
-- ============================================================================
local function HideBossLootButtons()
    if bossLootTimer then
        bossLootTimer:SetScript("OnUpdate", nil)
        bossLootTimer = nil
    end
    if bossLootFrame then
        bossLootFrame:Hide()
    end
    if bossLootEditBox then
        bossLootEditBox:Hide()
    end
end

local function ShowBossLootButtons()
    if not bossLootFrame then
        local f = CreateFrame("Frame", "NSQC4BossLootFrame", UIParent)
        f:SetSize(300, BOSS_LOOT_FRAME_HEIGHT)
        f:SetFrameStrata("TOOLTIP")

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", f, "TOP", 0, -5)
        title:SetText("Начислить ГП рейду:")
        title:SetTextColor(1, 0.82, 0)

        local xOffset = 10
        for _, value in ipairs(BOSS_LOOT_GP_VALUES) do
            local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            btn:SetSize(40, 20)
            btn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, -25)
            btn:SetText(tostring(value))
            btn:SetScript("OnClick", function()
                AssignGpToRaid(value)
                HideBossLootButtons()
            end)
            xOffset = xOffset + 45
        end

        local qBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        qBtn:SetSize(30, 20)
        qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, -25)
        qBtn:SetText("?")
        qBtn:SetScript("OnClick", function()
            if bossLootEditBox then
                bossLootEditBox:Show()
                bossLootEditBox:SetFocus()
            end
        end)

        local eb = CreateFrame("EditBox", "NSQC4BossLootEditBox", f, "InputBoxTemplate")
        eb:SetSize(60, 20)
        eb:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset + 35, -25)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(6)
        eb:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then
                AssignGpToRaid(v)
            end
            self:SetText("")
            self:ClearFocus()
            HideBossLootButtons()
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:Hide()
            self:ClearFocus()
        end)
        eb:Hide()

        bossLootFrame = f
        bossLootEditBox = eb
    end

    bossLootFrame:ClearAllPoints()
    if LootFrame and LootFrame:IsShown() then
        bossLootFrame:SetPoint("BOTTOM", LootFrame, "TOP", 0, 5)
    else
        bossLootFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end

    bossLootFrame:Show()

    if bossLootTimer then
        bossLootTimer:SetScript("OnUpdate", nil)
    end
    bossLootTimer = bossLootTimer or CreateFrame("Frame")
    local elapsed = 0
    bossLootTimer:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= BOSS_LOOT_BUTTON_TIMEOUT then
            self:SetScript("OnUpdate", nil)
            HideBossLootButtons()
        end
    end)
end

-- ============================================================================
-- Обработка LOOT_OPENED
-- ============================================================================
local function OnBossLootOpened()
    if not IsRaidLeader() then return end
    if UnitLevel("target") ~= -1 then return end
    
    local guid = UnitGUID("target")
    if not guid then return end
    if bossLootDone[guid] then return end
    bossLootDone[guid] = true
    
    local numItems = GetNumLootItems()
    if numItems == 0 then return end
    
    local items = {}
    for i = 1, numItems do
        if LootSlotIsItem(i) then
            local _, _, _, rarity = GetLootSlotInfo(i)
            local link = GetLootSlotLink(i)
            if link and rarity and rarity >= 4 then
                table.insert(items, link)
            end
        end
    end
    
    if #items == 0 then return end
    
    local bossName = UnitName("target") or "Босс"
    SendChatMessage("=== Лут с " .. bossName .. " ===", "RAID")
    for _, link in ipairs(items) do
        SendChatMessage(link, "RAID")
    end
    
    ShowBossLootButtons()
end

-- ============================================================================
-- Подписка
-- ============================================================================
local lootFrame = CreateFrame("Frame")
lootFrame:RegisterEvent("LOOT_OPENED")
lootFrame:SetScript("OnEvent", OnBossLootOpened)

local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    bossLootDone = {}
end)

-- ============================================================================
-- ПКМ/колесо по слоту лута → отправка "АУК <itemlink>" в RAID_WARNING
-- ============================================================================

-- Переопределяем LootButton_OnClick: MiddleButton → только АУК (лут не берётся),
-- LeftButton/RightButton → стандартное поведение
local origLootButton_OnClick = LootButton_OnClick

LootButton_OnClick = function(self, button)
    if button == "MiddleButton" then
        if IsRaidLeader() then
            local slot = self:GetID()
            local link = GetLootSlotLink(slot)
            if link then
                SendChatMessage("АУК " .. link, "RAID_WARNING")
            end
        end
        return
    end
    if origLootButton_OnClick then
        return origLootButton_OnClick(self, button)
    end
end

-- При каждом показе окна лута — регистрируем среднюю кнопку на слотах
local origLootFrame_Show = LootFrame_Show

LootFrame_Show = function(...)
    if origLootFrame_Show then origLootFrame_Show(...) end
    for i = 1, 4 do
        local btn = _G["LootButton" .. i]
        if btn then
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        end
    end
end


































end -- конец функции настроек

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)