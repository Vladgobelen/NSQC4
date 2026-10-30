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

    local function UpdateSystemChatVisibility()
        local C = NSQC4.Nowim.Config
        if not C or not C.db or not C.db.settings then return end
        local hideSystem = C.db.settings.interceptEnter
        for i = 1, 7 do
            local frame = _G["ChatFrame"..i]
            if frame then
                if hideSystem then
                    frame:SetAlpha(0.01)
                    if frame.Background then frame.Background:SetAlpha(0.01) end
                else
                    frame:SetAlpha(1)
                    if frame.Background then frame.Background:SetAlpha(1) end
                end
            end
        end
    end
    NSQC4.Nowim.UpdateSystemChatVisibility = UpdateSystemChatVisibility

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

    local function ShouldNowimIntercept()
        local Nowim = NSQC4.Nowim
        if not Nowim or not Nowim.Config or not Nowim.Config.db then return false end
        local s = Nowim.Config.db.settings
        if s.interceptEnter then return true end
        return s.lastChatFocus == "nowim"
    end

    local function ApplyBinding()
        if ShouldNowimIntercept() then
            SetOverrideBindingClick(enterCatcher, true, "ENTER", "NSQC4_NowimEnterCatcher")
            SetOverrideBindingClick(enterCatcher, true, "NUMPADENTER", "NSQC4_NowimEnterCatcher")
        else
            ClearOverrideBindings(enterCatcher)
        end
    end

    NSQC4.Nowim = NSQC4.Nowim or {}
    NSQC4.Nowim.ApplyEnterBinding = ApplyBinding

    function NSQC4.Nowim.FocusNowimChat()
        local C = NSQC4.Nowim.Config
        if C and C.db and C.db.settings then
            C.db.settings.lastChatFocus = "nowim"
        end
        ApplyBinding()
    end

    function NSQC4.Nowim.FocusBlizzChat()
        local C = NSQC4.Nowim.Config
        if C and C.db and C.db.settings then
            C.db.settings.lastChatFocus = "blizz"
        end
        ApplyBinding()
    end

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
        if not mainFrame or mainFrame._nowimEnterHooked then return false end
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
        return true
    end

    if not HookMainFrame() then
        local g = CreateFrame("Frame")
        g:RegisterEvent("PLAYER_LOGIN")
        g:SetScript("OnEvent", function(self)
            if HookMainFrame() then self:UnregisterAllEvents() end
        end)
    end

    -- ========================================================================
    -- ЛОВИМ ФОКУС НА СТАНДАРТНОМ ЧАТЕ
    -- ========================================================================

    for i = 1, 7 do
        local eb = _G["ChatFrame"..i.."EditBox"]
        if eb and not eb._nowimFocusHooked then
            eb._nowimFocusHooked = true
            
            eb:HookScript("OnEditFocusGained", function(self)
                if NSQC4.Nowim.FocusBlizzChat then
                    NSQC4.Nowim.FocusBlizzChat()
                end
            end)
        end
    end

end)