-- ============================================================================
-- NSQC4 / Quests / Field / Settings / Content
-- Один раздел окна настроек: заголовок + кнопки сброса.
--
-- Мышь окна — та же схема, что у поля:
--   win:SetScript("OnMouseDown", Dispatch)   (W.SetupWindowMouse)
--   Dispatch перебирает win._mouseHandlers
--   Content.lua добавляет СВОЙ обработчик, который делает хит-тест кнопок.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local W        = NSQC4.FieldWindow
    local UIButton = NSQC4.UIButton
    if not W or not UIButton then return end

    -- --------------------------------------------------------------------
    -- Добавить кнопку и, если окно уже существует, перестроить.
    -- --------------------------------------------------------------------
    local function AddButton(windowId, index, label, onClick)
        local rec = UIButton:CreateRecord(label, onClick)

        W._items = W._items or {}
        local items = W._items[windowId]
        if not items then
            items = {}
            W._items[windowId] = items
        end
        items[index] = rec

        if W[windowId] and W.LayoutWindow then
            W:LayoutWindow(windowId)
        end

        return rec
    end

    -- 1) Заголовок раздела
    W:RegisterLabel("settings", 1, "Настройки", nil, { align = "CENTER" })

    -- 2) Сброс положения
    AddButton("settings", 2, "Сбросить положение", function()
        local field = NSQC4.Field
        local NSDB  = NSQC4.NSDB
        if not field or not NSDB then return end

        NSDB:Delete("field", "x")
        NSDB:Delete("field", "y")

        if field.frame then
            field.frame:ClearAllPoints()
            field.frame:SetPoint("CENTER")
            field:Save()
        end
    end)

    -- 3) Сброс размера
    AddButton("settings", 3, "Сбросить размер", function()
        local field = NSQC4.Field
        local NSDB  = NSQC4.NSDB
        if not field or not NSDB then return end

        NSDB:Delete("field", "cellSize")

        if field.Resize then
            field:Resize(32)
        end
    end)

    -- ========================================================================
    -- Обработчик мыши окна: хит-тест кнопок по геометрии.
    -- ========================================================================
    local function AttachButtonMouse(win)
        if not win or win._buttonsMouseAttached then return end
        win._buttonsMouseAttached = true

        W.AddWindowMouseHandler(win, function(x, y, button, event)
            if event ~= "down" then
                if event == "up" then
                    UIButton:Release()
                end
                return false
            end

            if button ~= "LeftButton" then return false end

            local items = W._items and W._items["settings"]
            if not items then return false end

            local winLeft, winBottom = win:GetLeft(), win:GetBottom()
            if not winLeft or not winBottom then return false end
            local screenX = winLeft + x
            local screenY = winBottom + y

            for _, rec in pairs(items) do
                if rec.kind == "button" and rec.frame and rec.frame:IsShown() then
                    local l = rec.frame:GetLeft()
                    local r = rec.frame:GetRight()
                    local t = rec.frame:GetTop()
                    local b = rec.frame:GetBottom()
                    if l and r and t and b
                       and screenX >= l and screenX <= r
                       and screenY >= b and screenY <= t then
                        UIButton:Press(rec)
                        if rec.onClick then rec.onClick(button) end
                        return true
                    end
                end
            end

            return false
        end)
    end

    -- Если окно уже создано — навесить всё нужное сразу.
    local win = W["settings"]
    if win then
        W.SetupWindowMouse(win)
        AttachButtonMouse(win)
    end

    -- Перехватить W:Register, чтобы при создании окна навесить всё нужное.
    local oldRegister = W.Register
    W.Register = function(self, desc)
        local w = oldRegister(self, desc)
        if w and desc and desc.id == "settings" then
            W.SetupWindowMouse(w)     -- ← через W, а не голое имя
            AttachButtonMouse(w)
        end
        return w
    end
end, 580)