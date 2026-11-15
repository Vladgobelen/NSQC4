-- ============================================================================
-- NSQC4 / Quests / Field / Settings / Content
-- Один раздел окна настроек: заголовок + кнопки сброса.
--
-- НЕ реализует мышь окна (UI/Window/API/Mouse/*).
-- НЕ реализует хит-тест кнопок (UI/Window/API/Buttons/Hit.lua).
-- НЕ перехватывает W:Register.
--
-- Кнопки добавляются через W:AddButton (583).
-- Мышь и хит-тест навешиваются в UI/Window/API/Create.lua (491)
-- автоматически после создания окна.
-- ============================================================================
NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    -- 1) Заголовок раздела
    W:RegisterLabel("settings", 1, "Настройки", nil, { align = "CENTER" })

    -- 2) Сброс положения
    W:AddButton("settings", 2, "Сбросить положение", function()
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
    W:AddButton("settings", 3, "Сбросить размер", function()
        local field = NSQC4.Field
        local NSDB  = NSQC4.NSDB
        if not field or not NSDB then return end

        NSDB:Delete("field", "cellSize")

        if field.Resize then
            field:Resize(32)
        end
    end)
end, 580)