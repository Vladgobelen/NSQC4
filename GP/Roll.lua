-- ============================================================================
-- NSQC4 / GP / Roll
-- Модуль ролла. Окно как в AUK.lua. ЛКМ/ПКМ по строке — как в аукционе.
--
-- ИСПРАВЛЕНО:
--  1) Роллы читаются ТОЛЬКО из CHAT_MSG_SYSTEM (там они приходят у всех).
--     Парсер устойчив: срезает "[...] ", хвостовые пробелы, RU "бросает",
--     EN "rolls", fallback без слова.
--  2) Убрано дублирование пересылки в OFFICER (раньше уходило 2 раза).
--  3) RegisterRoll нормализует имя (срезает "-реалм").
--  4) CHAT_MSG_RAID* больше не парсит роллы — только -время N.
--  5) Roll_Start с silent=true всё равно рассылает AUC_ROLL_START,
--     чтобы окно открывалось у всех.
--  6) Команды РОЛЛ / ролл / -ролл / -РОЛЛ ловятся байтово (UTF-8).
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    local DEFAULT_ROLL_TIME = 20
    local TICK_INTERVAL     = 0.5
    local ADDON_PREFIX      = "AUC_ROLL_START"
    local ADDON_CANCEL      = "AUC_ROLL_CANCEL"
    local ADDON_BAN         = "AUC_ROLL_BAN"
    local ADDON_SEP         = "@@"

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

    local function GetClassAndNote(name)
        local short = ShortName(name)
        if not short then return "WARRIOR", "" end
        for i = 1, GetNumGuildMembers(true) do
            local gName, _, _, _, _, _, publicNote, _, _, _, classFile = GetGuildRosterInfo(i)
            if gName then
                local gShort = ShortName(gName)
                if gShort == short then
                    return classFile or "WARRIOR", publicNote or ""
                end
            end
        end
        return "WARRIOR", ""
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
    -- Парсер строки ролла из CHAT_MSG_SYSTEM
    --   "Имя бросает 42 (1-100)"
    --   "Name rolls 42 (1-100)"
    --   "[Рейд] Имя бросает 42 (1-100)"
    --   "Имя бросает 42 (1-100) " (хвостовой пробел)
    -- ========================================================================
    local function TryParseRoll(msg)
        if not msg then return nil end

        -- 1) Срезаем префикс канала вида "[Рейд] " / "[Raid] " / "[Гильдия] "
        local s = msg:gsub("^%[.-%]%s*", "")
        -- 2) Срезаем хвостовые пробелы
        s = s:gsub("%s+$", "")

        -- 3) Основной паттерн: "Имя <что-угодно-нежадно> N (min-max)"
        --    ".-" нежадный, чтобы не съесть лишние цифры.
        local name, value, minV, maxV =
            s:match("^(%S+)%s+.-(%d+)%s*%((%d+)%-(%d+)%)$")

        -- 4) Fallback: "Имя N (min-max)" без слова между
        if not name then
            name, value, minV, maxV =
                s:match("^(%S+)%s+(%d+)%s*%((%d+)%-(%d+)%)$")
        end
        if not name then return nil end

        local n  = tonumber(value)
        local mn = tonumber(minV)
        local mx = tonumber(maxV)
        if not n or mn ~= 1 or mx ~= 100 then return nil end

        -- 5) Срезаем "-реалм", если есть
        name = name:match("^([^%-]+)") or name

        return name, n
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
            SendAddonMessage(ADDON_CANCEL, "", "RAID")
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
            SendChatMessage("-время 10", "RAID_WARNING")
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

            local class, publicNote = GetClassAndNote(entry.name)
            local cc = CLASS_COLORS[class] or CLASS_COLORS.WARRIOR

            local nt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nt:SetPoint("LEFT", 5, 0)
            local nameColor = entry.banned and "|cffff0000"
                or (entry.name == myName and "|cffffd100" or cc)
            local banSuffix = entry.banned and " |cffff0000[ЗАБАНЕН]|r" or ""
            local dn = entry.name
            if publicNote and publicNote ~= "" then
                dn = dn .. " (" .. publicNote .. ")"
            end
            nt:SetText(nameColor .. dn .. banSuffix .. "|r")

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
                            SendAddonMessage(ADDON_BAN, entry.name, "RAID")
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

        SendAddonMessage(ADDON_CANCEL, "", "RAID")
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

    function NSQC4.Roll_Start(itemLink, itemName, duration, silent)
        if rollState then return end
        local dur = duration or DEFAULT_ROLL_TIME
        rollState = {
            itemLink = itemLink,
            item     = itemName or "Предмет",
            rolls    = {},
            banned   = {},
            timerEnd = GetTime() + dur,
            isLeader = IsRaidLeader(),
        }

        if not silent and rollState.isLeader and itemLink then
            SendChatMessage("-ролл " .. itemLink, "RAID_WARNING")
        end

        -- РАССЫЛКА ДЛЯ ОСТАЛЬНЫХ (независимо от silent)
        if rollState.isLeader and itemLink then
            local payload = itemLink .. ADDON_SEP .. dur
            if #payload > 255 then
                local name = itemLink:match("|h%[(.-)%]|h") or itemName or "Предмет"
                payload = name .. ADDON_SEP .. dur
            end
            SendAddonMessage(ADDON_PREFIX, payload, "RAID")
        end

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

        -- Нормализация: срезаем "-реалм"
        name = name:match("^([^%-]+)") or name

        if rollState.banned and rollState.banned[name] then return end
        if rollState.rolls[name] then return end

        rollState.rolls[name] = value
        RefreshRollFrame()
    end

    -- ========================================================================
    -- Хелперы для кириллицы (UTF-8) в Lua 5.1
    -- ========================================================================
    local function StripLeadingDash(s)
        if s:sub(1, 1) == "-" then
            return s:sub(2):gsub("^%s+", "")
        end
        return s
    end

    -- Проверка, что строка начинается с "ролл"/"РОЛЛ" (байтово).
    -- "р"=D1 80, "Р"=D0 A0; "о"=D0 BE, "О"=D0 9E;
    -- "л"=D0 BB, "Л"=D0 9B
    local function StartsWithRoll(s)
        local r1, r2 = s:byte(1, 2)
        local o1, o2 = s:byte(3, 4)
        local l1, l2 = s:byte(5, 6)
        local l3, l4 = s:byte(7, 8)

        local isR = (r1 == 0xD1 and r2 == 0x80) or (r1 == 0xD0 and r2 == 0xA0)
        local isO = (o1 == 0xD0 and (o2 == 0xBE or o2 == 0x9E))
        local isL1 = (l1 == 0xD0 and (l2 == 0xBB or l2 == 0x9B))
        local isL2 = (l3 == 0xD0 and (l4 == 0xBB or l4 == 0x9B))
        if not (isR and isO and isL1 and isL2) then return false, nil end

        local rest = s:sub(9)
        return true, rest
    end

    -- ========================================================================
    -- Обработчик команд РОЛЛ / -РОЛЛ
    -- ========================================================================
    local function HandleRollCommand(words, sender, text, channel, prefix)
        if sender ~= UnitName("player") then return end

        local s = text:gsub("^%s+", "")
        s = StripLeadingDash(s)

        local ok, rest = StartsWithRoll(s)
        if not ok then return end
        rest = rest:gsub("^%s+", "")

        local itemLink = rest:match("(|c%x+|Hitem:.-|h.-|h|r)")
        if itemLink then
            local itemName = itemLink:match("|h%[(.-)%]|h") or "Предмет"
            NSQC4.Roll_Start(itemLink, itemName, DEFAULT_ROLL_TIME, true)
            return
        end

        local plainName = rest:match("^%[(.-)%]")
        if plainName then
            NSQC4.Roll_Start(plainName, plainName, DEFAULT_ROLL_TIME, true)
            return
        end

        if rest == "" then
            RandomRoll(1, 100)
            return
        end

        local minV, maxV = rest:match("^(%d+)%s*%-%s*(%d+)$")
        if minV and maxV then
            RandomRoll(tonumber(minV), tonumber(maxV))
            return
        end
    end

    -- ========================================================================
    -- Команда -р (быстрый ролл)
    -- ========================================================================
    local function QuickRoll(sender, words)
        if sender ~= UnitName("player") then return end

        local arg = words[2]
        if arg then
            local minV, maxV = arg:match("^(%d+)%-(%d+)$")
            if minV and maxV then
                RandomRoll(tonumber(minV), tonumber(maxV))
                return
            end
        end

        RandomRoll(1, 100)
    end

    NSQC4.ChatHandler:Register("GUILD:-р", {
        func = function(words, sender, text, channel, prefix) QuickRoll(sender, words) end,
        stopOnMatch = true,
    })
    NSQC4.ChatHandler:Register("RAID:-р", {
        func = function(words, sender, text, channel, prefix) QuickRoll(sender, words) end,
        stopOnMatch = true,
    })
    NSQC4.ChatHandler:Register("RAID_LEADER:-р", {
        func = function(words, sender, text, channel, prefix) QuickRoll(sender, words) end,
        stopOnMatch = true,
    })
    NSQC4.ChatHandler:Register("RAID_WARNING:-р", {
        func = function(words, sender, text, channel, prefix) QuickRoll(sender, words) end,
        stopOnMatch = true,
    })

    -- ========================================================================
    -- Регистрация РОЛЛ / -РОЛЛ во всех каналах
    -- ========================================================================
    NSQC4.ChatHandler:Register("GUILD:ролл",  { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("GUILD:-ролл", { func = HandleRollCommand, stopOnMatch = true })

    NSQC4.ChatHandler:Register("RAID:ролл",  { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("RAID:-ролл", { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("RAID_LEADER:ролл",  { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("RAID_LEADER:-ролл", { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("RAID_WARNING:ролл",  { func = HandleRollCommand, stopOnMatch = true })
    NSQC4.ChatHandler:Register("RAID_WARNING:-ролл", { func = HandleRollCommand, stopOnMatch = true })

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
        -- ====================================================================
        -- РОЛЛЫ: единственный источник — CHAT_MSG_SYSTEM
        -- ====================================================================
        if event == "CHAT_MSG_SYSTEM" then
            local msg = ...
            if not msg then return end

            local name, value = TryParseRoll(msg)
            if not name then return end

            -- Если это наш собственный ролл — пересылаем в офицер-чат ОДИН раз
            if name == UnitName("player") then
                SendChatMessage(msg, "OFFICER")
            end

            if rollState then
                RegisterRoll(name, value)
            end
            return
        end

        -- ====================================================================
        -- RAID*: только "-время N" и старт ролла (фолбэк)
        -- ====================================================================
        if event == "CHAT_MSG_RAID"
           or event == "CHAT_MSG_RAID_LEADER"
           or event == "CHAT_MSG_RAID_WARNING" then
            local msg = ...
            if not msg then return end

            local addTime = tonumber(msg:match("^%s*%-время%s+(%d+)"))
            if addTime and rollState and IsRaidLeader() then
                rollState.timerEnd = rollState.timerEnd + addTime
                UpdateTimer()
                return
            end

            -- Фолбэк-старт по чату (на случай, если ChatHandler не сработал)
            if not rollState then
                local s = msg:gsub("^%s+", "")
                s = StripLeadingDash(s)
                local ok, rest = StartsWithRoll(s)
                if ok then
                    rest = rest:gsub("^%s+", "")
                    local link = rest:match("(|c%x+|Hitem:.-|h.-|h|r)")
                    if link then
                        local itemName = link:match("|h%[(.-)%]|h") or "Предмет"
                        NSQC4.Roll_Start(link, itemName, DEFAULT_ROLL_TIME, true)
                        return
                    end
                    local plainName = rest:match("^%[(.-)%]")
                    if plainName then
                        NSQC4.Roll_Start(plainName, plainName, DEFAULT_ROLL_TIME, true)
                        return
                    end
                end
            end
            return
        end

        -- ====================================================================
        -- ADDON: старт / отмена / бан
        -- ====================================================================
        if event == "CHAT_MSG_ADDON" then
            local prefix, addonMsg, _, sender = ...
            if not prefix or not sender then return end

            if prefix == ADDON_PREFIX and not rollState then
                local itemLink, duration = addonMsg:match("^(.*)" .. ADDON_SEP .. "(%d+)$")
                if itemLink then
                    local itemName = itemLink:match("|h%[(.-)%]|h") or itemLink
                    NSQC4.Roll_Start(itemLink, itemName, tonumber(duration) or DEFAULT_ROLL_TIME, true)
                end
                return
            end
            if prefix == ADDON_CANCEL then
                if rollState then NSQC4.Roll_Stop() end
                return
            end
            if prefix == ADDON_BAN and rollState then
                rollState.banned = rollState.banned or {}
                rollState.banned[addonMsg] = true
                rollState.rolls[addonMsg] = nil
                RefreshRollFrame()
                return
            end
        end
    end)

    -- РОЛЛ
    NSQC4.SlashPanel_RegisterSectionButton(
        "ГП",
        "Р",
        "-ролл",
        {
            { text = "Запуск ролла на предмет в рейде от РЛа",             r = 1.00, g = 0.82, b = 0.00 },
            { text = " " },
            { text = "Варианты команд:",                                   r = 0.40, g = 0.80, b = 1.00 },
            { text = "  ролл",                                             r = 0.85, g = 0.85, b = 0.85 },
            { text = "  РОЛЛ",                                             r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -ролл",                                            r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -РОЛЛ",                                            r = 0.85, g = 0.85, b = 0.85 },
            { text = " " },
            { text = "Использование: <команда> <предмет>",                 r = 0.40, g = 1.00, b = 0.40 },
            { text = "Пример: -ролл [Резная кость горгульи]",              r = 0.60, g = 0.60, b = 0.60 },
            { text = " " },
            { text = "Только РЛ/ассист. Открывает окно ролла у всех.",     r = 1.00, g = 0.40, b = 0.40 },
        }
    )

    -- БЫСТРЫЙ РОЛЛ
    NSQC4.SlashPanel_RegisterSectionButton(
        "ГП",
        "р",
        "-р",
        {
            { text = "Быстрый ролл (стандартный /random)",                 r = 1.00, g = 0.82, b = 0.00 },
            { text = " " },
            { text = "Варианты команд:",                                   r = 0.40, g = 0.80, b = 1.00 },
            { text = "  -р",                                               r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -р 1-20",                                          r = 0.85, g = 0.85, b = 0.85 },
            { text = " " },
            { text = "Использование:",                                     r = 0.40, g = 1.00, b = 0.40 },
            { text = "  -р        — ролл 1–100",                           r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -р 1-20   — ролл в указанном диапазоне",           r = 0.85, g = 0.85, b = 0.85 },
            { text = " " },
            { text = "Результат уходит в чат, как обычный /roll.",         r = 0.60, g = 0.60, b = 0.60 },
        }
    )

    -- АУК
    NSQC4.SlashPanel_RegisterSectionButton(
        "ГП",
        "А",
        "-аук ",
        {
            { text = "Запуск аукциона на предмет в рейде от РЛа",          r = 1.00, g = 0.82, b = 0.00 },
            { text = " " },
            { text = "Варианты команд:",                                   r = 0.40, g = 0.80, b = 1.00 },
            { text = "  аук",                                              r = 0.85, g = 0.85, b = 0.85 },
            { text = "  АУК",                                              r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -аук",                                             r = 0.85, g = 0.85, b = 0.85 },
            { text = "  -АУК",                                             r = 0.85, g = 0.85, b = 0.85 },
            { text = " " },
            { text = "Использование: <команда> <предмет> [шаг N] [время N]", r = 0.40, g = 1.00, b = 0.40 },
            { text = "Пример: -аук [Кость] шаг 10 время 20",               r = 0.60, g = 0.60, b = 0.60 },
            { text = " " },
            { text = "Только РЛ/ассист. Открывает окно аукциона у всех.",  r = 1.00, g = 0.40, b = 0.40 },
        }
    )

end)