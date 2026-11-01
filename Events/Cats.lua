-- ============================================================================
-- NSQC4 / Events / Cats
-- Модуль: events_cats.
-- ============================================================================

NSQC4.RegisterModule("events_cats", function()

    NSQC4.Cats = NSQC4.Cats or {}
    local C = NSQC4.Cats

    C.last = C.last or {
        guid     = nil,
        name     = nil,
        time     = nil, 
        getTime  = nil,
        changes  = 0,
    }

    local function EnsureDB()
        NSQS2DB = NSQS2DB or {}
        NSQS2DB.cats = NSQS2DB.cats or {}
        NSQS2DB.cats.lastTarget = NSQS2DB.cats.lastTarget or {}
        return NSQS2DB.cats.lastTarget
    end

    local function LoadLast()
        local db = EnsureDB()
        if db.guid then
            C.last.guid    = db.guid
            C.last.name    = db.name
            C.last.time    = db.time
            C.last.getTime = nil 
            C.last.changes = tonumber(db.changes) or 0
        end
    end

    local function SaveLast()
        local db = EnsureDB()
        db.guid    = C.last.guid
        db.name    = C.last.name
        db.time    = C.last.time
        db.changes = C.last.changes
    end

    LoadLast()

    function C.GetLast()
        return C.last
    end

    function C.GetLastGuid()
        return C.last.guid
    end

    function C.GetLastKey()
        if not C.last.guid or not C.last.name then return nil end
        return (UnitName("player") or "?") .. ":" .. C.last.guid
    end

    function C.ClearLast()
        C.last.guid    = nil
        C.last.name    = nil
        C.last.time    = nil
        C.last.getTime = nil
        C.last.changes = 0
        SaveLast()
    end

    local function OnTargetChanged()
        local guid = UnitGUID("target")
        if not guid then
            return
        end

        local name = UnitName("target") or "?"

        C.last.guid    = guid
        C.last.name    = name
        C.last.time    = time()
        C.last.getTime = GetTime()
        C.last.changes = (C.last.changes or 0) + 1

        SaveLast()

        SendAddonMessage("itsCat " .. name, guid, "GUILD")
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:SetScript("OnEvent", function()
        OnTargetChanged()
    end)

    SLASH_CATS1 = "/cats"
    SlashCmdList["CATS"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")
        if msg == "clear" then
            C.ClearLast()
            print("|cff00ff00[NSQC4 Cats]|r последняя цель очищена")
            return
        end
        local l = C.last
        print("|cff00ff00[NSQC4 Cats]|r")
        print("  guid:    " .. tostring(l.guid))
        print("  name:    " .. tostring(l.name))
        print("  time:    " .. tostring(l.time) .. " (" .. (l.time and date("%d.%m.%y %H:%M:%S", l.time) or "?") .. ")")
        print("  getTime: " .. tostring(l.getTime))
        print("  changes: " .. tostring(l.changes))
        local k = C.GetLastKey()
        print("  key:     " .. tostring(k))
    end

    -- ========================================================================
    -- Метаданные модуля events_cats
    -- ========================================================================
    NSQC4.SetModuleMeta("events_cats", {
        label   = "Котики",
        tooltip = "Эвент: Котики.",
        order   = 20,
    })

end)