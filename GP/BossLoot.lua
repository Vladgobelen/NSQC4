-- ============================================================================
-- NSQC4 / GP / BossLoot
-- Панель начисления ГП при открытии лута. Бан. Аук по СКМ.
-- Модуль: "gp".
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local GP_VALUES      = { 5, 10, 20, 50 }
    local FRAME_HEIGHT   = 55
    local FRAME_WIDTH    = 330
    local RARITY_EPIC    = 4
    local SPOT_RADIUS    = 0.005   -- радиус в долях карты (~10-20 м)
    local SPOT_R2        = SPOT_RADIUS * SPOT_RADIUS
    local BAN_ICON       = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"

    -- ========================================================================
    -- Хранилище (в nsDbc4.settings.gp)
    -- ========================================================================
    nsDbc4.settings.gp = nsDbc4.settings.gp or {}
    local gpDb = nsDbc4.settings.gp
    gpDb.donePlayers   = gpDb.donePlayers   or {}
    gpDb.doneSpots     = gpDb.doneSpots     or {}
    gpDb.bannedPlayers = gpDb.bannedPlayers or {}
    gpDb.bannedSpots   = gpDb.bannedSpots   or {}

    -- ========================================================================
    -- Состояние модуля
    -- ========================================================================
    local panel
    local editBox
    local banWindow

    local guildCache = {}
    local guildCacheReady = false

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    local function InSpotList(list, x, y)
        if not list or not x or not y then return false end
        for _, spot in ipairs(list) do
            local dx, dy = spot.x - x, spot.y - y
            if dx*dx + dy*dy <= SPOT_R2 then return true end
        end
        return false
    end

    local function IsInMyGuild(name)
        if not name then return false end
        if not guildCacheReady then
            wipe(guildCache)
            for i = 1, GetNumGuildMembers() do
                local n = GetGuildRosterInfo(i)
                if n then guildCache[ShortName(n)] = true end
            end
            guildCacheReady = true
        end
        return guildCache[ShortName(name)] == true
    end

    -- ========================================================================
    -- Начисление ГП рейду
    -- ========================================================================
    local function AssignGpToRaid(value)
        value = tonumber(value)
        if not value or value == 0 then return end
        if not IsInGuild() then
            print("|cffff0000[NSQC4]|r Не в гильдии — рассылка ГП невозможна")
            return
        end

        local inRaid = IsInRaid()
        local num = GetNumGroupMembers()
        local log = "Рейд " .. value
        local count = 0

        for i = 1, num do
            local unit = inRaid and ("raid"..i) or (i == 1 and "player" or ("party"..(i-1)))
            local nick = UnitName(unit)
            if nick then
                local short = ShortName(nick)
                local prefix = IsInMyGuild(short) and "nsGP1" or "nsGP1A"
                SendAddonMessage(prefix .. " " .. value, short, "GUILD")
                log = log .. " " .. short
                count = count + 1
            end
        end
        SendAddonMessage("nsGPlog", log, "GUILD")
        print("|cff00ff00[NSQC4]|r Начислено " .. value .. " ГП " .. count .. " игрокам рейда")
    end

    -- ========================================================================
    -- Запись в donePlayers / doneSpots
    -- ========================================================================
    local function MarkDone()
        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick then gpDb.donePlayers[nick] = true end
        else
            local zone = GetRealZoneText()
            local x, y = GetPlayerMapPosition("player")
            if zone and x and y and x > 0 and y > 0 then
                gpDb.doneSpots[zone] = gpDb.doneSpots[zone] or {}
                table.insert(gpDb.doneSpots[zone], { x = x, y = y })
            end
        end
    end

    -- ========================================================================
    -- Запись в bannedPlayers / bannedSpots
    -- ========================================================================
    local function MarkBanned()
        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick then
                gpDb.bannedPlayers[nick] = true
                print("|cffff8000[NSQC4]|r Забанен игрок: "..nick)
            end
        else
            local zone = GetRealZoneText()
            local x, y = GetPlayerMapPosition("player")
            if zone and x and y and x > 0 and y > 0 then
                gpDb.bannedSpots[zone] = gpDb.bannedSpots[zone] or {}
                table.insert(gpDb.bannedSpots[zone], { x = x, y = y })
                print("|cffff8000[NSQC4]|r Забанено место: "..zone)
            end
        end
    end

    -- ========================================================================
    -- Проверка: заблокировано ли (бан или уже начислено)
    -- ========================================================================
    local function IsBlocked()
        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick then
                if gpDb.bannedPlayers[nick] then return true end
                if gpDb.donePlayers[nick]   then return true end
            end
        else
            local zone = GetRealZoneText()
            local x, y = GetPlayerMapPosition("player")
            if zone and x and y and x > 0 and y > 0 then
                if InSpotList(gpDb.bannedSpots[zone], x, y) then return true end
                if InSpotList(gpDb.doneSpots[zone],   x, y) then return true end
            end
        end
        return false
    end

    -- ========================================================================
    -- Проверка: есть ли эпик в луте
    -- ========================================================================
    local function HasEpicLoot()
        for i = 1, GetNumLootItems() do
            local _, _, _, rarity = GetLootSlotInfo(i)
            if rarity and rarity >= RARITY_EPIC then return true end
        end
        return false
    end

    -- ========================================================================
    -- Панель
    -- ========================================================================
    local function CreatePanel()
        local f = CreateFrame("Frame", "NSQC4BossLootFrame", UIParent)
        f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
        f:SetFrameStrata("TOOLTIP")
        f:SetPoint("BOTTOM", LootFrame, "TOP", 0, 5)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", f, "TOP", 0, -5)
        title:SetText("Начислить ГП рейду:")
        title:SetTextColor(1, 0.82, 0)

        local xOffset = 10
        for _, value in ipairs(GP_VALUES) do
            local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            btn:SetSize(40, 20)
            btn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, -25)
            btn:SetText(tostring(value))
            btn:SetScript("OnClick", function()
                AssignGpToRaid(value)
                MarkDone()
                f:Hide()
            end)
            xOffset = xOffset + 45
        end

        -- Кнопка "?" — свой ввод
        local qBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        qBtn:SetSize(30, 20)
        qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, -25)
        qBtn:SetText("?")
        qBtn:SetScript("OnClick", function()
            if editBox then
                editBox:Show()
                editBox:SetFocus()
            end
        end)
        xOffset = xOffset + 35

        -- EditBox
        local eb = CreateFrame("EditBox", "NSQC4BossLootEditBox", f, "InputBoxTemplate")
        eb:SetSize(60, 20)
        eb:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, -25)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(6)
        eb:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then
                AssignGpToRaid(v)
                MarkDone()
            end
            self:SetText("")
            self:ClearFocus()
            self:Hide()
            f:Hide()
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:Hide()
            self:ClearFocus()
        end)
        eb:Hide()
        editBox = eb

        -- Кнопка бана
        local banBtn = CreateFrame("Button", nil, f)
        banBtn:SetSize(20, 20)
        banBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset + 65, -25)
        banBtn:SetNormalTexture(BAN_ICON)
        banBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        banBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        banBtn:SetScript("OnClick", function(_, button)
            if button == "LeftButton" then
                MarkBanned()
                f:Hide()
            elseif button == "RightButton" then
                NSQC4.ShowBanWindow()
            end
        end)

        banBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Бан")
            GameTooltip:AddLine("ЛКМ — забанить цель или точку", 1, 1, 1)
            GameTooltip:AddLine("ПКМ — список банов", 1, 1, 1)
            GameTooltip:Show()
        end)
        banBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        panel = f
    end

    local function ShowPanel()
        if not panel then CreatePanel() end
        panel:Show()
    end

    local function HidePanel()
        if panel then panel:Hide() end
        if editBox then editBox:Hide() end
    end

    -- ========================================================================
    -- LOOT_OPENED / LOOT_CLOSED
    -- ========================================================================
    local lootFrame = CreateFrame("Frame")
    lootFrame:RegisterEvent("LOOT_OPENED")
    lootFrame:RegisterEvent("LOOT_CLOSED")
    lootFrame:SetScript("OnEvent", function(_, event)
        if event == "LOOT_CLOSED" then
            HidePanel()
            return
        end

        if not IsRaidLeader() then return end
        if GetLootMethod() ~= "master" then return end
        if IsBlocked() then return end
        if not HasEpicLoot() then return end

        ShowPanel()
    end)

    -- ========================================================================
    -- Кэш гильдии
    -- ========================================================================
    local rosterFrame = CreateFrame("Frame")
    rosterFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    rosterFrame:RegisterEvent("PLAYER_LOGOUT")
    rosterFrame:SetScript("OnEvent", function(_, event)
        guildCacheReady = false
        if event == "PLAYER_LOGOUT" then
            wipe(guildCache)
        end
    end)

    -- ========================================================================
    -- АУК по СКМ: чтение имени предмета с кнопки → поиск ссылки → отправка
    -- ========================================================================
    local function GetButtonText(b)
        if not b then return nil end
        local name = b:GetName()
        if name then
            local nameFS = _G[name .. "Text"]   -- LootButtonNText — имя предмета
            if nameFS then
                local t = nameFS:GetText()
                if t and t ~= "" then return t end
            end
        end
        return nil
    end

    local function FindLinkByName(name)
        if not name then return nil end
        for i = 1, GetNumLootItems() do
            local link = GetLootSlotLink(i)
            if link and GetItemInfo(link) == name then
                return link
            end
        end
        return nil
    end

    local function HookLootButton(i)
        local b = _G["LootButton"..i]
        if not b then return end
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        if not b._nsOrigClick then
            b._nsOrigClick = b:GetScript("OnClick")
        end
        b:SetScript("OnClick", function(self, button)
            if button == "MiddleButton" then
                if InCombatLockdown() then return end
                if not IsRaidLeader() then return end
                local txt = GetButtonText(self)
                local link = FindLinkByName(txt)
                if link then
                    SendChatMessage("АУК " .. link, "RAID_WARNING")
                end
                return
            end
            if b._nsOrigClick then return b._nsOrigClick(self, button) end
        end)
    end

    local function RehookAll()
        for i = 1, 4 do HookLootButton(i) end
    end

    if LootFrameUpButton then
        LootFrameUpButton:HookScript("OnClick", RehookAll)
    end
    if LootFrameDownButton then
        LootFrameDownButton:HookScript("OnClick", RehookAll)
    end

    local lootHookFrame = CreateFrame("Frame")
    lootHookFrame:RegisterEvent("LOOT_OPENED")
    lootHookFrame:SetScript("OnEvent", RehookAll)

    -- ========================================================================
    -- Окно управления банами
    -- ========================================================================
    function NSQC4.ShowBanWindow()
        if banWindow then
            banWindow:Show()
            banWindow:Refresh()
            return
        end

        local w = CreateFrame("Frame", "NSQC4BanWindow", UIParent)
        banWindow = w
        w:SetSize(420, 450)
        w:SetPoint("CENTER")
        w:SetMovable(true)
        w:EnableMouse(true)
        w:RegisterForDrag("LeftButton")
        w:SetScript("OnDragStart", w.StartMoving)
        w:SetScript("OnDragStop", w.StopMovingOrSizing)
        w:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        local closeBtn = CreateFrame("Button", nil, w, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)

        local title = w:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -18)
        title:SetText("Список банов")

        local scroll = CreateFrame("ScrollFrame", "NSQC4BanScroll", w, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 15, -45)
        scroll:SetPoint("BOTTOMRIGHT", -35, 15)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(360, 1)
        scroll:SetScrollChild(content)

        local entries = {}

        function w:Refresh()
            local rows = {}
            for nick in pairs(gpDb.bannedPlayers) do
                table.insert(rows, { kind = "player", nick = nick })
            end
            for zone, list in pairs(gpDb.bannedSpots) do
                for idx, spot in ipairs(list) do
                    table.insert(rows, {
                        kind = "spot", zone = zone,
                        x = spot.x, y = spot.y, idx = idx,
                    })
                end
            end
            table.sort(rows, function(a, b)
                if a.kind ~= b.kind then return a.kind == "player" end
                if a.kind == "player" then return a.nick < b.nick end
                if a.zone ~= b.zone then return a.zone < b.zone end
                return a.idx < b.idx
            end)

            local rowHeight = 22
            for i, row in ipairs(rows) do
                local entry = entries[i]
                if not entry then
                    entry = CreateFrame("Button", nil, content)
                    entry:SetSize(360, rowHeight)
                    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    entry.text:SetPoint("LEFT", 5, 0)
                    entry.text:SetWidth(340)
                    entry.text:SetJustifyH("LEFT")
                    entry:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                    entries[i] = entry
                end

                if row.kind == "player" then
                    entry.text:SetText("|cffff8000Ник:|r " .. row.nick)
                else
                    entry.text:SetText(string.format("|cff00ffffЗона:|r %s |cff808080(%.4f, %.4f)|r",
                        row.zone, row.x, row.y))
                end

                entry:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)
                entry:Show()

                entry:SetScript("OnClick", function()
                    if row.kind == "player" then
                        gpDb.bannedPlayers[row.nick] = nil
                    else
                        local list = gpDb.bannedSpots[row.zone]
                        if list then
                            table.remove(list, row.idx)
                            if #list == 0 then gpDb.bannedSpots[row.zone] = nil end
                        end
                    end
                    w:Refresh()
                end)
            end

            for i = #rows + 1, #entries do
                entries[i]:Hide()
            end

            content:SetHeight(math.max(#rows * rowHeight, 1))
            scroll:UpdateScrollChildRect()
        end

        w:Refresh()
        w:Show()
    end

end)