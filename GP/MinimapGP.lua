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
    -- nsGP() — сбор ГП всего рейда (для тултипа кнопки)
    -- ========================================================================
    local function Split(inputstr)
        if not inputstr then return {} end
        local t = {}
        for str in string.gmatch(inputstr, "([^%s]+)") do
            table.insert(t, str)
        end
        return t
    end

    local function BuildGuildRosterIndex()
        local index = {}
        local count = GetNumGuildMembers(true) or 0
        for i = 1, count do
            local name, rankName, _, _, _, _, publicNote, officerNote =
                GetGuildRosterInfo(i)

            if name then
                local plainName = name:match("^(.-)-") or name

                local gp = 0
                if officerNote then
                    local parts = Split(officerNote)
                    if parts[3] then
                        gp = tonumber(parts[3]) or 0
                    end
                end

                index[plainName] = {
                    nome = name,
                    rank = rankName,
                    public = publicNote or "",
                    znach = gp,
                }
            end
        end
        return index
    end

    function nsGP()
        local guildIndex = BuildGuildRosterIndex()

        local result = {}
        local num = GetNumRaidMembers() or 0

        for i = 1, num do
            local unit = "raid" .. i
            local unitName = UnitName(unit)

            if unitName then
                local plainName = unitName:match("^(.-)-") or unitName
                local info = guildIndex[plainName]

                if info then
                    table.insert(result, {
                        nome   = info.nome,
                        public = info.public,
                        rank   = info.rank,
                        znach  = info.znach,
                    })
                else
                    table.insert(result, {
                        nome   = unitName,
                        public = "НЕ В ГИЛЬДИИ",
                        rank   = "",
                        znach  = 0,
                    })
                end
            end
        end

        table.sort(result, function(a, b)
            return (a.znach or 0) < (b.znach or 0)
        end)

        return result
    end

    -- ========================================================================
    -- Константы
    -- ========================================================================
    local ID       = 973
    local POSEX    = 25
    local POSEY    = -20
    local SIZE_X   = 32
    local SIZE_Y   = 32

    local myNome   = UnitName("player")

    -- ========================================================================
    -- Утилиты
    -- ========================================================================
    local function safePlaySound(path)
        if PlaySoundFile then
            PlaySoundFile(path)
        end
    end

    local function safeLength(tbl)
        if type(tbl) ~= "table" then return 0 end
        return #tbl
    end

    local function safeGetGP()
        if not nsGP then return {} end
        return nsGP() or {}
    end

    -- ========================================================================
    -- Инфо о себе из ростера гильдии
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

                if officerNote then
                    local parts = Split(officerNote)
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

        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

        local rez = safeGetGP()
        local num = safeLength(rez)
        local pbl, rezultat = GetMyGuildInfo()

        local raidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0

        if raidMembers ~= 0 and num ~= 0 then
            for i = 1, num do
                local entry = rez[i]
                if entry and entry['nome'] then
                    local playerName = entry['nome']
                    local displayName = (playerName ~= myNome) and "|cFF6495ED" or "|cffff0000"
                    local publicNote = entry['public'] or ""
                    local znach = entry['znach'] or ""

                    -- Кэш внешних ГП (для не-гильдейцев)
                    if gpDb and gpDb.GetExternalGp then
                        local cachedGp = gpDb:GetExternalGp(playerName)
                        if cachedGp ~= nil and cachedGp ~= 0 then
                            znach = cachedGp
                        end
                    end

                    GameTooltip:AddLine(displayName .. playerName ..
                        " |cffFF8C00(" .. publicNote .. "): |cff99ff99" .. znach)
                end
            end
        else
            if myNome and pbl and rezultat then
                GameTooltip:AddLine("|cFF6495ED" .. myNome ..
                    " |cffFF8C00(" .. pbl .. "): |cff99ff99" .. rezultat)
            end
        end

        GameTooltip:Show()
    end

    -- ========================================================================
    -- Уход мыши
    -- ========================================================================
    local function OnLeave()
        if GameTooltip then GameTooltip:Hide() end
    end

    -- ========================================================================
    -- Клик
    -- ========================================================================
    local function OnClick(button, mouseButton)
        safePlaySound("Interface\\AddOns\\NSQC4\\Media\\Sounds\\clc.ogg")

        if mouseButton == "MiddleButton" then
            if RandomRoll then RandomRoll(1, 100) end
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
                            local entry = rez[i]
                            if entry and entry['nome'] and entry['public'] and entry['znach'] then
                                SendChatMessage(entry['nome'] .. "(" .. entry['public'] .. "): " .. entry['znach'], "OFFICER", nil, 1)
                            end
                        end
                    else
                        if myNome and pbl and rezultat then
                            SendChatMessage(myNome .. "(" .. pbl .. "): " .. rezultat, "OFFICER", nil, 1)
                        end
                    end
                else
                    if myNome and pbl and rezultat then
                        SendChatMessage(myNome .. "(" .. pbl .. "): " .. rezultat, "OFFICER", nil, 1)
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
    -- Создание кнопки
    -- ========================================================================
    local btn = CreateFrame("Button", "NSQC4MinimapGPButton", Minimap)
    local btnHolder = { [ID] = btn }

    btn:SetSize(SIZE_X, SIZE_Y)
    btn:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_06")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btn:SetPoint("LEFT", MinimapZoomOut, "RIGHT", POSEX, POSEY)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonDown", "MiddleButtonDown")

    btn:SetScript("OnEnter", function(b, mouseButton)
        if MinimapZoomOut then
            btnHolder[ID]:SetPoint("LEFT", MinimapZoomOut, "RIGHT", 0, POSEY)
        end
        OnEnter(b)
    end)

    btn:SetScript("OnLeave", function(b, mouseButton)
        if MinimapZoomOut then
            btnHolder[ID]:SetPoint("LEFT", MinimapZoomOut, "RIGHT", 25, POSEY)
        end
        OnLeave()
    end)

    btn:SetScript("OnClick", function(b, mouseButton)
        OnClick(b, mouseButton)
    end)

end)