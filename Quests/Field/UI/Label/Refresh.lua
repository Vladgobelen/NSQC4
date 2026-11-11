-- ============================================================================
-- NSQC4 / Quests / Field / UI / Label / Refresh
-- Отрисовка лейблов. Положение — по rec.align (LEFT / CENTER / RIGHT).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local W = NSQC4.FieldWindow
    if not W then return end

    local LABEL_H  = 24
    local DESC_GAP = 4
    local TITLE_R, TITLE_G, TITLE_B = 1, 0.82, 0
    local DESC_R,  DESC_G,  DESC_B  = 0.7, 0.7, 0.7

    local function ApplyAlign(fs, win, y, align)
        fs:ClearAllPoints()
        if align == "CENTER" then
            fs:SetPoint("TOP", win, "TOP", 0, y)
            fs:SetJustifyH("CENTER")
        elseif align == "RIGHT" then
            fs:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, y)
            fs:SetJustifyH("RIGHT")
        else
            fs:SetPoint("TOPLEFT", win, "TOPLEFT", 8, y)
            fs:SetJustifyH("LEFT")
        end
    end

    function W:DrawLabel(windowId, rec, y, availableW)
        local win = self[windowId]
        if not win then return 0 end

        local align = rec.align or "LEFT"

        if not rec.frame then
            local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetText(rec.title)
            title:SetTextColor(TITLE_R, TITLE_G, TITLE_B)
            rec.frame = title

            if rec.desc then
                local desc = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                desc:SetText(rec.desc)
                desc:SetTextColor(DESC_R, DESC_G, DESC_B)
                desc:SetNonSpaceWrap(true)
                rec.descFrame = desc
            end
        end

        ApplyAlign(rec.frame, win, y, align)
        rec.frame:Show()

        local h = LABEL_H
        if rec.descFrame then
            rec.descFrame:SetWidth(availableW)
            ApplyAlign(rec.descFrame, win, y - LABEL_H, align)
            rec.descFrame:Show()
            h = h + (rec.descFrame:GetStringHeight() or 0) + DESC_GAP
        end
        return h
    end

end, 520)