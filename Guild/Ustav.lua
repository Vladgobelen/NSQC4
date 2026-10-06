-- ============================================================================
-- NSQC4 / Guild / Ustav
-- Команда «-устав» — вывод пунктов устава в офицерский чат.
-- Модуль: ustav.
-- ============================================================================

NSQC4.RegisterModule("ustav", function()

    -- ========================================================================
    -- Данные
    -- ========================================================================
    local SECTIONS = NSQC4.Charter and NSQC4.Charter.SECTIONS or {}

    local sectionById = {}
    for _, s in ipairs(SECTIONS) do
        sectionById[s.id] = s
    end

    -- ========================================================================
    -- Очередь вывода (0.1с между строками)
    -- ========================================================================
    local DELAY = 0.1

    local queue = {}
    local queueFrame
    local elapsed = 0

    local function EnsureQueueFrame()
        if queueFrame then return end

        queueFrame = CreateFrame("Frame")
        queueFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed < DELAY then return end
            elapsed = 0

            local line = table.remove(queue, 1)
            if not line then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                queueFrame = nil
                return
            end

            SendChatMessage(line, "OFFICER", nil, 1)
        end)
    end

    local function EnqueueLine(line)
        table.insert(queue, line)
        EnsureQueueFrame()
    end

    local function EnqueueSection(section)
        EnqueueLine(section.id .. ". " .. section.text)
    end

    local function EnqueueAll()
        for _, s in ipairs(SECTIONS) do
            EnqueueSection(s)
        end
    end

    -- ========================================================================
    -- Обработчик
    -- ========================================================================
    local function HandleUstav(words, sender, text, channel, prefix)
        local myName = UnitName("player") or ""

        local arg1 = words[2]
        local arg2 = words[3]

        -- Без аргументов: сам игрок — весь устав
        if not arg1 then
            if sender == myName then
                EnqueueAll()
            end
            return
        end

        -- Один аргумент
        if not arg2 then
            -- Мой ник — весь устав
            if arg1 == myName then
                EnqueueAll()
                return
            end

            -- Число + я сам отправил — пункт
            if tonumber(arg1) and sender == myName then
                local section = sectionById[arg1]
                if section then
                    EnqueueSection(section)
                end
                return
            end

            return
        end

        -- Два аргумента — ник и число в любом порядке
        local num, isMine = nil, false

        if tonumber(arg1) and arg2 == myName then
            num = arg1
            isMine = true
        elseif arg1 == myName and tonumber(arg2) then
            num = arg2
            isMine = true
        end

        if not isMine then
            return
        end

        local section = sectionById[num]
        if section then
            EnqueueSection(section)
        end
    end

    NSQC4.ChatHandler:Register("GUILD:-устав", {
        func = HandleUstav,
        stopOnMatch = true,
    })

end)