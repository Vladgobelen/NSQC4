-- ============================================================================
-- NSQC4 / Quests / Field / UI / Buttons / Draw / Appearance
-- Одна логика: текстура и цвет кнопки.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then return end

    function QuestsField:ApplyButtonAppearance(rec, data)
        local tex = rec.texture
        tex:SetTexture(data.icon)

        local c = data.opts and data.opts.color
        if c then
            tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        else
            tex:SetVertexColor(1, 1, 1, 1)
        end
    end

end, 463)