NSQC4.RegisterModule("quests", function()
    local W = NSQC4.FieldWindow
    if not W then return end

    local RADIO_H, RADIO_GAP, MARGIN, ICON_W, ICON_GAP = 24, 6, 8, 24, 12

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

    function W:DrawRadio(windowId, rec, y, availableW)
        local win = self[windowId]
        if not win then return 0 end
        local btns = self:EnsureRadioGroup(windowId, rec.groupId)
        if not btns then return 0 end
        local grp = self._radioGroups[windowId][rec.groupId]
        if not grp then return 0 end

        local align = grp.align or "LEFT"
        local winW = win:GetWidth()
        local n = 0
        for _, opt in ipairs(grp.options or {}) do
            if btns[opt.value] then n = n + 1 end
        end
        local totalW = ICON_W * n + (n > 1 and ICON_GAP * (n - 1) or 0)

        local x = (align == "CENTER") and (winW - totalW) / 2
               or (align == "RIGHT") and (winW - MARGIN - totalW)
               or MARGIN

        for _, opt in ipairs(grp.options or {}) do
            local rb = btns[opt.value]
            if rb then
                rb:ClearAllPoints()
                rb:SetPoint("TOPLEFT", win, "TOPLEFT", x, y)
                rb:Show()
                x = x + ICON_W + ICON_GAP
            end
        end
        return RADIO_H + RADIO_GAP
    end
end, 560)