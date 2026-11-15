-- ============================================================================
-- NSQC4 / Quests / Field / UI / Window / API / Visible
-- Одна логика: управление видимостью окна.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

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
end, 492)