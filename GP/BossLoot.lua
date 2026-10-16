-- ============================================================================
-- NSQC4 / GP / BossLoot
-- Панель начисления ГП при открытии лута. Аук по СКМ. Ролл — через Roll.lua.
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

    -- ========================================================================
    -- Хранилище
    -- ========================================================================
    nsDbc4.settings.gp = nsDbc4.settings.gp or {}
    local gpDb = nsDbc4.settings.gp
    gpDb.rollMode      = gpDb.rollMode      or false
    gpDb.collapsed     = gpDb.collapsed     or {}
    gpDb.pinned        = gpDb.pinned        or false
    gpDb.pinnedPos     = gpDb.pinnedPos     or nil

    -- ========================================================================
    -- Состояние модуля
    -- ========================================================================
    local panel
    local editBox
    local rollCheckbox
    local panelLastBannedOnly = false

    local guildCache = {}
    local guildCacheReady = false

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
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

    local function AmIMasterLooter()
        local method, mlParty, mlRaid = GetLootMethod()
        if method ~= "master" then return false end

        if IsInRaid() then
            local myName = UnitName("player")
            for i = 1, GetNumRaidMembers() do
                if UnitName("raid"..i) == myName then
                    return mlRaid == i
                end
            end
            return false
        end

        return mlParty == 0
    end

    -- ========================================================================
    -- Привязка чекбокса ролла под кнопкой 50
    -- ========================================================================
    local function AttachRollCheckboxToPanel(p)
        if not rollCheckbox or not p then return end
        rollCheckbox:ClearAllPoints()
        local anchor = (p.gpButtons and p.gpButtons[4]) or p
        local ox = (p.gpButtons and p.gpButtons[4]) and 0 or 155
        rollCheckbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", ox, 0)
    end

    -- ========================================================================
    -- Ключ состояния панели
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
        if not NSQC4.CanAssignGp() then return end
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
    local COLLAPSE_X_OFFSET
    local COLLAPSE_Y_OFFSET = -25

    local ShowPanel

    local function ResetPanelToLoot(f)
        gpDb.pinnedPos = nil
        f:ClearAllPoints()
        f:SetPoint("BOTTOM", LootFrame, "TOP", 0, 5)
    end

    local function SavePinPos(self)
        local point, _, relPoint, x, y = self:GetPoint()

        local cx, cy = self:GetCenter()
        local lx, ly = LootFrame:GetCenter()
        if cx and cy and lx and ly then
            local dx = math.abs(cx - lx)
            local dy = math.abs(cy - ly)
            if dx < 80 and dy < 80 then
                ResetPanelToLoot(self)
                AttachRollCheckboxToPanel(self)
                return
            end
        end

        gpDb.pinnedPos = {
            point    = point,
            relPoint = relPoint,
            x        = x,
            y        = y,
        }
        AttachRollCheckboxToPanel(self)
    end

    local function ApplyDragHooks(f)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self)
            self:StartMoving()
            self:SetScript("OnUpdate", function(s)
                AttachRollCheckboxToPanel(s)
            end)
        end)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self:SetScript("OnUpdate", nil)
            SavePinPos(self)
        end)
    end

    local function RemoveDragHooks(f)
        f:SetMovable(false)
        f:EnableMouse(false)
        f:RegisterForDrag()
        f:SetScript("OnDragStart", nil)
        f:SetScript("OnDragStop", nil)
    end

    local function CreatePanel()
        local f = CreateFrame("Frame", "NSQC4BossLootFrame", UIParent)
        f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
        f:SetFrameStrata("TOOLTIP")

        if gpDb.pinned and gpDb.pinnedPos then
            local p = gpDb.pinnedPos
            f:SetPoint(
                p.point    or "CENTER",
                UIParent,
                p.relPoint or "CENTER",
                p.x or 0, p.y or 0)
        else
            f:SetPoint("BOTTOM", LootFrame, "TOP", 0, 5)
        end

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
            end
            self:SetText("")
            self:ClearFocus()
            self:Hide()
        end)
        eb:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:Hide()
            self:ClearFocus()
        end)
        eb:Hide()
        editBox = eb
        table.insert(gpButtons, eb)

        COLLAPSE_X_OFFSET = xOffset + 10

        local pinBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        pinBtn:SetSize(30, 20)
        pinBtn:SetPoint("TOPLEFT", f, "TOPLEFT", COLLAPSE_X_OFFSET, COLLAPSE_Y_OFFSET)
        pinBtn:SetText(gpDb.pinned and "З*" or "З")
        pinBtn:SetScript("OnClick", function()
            gpDb.pinned = not gpDb.pinned
            if gpDb.pinned then
                ApplyDragHooks(f)
                pinBtn:SetText("З*")
                ShowPanel(panelLastBannedOnly)
                print("|cff00ff00[NSQC4]|r Панель закреплена. Перетаскивай ЛКМ.")
            else
                RemoveDragHooks(f)
                pinBtn:SetText("З")
                ResetPanelToLoot(f)
                AttachRollCheckboxToPanel(f)
                if not LootFrame or not LootFrame:IsShown() then
                    f:Hide()
                    if rollCheckbox then rollCheckbox:Hide() end
                end
                print("|cff00ff00[NSQC4]|r Панель откреплена.")
            end
        end)
        pinBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Закрепить панель")
            GameTooltip:AddLine("Закреплённая панель видна в рейде, перетаскивается ЛКМ.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        pinBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        f.pinBtn = pinBtn

        COLLAPSE_X_OFFSET = COLLAPSE_X_OFFSET + 35

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

        if gpDb.pinned then
            ApplyDragHooks(f)
        end

        panel = f
    end

    ShowPanel = function(bannedOnly)
        if not panel then CreatePanel() end

        panelLastBannedOnly = bannedOnly and true or false

        local collapsed = IsCollapsed()

        if collapsed then
            for _, el in ipairs(panel.gpButtons) do el:Hide() end
            panel.title:Hide()
            if editBox then editBox:Hide() end

            if panel.pinBtn then
                panel.pinBtn:ClearAllPoints()
                panel.pinBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, COLLAPSE_Y_OFFSET)
                panel.pinBtn:Show()
            end

            panel.collapseBtn:ClearAllPoints()
            panel.collapseBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 45, COLLAPSE_Y_OFFSET)
            panel.collapseBtn:SetText(">>")
            panel.collapseBtn:Show()

            AttachRollCheckboxToPanel(panel)

            panel:SetSize(85, 30)
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

            if panel.pinBtn then
                panel.pinBtn:ClearAllPoints()
                panel.pinBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", COLLAPSE_X_OFFSET - 35, COLLAPSE_Y_OFFSET)
                panel.pinBtn:Show()
            end

            panel.collapseBtn:ClearAllPoints()
            panel.collapseBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", COLLAPSE_X_OFFSET, COLLAPSE_Y_OFFSET)
            panel.collapseBtn:SetText("<<")
            panel.collapseBtn:Show()

            AttachRollCheckboxToPanel(panel)
        end

        panel:Show()
    end

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
            GameTooltip:AddLine("Если включён — СКМ по вещи запускает ролл.", 1, 1, 1, true)
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

        if panel then
            AttachRollCheckboxToPanel(panel)
        else
            cb:SetPoint("BOTTOMLEFT", LootFrame, "TOPLEFT", 65, -13)
        end

        return cb
    end

    -- ========================================================================
    -- LOOT_OPENED / LOOT_CLOSED
    -- ========================================================================
    local lootFrame = CreateFrame("Frame")
    lootFrame:RegisterEvent("LOOT_OPENED")
    lootFrame:RegisterEvent("LOOT_CLOSED")
    lootFrame:SetScript("OnEvent", function(_, event)
        if event == "LOOT_CLOSED" then
            if not gpDb.pinned then
                HidePanel()
            end
            if rollCheckbox and not gpDb.pinned then
                rollCheckbox:Hide()
            end
            return
        end

        if not AmIMasterLooter() then return end

        -- Список предметов — в рейд
        local items = {}
        for i = 1, GetNumLootItems() do
            local link = GetLootSlotLink(i)
            if link then
                table.insert(items, link)
            end
        end

        if #items > 0 then
            local idx = 1
            local timer = CreateFrame("Frame")
            local elapsed = 0
            timer:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= 0.5 then
                    elapsed = 0
                    if items[idx] then
                        SendChatMessage(items[idx], "RAID")
                        idx = idx + 1
                    else
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                    end
                end
            end)
            timer:Show()
        end

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
    -- Реакция на состав рейда
    -- ========================================================================
    local raidFrame = CreateFrame("Frame")
    raidFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    raidFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    raidFrame:SetScript("OnEvent", function()
        if not gpDb.pinned then return end

        if not panel then CreatePanel() end

        if IsInRaid() then
            if not panel:IsShown() then
                ShowPanel(panelLastBannedOnly)
            end
        else
            if panel:IsShown() then
                panel:Hide()
            end
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

                local txt = GetButtonText(self)
                local link, slot = FindLinkByName(txt)
                if not link then
                    print("|cffff0000[NSQC4]|r Не удалось получить ссылку на предмет.")
                    return
                end

                if gpDb.rollMode then
                    SendChatMessage("-ролл " .. link, "RAID_WARNING")
                    SendAddonMessage("AUC_ROLL_START", link .. "|20", "RAID")
                else
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
    -- Восстановление закреплённой панели после /reload
    -- ========================================================================
    if gpDb.pinned then
        CreatePanel()
        if IsInRaid() then
            ShowPanel(false)
        end
    end

end)