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
-- СОЗДАНИЕ
-- ============================================================================
function NSQC4.ChatHandler:new(chatTypes, opts)
    opts = opts or {}
    local obj = setmetatable({}, self)

    obj.triggers   = {}                    -- [key] = { trigger, trigger, ... }
    obj.textPrefix = opts.textPrefix or "-"  -- все команды в чате начинаются с "-"
    obj.addonPrefix = opts.addonPrefix or "ns_"  -- все ADDON-префиксы начинаются с "ns_"
    obj.debug      = opts.debug or false
    obj.funcCache  = {}

    obj.frame = CreateFrame("Frame")

    -- Регистрация чатов
    if chatTypes and #chatTypes > 0 then
        for _, t in ipairs(chatTypes) do
            local ev = CHAT_EVENTS[t]
            if ev then obj.frame:RegisterEvent(ev) end
        end
    else
        -- Все, кроме SYSTEM
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
    self.funcCache = {}
end

-- ============================================================================
-- РЕГИСТРАЦИЯ ТРИГГЕРОВ
-- ============================================================================
-- key — "CHATTYPE:firstword"  (например "GUILD:-кик", "ADDON:ns_ver")
-- Или "*" для catch-all
function NSQC4.ChatHandler:Register(key, trigger)
    if not key or not trigger then return end
    self.triggers[key] = self.triggers[key] or {}
    table.insert(self.triggers[key], trigger)
end

-- ============================================================================
-- ОБРАБОТКА СООБЩЕНИЙ
-- ============================================================================
function NSQC4.ChatHandler:OnChatMessage(event, ...)
    local text, sender, prefix, channel

    if event == "CHAT_MSG_ADDON" then
        prefix, text, channel, sender = ...
        if not prefix or prefix:sub(1, #self.addonPrefix) ~= self.addonPrefix then
            return
        end
    else
        text, sender = ...
        if not text or text == "" then return end
        if text:sub(1, #self.textPrefix) ~= self.textPrefix then
            if not self.triggers["*"] then return end
        end
    end

    if not text then return end

    -- Защита от text без слов (только пробелы)
    local firstWordRaw = text:match("^(%S+)")
    if not firstWordRaw then return end

    local shortType = event:match("^CHAT_MSG_(.+)$")
    local firstWord = firstWordRaw:lower()

    if self.debug then
        print("|cff00ff00[ChatHandler]|r", event, "| key=" .. shortType .. ":" .. firstWord, "| sender=" .. tostring(sender))
    end

    local key = shortType .. ":" .. firstWord

    -- 1. O(1) — прямой lookup
    local list = self.triggers[key]
    if list then
        if self:RunTriggers(list, event, text, sender, prefix, channel, shortType) then
            return
        end
    end

    -- 2. ADDON по префиксу
    if event == "CHAT_MSG_ADDON" and prefix then
        local pkey = "ADDON:" .. prefix:lower()
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
    for _, t in ipairs(list) do
        if self:CheckTrigger(t, event, text, sender, prefix, channel, shortType) then
            if t.stopOnMatch then return true end
        end
    end
    return false
end

-- ============================================================================
-- ПРОВЕРКА ОДНОГО ТРИГГЕРА
-- ============================================================================
function NSQC4.ChatHandler:CheckTrigger(t, event, text, sender, prefix, channel, shortType)
    -- 1. Тип чата
    if t.chatType then
        local found = false
        for _, ct in ipairs(t.chatType) do
            if ct == shortType then found = true; break end
        end
        if not found then return false end
    end

    -- 2. Дополнительные условия (предикаты)
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
                return false
            end
        end
    end

    -- 3. Вызов обработчика
    local func = t.func
    if type(func) == "string" then
        func = self.funcCache[func]
        if not func then
            func = _G[t.func]
            self.funcCache[t.func] = func
        end
    end

    if type(func) == "function" then
        -- Передаём words, sender, text, channel
        local words = {}
        for w in text:gmatch("%S+") do table.insert(words, w) end
        func(words, sender, text, channel, prefix)
    elseif self.debug then
        print("|cffff0000[ChatHandler]|r функция не найдена:", tostring(t.func))
    end

    return true
end

NSQC4.ChatHandler = NSQC4.ChatHandler:new({"GUILD", "ADDON"})