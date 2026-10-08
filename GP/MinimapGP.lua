-- ============================================================================
-- NSQC4 / GP / MinimapGP
-- Кнопка ГП у миникарты (позиция 973).
-- - OnEnter: показывает состав рейда и ГП в тултипе.
-- - OnClick (ЛКМ): рассылает ГП по рейду в OFFICER.
-- - OnClick (ПКМ): открывает форум-топик.
-- - OnClick (СКМ): /roll 1-100.
-- Модуль: gp (тот же ключ, что и остальные GP-файлы).
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    -- ========================================================================
    -- Константы и зависимости
    -- ========================================================================
    local ID       = 973
    local POSEX    = 25
    local POSEY    = -20
    local SIZE_X   = 32
    local SIZE_Y   = 32

    local myNome   = UnitName("player")

    -- ========================================================================
    -- Утилиты (мягкие, с проверками — старая логика сохранена)
    -- ========================================================================

    local function safePlaySound(path)
        if PlaySoundFile then
            PlaySoundFile(path)
        end
    end

    local function safeSplit(text)
        if not mysplit then return {} end
        return mysplit(text)
    end

    local function safeGetGP()
        if not nsGP then return {} end
        return nsGP() or {}
    end

    local function safeLength(tbl)
        if not tablelength then return 0 end
        return tablelength(tbl) or 0
    end

    -- ========================================================================
    -- Получение данных игрока из ростера гильдии
    -- ========================================================================
    local function GetMyGuildInfo()
        local pbl, rezultat, rank

        if not GetNumGuildMembers or not GetGuildRosterInfo then
            return pbl, rezultat, rank
        end

        for i = 1, GetNumGuildMembers(true) do
            local name, rankName, _, _, _, _, publicNote, officerNote =
                GetGuildRosterInfo(i)

            if name == myNome then
                pbl = publicNote
                rank = rankName

                if officerNote and mysplit then
                    local parts = mysplit(officerNote)
                    if parts and #parts >= 3 then
                        rezultat = parts[3]
                    end
                end
            end
        end

        return pbl, rezultat, rank
    end

    -- ========================================================================
    -- Тултип (OnEnter)
    -- ========================================================================
    local function OnEnter(button)
        if not GameTooltip then return end

        if FriendsFrame then FriendsFrame:Show() end
        if GuildFrame   then GuildFrame:Show()   end

        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

        local rez = safeGetGP()
        local num = safeLength(rez)
        local pbl, rezultat = GetMyGuildInfo()

        if GetNumRaidMembers and GetNumRaidMembers() ~= 0 and num ~= 0 then
            for i = 1, num do
                local key = tostring(i)
                local entry = rez[key]

                if entry and entry['nome'] then
                    local playerName = entry['nome']
                    local displayName = (playerName ~= myNome) and "|cFF6495ED" or "|cffFF0000"
                    local publicNote = entry['public'] or ""
                    local znach = entry['znach'] or ""

                    -- Кэш внешних ГП
                    if gpDb and gpDb.GetExternalGp then
                        local cachedGp = gpDb:GetExternalGp(playerName)
                        if cachedGp ~= nil and cachedGp ~= 0 then
                            znach = tostring(cachedGp)
                        end
                    end

                    GameTooltip:AddLine(displayName .. playerName ..
                        " |cffFF8C00(" .. publicNote .. "): |cff99ff99" .. znach)

                    if gplabels then
                        table.insert(gplabels, playerName ..
                            " |cffFF8C00(" .. publicNote .. "): |cff99ff99" .. znach)
                    end
                end
            end

            if createParent then
                createParent()
            end
        else
            if myNome and pbl and rezultat then
                GameTooltip:AddLine("|cFF6495ED" .. myNome ..
                    " |cffFF8C00(" .. pbl .. "): |cff99ff99" .. rezultat)
            end
        end

        if FriendsFrame then FriendsFrame:Hide() end
        if GuildFrame   then GuildFrame:Hide()   end

        GameTooltip:Show()
    end

    -- ========================================================================
    -- Уход мыши (OnLeave)
    -- ========================================================================
    local function OnLeave()
        if GameTooltip then
            GameTooltip:Hide()
        end

        if gplabels then
            gplabels = {}
        end

        if testQ then
            testQ['gpRez'] = nil
        end
    end

    -- ========================================================================
    -- Клик (OnClick)
    -- ========================================================================
    local function OnClick(button, mouseButton)
        safePlaySound("Interface\\AddOns\\NSQC4\\Media\\Sounds\\clc.ogg")

        if mouseButton == "MiddleButton" then
            if RandomRoll then
                RandomRoll(1, 100)
            end
            return
        end

        if mouseButton == "LeftButton" then
            local rez = safeGetGP()
            local num = safeLength(rez)
            local pbl, rezultat, rank = GetMyGuildInfo()

            if SendChatMessage then
                if num ~= 0 then
                    if rank == "Капитан" or rank == "Статик" or rank == "Лейтенант" then
                        for i = 1, num do
                            local key = tostring(i)
                            local entry = rez[key]

                            if entry and entry['nome'] and entry['public'] and entry['znach'] then
                                SendChatMessage(
                                    entry['nome'] .. "(" .. entry['public'] .. "): " .. entry['znach'],
                                    "OFFICER", nil, 1
                                )
                            end
                        end
                    else
                        if myNome and pbl and rezultat then
                            SendChatMessage(myNome .. "(" .. pbl .. "): " .. rezultat,
                                "OFFICER", nil, 1)
                        end
                    end
                else
                    if myNome and pbl and rezultat then
                        SendChatMessage(myNome .. "(" .. pbl .. "): " .. rezultat,
                            "OFFICER", nil, 1)
                    end
                end
            end
            return
        end

        if mouseButton == "RightButton" then
            if NSForumClient and NSForumClient.OpenTopicById then
                NSForumClient.OpenTopicById(1)
            end
            return
        end
    end

    -- ========================================================================
    -- Создание и настройка кнопки
    -- ========================================================================
    local self = {}
    self[ID] = CreateFrame("Button", "NSQC4MinimapGPButton", Minimap)
    local btn = self[ID]

    btn:SetSize(SIZE_X, SIZE_Y)
    btn:SetNormalTexture("Interface\\Icons\\INV_Misc_Bag_07")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btn:SetPoint("LEFT", MinimapZoomOut, "RIGHT", POSEX, POSEY)

    -- Заглушка, чтобы не сломать старую логику с btn[id]:SetPoint
    local btnHolder = { [ID] = btn }

    btn:RegisterForClicks("LeftButtonUp", "RightButtonDown", "MiddleButtonDown")

    btn:SetScript("OnEnter", function(b, mouseButton)
        if MinimapZoomOut and btnHolder[ID] then
            btnHolder[ID]:SetPoint("LEFT", MinimapZoomOut, "RIGHT", 0, POSEY)
        end
        OnEnter(b)
    end)

    btn:SetScript("OnLeave", function(b, mouseButton)
        if MinimapZoomOut and btnHolder[ID] then
            btnHolder[ID]:SetPoint("LEFT", MinimapZoomOut, "RIGHT", 25, POSEY)
        end
        OnLeave()
    end)

    btn:SetScript("OnClick", function(b, mouseButton)
        OnClick(b, mouseButton)
    end)

end)