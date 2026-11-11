-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API
-- Одна логика: создание и управление пустыми окнами.
--
-- НЕ подключает мышь автоматически — для этого есть AttachMouseHandlers(key),
-- который должен быть вызван явно после регистрации контента окна.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    local C = NSQC4.FieldWindowConst
    if not W or not C then return end

    local function ResolveSize(val, fieldDim, default)
        if val == "FIELD" then return fieldDim end
        if type(val) == "number" then return val end
        return default
    end

    function W:Register(desc)
        if not desc or not desc.id then return nil end
        if self[desc.id] then return self[desc.id] end

        local field = NSQC4.Field
        if not field or not field.frame then return nil end

        local f   = field.frame
        local key = desc.id

        local w = ResolveSize(desc.width,  f:GetWidth(),  C.DEFAULT_WIDTH)
        local h = ResolveSize(desc.height, f:GetHeight(), f:GetHeight())

        local win = CreateFrame("Frame", "NSQC4FieldWindow_"..key, f)
        win:SetFrameStrata(f:GetFrameStrata())
        win:SetFrameLevel(f:GetFrameLevel() + C.FRAME_LEVEL_ADD)
        win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        win:SetBackdropColor(0, 0, 0, 0.9)
        win:EnableMouse(true)
        win:Hide()
        win.side = desc.side

        if desc.side == "LEFT" or desc.side == "RIGHT" then
            win:SetWidth(w)

            if desc.side == "LEFT" then
                win:SetPoint("TOPRIGHT",    f, "TOPLEFT",    -C.GAP, 0)
                win:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -C.GAP, 0)
            else
                win:SetPoint("TOPLEFT",    f, "TOPRIGHT",    C.GAP, 0)
                win:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", C.GAP, 0)
            end
        else
            win:SetHeight(h)

            if desc.side == "TOP" then
                win:SetPoint("BOTTOMLEFT",  f, "TOPLEFT",  0,  C.GAP)
                win:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0,  C.GAP)
            else
                win:SetPoint("TOPLEFT",  f, "BOTTOMLEFT",  0, -C.GAP)
                win:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -C.GAP)
            end
        end

        if desc.onShow then win:SetScript("OnShow", desc.onShow) end
        if desc.onHide then win:SetScript("OnHide", desc.onHide) end

        W[key] = win

        W._list = W._list or {}
        W._list[#W._list + 1] = win

        W._items = W._items or {}
        W._items[key] = W._items[key] or {}

        -- Раскладка элементов (если контент уже зарегистрирован).
        if next(W._items[key]) and W.LayoutWindow then
            W:LayoutWindow(key)
        end

        return win
    end

    -- ========================================================================
    -- AttachMouseHandlers — подключить мышь окна через UIButton.
    -- Должен быть вызван явно после регистрации контента окна.
    -- ========================================================================
    function W:AttachMouseHandlers(key)
        local win = self[key]
        if not win then return end

        local UIButton = NSQC4.UIButton
        if not UIButton or not UIButton.SetupMouse then return end

        local getItems = function()
            return self._items and self._items[key]
        end

        UIButton:SetupMouse(win, getItems)
    end

    function W:Show(key)
        local win = self[key]
        if win then win:Show() end
    end

    function W:Hide(key)
        local win = self[key]
        if win then win:Hide() end
    end

    function W:Toggle(key)
        local win = self[key]
        if not win then return end

        if win:IsShown() then win:Hide() else win:Show() end
    end

    function W:IsShown(key)
        local win = self[key]
        return win and win:IsShown() or false
    end
end, 490)