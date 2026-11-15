-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Create
-- Одна логика: создание окна (Register) + отложенные onShow-хуки.
--
-- После создания окна:
--   - навешивает мышь (W:SetupWindowMouse, 497)
--   - навешивает хит-тест кнопок (W:AttachButtonMouse, 584), если есть items
--   - вызывает отложенные onShow-хуки (W:RegisterOnShow)
--
-- Это заменяет манки-патчинг W:Register из Content.lua и W:Show/W:Toggle
-- из Radio.lua.
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

        -- 1) Мышь окна
        if W.SetupWindowMouse then
            W:SetupWindowMouse(win)
        end

        -- 2) Хит-тест кнопок (если для окна уже зарегистрированы кнопки)
        if W.AttachButtonMouse and next(W._items[key]) then
            W:AttachButtonMouse(win, key)
        end

        -- 3) Раскладка
        if next(W._items[key]) and W.LayoutWindow then
            W:LayoutWindow(key)
        end

        -- 4) Отложенные onShow-хуки
        local hooks = W._onShowHooks and W._onShowHooks[key]
        if hooks then
            for _, fn in ipairs(hooks) do
                local ok, err = pcall(fn, win)
                if not ok then
                    print("|cffff0000[NSQC4]|r onShow hook:", tostring(err))
                end
            end
            W._onShowHooks[key] = nil
        end

        return win
    end

    -- ========================================================================
    -- RegisterOnShow — зарегистрировать колбэк, который вызовется после
    -- создания окна. Если окно уже создано — вызовется сразу.
    -- ========================================================================
    function W:RegisterOnShow(key, fn)
        if not key or type(fn) ~= "function" then return end
        self._onShowHooks = self._onShowHooks or {}
        self._onShowHooks[key] = self._onShowHooks[key] or {}
        local list = self._onShowHooks[key]

        local win = self[key]
        if win then
            local ok, err = pcall(fn, win)
            if not ok then
                print("|cffff0000[NSQC4]|r onShow hook:", tostring(err))
            end
        else
            list[#list + 1] = fn
        end
    end
end, 491)