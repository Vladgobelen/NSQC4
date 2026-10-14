-- ============================================================================
-- NSQC4 / GP / BossLoot
-- Панель начисления ГП при открытии лута. Бан. Аук по СКМ. Ролл по СКМ.
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
    local DEFAULT_SPOT_RADIUS = 0.005
    local ROLL_TIME      = 15

    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    nsDbc4.settings.gp = nsDbc4.settings.gp or {}
    local gpDb = nsDbc4.settings.gp
    gpDb.donePlayers   = gpDb.donePlayers   or {}
    gpDb.doneSpots     = gpDb.doneSpots     or {}
    gpDb.bannedPlayers = gpDb.bannedPlayers or {}
    gpDb.bannedSpots   = gpDb.bannedSpots   or {}
    gpDb.rollMode      = gpDb.rollMode      or false
    gpDb.collapsed     = gpDb.collapsed     or {}

    -- ========================================================================
    -- Состояние модуля
    -- ========================================================================
    local panel
    local editBox
    local banWindow
    local rollCheckbox
    local panelLastBannedOnly = false

    local guildCache = {}
    local guildCacheReady = false

    local rollState = nil

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    local function SpotRadius(spot)
        if spot and spot.radius then return spot.radius end
        return DEFAULT_SPOT_RADIUS
    end

    local function InSpotList(list, x, y)
        if not list or not x or not y then return false end
        for _, spot in ipairs(list) do
            local r = SpotRadius(spot)
            local dx, dy = spot.x - x, spot.y - y
            if dx*dx + dy*dy <= r*r then return true end
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

    local function DistanceBetweenSpots(x1, y1, x2, y2)
        local dx = (x2 - x1)
        local dy = (y2 - y1)
        return math.sqrt(dx*dx + dy*dy) * 10000
    end

    local function AmIMasterLooter()
        local method, mlParty, mlRaid = GetLootMethod()
        if method ~= "master" then return false end
        return mlParty == 0
    end

    -- ========================================================================
    -- Ключ состояния панели (таргет + подлокация)
    -- ========================================================================
    local function GetCollapseKey()
        local sz = GetSubZoneText()
        if not sz or sz == "" then sz = GetRealZoneText() end
        if not sz then return nil end

        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick then return "P:" .. nick .. "@" .. sz end
        end
        return "S:" .. sz
    end

    local function IsCollapsed()
        local key = GetCollapseKey()
        if not key then return false end
        return gpDb.collapsed[key] == true
    end

    local function ToggleCollapsed()
        local key = GetCollapseKey()
        if not key then return false end
        if gpDb.collapsed[key] then
            gpDb.collapsed[key] = nil
            return false
        else
            gpDb.collapsed[key] = true
            return true
        end
    end

    -- ========================================================================
    -- Начисление ГП рейду
    -- ========================================================================
    local function AssignGpToRaid(value)
        if not NSQC4.CanAssignGp() then
            return
        end

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
                if prefix == "nsGP1" then
                    SendAddonMessage("nsGP1 " .. value, short, "GUILD")
                else
                    SendAddonMessage("nsGP1A", value .. " " .. short, "GUILD")
                end
                log = log .. " " .. short
                count = count + 1
            end
        end
        SendAddonMessage("nsGPlog", log, "GUILD")
        print("|cff00ff00[NSQC4]|r Начислено " .. value .. " ГП " .. count .. " игрокам рейда")
    end

    -- ========================================================================
    -- done / banned
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
                table.insert(gpDb.doneSpots[zone], {
                    x = x, y = y, radius = DEFAULT_SPOT_RADIUS,
                })
            end
        end
    end

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
                table.insert(gpDb.bannedSpots[zone], {
                    x = x, y = y, radius = DEFAULT_SPOT_RADIUS,
                })
                print("|cffff8000[NSQC4]|r Забанено место: "..zone)
            end
        end
    end

    local function IsBanned()
        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick and gpDb.bannedPlayers[nick] then return true end
        else
            local zone = GetRealZoneText()
            local x, y = GetPlayerMapPosition("player")
            if zone and x and y and x > 0 and y > 0 then
                if InSpotList(gpDb.bannedSpots[zone], x, y) then return true end
            end
        end
        return false
    end

    local function IsDone()
        if UnitExists("target") then
            local nick = ShortName(UnitName("target"))
            if nick and gpDb.donePlayers[nick] then return true end
        else
            local zone = GetRealZoneText()
            local x, y = GetPlayerMapPosition("player")
            if zone and x and y and x > 0 and y > 0 then
                if InSpotList(gpDb.doneSpots[zone], x, y) then return true end
            end
        end
        return false
    end

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
    local COLLAPSE_X_OFFSET   -- вычисляется в CreatePanel
    local COLLAPSE_Y_OFFSET = -25

    local function CreatePanel()
        local f = CreateFrame("Frame", "NSQC4BossLootFrame", UIParent)
        f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
        f:SetFrameStrata("TOOLTIP")
        f:SetPoint("BOTTOM", LootFrame, "TOP", 0, 5)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", f, "TOP", 0, -5)
        title:SetText("Начислить ГП рейду:")
        title:SetTextColor(1, 0.82, 0)

        local gpButtons = {}

        local xOffset = 10
        for _, value in ipairs(GP_VALUES) do
            local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            btn:SetSize(40, 20)
            btn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, COLLAPSE_Y_OFFSET)
            btn:SetText(tostring(value))
            btn:SetScript("OnClick", function()
                AssignGpToRaid(value)
                MarkDone()
                f:Hide()
            end)
            table.insert(gpButtons, btn)
            xOffset = xOffset + 45
        end

        local qBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        qBtn:SetSize(30, 20)
        qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, COLLAPSE_Y_OFFSET)
        qBtn:SetText("?")
        qBtn:SetScript("OnClick", function()
            if editBox then
                editBox:Show()
                editBox:SetFocus()
            end
        end)
        table.insert(gpButtons, qBtn)
        xOffset = xOffset + 35

        local eb = CreateFrame("EditBox", "NSQC4BossLootEditBox", f, "InputBoxTemplate")
        eb:SetSize(60, 20)
        eb:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, COLLAPSE_Y_OFFSET)
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
        table.insert(gpButtons, eb)

        -- координата для кнопки сворачивания (после editBox)
        COLLAPSE_X_OFFSET = xOffset + 10

        local collapseBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        collapseBtn:SetSize(30, 20)
        collapseBtn:SetPoint("TOPLEFT", f, "TOPLEFT", COLLAPSE_X_OFFSET, COLLAPSE_Y_OFFSET)
        collapseBtn:SetText("<<")
        collapseBtn:SetScript("OnClick", function()
            if not GetCollapseKey() then
                print("|cffff0000[NSQC4]|r Не удалось определить подлокацию")
                return
            end
            ToggleCollapsed()
            ShowPanel(panelLastBannedOnly)
        end)
        collapseBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Свернуть/развернуть")
            GameTooltip:AddLine("Состояние запоминается для текущего таргета и подлокации", 1, 1, 1, true)
            GameTooltip:AddLine("Подлокация: " .. (GetSubZoneText() or "?"), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        collapseBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        f.gpButtons   = gpButtons
        f.collapseBtn = collapseBtn
        f.title       = title
        f.editBox     = eb

        panel = f
    end

    function ShowPanel(bannedOnly)  -- forward declaration через глобальную ссылку модуля
    end

    local function ShowPanelImpl(bannedOnly)
        if not panel then CreatePanel() end

        panelLastBannedOnly = bannedOnly and true or false

        local collapsed = IsCollapsed()

        if collapsed then
            for _, el in ipairs(panel.gpButtons) do el:Hide() end
            panel.title:Hide()
            if editBox then editBox:Hide() end

            panel.collapseBtn:ClearAllPoints()
            panel.collapseBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, COLLAPSE_Y_OFFSET)
            panel.collapseBtn:SetText(">>")
            panel.collapseBtn:Show()

            panel:SetSize(50, 30)
        else
            panel:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
            panel.title:Show()

            for _, el in ipairs(panel.gpButtons) do
                if bannedOnly then
                    el:Hide()
                else
                    if el == editBox then
                        el:Hide()
                    else
                        el:Show()
                    end
                end
            end

            if bannedOnly then
                panel.title:SetText("|cffff8000Забанено|r — только бан")
            else
                panel.title:SetText("Начислить ГП рейду:")
            end

            panel.collapseBtn:ClearAllPoints()
            panel.collapseBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", COLLAPSE_X_OFFSET, COLLAPSE_Y_OFFSET)
            panel.collapseBtn:SetText("<<")
            panel.collapseBtn:Show()
        end

        panel:Show()
    end

    -- подменяем forward-объявление на реализацию
    ShowPanel = ShowPanelImpl

    local function HidePanel()
        if panel then panel:Hide() end
        if editBox then editBox:Hide() end
    end

    -- ========================================================================
    -- Чекбокс режима «Ролл»
    -- ========================================================================
    local function CreateRollCheckbox()
        local cb = CreateFrame("CheckButton", "NSQC4RollCheckbox", UIParent, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("BOTTOMLEFT", LootFrame, "TOPLEFT", 65, -13)

        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText("Режим ролла")
        cb.text:SetTextColor(1, 0.82, 0)

        cb:SetScript("OnClick", function(self)
            gpDb.rollMode = self:GetChecked() and true or false
        end)

        cb:SetScript("OnEnter", function(self)
            if panel then panel:Hide() end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Режим ролла", 1, 0.82, 0)
            GameTooltip:AddLine("Если включён — СКМ по вещи запускает ролл на 15 сек.", 1, 1, 1, true)
            GameTooltip:AddLine("Побеждает наибольший ролл (1-100).", 1, 1, 1, true)
            GameTooltip:Show()
        end)

        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
            if panel then
                ShowPanel(panelLastBannedOnly)
            end
        end)

        rollCheckbox = cb
        return cb
    end

    -- ========================================================================
    -- Ролл
    -- ========================================================================
    local function FinishRoll()
        if not rollState then return end

        local winnerName = nil
        local winnerValue = -1

        for _, r in ipairs(rollState.rolls) do
            if r.value > winnerValue then
                winnerValue = r.value
                winnerName = r.name
            end
        end

        local itemLink = rollState.itemLink
        local slot     = rollState.slot

        if rollState.timerFrame then
            rollState.timerFrame:SetScript("OnUpdate", nil)
            rollState.timerFrame:Hide()
        end

        if not LootFrame or not LootFrame:IsShown() then
            SendChatMessage("Ролл завершён, но окно лута закрыто. Выдать вручную: " .. (itemLink or "?"), "RAID_WARNING")
            rollState = nil
            return
        end

        if not winnerName then
            SendChatMessage("Ролл по " .. (itemLink or "?") .. ": никто не бросил.", "RAID_WARNING")
            rollState = nil
            return
        end

        local currentLink = GetLootSlotLink(slot)
        if not currentLink or currentLink ~= itemLink then
            SendChatMessage("Ролл завершён, но предмет исчез из слота. Выдать вручную: " .. (itemLink or "?"), "RAID_WARNING")
            rollState = nil
            return
        end

        local lowerWinner = string.lower(winnerName)
        local found = false

        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local cand = GetMasterLootCandidate(i)
                if cand and string.lower(cand) == lowerWinner then
                    GiveMasterLoot(slot, i)
                    found = true
                    break
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() + 1 do
                local cand = GetMasterLootCandidate(i)
                if cand and string.lower(cand) == lowerWinner then
                    GiveMasterLoot(slot, i)
                    found = true
                    break
                end
            end
        end

        if found then
            SendChatMessage(winnerName .. " выиграл " .. (itemLink or "?") .. " с роллом " .. winnerValue, "RAID_WARNING")
        else
            SendChatMessage("Ролл выиграл " .. winnerName .. " (" .. winnerValue .. "), но выдать не удалось. Слот: " .. tostring(slot) .. ", предмет: " .. (itemLink or "?"), "RAID_WARNING")
        end

        rollState = nil
    end

    local function StartRoll(itemLink, slot)
        if rollState then return end

        rollState = {
            itemLink = itemLink,
            slot     = slot,
            rolls    = {},
            seen     = {},
            startAt  = GetTime(),
        }

        SendChatMessage("РОЛЛ " .. itemLink, "RAID")

        local frame = CreateFrame("Frame")
        rollState.timerFrame = frame
        local elapsed = 0

        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= ROLL_TIME then
                self:SetScript("OnUpdate", nil)
                FinishRoll()
            end
        end)
    end

    local sysFrame = CreateFrame("Frame")
    sysFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    sysFrame:SetScript("OnEvent", function(_, _, msg)
        if not rollState then return end
        if type(msg) ~= "string" then return end

        local name, n, min, max = msg:match("^(%S+)%s+выбрасывает%s+(%d+)%s+%((%d+)%-(%d+)%)$")
        if not name then return end

        local value = tonumber(n)
        local minV  = tonumber(min)
        local maxV  = tonumber(max)

        if not value or not minV or not maxV then return end
        if minV ~= 1 or maxV ~= 100 then return end

        if rollState.seen[name] then return end
        rollState.seen[name] = true
        table.insert(rollState.rolls, { name = name, value = value })
    end)

    -- ========================================================================
    -- LOOT_OPENED / LOOT_CLOSED
    -- ========================================================================
    local lootFrame = CreateFrame("Frame")
    lootFrame:RegisterEvent("LOOT_OPENED")
    lootFrame:RegisterEvent("LOOT_CLOSED")
    lootFrame:SetScript("OnEvent", function(_, event)
        if event == "LOOT_CLOSED" then
            HidePanel()
            if rollCheckbox then rollCheckbox:Hide() end
            return
        end

        if not AmIMasterLooter() then return end

        if IsDone() then return end

        if HasEpicLoot() then
            ShowPanel(false)
        end

        if not rollCheckbox then
            CreateRollCheckbox()
        end
        rollCheckbox:SetChecked(gpDb.rollMode == true)
        rollCheckbox:Show()
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
    -- СКМ по кнопке лута
    -- ========================================================================
    local function GetButtonText(b)
        if not b then return nil end
        local name = b:GetName()
        if name then
            local nameFS = _G[name .. "Text"]
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
                return link, i
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
                if not AmIMasterLooter() then return end

                if rollState then return end

                local txt = GetButtonText(self)
                local link, slot = FindLinkByName(txt)
                if not link then
                    print("|cffff0000[NSQC4]|r Не удалось получить ссылку на предмет.")
                    return
                end

                if gpDb.rollMode then
                    StartRoll(link, slot)
                else
                    SendChatMessage("АУК " .. link, "RAID")
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

        local function GetCurrentKey()
            if UnitExists("target") then
                local nick = ShortName(UnitName("target"))
                if nick and gpDb.bannedPlayers[nick] then
                    return "player", nick
                end
            else
                local zone = GetRealZoneText()
                local x, y = GetPlayerMapPosition("player")
                if zone and x and y and x > 0 and y > 0 then
                    local list = gpDb.bannedSpots[zone]
                    if list then
                        for idx, spot in ipairs(list) do
                            local r = SpotRadius(spot)
                            local dx, dy = spot.x - x, spot.y - y
                            if dx*dx + dy*dy <= r*r then
                                return "spot", zone, idx
                            end
                        end
                    end
                end
            end
            return nil
        end

        function w:Refresh()
            local curKind, curKey, curIdx = GetCurrentKey()

            local rows = {}
            for nick in pairs(gpDb.bannedPlayers) do
                table.insert(rows, { kind = "player", nick = nick })
            end
            for zone, list in pairs(gpDb.bannedSpots) do
                for idx, spot in ipairs(list) do
                    table.insert(rows, {
                        kind = "spot", zone = zone,
                        x = spot.x, y = spot.y,
                        radius = spot.radius,
                        idx = idx,
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
                    entry.sel = entry:CreateTexture(nil, "BACKGROUND")
                    entry.sel:SetAllPoints(true)
                    entry.sel:SetTexture("Interface\\Buttons\\WHITE8X8")
                    entry.sel:SetVertexColor(0.3, 0.5, 0.9, 0.5)
                    entry.sel:Hide()
                    entry:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    entries[i] = entry
                end

                if row.kind == "player" then
                    entry.text:SetText("|cffff8000Ник:|r " .. row.nick)
                else
                    local rStr = row.radius and string.format("%.0f", row.radius * 10000) or "?"
                    entry.text:SetText(string.format(
                        "|cff00ffffЗона:|r %s |cff808080(%.4f, %.4f) r=%s|r",
                        row.zone, row.x, row.y, rStr))
                end

                local isCurrent = false
                if curKind == "player" and row.kind == "player" and row.nick == curKey then
                    isCurrent = true
                elseif curKind == "spot" and row.kind == "spot"
                       and row.zone == curKey and row.idx == curIdx then
                    isCurrent = true
                end

                if isCurrent then
                    entry.sel:Show()
                else
                    entry.sel:Hide()
                end

                entry:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)
                entry:Show()

                entry:SetScript("OnClick", function(_, button)
                    if button == "LeftButton" then
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
                    elseif button == "RightButton" then
                        if row.kind ~= "spot" then return end

                        local px, py = GetPlayerMapPosition("player")
                        local zone = GetRealZoneText()
                        if not px or not py or px == 0 or py == 0 then
                            print("|cffff0000[NSQC4]|r Не удалось получить вашу позицию")
                            return
                        end
                        if zone ~= row.zone then
                            print("|cffff0000[NSQC4]|r Вы не в этой локации")
                            return
                        end

                        local dx = px - row.x
                        local dy = py - row.y
                        local newRadius = math.sqrt(dx*dx + dy*dy)
                        if newRadius <= 0 then
                            print("|cffff0000[NSQC4]|r Вы в самой точке — радиус не изменён")
                            return
                        end

                        local list = gpDb.bannedSpots[row.zone]
                        if list and list[row.idx] then
                            list[row.idx].radius = newRadius
                            print(string.format("|cff00ff00[NSQC4]|r Радиус обновлён: %.0f ярдов",
                                newRadius * 10000))
                        end
                        w:Refresh()
                    end
                end)

                entry:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

                    if row.kind == "player" then
                        GameTooltip:SetText("Забаненный игрок", 1, 0.82, 0)
                        GameTooltip:AddLine("|cffFF8C00ЛКМ|r — удалить из бана")
                    else
                        GameTooltip:SetText("Забаненная точка", 1, 0.82, 0)

                        local px, py = GetPlayerMapPosition("player")
                        local zone = GetRealZoneText()

                        if px and py and px > 0 and py > 0 and zone == row.zone then
                            local dist = DistanceBetweenSpots(px, py, row.x, row.y)
                            GameTooltip:AddLine(string.format("Расстояние: |cff00ff00%.0f|r ярдов", dist))
                        else
                            GameTooltip:AddLine("|cff808080Вы не в этой локации|r")
                        end

                        local rStr = row.radius and string.format("%.0f", row.radius * 10000) or "?"
                        GameTooltip:AddLine("Текущий радиус: |cff00BFFF" .. rStr .. "|r ярдов")

                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffFF8C00ЛКМ|r — удалить из бана")
                        GameTooltip:AddLine("|cffF4A460ПКМ|r — переписать радиус по текущему расстоянию")
                    end

                    GameTooltip:Show()
                end)
                entry:SetScript("OnLeave", function() GameTooltip:Hide() end)
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