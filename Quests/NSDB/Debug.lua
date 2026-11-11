-- ============================================================================
-- NSQC4 / Quests / NSDB / Debug
-- Одна логика: /ns_db tables | dump <scope> | clear <scope> | drop <scope>.
-- dump рекурсивный: показывает вложенные таблицы.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local NSDB = NSQC4.NSDB
    if not NSDB then return end

    local function DumpTree(t, prefix, depth)
        if depth > 6 then return end
        local keys = {}
        for k in pairs(t) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local v = t[k]
            if type(v) == "table" then
                print(string.format("  %s%s = {", prefix, tostring(k)))
                DumpTree(v, prefix .. "  ", depth + 1)
                print(string.format("  %s}", prefix))
            else
                print(string.format("  %s%s = %s", prefix, tostring(k), tostring(v)))
            end
        end
    end

    SLASH_NSDB1 = "/ns_db"
    SlashCmdList["NSDB"] = function(msg)
        local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
        cmd = (cmd or ""):lower()
        arg = arg or ""

        if cmd == "" or cmd == "tables" then
            local root = NSDB:Root()
            local names = {}
            for n in pairs(root) do names[#names + 1] = n end
            table.sort(names)
            print(string.format("[NSDB] таблиц верхнего уровня: %d", #names))
            for _, n in ipairs(names) do
                print(string.format("  %s", n))
            end

        elseif cmd == "dump" then
            if arg == "" then
                print("[NSDB] /ns_db dump <scope>")
                return
            end
            local t = NSDB:Walk(arg)
            if not t then
                print("[NSDB] нет таблицы: " .. arg)
                return
            end
            print(string.format("[NSDB] %s = {", arg))
            DumpTree(t, "  ", 0)
            print("}")

        elseif cmd == "clear" then
            if arg == "" then
                print("[NSDB] /ns_db clear <scope>")
                return
            end
            print(string.format("[NSDB] clear %s → %s", arg,
                tostring(NSDB:Clear(arg))))

        elseif cmd == "drop" then
            if arg == "" then
                print("[NSDB] /ns_db drop <scope>")
                return
            end
            print(string.format("[NSDB] drop %s → %s", arg,
                tostring(NSDB:DropTable(arg))))

        else
            print("[NSDB] /ns_db tables | dump <scope> | clear <scope> | drop <scope>")
        end
    end

    print("|cff00ffff[NSDB]|r База данных загружена. /ns_db tables | dump <scope>")

end, 270)