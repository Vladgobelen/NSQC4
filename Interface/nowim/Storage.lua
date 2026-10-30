-- ============================================================================
-- NSQC4 / nowim / Storage
-- ============================================================================

NSQC4.RegisterModule("nowim", function()

    local C = NSQC4.Nowim.Config
    local U = NSQC4.Nowim.Utils
    local A = NSQC4.Nowim.Aliases

    local S = {}
    NSQC4.Nowim.Storage = S

    local function ResolveKey(nick)
        if not nick then return nil end
        local s = tostring(nick)
        if C.db.channels[s] then return s end
        if C.db.channels[nick] then return nick end
        return A.GetMainName(s)
    end

    function S.AddMessage(target, text, isMine, realSender, chatType)
        local key = ResolveKey(target)
        if not key or not text then return end
        if type(key) ~= "string" then return end

        C.db.dialogs[key] = C.db.dialogs[key] or { messages = {} }
        local dialog = C.db.dialogs[key]

        local charTag = realSender or (isMine and UnitName("player") or nil)

        local msgData = {
            text = text,
            isMine = isMine,
            time = U.GetTimeString(),
            char = charTag,
            chatType = chatType -- СОХРАНЯЕМ ТИП
        }

        table.insert(dialog.messages, msgData)

        if #dialog.messages > C.MAX_HISTORY then
            local oldMsg = table.remove(dialog.messages, 1)
            C.db.archives[key] = C.db.archives[key] or { messages = {} }
            table.insert(C.db.archives[key].messages, oldMsg)
        end
    end

    function S.GetMessages(key)
        local resolvedKey = ResolveKey(key)
        if not resolvedKey or not C.db.dialogs[resolvedKey] then return nil end
        return C.db.dialogs[resolvedKey].messages
    end

    function S.ClearHistory(key)
        local resolvedKey = ResolveKey(key)
        if resolvedKey and C.db.dialogs[resolvedKey] then
            C.db.dialogs[resolvedKey].messages = {}
        end
    end

    function S.GetContacts()
        local list = {}
        
        for key in pairs(C.db.dialogs) do
            local s = tostring(key)
            if not C.db.channels[s] and not C.db.channels[key] then
                table.insert(list, { key = s, name = s, isChannel = false })
            end
        end
        
        for id, data in pairs(C.db.channels) do
            local key = tostring(id)
            table.insert(list, { key = key, name = tostring(data.name or id), isChannel = true })
        end

        table.sort(list, function(a, b)
            local nameA = tostring(a.name or "")
            local nameB = tostring(b.name or "")
            if a.isChannel ~= b.isChannel then return a.isChannel == false end
            return nameA < nameB
        end)
        
        return list
    end

end)