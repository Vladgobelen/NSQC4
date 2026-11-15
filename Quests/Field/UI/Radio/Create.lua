-- ============================================================================
-- NSQC4 / Quests / Field / UI / Radio / Create
-- Одна логика: создание CheckButton для радио-группы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    local function SafeName(windowId, groupId, value)
        local raw = string.format("NSQC4FieldRadio_%s_%s_%s",
            tostring(windowId), tostring(groupId), tostring(value))
        return (raw:gsub("[^%w_]", "_"))
    end

    function W:EnsureRadioGroup(windowId, groupId)
        local win = self[windowId]
        if not win then return nil end
        local grp = self._radioGroups and self._radioGroups[windowId]
                        and self._radioGroups[windowId][groupId]
        if not grp then return nil end
        if grp._buttons then return grp._buttons end

        grp._buttons = {}
        for _, opt in ipairs(grp.options or {}) do
            local name = SafeName(windowId, groupId, opt.value)
            local rb = _G[name] or CreateFrame("CheckButton", name, win, "UIRadioButtonTemplate")
            rb:SetParent(win)
            rb:SetFrameLevel(win:GetFrameLevel() + 5)
            rb:EnableMouse(true)
            rb.value = opt.value
            rb:Hide()

            local fs = rb:GetFontString()
            if fs then fs:Hide() end
            local fsG = _G[name .. "Text"]
            if fsG then fsG:Hide() end

            if opt.tooltip then
                rb:SetScript("OnEnter", function(s)
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(opt.tooltip, 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                rb:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end

            rb:SetScript("OnClick", function(s)
                for _, o in pairs(grp._buttons) do o:SetChecked(o == s) end
                if grp.onSelect then grp.onSelect(s.value) end
            end)

            grp._buttons[opt.value] = rb
        end
        return grp._buttons
    end
end, 553)