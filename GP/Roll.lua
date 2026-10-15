-- ============================================================================
-- NSQC4 / GP / Roll
-- Модуль ролла. Окно как в AUK.lua. ЛКМ/ПКМ по строке — как в аукционе.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    local DEFAULT_ROLL_TIME = 20
    local TICK_INTERVAL     = 0.5

    local CLASS_COLORS = {
        WARRIOR     = "|cffC79C6E", PALADIN = "|cffF58CBA",
        HUNTER      = "|cffABD473", ROGUE   = "|cffFFF569",
        PRIEST      = "|cffFFFFFF", DEATHKNIGHT = "|cffC41F3B",
        SHAMAN      = "|cff0070DE", MAGE    = "|cff69CCF0",
        WARLOCK     = "|cff9482C9", DRUID   = "|cffFF7D0A",
    }

    local rollFrame = nil
    local rollState = nil
    local tickTimer = nil

    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    local function IsRaidLeader()
        if not IsInRaid() then
            return UnitIsPartyLeader("player") == 1
        end
        return UnitIsRaidOfficer("player") == 1
            or UnitIsPartyLeader("player") == 1
    end

    local function GetClassByName(name)
        local short = ShortName(name)
        if not short then return "WARRIOR" end
        for i = 1, GetNumGuildMembers(true) do
            local gName, _, _, _, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
            if gName then
                local gShort = ShortName(gName)
                if gShort == short then
                    return classFile or "WARRIOR"
                end
            end
        end
        return "WARRIOR"
    end

    local function GetItemIdFromLink(link)
        if not link then return nil end
        return link:match("item:(%d+)")
    end

    local function FindLootSlotByLink(link)
        if not link then return nil end
        local targetId = GetItemIdFromLink(link)
        if not targetId then return nil end
        for i = 1, (GetNumLootItems and GetNumLootItems() or 0) do
            local slotLink = GetLootSlotLink(i)
            if slotLink and GetItemIdFromLink(slotLink) == targetId then
                return i
            end
        end
        return nil
    end

    -- ========================================================================
    -- Окно
    -- ========================================================================
    local function CreateRollFrame()
        if rollFrame then return rollFrame end

        local f = CreateFrame("Frame", "NSQC4RollFrame", UIParent)
        f:SetSize(350, 250)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\White8x8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 8, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:SetBackdropColor(0, 0, 0, 0.95)
        f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetFrameStrata("DIALOG")
        f:SetPoint("CENTER")
        f:Hide()

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetSize(24, 24)
        closeBtn:SetPoint("TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function()
            if not rollState then f:Hide(); return end
            if not IsRaidLeader() then
                print("|cffff0000[Roll]|r Только РЛ может отменить ролл.")
                return
            end
            SendAddonMessage("AUC_ROLL_CANCEL", "", "RAID")
            NSQC4.Roll_Stop()
        end)
        f.closeBtn = closeBtn

        f.itemTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.itemTitle:SetPoint("TOPLEFT", 10, -30)
        f.itemTitle:SetPoint("TOPRIGHT", -60, -30)
        f.itemTitle:SetJustifyH("LEFT")
        f.itemTitle:SetText("Ролл")

        local tm = CreateFrame("Frame", nil, f)
        tm:SetAllPoints(f.itemTitle)
        tm:EnableMouse(true)
        tm:SetScript("OnEnter", function()
            if not rollState or not rollState.itemLink then return end
            GameTooltip:SetOwner(tm, "ANCHOR_TOPRIGHT")
            GameTooltip:SetHyperlink(rollState.itemLink)
            GameTooltip:Show()
        end)
        tm:SetScript("OnLeave", function() GameTooltip:Hide() end)

        f.infoText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.infoText:SetPoint("TOPLEFT", 10, -50)
        f.infoText:SetText("Осталось:")

        f.countdownText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.countdownText:SetPoint("TOPRIGHT", -10, -50)
        f.countdownText:SetJustifyH("RIGHT")
        f.countdownText:SetText("20с")

        local div = f:CreateTexture(nil, "OVERLAY")
        div:SetTexture(0.5, 0.5, 0.5, 0.5)
        div:SetSize(f:GetWidth() - 20, 1)
        div:SetPoint("TOPLEFT", 10, -60)
        div:SetPoint("TOPRIGHT", -10, -60)

        local sf = CreateFrame("ScrollFrame", "NSQC4RollScroll", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 10, -65)
        sf:SetPoint("BOTTOMRIGHT", -25, 55)

        local content = CreateFrame("Frame", "NSQC4RollContent", sf)
        content:SetSize(300, 100)
        sf:SetScrollChild(content)
        f.content = content
        content.rows = {}

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(80, 22)
        addBtn:SetPoint("BOTTOMLEFT", 10, 10)
        addBtn:SetText("+10 сек")
        addBtn:SetScript("OnClick", function()
            if not rollState then return end
            if not IsRaidLeader() then
                print("|cffff0000[Roll]|r Только РЛ может продлить таймер.")
                return
            end
            SendChatMessage("-время 10", "RAID")
        end)
        f.addBtn = addBtn

        rollFrame = f
        return f
    end

    -- ========================================================================
    -- Отрисовка
    -- ========================================================================
    local function RefreshRollFrame()
        if not rollFrame or not rollState then return end

        if rollFrame.content.rows then
            for _, row in ipairs(rollFrame.content.rows) do
                if row then row:Hide(); row:SetParent(nil) end
            end
        end
        rollFrame.content.rows = {}

        rollFrame.itemTitle:SetText(rollState.item or "Предмет")
        if rollState.itemLink then
            local hex = rollState.itemLink:match("|cff(%x%x%x%x%x%x)")
            if hex then
                rollFrame.itemTitle:SetTextColor(
                    tonumber(hex:sub(1, 2), 16) / 255,
                    tonumber(hex:sub(3, 4), 16) / 255,
                    tonumber(hex:sub(5, 6), 16) / 255)
            else
                rollFrame.itemTitle:SetTextColor(1, 1, 1)
            end
        end

        local list = {}
        for name, value in pairs(rollState.rolls) do
            list[#list + 1] = {
                name = name,
                value = value,
                banned = rollState.banned and rollState.banned[name] or false,
            }
        end
        table.sort(list, function(a, b) return a.value > b.value end)

        local content = rollFrame.content
        local totalHeight = 5
        local rowHeight = 22
        local maxRowWidth = 280
        local myName = UnitName("player")
        local isRL = IsRaidLeader()

        for i, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, content)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", 10, -totalHeight)
            row:SetPoint("TOPRIGHT", -10, -totalHeight)
            row:EnableMouse(true)
            local cc = CLASS_COLORS[GetClassByName(entry.name)] or CLASS_COLORS.WARRIOR

            local nt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nt:SetPoint("LEFT", 5, 0)
            local nameColor = entry.banned and "|cffff0000"
                or (entry.name == myName and "|cffffd100" or cc)
            local banSuffix = entry.banned and " |cffff0000[ЗАБАНЕН]|r" or ""
            nt:SetText(nameColor .. entry.name .. banSuffix .. "|r")

            local bt = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            bt:SetPoint("RIGHT", -5, 0)
            if entry.banned then
                bt:SetText("|cffff0000БАН|r")
            elseif i == 1 then
                bt:SetText("|cff00ff00" .. entry.value .. "|r")
            else
                bt:SetText(tostring(entry.value))
            end

            row:SetScript("OnMouseUp", function(_, button)
                if not rollState or not isRL then return end
                if button == "LeftButton" and not entry.banned then
                    NSQC4.ShowConfirm(
                        "Назначить победителем?",
                        "Назначить " .. entry.name .. " победителем (ролл " .. entry.value .. ")?",
                        function() NSQC4.Roll_GiveTo(entry.name, entry.value) end,
                        nil)
                elseif button == "RightButton" and not entry.banned then
                    NSQC4.ShowConfirm(
                        "Забанить игрока?",
                        "Игрок " .. entry.name .. " будет исключён из ролла.",
                        function()
                            rollState.banned = rollState.banned or {}
                            rollState.banned[entry.name] = true
                            rollState.rolls[entry.name] = nil
                            SendAddonMessage("AUC_ROLL_BAN", entry.name, "RAID")
                            RefreshRollFrame()
                        end,
                        nil)
                end
            end)

            row:Show()
            content.rows[i] = row
            local rw = nt:GetStringWidth() + 20 + bt:GetStringWidth() + 25
            if rw > maxRowWidth then maxRowWidth = rw end
            totalHeight = totalHeight + rowHeight
        end

        if #list == 0 then
            local er = CreateFrame("Frame", nil, content)
            er:SetHeight(rowHeight)
            er:SetPoint("TOPLEFT", 10, -totalHeight)
            er:SetPoint("TOPRIGHT", -10, -totalHeight)
            local et = er:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            et:SetPoint("CENTER", 0, 0)
            et:SetText("|cff808080Ожидание роллов...|r")
            er:Show()
            content.rows[1] = er
            totalHeight = totalHeight + rowHeight
        end

        content:SetHeight(totalHeight + 10)
        content:SetWidth(maxRowWidth)
        rollFrame:SetSize(maxRowWidth + 20, totalHeight + 140)
    end

    -- ========================================================================
    -- Таймер
    -- ========================================================================
    local function UpdateTimer()
        if not rollFrame or not rollState then return end
        local rem = math.max(0, math.floor(rollState.timerEnd - GetTime()))
        rollFrame.countdownText:SetText(rem .. "с")
        if rem <= 5 then
            rollFrame.countdownText:SetTextColor(1, 0.3, 0.3)
        else
            rollFrame.countdownText:SetTextColor(1, 1, 1)
        end
    end

    local function StartTicker()
        if tickTimer then return end
        tickTimer = CreateFrame("Frame")
        local elapsed = 0
        tickTimer:SetScript("OnUpdate", function(_, dt)
            if not rollState then
                tickTimer:SetScript("OnUpdate", nil)
                tickTimer = nil
                return
            end
            elapsed = elapsed + dt
            if elapsed >= TICK_INTERVAL then
                elapsed = 0
                UpdateTimer()
            end
            if rollState.isLeader and GetTime() >= rollState.timerEnd then
                NSQC4.Roll_Finish()
            end
        end)
    end

    local function StopTicker()
        if tickTimer then
            tickTimer:SetScript("OnUpdate", nil)
            tickTimer = nil
        end
    end

    -- ========================================================================
    -- API
    -- ========================================================================
    function NSQC4.Roll_GiveTo(playerName, value)
        if not rollState then return end
        if not IsRaidLeader() then return end
        if rollState.banned and rollState.banned[playerName] then return end

        local itemLink = rollState.itemLink
        local slot = FindLootSlotByLink(itemLink)
        if not slot or not LootFrame or not LootFrame:IsShown() then
            print("|cffff0000[Roll]|r Окно лута закрыто или предмет не найден.")
            NSQC4.Roll_Stop()
            return
        end

        local lower = string.lower(playerName)
        local found = false

        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local cand = GetMasterLootCandidate(i)
                if cand and string.lower(cand) == lower then
                    GiveMasterLoot(slot, i)
                    found = true
                    break
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() + 1 do
                local cand = GetMasterLootCandidate(i)
                if cand and string.lower(cand) == lower then
                    GiveMasterLoot(slot, i)
                    found = true
                    break
                end
            end
        end

        if found then
            SendChatMessage(playerName .. " выиграл " .. (itemLink or "?") .. " с роллом " .. (value or 0), "RAID_WARNING")
        else
            print("|cffff0000[Roll]|r Не удалось выдать лут: " .. playerName)
        end

        SendAddonMessage("AUC_ROLL_CANCEL", "", "RAID")
        NSQC4.Roll_Stop()
    end

    function NSQC4.Roll_Finish()
        if not rollState or not rollState.isLeader then return end
        local winner, winnerValue = nil, -1
        for name, value in pairs(rollState.rolls) do
            if not (rollState.banned and rollState.banned[name]) then
                if value > winnerValue then
                    winner = name
                    winnerValue = value
                end
            end
        end
        if not winner then
            SendChatMessage("Ролл по " .. (rollState.itemLink or "?") .. ": никто не бросил.", "RAID_WARNING")
            NSQC4.Roll_Stop()
            return
        end
        NSQC4.Roll_GiveTo(winner, winnerValue)
    end

    function NSQC4.Roll_Start(itemLink, itemName, duration)
        if rollState then return end
        rollState = {
            itemLink = itemLink,
            item     = itemName or "Предмет",
            rolls    = {},
            banned   = {},
            timerEnd = GetTime() + (duration or DEFAULT_ROLL_TIME),
            isLeader = IsRaidLeader(),
        }
        StartTicker()
        local f = CreateRollFrame()
        f:Show()
        f:Raise()
        RefreshRollFrame()
        UpdateTimer()
    end

    function NSQC4.Roll_Stop()
        rollState = nil
        StopTicker()
        if rollFrame then
            rollFrame:Hide()
            if rollFrame.content and rollFrame.content.rows then
                for _, row in ipairs(rollFrame.content.rows) do
                    if row then row:Hide(); row:SetParent(nil) end
                end
                rollFrame.content.rows = {}
            end
        end
    end

    local function RegisterRoll(name, value)
        if not rollState then return end
        value = tonumber(value)
        if not name or not value then return end
        if rollState.banned and rollState.banned[name] then return end
        rollState.rolls[name] = value
        RefreshRollFrame()
    end

    -- ========================================================================
    -- События
    -- ========================================================================
    local sysFrame = CreateFrame("Frame")
    sysFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    sysFrame:RegisterEvent("CHAT_MSG_RAID")
    sysFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    sysFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    sysFrame:RegisterEvent("CHAT_MSG_ADDON")

    sysFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_SYSTEM" then
            local msg = ...
            if not msg or not rollState then return end
            local name, n, min, max = msg:match("^(%S+)%s+выбрасывает%s+(%d+)%s+%((%d+)%-(%d+)%)$")
            if not name then return end
            local value, minV, maxV = tonumber(n), tonumber(min), tonumber(max)
            if not value or minV ~= 1 or maxV ~= 100 then return end
            RegisterRoll(name, value)
            return
        end

        if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" then
            local msg = ...
            if not msg then return end
            local itemLink = msg:match("^%s*%-ролл%s*(|c%x+|Hitem:.-|h.-|h|r)")
            if itemLink then
                if not rollState then
                    local itemName = itemLink:match("|h%[(.-)%]|h") or "Предмет"
                    NSQC4.Roll_Start(itemLink, itemName, DEFAULT_ROLL_TIME)
                end
                return
            end
            local addTime = tonumber(msg:match("^%s*%-время%s+(%d+)"))
            if addTime and rollState then
                rollState.timerEnd = rollState.timerEnd + addTime
                UpdateTimer()
                return
            end
        end

        if event == "CHAT_MSG_ADDON" then
            local prefix, addonMsg, _, sender = ...
            if not prefix or not sender then return end
            if prefix == "AUC_ROLL_START" and not rollState then
                local itemLink, duration = addonMsg:match("^([^|]+)|(%d+)$")
                if itemLink then
                    local itemName = itemLink:match("|h%[(.-)%]|h") or "Предмет"
                    NSQC4.Roll_Start(itemLink, itemName, tonumber(duration) or DEFAULT_ROLL_TIME)
                end
                return
            end
            if prefix == "AUC_ROLL_CANCEL" then
                if rollState then NSQC4.Roll_Stop() end
                return
            end
            if prefix == "AUC_ROLL_BAN" and rollState then
                rollState.banned = rollState.banned or {}
                rollState.banned[addonMsg] = true
                rollState.rolls[addonMsg] = nil
                RefreshRollFrame()
                return
            end
        end
    end)

end)