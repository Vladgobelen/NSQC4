-- ============================================================================
-- NSQC4 / Quests / Field / Settings / Init
-- Одна логика: регистрация кнопки «Настройки» на панели LEFT.
--
-- НЕ создаёт окно, НЕ регистрирует контент окна.
-- Окно создаётся лениво при первом клике (W:Register + W:Toggle).
--
-- Мышь окна настраивается через единый механизм (как у поля):
--   W.SetupWindowMouse(win) — навешивает Dispatch на окно (аналог Field/Mouse.lua)
--   W.AddWindowMouseHandler(win, fn) — регистрация обработчиков (аналог AddMouseHandler)
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local QuestsField = NSQC4.QuestsFieldClass
    local W           = NSQC4.FieldWindow
    if not QuestsField or not W then return end

    local field = NSQC4.Field
    if not field then return end

    -- ========================================================================
    -- SetupWindowMouse — навесить Dispatch на окно.
    -- Та же логика, что Field/Frame/Mouse.lua для поля, но для окна.
    -- ========================================================================
    local function SetupWindowMouse(win)
        if not win or win._mouseSetup then return end
        win._mouseSetup = true
        win._mouseHandlers = win._mouseHandlers or {}

        win:EnableMouse(true)

        local function CursorInWindow()
            local scale = UIParent:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            local left, bottom = win:GetLeft(), win:GetBottom()
            if not left or not bottom then return nil end
            return cx - left, cy - bottom
        end

        local function Dispatch(_, button, event)
            local x, y = CursorInWindow()
            if not x then return end
            for _, fn in ipairs(win._mouseHandlers) do
                if fn(x, y, button, event) then return end
            end
        end

        win:SetScript("OnMouseDown", function(_, button)
            Dispatch(win, button, "down")
        end)
        win:SetScript("OnMouseUp", function(_, button)
            Dispatch(win, button, "up")
        end)
    end

    -- ========================================================================
    -- AddWindowMouseHandler — API окна: добавить обработчик.
    -- ========================================================================
    local function AddWindowMouseHandler(win, fn)
        if not win or type(fn) ~= "function" then return end
        win._mouseHandlers = win._mouseHandlers or {}
        win._mouseHandlers[#win._mouseHandlers + 1] = fn
    end

    -- Экспортируем API окна наружу через W, чтобы Content.lua мог добавить
    -- свой обработчик (хит-тест кнопок).
    W.SetupWindowMouse      = SetupWindowMouse
    W.AddWindowMouseHandler = AddWindowMouseHandler

    -- ========================================================================
    -- Кнопка «Настройки» на панели LEFT
    -- ========================================================================
    field:RegisterButton(
        "LEFT", 1, 1,
        "Interface\\Icons\\INV_Misc_Gear_01",
        function(button)
            if button ~= "LeftButton" then return end

            W:Register({
                id     = "settings",
                side   = "LEFT",
                width  = 260,
                height = "FIELD",
            })

            local win = W["settings"]
            if win then
                SetupWindowMouse(win)
                -- Обработчик кнопок окна регистрируется в Content.lua
                -- через W.AddWindowMouseHandler(win, fn).
                -- Если Content.lua уже выполнился — обработчик уже в списке.
            end

            W:Toggle("settings")
        end,
        {
            tooltip = "Настройки поля",
            color   = { 1, 0.82, 0, 1 },
            visible = 1,
        }
    )
end, 570)