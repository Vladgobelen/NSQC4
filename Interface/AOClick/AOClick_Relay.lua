-- ============================================================================
-- NSQC4 / Interface / AOClick / Relay
-- Модуль ui_ao: парсинг и замена релей-сообщений АО.
-- ============================================================================

NSQC4.RegisterModule("ui_ao", function()

    local A = NSQC4.AOClick
    if not A then return end

    local aoSettings = A.aoSettings
    local CLASS_COLORS = A.CLASS_COLORS
    local DEFAULT_COLOR = A.DEFAULT_COLOR
    local NICK_COLOR_RESET = A.NICK_COLOR_RESET
    local aoNames = A.aoNames

    local function BuildRelayReplacement(code, nick, meta, faction)
        local cleanName = nick:gsub(":+$", "")
        local color = CLASS_COLORS[code] or DEFAULT_COLOR
        aoNames[cleanName] = { faction = faction }

        local finalMeta = meta
        if meta and meta ~= "" then
            local parts = {}
            for val in meta:gmatch("([^:]+)") do table.insert(parts, val) end

            local lvl = parts[1]
            local gp  = parts[2]
            local rep = parts[3]

            local outParts = {}
            if not aoSettings.hideLevel and lvl and tonumber(lvl) ~= 80 and tonumber(lvl) ~= 0 then
                table.insert(outParts, lvl)
            end
            if not aoSettings.hideGP and gp and tonumber(gp) ~= 0 then
                table.insert(outParts, gp)
            end
            if not aoSettings.hideRep and rep and tonumber(rep) ~= 0 then
                table.insert(outParts, rep)
            end

            if #outParts > 0 then
                finalMeta = ":" .. table.concat(outParts, ":")
            else
                finalMeta = ""
            end
        end

        local nickDisplay = cleanName .. (finalMeta or "")

        local nickLink = "|Hplayer:" .. cleanName .. "|h" ..
            color .. "[" .. nickDisplay .. "]" .. NICK_COLOR_RESET .. "|h"

        return nickLink .. ": "
    end

    local function ReplaceAll(msg)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[\208\158(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[\208\158(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[\208\144(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[\208\144(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Alliance") end)

        msg = msg:gsub(
            "%[O(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Horde")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Horde")
                end
            end)
        msg = msg:gsub(
            "%[O(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Horde") end)
        msg = msg:gsub(
            "%[O(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Horde") end)

        msg = msg:gsub(
            "%[A(%d):(%-?%d+):(%-?%d+)%]%s+(%S+):%s*",
            function(code, level, rep, nick)
                if tonumber(level) == 80 then
                    return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance")
                else
                    return BuildRelayReplacement(code, nick, ":" .. level .. ":" .. rep, "Alliance")
                end
            end)
        msg = msg:gsub(
            "%[A(%d):(%-?%d+)%]%s+(%S+):%s*",
            function(code, rep, nick) return BuildRelayReplacement(code, nick, ":" .. rep, "Alliance") end)
        msg = msg:gsub(
            "%[A(%d)%]%s+(%S+):%s*",
            function(code, nick) return BuildRelayReplacement(code, nick, nil, "Alliance") end)

        return msg
    end
    A.ReplaceAll = ReplaceAll

    local function IsRelayText(text)
        if not text or text == "" then return false end
        if text:match("^%[\208\158") then return true end
        if text:match("^%[\208\144") then return true end
        if text:match("^%[O")        then return true end
        if text:match("^%[A")        then return true end
        return false
    end
    A.IsRelayText = IsRelayText

    local function ExtractLetter(text)
        if text:match("^%[\208\158") then return "О" end
        if text:match("^%[\208\144") then return "А" end
        if text:match("^%[O")        then return "О" end
        if text:match("^%[A")        then return "А" end
        return ""
    end
    A.ExtractLetter = ExtractLetter

end)