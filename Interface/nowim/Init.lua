-- ============================================================================
-- NSQC4 / nowim / Init
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    SLASH_NSMSG1 = "/nowim"
    SlashCmdList["NSMSG"] = function()
        local UI = NSQC4.Nowim and NSQC4.Nowim.UI
        if UI and UI.MainFrame then
            UI.MainFrame:ShowFrame()
        end
    end

    if NSQC4.SlashPanel_RegisterSectionButton then
        NSQC4.SlashPanel_RegisterSectionButton(
            "Чат (Nowim)",
            "Ч",
            "/nowim",
            {
                { text = "Кастомный чат Nowim", r = 1.00, g = 0.82, b = 0.00 },
                { text = " " },
                { text = "|cffff0000Внимание!|r Чат находится в разработке.", r = 1.00, g = 0.2, b = 0.2 },
                { text = "Он очень кривой, могут быть баги и вылеты.", r = 0.85, g = 0.85, b = 0.85 },
                { text = "Пользуйтесь на свой страх и риск.", r = 0.85, g = 0.85, b = 0.85 },
            }
        )
    end

    -- ФУНКЦИЯ СКРЫТИЯ/ПОКАЗА СИСТЕМНОГО ЧАТА
    local function UpdateSystemChatVisibility()
        local C = NSQC4.Nowim.Config
        if not C or not C.db or not C.db.settings then return end

        local hideSystem = C.db.settings.interceptEnter
        
        -- Сдвигаем стандартные окна чата и их вкладки за экран
        for i = 1, 7 do
            local frame = _G["ChatFrame"..i]
            local tab = _G["ChatFrame"..i.."Tab"]
            
            if frame then
                frame:ClearAllPoints()
                if hideSystem then
                    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -3000, -3000)
                else
                    -- Возвращаем на стандартное место (примерно)
                    if i == 1 then
                        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 32)
                    else
                        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 32 + (i-1)*100)
                    end
                end
            end
            
            if tab then
                tab:ClearAllPoints()
                if hideSystem then
                    tab:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -3000, 3000)
                else
                    -- Вкладки обычно привязаны к фреймам, вернем их обратно
                    -- (если они сломаются, их пересоздаст игра при перезагрузке)
                end
            end
        end
        
        -- Скрываем кнопку "Болтать" и поле ввода
        if ChatFrameMenuButton then
            if hideSystem then ChatFrameMenuButton:Hide() else ChatFrameMenuButton:Show() end
        end
        if ChatFrame1EditBox then
            if hideSystem then ChatFrame1EditBox:Hide() else ChatFrame1EditBox:Show() end
        end
    end

    NSQC4.Nowim.UpdateSystemChatVisibility = UpdateSystemChatVisibility

    -- Невидимая кнопка для перехвата Enter
    local enterCatcher = CreateFrame("Button", "NSQC4_NowimEnterCatcher", UIParent)
    enterCatcher:SetSize(1, 1)
    enterCatcher:SetPoint("CENTER")
    enterCatcher:Hide()

    enterCatcher:SetScript("OnClick", function()
        local Nowim = NSQC4.Nowim
        if not Nowim then return end
        local C = Nowim.Config
        local UI = Nowim.UI
        if not UI or not UI.MainFrame then return end

        local mainFrame = UI.MainFrame

        if not mainFrame:IsShown() then
            if C.db.activeTab then
                local found = false
                for _, key in ipairs(C.db.openTabs or {}) do
                    if key == C.db.activeTab then found = true; break end
                end
                if found and Nowim.ChatEngine then
                    Nowim.ChatEngine.OpenDialog(C.db.activeTab)
                end
            end
            mainFrame:ShowFrame()
        end

        if UI.Input and UI.Input.Open then
            UI.Input.Open()
        end
    end)

    local function ApplyBinding()
        local Nowim = NSQC4.Nowim
        if not Nowim or not Nowim.Config then return end
        local enabled = Nowim.Config.db.settings.interceptEnter

        if enabled then
            SetOverrideBindingClick(enterCatcher, true, "ENTER", "NSQC4_NowimEnterCatcher")
            SetOverrideBindingClick(enterCatcher, true, "NUMPADENTER", "NSQC4_NowimEnterCatcher")
        else
            ClearOverrideBindings(enterCatcher)
        end

        UpdateSystemChatVisibility()
    end

    NSQC4.Nowim = NSQC4.Nowim or {}
    NSQC4.Nowim.ApplyEnterBinding = ApplyBinding

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        if NSQC4.Nowim and NSQC4.Nowim.Config and NSQC4.Nowim.Config.db then
            ApplyBinding()
        end
    end)

    local function HookMainFrame()
        local UI = NSQC4.Nowim and NSQC4.Nowim.UI
        local mainFrame = UI and UI.MainFrame
        if not mainFrame or mainFrame._nowimEnterHooked then return end
        mainFrame._nowimEnterHooked = true

        local orig_Hide = mainFrame.Hide
        mainFrame.Hide = function(self)
            if orig_Hide then orig_Hide(self) else self:Hide() end
            ApplyBinding()
        end

        local orig_Show = mainFrame.ShowFrame
        mainFrame.ShowFrame = function(self)
            if orig_Show then orig_Show(self) else self:Show() end
            ApplyBinding()
        end
    end

    if not HookMainFrame() then
        local g = CreateFrame("Frame")
        g:RegisterEvent("PLAYER_LOGIN")
        g:SetScript("OnEvent", function(self)
            if HookMainFrame() then self:UnregisterAllEvents() end
        end)
    end

end)