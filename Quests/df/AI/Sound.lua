-- ============================================================================
-- NSQC4 / Quests / df / AI / Sound
-- Короткие звуки событий: работа по terrain, старт к цели по kind.
-- Без стопов — короткие, накладываются.
--
-- Sound:PlayTerrain(terrainId)
-- Sound:PlayKind(kind)          -- "goblin" → gob.ogg, "dwarf" → gom.ogg
--
-- Отладка: /run NSQC4.QuestsDfAISound.DEBUG = true
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local Sound = {}
    NSQC4.QuestsDfAISound = Sound

    Sound.DEBUG   = false
    Sound.ENABLED = true

    local IMG_PATH = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\"

    local TERRAIN_SOUND = {
        earth = "0uz.ogg",
        grass = "00f.ogg",
        stone = "0ka.ogg",
        tree  = "00t.ogg",
        -- pool — пока нет
    }

    local KIND_SOUND = {
        goblin = "gob.ogg",
        dwarf  = "gom.ogg",
    }

    local function dbg(...)
        if Sound.DEBUG then print("|cffffaa00[SND]|r", ...) end
    end

    function Sound:PlayFile(file)
        if not Sound.ENABLED then return end
        if not file or file == "" then return end
        local path = IMG_PATH .. file
        local willPlay, handle = PlaySoundFile(path, "SFX")
        dbg("play", file, willPlay and "ok" or "fail", tostring(handle))
    end

    function Sound:PlayTerrain(terrainId)
        local file = TERRAIN_SOUND[terrainId]
        if not file then
            dbg("no terrain sound for", tostring(terrainId))
            return
        end
        self:PlayFile(file)
    end

    function Sound:PlayKind(kind)
        local file = KIND_SOUND[kind]
        if not file then
            dbg("no kind sound for", tostring(kind))
            return
        end
        self:PlayFile(file)
    end

end)