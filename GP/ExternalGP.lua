-- ============================================================================
-- NSQC4 / GP / ExternalGP
-- ============================================================================

NSQC4.RegisterModule("gp", function()

    if not NSQC4.ChatHandler or not NSQC4.ChatHandler.Register then
        return
    end

    local myName  = UnitName("player") or ""
    local plainMe = myName:match("^(.-)-") or myName

    local function ParseGpNick(text)
        if not text then return nil, nil end
        return text:match("^(%d+)[%s\160\194\129]+(.+)$")
    end

    local function SaveExternalGp(gpStr, nick)
        if not gpStr or not nick or nick == "" then return end
        local gp = tonumber(gpStr)
        if not gp then gp = 0 end
        local cleanNick = nick:match("^(.-)-") or nick

        if gpDb and gpDb.SetExternalGp then
            gpDb:SetExternalGp(cleanNick, gp)
        end
    end

    NSQC4.ChatHandler:Register("ADDON:showgpa", {
        func = function(words, sender, text, channel, prefix)
            if sender == myName then return end

            local targetNick = text and text:match("^%s*(.-)%s*$")
            if not targetNick or targetNick == "" then return end
            local plainTarget = targetNick:match("^(.-)-") or targetNick
            if plainTarget ~= plainMe then return end

            local myGP = 0
            for i = 1, GetNumGuildMembers(true) do
                local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
                if name then
                    local plainName = name:match("^(.-)-") or name
                    if plainName == plainMe then
                        if officerNote and officerNote ~= "" then
                            local words2 = {}
                            for word in officerNote:gmatch("%S+") do
                                table.insert(words2, word)
                            end
                            if #words2 >= 3 then
                                myGP = tonumber(words2[3]) or 0
                            end
                        end
                        break
                    end
                end
            end
            SendAddonMessage("hisGP", tostring(myGP) .. " " .. myName, "RAID")
        end,
        stopOnMatch = true,
    })

    NSQC4.ChatHandler:Register("ADDON:enaltogi", {
        func = function(words, sender, text, channel, prefix)
            local gp, nick = ParseGpNick(text)
            if not gp or not nick then return end
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

    NSQC4.ChatHandler:Register("ADDON:ns_hisgp", {
        func = function(words, sender, text, channel, prefix)
            local gp, nick = ParseGpNick(text)
            if not gp or not nick then return end
            SaveExternalGp(gp, nick)
        end,
        stopOnMatch = true,
    })

end)