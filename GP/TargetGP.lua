-- ============================================================================
-- NSQC4 / GP / TargetGP
-- Кнопка «ГП» у фрейма таргета (только игрок, только при наведении).
-- Два режима: hover (всплывающий) и click (по клику). ПКМ — переключение.
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    local DEFAULT_VALUES = { 5, 10, 20, 50 }
    local PANEL_HOVER_TIMEOUT = 5

    nsDbc4.settings.gp = nsDbc4.settings.gp or {}
    local gpDb = nsDbc4.settings.gp
    gpDb.targetButtonValues = gpDb.targetButtonValues or { 5, 10, 20, 50 }
    gpDb.targetButtonPos = gpDb.targetButtonPos or {
        point = "RIGHT", relativePoint = "LEFT", x = -8, y = 0,
    }
    gpDb.targetButtonMode = gpDb.targetButtonMode or "hover"

    local function GetButtonValue(i) return gpDb.targetButtonValues[i] or DEFAULT_VALUES[i] end
    local function SetButtonValue(i, v) gpDb.targetButtonValues[i] = v end

    local function ShortName(name)
        if not name then return nil end
        return name:match("^([^%-]+)") or name
    end

    local function IsOfficer()
        if NSQC4._gpWindow and NSQC4._gpWindow._CheckOfficerRank then
            return NSQC4._gpWindow:_CheckOfficerRank()
        end
        if not IsInGuild() then return false end
        local playerName = UnitName("player")
        for i = 1, GetNumGuildMembers(true) do
            local name, _, rankIndex = GetGuildRosterInfo(i)
            if name and name == playerName then
                local rankName = GuildControlGetRankName(rankIndex + 1)
                if rankName == "Капитан" or rankName == "Лейтенант" or rankName == "Командор" then
                    return true
                end
                break
            end
        end
        return false
    end

    local function IsInMyGuild(short)
        if not short then return false end
        for i = 1, GetNumGuildMembers() do
            local n = GetGuildRosterInfo(i)
            if n and ShortName(n) == short then return true end
        end
        return false
    end

    local function GetPlayerID(short)
        if not short then return nil end
        for i = 1, GetNumGuildMembers(true) do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
            if name and ShortName(name) == short and officerNote then
                local words = {}
                for w in officerNote:gmatch("%S+") do table.insert(words, w) end
                if #words >= 2 then return words[2] end
            end
        end
        return nil
    end

    local function ApplyGP(short, value)
        if not short or not value or value == 0 then return end
        if not NSQC4.CanAssignGp() then return end
        if not IsOfficer() then
            print("|cFFFF0000[NSQC4]|r Только офицеры могут начислять ГП.")
            return
        end
        if not IsInGuild() then
            print("|cffff0000[NSQC4]|r Не в гильдии.")
            return
        end

        if IsInMyGuild(short) then
            SendAddonMessage("nsGP1 " .. value, short, "GUILD")
        else
            SendAddonMessage("nsGP1A", value .. " " .. short, "GUILD")
        end

        local playerID = GetPlayerID(short)
        local logTarget = playerID or ("N:" .. short)
        local logStr = string.format("Цель %d %s", value, logTarget)
        SendAddonMessage("nsGPlog", logStr, "GUILD")

        if value > 0 then
            print("|cff00ff00[NSQC4]|r Начислено " .. value .. " ГП: " .. short)
        else
            print("|cffff8080[NSQC4]|r Снято " .. (-value) .. " ГП: " .. short)
        end
    end

    local targetBtn, panel, editBox, editMode
    local CreatePanel
    local panelCloseAt = 0
    local lastRefresh = 0

    local function ShowPanel()
        local p = panel or CreatePanel()
        p:ClearAllPoints()
        p:SetPoint("TOP", targetBtn, "BOTTOM", 0, -5)
        p:Show()
        panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
    end

    local function HidePanel()
        if panel and panel:IsShown() then panel:Hide() end
    end

    local function ApplyButtonPos(btn)
        local p = gpDb.targetButtonPos
        btn:ClearAllPoints()
        btn:SetPoint(p.point, TargetFrame, p.relativePoint, p.x, p.y)
    end

    local function CreateTargetBtn()
        if targetBtn then return targetBtn end
        local btn = CreateFrame("Button", "NSQC4TargetGPBtn", UIParent, "UIPanelButtonTemplate")
        btn:SetSize(36, 22); btn:SetText("ГП"); btn:SetFrameStrata("MEDIUM")
        btn:SetMovable(true); btn:SetClampedToScreen(true); btn:Hide()
        btn:RegisterForDrag("LeftButton")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        if TargetFrame then ApplyButtonPos(btn) end

        local isDragging = false

        btn:SetScript("OnDragStart", function(self)
            isDragging = true
            self:StartMoving()
        end)

        btn:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            isDragging = false

            local cx, cy = self:GetCenter()
            local tx, ty = TargetFrame:GetCenter()
            if not (cx and cy and tx and ty) then return end

            local tw = TargetFrame:GetWidth() / 2
            local th = TargetFrame:GetHeight() / 2
            local bw = self:GetWidth() / 2
            local bh = self:GetHeight() / 2
            local dx = cx - tx
            local dy = cy - ty

            local distRight  = math.abs(dx - tw - bw)
            local distLeft   = math.abs(dx + tw + bw)
            local distTop    = math.abs(dy - th - bh)
            local distBottom = math.abs(dy + th + bh)
            local minDist = math.min(distRight, distLeft, distTop, distBottom)

            local point, relPoint, x, y
            if minDist == distRight then
                point, relPoint, x, y = "LEFT", "RIGHT", dx - tw - bw, 0
            elseif minDist == distLeft then
                point, relPoint, x, y = "RIGHT", "LEFT", dx + tw + bw, 0
            elseif minDist == distTop then
                point, relPoint, x, y = "BOTTOM", "TOP", 0, dy - th - bh
            else
                point, relPoint, x, y = "TOP", "BOTTOM", 0, dy + th + bh
            end

            self:ClearAllPoints()
            self:SetPoint(point, TargetFrame, relPoint, math.floor(x), math.floor(y))
            gpDb.targetButtonPos = {
                point = point, relativePoint = relPoint,
                x = math.floor(x), y = math.floor(y),
            }
        end)

        -- ====================================================================
        -- OnClick: ЛКМ — toggle (режим click) / ничего (режим hover)
        --           ПКМ — переключение режима
        -- ====================================================================
        btn:SetScript("OnClick", function(self, mouseButton)
            if isDragging then return end

            if mouseButton == "RightButton" then
                gpDb.targetButtonMode = (gpDb.targetButtonMode == "hover") and "click" or "hover"
                print("|cff00ff00[NSQC4]|r Режим кнопки ГП: " .. gpDb.targetButtonMode)
                return
            end

            if mouseButton == "LeftButton" then
                if gpDb.targetButtonMode == "click" then
                    if panel and panel:IsShown() then
                        HidePanel()
                    else
                        ShowPanel()
                    end
                end
                -- в режиме hover ЛКМ — ничего
            end
        end)

        -- ====================================================================
        -- OnEnter: в режиме hover — открыть панель + таймер
        --          в режиме click — только тултип
        -- ====================================================================
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            local mode = gpDb.targetButtonMode
            GameTooltip:SetText("ГП для цели", 1, 0.82, 0)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFD100Текущий режим:|r " ..
                (mode == "hover" and "|cff00ff00всплывающий|r" or "|cff00BFFFпо клику|r"))

            if mode == "hover" then
                GameTooltip:AddLine("Наведи на «ГП» — панель появится", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Удерживай мышь на панели — останется", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Ушла мышь — исчезнет через 5 сек", 0.8, 0.8, 0.8)
            else
                GameTooltip:AddLine("ЛКМ — открыть/закрыть панель", 0.8, 0.8, 0.8)
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFF8C00ПКМ|r — переключить режим", 1, 1, 1)
            GameTooltip:AddLine("ЛКМ + движение — перетащить", 0.8, 0.8, 0.8)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("ЛКМ на кнопке значения — начислить", 0.6, 1, 0.6)
            GameTooltip:AddLine("ПКМ на кнопке значения — снять", 1, 0.6, 0.6)
            GameTooltip:AddLine("СКМ на кнопке значения — задать значение", 0.6, 0.6, 1)
            GameTooltip:AddLine("? — разовое значение", 0.8, 0.8, 0.8)

            GameTooltip:Show()

            if mode == "hover" and not isDragging then
                ShowPanel()
            end
        end)

        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        targetBtn = btn
        return btn
    end

    CreatePanel = function()
        if panel then return panel end
        local f = CreateFrame("Frame", "NSQC4TargetGPPanel", UIParent)
        -- Убираем жесткий размер: 280, 60
        f:SetSize(1, 1) 
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        f:EnableMouse(true)
        f:Hide()

        f:SetScript("OnEnter", function()
            if gpDb.targetButtonMode == "hover" then
                panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
            end
        end)

        f.buttons = {}
        local padding = 8
        local xOffset = padding
        local yOffset = -padding
        local btnWidth = 40
        local btnHeight = 20

        for i = 1, 4 do
            local b = CreateFrame("Button", "NSQC4TargetGPBtn" .. i, f, "UIPanelButtonTemplate")
            b:SetSize(btnWidth, btnHeight)
            b:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
            b:SetText(tostring(GetButtonValue(i)))
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

            b:SetScript("OnClick", function(self, mouseButton)
                local value = GetButtonValue(i)
                local short = UnitExists("target") and ShortName(UnitName("target")) or nil
                if not short then return end
                if mouseButton == "LeftButton" then ApplyGP(short, value)
                elseif mouseButton == "RightButton" then ApplyGP(short, -value)
                elseif mouseButton == "MiddleButton" then
                    editMode = i; editBox:SetText(tostring(value)); editBox:Show(); editBox:SetFocus(); editBox:HighlightText()
                end
            end)

            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("ГП: " .. GetButtonValue(i), 1, 0.82, 0)
                GameTooltip:AddLine("ЛКМ — начислить", 0.6, 1, 0.6)
                GameTooltip:AddLine("ПКМ — снять", 1, 0.6, 0.6)
                GameTooltip:AddLine("СКМ — задать значение", 0.6, 0.6, 1)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)

            f.buttons[i] = b
            xOffset = xOffset + btnWidth + 5 -- 5 пикселей между кнопками
        end

        local qBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        qBtn:SetSize(30, btnHeight)
        qBtn:SetPoint("TOPLEFT", f, "TOPLEFT", xOffset, yOffset)
        qBtn:SetText("?")
        qBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        qBtn:SetScript("OnClick", function(self, mouseButton)
            editMode = "custom"; editBox:SetText(""); editBox:Show(); editBox:SetFocus()
        end)
        qBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Разовое значение", 1, 0.82, 0)
            GameTooltip:AddLine("ЛКМ — начислить", 0.6, 1, 0.6)
            GameTooltip:AddLine("ПКМ — снять", 1, 0.6, 0.6)
            GameTooltip:Show()
        end)
        qBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.qBtn = qBtn
        
        -- Учитываем ширину последней кнопки (30) в расчете общей ширины
        local totalWidth = xOffset + 30 + padding
        
        -- EditBox для ввода
        local eb = CreateFrame("EditBox", "NSQC4TargetGPEdit", f, "InputBoxTemplate")
        eb:SetSize(60, 20)
        -- Ставим его ниже кнопок
        eb:SetPoint("TOPLEFT", f, "TOPLEFT", padding, -(padding + btnHeight + 5))
        eb:SetAutoFocus(false); eb:SetMaxLetters(6); eb:Hide()

        eb:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then
                if editMode == "custom" then
                    local short = UnitExists("target") and ShortName(UnitName("target")) or nil
                    if short then ApplyGP(short, v) end
                elseif type(editMode) == "number" then
                    SetButtonValue(editMode, v)
                    if panel and panel.buttons[editMode] then
                        panel.buttons[editMode]:SetText(tostring(v))
                    end
                end
            end
            self:SetText(""); self:ClearFocus(); self:Hide(); editMode = nil
        end)

        eb:SetScript("OnEscapePressed", function(self)
            self:SetText(""); self:ClearFocus(); self:Hide(); editMode = nil
        end)

        editBox = eb; panel = f
        
        -- Фиксируем итоговый размер панели (только под кнопки)
        -- Если EditBox показан, он не должен вылезать за пределы, поэтому добавляем высоту
        f:SetSize(totalWidth, padding + btnHeight + padding)
        
        return f
    end

    -- ====================================================================
    -- OnUpdate: авто-закрытие панели только в режиме hover
    -- ====================================================================
    local hoverFrame = CreateFrame("Frame")
    hoverFrame:SetScript("OnUpdate", function()
        if not TargetFrame then return end
        local btn = targetBtn or CreateTargetBtn()

        if panel and panel:IsShown() then
            if gpDb.targetButtonMode == "hover" then
                local btnHover = btn:IsMouseOver() or (TargetFrame:IsMouseOver() and UnitIsPlayer("target"))
                local panelHover = panel:IsMouseOver()

                if btnHover or panelHover then
                    if GetTime() - lastRefresh >= 1 then
                        panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
                        lastRefresh = GetTime()
                    end
                end

                if GetTime() >= panelCloseAt then
                    if not (btn:IsMouseOver() or panel:IsMouseOver()) then
                        HidePanel()
                    else
                        panelCloseAt = GetTime() + PANEL_HOVER_TIMEOUT
                    end
                end
            end

            btn:Show()
            return
        end

        local show = UnitExists("target") and UnitIsPlayer("target")
            and (TargetFrame:IsMouseOver() or btn:IsMouseOver())
        if show then btn:Show()
        else btn:Hide() end
    end)

    local restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_LOGIN")
    restoreFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        if not TargetFrame then return end
        ApplyButtonPos(CreateTargetBtn())
    end)

end)