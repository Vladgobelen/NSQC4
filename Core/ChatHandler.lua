-- ============================================================================
-- NSQC4 ChatHandler — диспетчер чат-команд с O(1)-маршрутизацией
-- ============================================================================

NSQC4 = NSQC4 or {}
NSQC4.ChatHandler = {}
NSQC4.ChatHandler.__index = NSQC4.ChatHandler

-- Тип чата → событие WoW
local CHAT_EVENTS = {
    SAY           = "CHAT_MSG_SAY",
    YELL          = "CHAT_MSG_YELL",
    WHISPER       = "CHAT_MSG_WHISPER",
    GUILD         = "CHAT_MSG_GUILD",
    OFFICER       = "CHAT_MSG_OFFICER",
    PARTY         = "CHAT_MSG_PARTY",
    PARTY_LEADER  = "CHAT_MSG_PARTY_LEADER",
    RAID          = "CHAT_MSG_RAID",
    RAID_LEADER   = "CHAT_MSG_RAID_LEADER",
    RAID_WARNING  = "CHAT_MSG_RAID_WARNING",
    BATTLEGROUND  = "CHAT_MSG_BATTLEGROUND",
    CHANNEL       = "CHAT_MSG_CHANNEL",
    ADDON         = "CHAT_MSG_ADDON",
}

-- ============================================================================
-- Отладка: включается NSQC4.ChatHandler.debug = true
-- ============================================================================
local function dbg(...)
    if NSQC4.ChatHandler and NSQC4.ChatHandler.debug then
        print("|cff00ffff[CH-DBG]|r", ...)
    end
end

-- ============================================================================
-- СОЗДАНИЕ
-- ============================================================================
function NSQC4.ChatHandler:new(chatTypes, opts)
    opts = opts or {}
    local obj = setmetatable({}, self)

    obj.triggers         = {}
    obj.triggersAnywhere = {}
    obj.textPrefix       = opts.textPrefix or "-"
    obj.addonPrefix      = opts.addonPrefix or ""
    obj.debug            = opts.debug or false
    obj.funcCache        = {}

    obj.frame = CreateFrame("Frame")

    if chatTypes and #chatTypes > 0 then
        for _, t in ipairs(chatTypes) do
            local ev = CHAT_EVENTS[t]
            if ev then obj.frame:RegisterEvent(ev) end
        end
    else
        for _, ev in pairs(CHAT_EVENTS) do
            if ev ~= "CHAT_MSG_SYSTEM" then
                obj.frame:RegisterEvent(ev)
            end
        end
    end

    obj.frame:SetScript("OnEvent", function(_, event, ...)
        obj:OnChatMessage(event, ...)
    end)

    return obj
end

-- ============================================================================
-- УНИЧТОЖЕНИЕ
-- ============================================================================
function NSQC4.ChatHandler:Destroy()
    if self.frame then
        self.frame:UnregisterAllEvents()
        self.frame:SetScript("OnEvent", nil)
        self.frame:Hide()
        self.frame = nil
    end
    self.triggers = {}
    self.triggersAnywhere = {}
    self.funcCache = {}
end

-- ============================================================================
-- РЕГИСТРАЦИЯ ТРИГГЕРОВ
-- ============================================================================
function NSQC4.ChatHandler:Register(key, trigger)
    if not key or not trigger then
        dbg("Register: пустой key или trigger")
        return
    end
    if trigger.anywhere then
        self.triggersAnywhere[key] = self.triggersAnywhere[key] or {}
        table.insert(self.triggersAnywhere[key], trigger)
        dbg("Register ANYWHERE key=["..key.."]")
    else
        self.triggers[key] = self.triggers[key] or {}
        table.insert(self.triggers[key], trigger)
        dbg("Register NORMAL key=["..key.."]")
    end
end

-- ============================================================================
-- ОБРАБОТКА СООБЩЕНИЙ
-- ============================================================================
function NSQC4.ChatHandler:OnChatMessage(event, ...)
    local text, sender, prefix, channel

    if event == "CHAT_MSG_ADDON" then
        prefix, text, channel, sender = ...
        if not prefix then dbg("ADDON без prefix"); return end
        if self.addonPrefix ~= "" and prefix:sub(1, #self.addonPrefix) ~= self.addonPrefix then
            dbg("ADDON prefix=["..prefix.."] не начинается с ["..self.addonPrefix.."] → skip")
            return
        end
    else
        text, sender = ...
        if not text or text == "" then return end
    end

    if not text then return end

    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local firstWordRaw = text:match("^(%S+)")
    if not firstWordRaw then return end

    local shortType = event:match("^CHAT_MSG_(.+)$")
    local firstWord = firstWordRaw:lower()

    local key = shortType .. ":" .. firstWord

    dbg("MSG event="..tostring(event).." shortType="..tostring(shortType)
        .." text=["..text.."] sender="..tostring(sender)
        .." firstWord=["..firstWord.."] key=["..key.."]")

    -- 1. O(1) — прямой lookup по первому слову.
    local list = self.triggers[key]
    if list then
        dbg("lookup NORMAL key=["..key.."] найден, триггеров="..#list)
        if self:RunTriggers(list, event, text, sender, prefix, channel, shortType) then
            return
        end
    else
        dbg("lookup NORMAL key=["..key.."] НЕ найден")
    end

    -- 1b. Триггеры с anywhere=true: проверяем каждое слово фразы.
    if next(self.triggersAnywhere) then
        dbg("anywhere-таблица не пуста, слов в тексте:")
        for word in text:gmatch("%S+") do
            local wkey = shortType .. ":" .. word:lower()
            local wlist = self.triggersAnywhere[wkey]
            dbg("  слово=["..word.."] wkey=["..wkey.."] список="..(wlist and #wlist or "nil"))
            if wlist then
                if self:RunTriggers(wlist, event, text, sender, prefix, channel, shortType) then
                    return
                end
            end
        end
    else
        dbg("anywhere-таблица ПУСТА")
    end

    -- 2. ADDON по префиксу
    if event == "CHAT_MSG_ADDON" and prefix then
        local basePrefix = prefix:match("^(%S+)") or prefix
        local pkey = "ADDON:" .. basePrefix:lower()
        local plist = self.triggers[pkey]
        if plist then
            if self:RunTriggers(plist, event, text, sender, prefix, channel, shortType) then
                return
            end
        end
    end

    -- 3. Catch-all "*"
    local anyList = self.triggers["*"]
    if anyList then
        self:RunTriggers(anyList, event, text, sender, prefix, channel, shortType)
    end
end

-- ============================================================================
-- ЗАПУСК СПИСКА ТРИГГЕРОВ
-- ============================================================================
function NSQC4.ChatHandler:RunTriggers(list, event, text, sender, prefix, channel, shortType)
    for i, t in ipairs(list) do
        dbg("  RunTriggers["..i.."] проверка")
        if self:CheckTrigger(t, event, text, sender, prefix, channel, shortType) then
            dbg("  RunTriggers["..i.."] сработал, stopOnMatch="..tostring(t.stopOnMatch))
            if t.stopOnMatch then return true end
        end
    end
    return false
end

-- ============================================================================
-- ПРОВЕРКА ОДНОГО ТРИГГЕРА
-- ============================================================================
function NSQC4.ChatHandler:CheckTrigger(t, event, text, sender, prefix, channel, shortType)
    if t.chatType then
        local found = false
        for _, ct in ipairs(t.chatType) do
            if ct == shortType then found = true; break end
        end
        if not found then
            dbg("    CheckTrigger: chatType не совпал")
            return false
        end
    end

    if t.conditions then
        for _, cond in ipairs(t.conditions) do
            local fn = cond
            if type(cond) == "string" then
                fn = self.funcCache[cond]
                if not fn then
                    fn = _G[cond]
                    self.funcCache[cond] = fn
                end
            end
            if not fn or not fn(text, sender, channel, prefix) then
                dbg("    CheckTrigger: условие не прошло")
                return false
            end
        end
    end

    local func = t.func
    if type(func) == "string" then
        func = self.funcCache[func]
        if not func then
            func = _G[t.func]
            self.funcCache[t.func] = func
        end
    end

    if type(func) == "function" then
        local words = {}
        for w in text:gmatch("%S+") do table.insert(words, w) end
        dbg("    CheckTrigger: вызов func")
        func(words, sender, text, channel, prefix)
    elseif self.debug then
        print("|cffff0000[ChatHandler]|r функция не найдена:", tostring(t.func))
    end

    return true
end

-- ============================================================================
-- ИНСТАНС
-- ============================================================================
local instance = NSQC4.ChatHandler:new(
    {"GUILD", "WHISPER", "ADDON", "RAID", "RAID_LEADER", "RAID_WARNING"},
    { addonPrefix = "", debug = false }
)
NSQC4.chat = instance
NSQC4.ChatHandler = instance