-- ============================================================================
-- NSQC4 / Course / Reminder
-- Напоминалка о прохождении курса Lua.
-- Класс NSReminder + вспомогательные функции.
-- Публикуется как NSQC4.Course.NSReminder.
-- Инстанс создаётся в Course/Init.lua.
-- ============================================================================

NSQC4.RegisterModule("course", function()

    NSQC4.Course = NSQC4.Course or {}

    -- ========================================================================
    -- Сообщения напоминалки
    -- ========================================================================
    local REMINDER_MESSAGES = {
        "Твои переменные скучают по тебе...",
        "Код сам себя не напишет!",
        "Lua ждёт тебя!",
        "Таблицы плачут без тебя",
        "Принц Артас ждёт твоего кода",
        "Прокрастинируешь?",
        "Один цикл и ты уже разработчик!",
        "string.format зовёт тебя домой",
        "Кто не учит Lua — тот не гильдмастер!",
        "Ещё один модуль и ты почти программист",
        "print('С возвращением!')",
        "Шеф уже спрашивает про твой прогресс",
        "Фарм подождёт, знания — нет",
        "Метатаблицы сами себя не объяснят",
        "local ты = 'ленивец' — исправь это!",
        "Твой персонаж уже выучил бы пару заклинаний",
        "while true do print('учи Lua') end",
        "Нажми на меня, чтобы продолжить обучение",
        "Ты не забыл про курс, правда?",
        "Где-то в ГХ плачет один учитель Lua",
        "Твои навыки кодинга ржавеют",
        "Сделай перерыв от фарма — учи Lua",
        "Таблица без данных — это просто {}",
        "Ты ближе к мастерству, чем думаешь",
        "Осталось совсем немного модулей!",
        "Хватит фармить золото, фарми знания",
        "Паладин бы уже давно прошёл этот курс",
        "nil — это то, что будет от твоих навыков",
        "return 'к курсу'",
        "Твоя гильдия гордится тобой... пока",
        "Сделай for i = 1, 10 do study() end",
        "У тебя есть незаконченные дела с Lua",
        "Твой print() молчит уже час",
        "Курс не убежит, но и сам себя не пройдёт",

        -- Новые сообщения
        "Твой прогресс в курсе = nil. Исправь это!",
        "Ошибка: attempt to index 'твой прогресс' (a nil value)",
        "if not course then print('грусть') end",
        "for i = 1, #твоей_лени do stop() end",
        "string.find(твой_день, 'Lua') вернул nil",
        "table.insert(твоя_жизнь, 'Lua')",
        "GetTime() показывает: пора на курс",
        "Твой /run заржавел без практики",
        "Не будь как local-переменная — стань глобальным!",
        "'end' не закрывает твои отговорки",
        "В чате шепчут: '... снова фармит вместо Lua'",
        "Даже мурлоки уже прошли этот курс",
        "Твоя гильдия ждёт не рейд, а твой print()",
        "Если nil — это значение, то твой прогресс — его пример",
        "В Азероте нет патча против лени",
        "Открой курс, пока сервер не ушёл на рестарт",
        "Каждый пропущенный модуль — это -1 к карме",
        "print('Привет') — уже начало пути",
        "local успех = труд + Lua",
        "if ты_тут then return end -- нет, так не выйдет",
        "while not пройден_курс do учись() end",
        "ipairs(дни) ждут твоего return",
        "pairs(отговорки) — бесконечная таблица",
        "tostring(твой_уровень) всё ещё 'новичок'",
        "tonumber('0') — столько модулей ты прошёл сегодня",
        "string.format('%s, пора учиться', UnitName('player'))",
        "UnitExists('target') есть, а цели учиться — нет",
        "UnitHealth('player') в норме, курс — нет",
        "GetMoney() не купит навык программирования",
        "Не давай курсу уйти в garbage collector (хм..а что это вообще?)",
        "Твой скилл пока на уровне testNumber = 1",
        "Даже print('Hello') лучше, чем ничего",
        "Не будь багом — стань фичей",
        "Время фармить не голд, а знания",
    }

    -- ========================================================================
    -- Ассеты: пары (текстура, звук)
    -- ========================================================================
    local ASSET_PAIRS = {
        {
            texture = "Interface\\AddOns\\NSQC4\\Media\\Images\\bbb.tga",
            sound   = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\bbb.ogg",
        },
        {
            texture = "Interface\\AddOns\\NSQC4\\Media\\Images\\gob.tga",
            sound   = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\gob.ogg",
        },
        {
            texture = "Interface\\AddOns\\NSQC4\\Media\\Images\\gom.tga",
            sound   = "Interface\\AddOns\\NSQC4\\Media\\Sounds\\gom.ogg",
        },
    }

    -- ========================================================================
    -- Константы времени
    -- ========================================================================
    local MIN_REMINDER_INTERVAL = 30 * 60    -- минимум 30 минут
    local MAX_REMINDER_INTERVAL = 60 * 60    -- максимум 1 час
    local NOT_OPENED_RECHECK    = 60         -- если курс ещё ни разу не открывали
    local COMBAT_REMINDER_DELAY = 60 * 60    -- после боя не показываем напоминалку 1 час

    -- ========================================================================
    -- Константы иконки
    -- ========================================================================
    local MIN_ICON_SIZE   = 64
    local MAX_ICON_SIZE   = 256
    local POSITION_OFFSET = 400

    -- ========================================================================
    -- Вспомогательные функции
    -- ========================================================================

    local function IsPlayerInCombat()
        if InCombatLockdown and InCombatLockdown() then
            return true
        end

        if UnitAffectingCombat and UnitAffectingCombat("player") then
            return true
        end

        return false
    end

    local function Trim(s)
        return (tostring(s or ""):match("^%s*(.-)%s*$"))
    end

    -- Курс когда-либо открывался? Смотрим в новое хранилище.
    local function HasCourseEverOpened()
        local courseLogic = nsDbc4 and nsDbc4.course and nsDbc4.course.logic
        if type(courseLogic) ~= "table" then
            return false
        end

        if courseLogic.currentModule ~= nil then
            return true
        end

        if type(courseLogic.taskDetails) == "table" and next(courseLogic.taskDetails) ~= nil then
            return true
        end

        return false
    end

    -- Проверка завершённости модуля по сохранённым данным.
    -- saved — это nsDbc4.course.logic.taskDetails[index].
    local function IsModuleCompleted(module, saved)
        local mtype = Trim(module.type)

        -- Инфо-модули и модули без типа считаем пройденными.
        if mtype == "" or mtype == "info" then
            return true
        end

        if type(saved) ~= "table" then
            return false
        end

        if saved.completed == true then
            return true
        end

        if mtype == "commenttest" then
            return saved.commentTestPassed == true
        end

        if mtype == "vartest" or mtype == "printtest" or mtype == "customtest" then
            if not module.tasks or #module.tasks == 0 then
                if mtype == "vartest" and module.formatTask then
                    return saved.formatDone == true or saved.formatTaskComplete == true
                end

                return true
            end

            local allDone = true

            if type(saved.done) == "table" then
                for i in ipairs(module.tasks) do
                    if not (saved.done[i] or saved.done[tostring(i)]) then
                        allDone = false
                        break
                    end
                end
            else
                return false
            end

            if not allDone then
                return false
            end

            if mtype == "vartest" and module.formatTask then
                return saved.formatDone == true or saved.formatTaskComplete == true
            end

            return true
        end

        return true
    end

    -- Курс полностью пройден?
    local function IsCourseFinished()
        if type(ns_llua) ~= "table" or type(ns_llua['lua']) ~= "table" then
            return false
        end

        local details = nsDbc4
            and nsDbc4.course
            and nsDbc4.course.logic
            and nsDbc4.course.logic.taskDetails

        if type(details) ~= "table" then
            details = {}
        end

        local hasModules = false

        for moduleIndex, module in pairs(ns_llua['lua']) do
            if type(moduleIndex) == "number" and type(module) == "table" then
                hasModules = true

                if not IsModuleCompleted(module, details[moduleIndex]) then
                    return false
                end
            end
        end

        return hasModules
    end

    -- Открыто ли окно курса?
    local function IsCourseWindowShown()
        local courseLogic = NSQC4.Course and NSQC4.Course.logic

        if courseLogic and courseLogic.ui and type(courseLogic.ui.IsShown) == "function" then
            return courseLogic.ui:IsShown()
        end

        return false
    end

    -- Открыть курс.
    local function OpenCourse()
        if IsCourseWindowShown() then
            return
        end

        local courseLogic = NSQC4.Course and NSQC4.Course.logic

        if courseLogic and type(courseLogic.ManageCourse) == "function" then
            courseLogic:ManageCourse()
        end
    end

    -- ========================================================================
    -- Класс NSReminder
    -- ========================================================================
    local NSReminder = {}
    NSReminder.__index = NSReminder

    function NSReminder:New()
        local self = setmetatable({}, NSReminder)

        self.frame = nil
        self.icon = nil
        self.label = nil
        self.timerFrame = nil
        self.fadeFrame = nil
        self.eventFrame = nil

        self.mode = "wait"
        self.elapsed = 0
        self.nextDelay = 0

        self.lastModule = nil
        self.iconSize = MIN_ICON_SIZE
        self.suppressClick = false

        return self
    end

    function NSReminder:Init()
        if self.frame then
            return
        end

        self.frame = CreateFrame("Button", nil, UIParent)
        self.frame:SetFrameStrata("TOOLTIP")
        self.frame:SetFrameLevel(100)
        self.frame:SetSize(MIN_ICON_SIZE, MIN_ICON_SIZE)
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        self.frame:SetMovable(true)
        self.frame:EnableMouse(true)
        self.frame:SetClampedToScreen(true)
        self.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        self.frame:Hide()

        self.icon = self.frame:CreateTexture(nil, "ARTWORK")
        self.icon:SetAllPoints(self.frame)
        self.icon:SetTexture(ASSET_PAIRS[1].texture)

        self.label = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.label:SetPoint("BOTTOM", self.frame, "TOP", 0, 5)
        self.label:SetJustifyH("CENTER")
        self.label:SetWidth(400)
        self.label:SetTextColor(1, 0.84, 0, 1)
        self.label:SetShadowOffset(1, -1)
        self.label:SetShadowColor(0, 0, 0, 1)

        self.frame:SetScript("OnEnter", function(frame)
            GameTooltip:SetOwner(frame, "ANCHOR_TOP")
            GameTooltip:SetText("Напоминание о курсе Lua", 1, 0.84, 0)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFFFFFFFFЛКМ:|r Открыть курс", 1, 1, 1)
            GameTooltip:AddLine("|cFFFFFFFFПКМ:|r Скрыть или перезапустить (рандом 1 из 3)", 1, 1, 1)
            GameTooltip:AddLine("|cFFFFFFFFShift+ЛКМ или СКМ:|r Перетащить", 1, 1, 1)
            GameTooltip:Show()

            self.label:Hide()
        end)

        self.frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
            self.label:Show()
        end)

        self.frame:SetScript("OnMouseDown", function(frame, button)
            if button == "MiddleButton" then
                frame:StartMoving()
            elseif button == "LeftButton" and IsShiftKeyDown() then
                self.suppressClick = true
                frame:StartMoving()
            end
        end)

        self.frame:SetScript("OnMouseUp", function(frame, button)
            if button == "MiddleButton" or button == "LeftButton" then
                frame:StopMovingOrSizing()
            end
        end)

        self.frame:SetScript("OnClick", function(frame, button)
            if self.suppressClick then
                self.suppressClick = false
                return
            end

            if button == "LeftButton" then
                OpenCourse()
                self:Hide()
                self:ScheduleRandom()
            elseif button == "RightButton" then
                self:OnRightClick()
            end
        end)

        self.frame:SetAlpha(0)

        self.timerFrame = CreateFrame("Frame")
        self.timerFrame:Show()
        self.timerFrame:SetScript("OnUpdate", function(_, elapsed)
            self:OnUpdate(elapsed)
        end)

        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:Show()
        self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.eventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" then
                self:OnEnterCombat()
            end
        end)
    end

    function NSReminder:HideImmediate()
        if not self.frame then
            return
        end

        if self.fadeFrame then
            self.fadeFrame:SetScript("OnUpdate", nil)
            self.fadeFrame:Hide()
        end

        self.frame:StopMovingOrSizing()
        self.frame:SetAlpha(0)
        self.frame:Hide()
    end

    function NSReminder:OnUpdate(elapsed)
        if self.mode ~= "wait" then
            return
        end

        self.elapsed = self.elapsed + elapsed

        if self.elapsed < self.nextDelay then
            return
        end

        self.elapsed = 0

        if IsPlayerInCombat() then
            self:HideImmediate()
            self:ScheduleCombatCooldown()
            return
        end

        -- Если курс никогда не открывали — не показываем напоминалку.
        if not HasCourseEverOpened() then
            self:ScheduleNotOpenedRecheck()
            return
        end

        -- Если курс полностью пройден — не показываем, но тихо проверяем снова.
        if IsCourseFinished() then
            self:ScheduleRandom()
            return
        end

        -- Если окно курса сейчас открыто — не мешаем.
        if IsCourseWindowShown() then
            self:ScheduleRandom()
            return
        end

        self:Show()
    end

    function NSReminder:ScheduleRandom()
        if self.mode == "stopped" then
            return
        end

        if IsPlayerInCombat() then
            self:ScheduleCombatCooldown()
            return
        end

        self.mode = "wait"
        self.elapsed = 0
        self.nextDelay = math.random(MIN_REMINDER_INTERVAL, MAX_REMINDER_INTERVAL)

        if self.timerFrame then
            self.timerFrame:Show()
        end
    end

    function NSReminder:ScheduleNotOpenedRecheck()
        self.mode = "wait"
        self.elapsed = 0
        self.nextDelay = NOT_OPENED_RECHECK

        if self.timerFrame then
            self.timerFrame:Show()
        end
    end

    function NSReminder:Stop()
        self.mode = "stopped"

        if self.fadeFrame then
            self.fadeFrame:SetScript("OnUpdate", nil)
            self.fadeFrame:Hide()
        end

        if self.timerFrame then
            self.timerFrame:Hide()
        end

        if self.eventFrame then
            self.eventFrame:SetScript("OnEvent", nil)
            self.eventFrame:UnregisterAllEvents()
            self.eventFrame:Hide()
        end

        self:HideImmediate()
    end

    function NSReminder:Show()
        if not self.frame then
            return
        end

        if IsPlayerInCombat() then
            self:HideImmediate()
            self:ScheduleCombatCooldown()
            return
        end

        local currentModule = nsDbc4
            and nsDbc4.course
            and nsDbc4.course.logic
            and nsDbc4.course.logic.currentModule

        if self.lastModule ~= currentModule then
            self.lastModule = currentModule
            self.iconSize = MIN_ICON_SIZE
        end

        local message = REMINDER_MESSAGES[math.random(#REMINDER_MESSAGES)]
        self.label:SetText(message)

        local asset = ASSET_PAIRS[math.random(#ASSET_PAIRS)]
        self.icon:SetTexture(asset.texture)

        self.frame:SetSize(self.iconSize, self.iconSize)

        local offsetX = math.random(-POSITION_OFFSET, POSITION_OFFSET)
        local offsetY = math.random(-POSITION_OFFSET, POSITION_OFFSET)

        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)

        self.frame:Show()
        self:StartFade(self.frame:GetAlpha(), 1, 0.3)

        if PlaySoundFile then
            PlaySoundFile(asset.sound)
        end

        if self.iconSize < MAX_ICON_SIZE then
            self.iconSize = self.iconSize * 2

            if self.iconSize > MAX_ICON_SIZE then
                self.iconSize = MAX_ICON_SIZE
            end
        end

        self.mode = "shown"

        if self.timerFrame then
            self.timerFrame:Hide()
        end
    end

    function NSReminder:Hide()
        if not self.frame then
            return
        end

        if not self.frame:IsShown() then
            return
        end

        if IsPlayerInCombat() then
            self:HideImmediate()
            return
        end

        self:StartFade(self.frame:GetAlpha(), 0, 0.3)
    end

    function NSReminder:ScheduleCombatCooldown()
        if self.mode == "stopped" then
            return
        end

        self.mode = "wait"
        self.elapsed = 0
        self.nextDelay = COMBAT_REMINDER_DELAY

        if self.timerFrame then
            self.timerFrame:Show()
        end
    end

    function NSReminder:OnRightClick()
        local roll = math.random(1, 3)

        if roll == 3 then
            self:Hide()
            self:ScheduleRandom()
        else
            self:Hide()
            self:Show()
        end
    end

    function NSReminder:OnEnterCombat()
        if self.mode == "stopped" then
            return
        end

        self:HideImmediate()
        self:ScheduleCombatCooldown()
    end

    function NSReminder:StartFade(fromAlpha, toAlpha, duration)
        if self.fadeFrame then
            self.fadeFrame:SetScript("OnUpdate", nil)
            self.fadeFrame:Hide()
        end

        if not self.frame then
            return
        end

        self.fadeFrame = CreateFrame("Frame")
        self.fadeFrame:Show()

        local elapsed = 0

        self.fadeFrame:SetScript("OnUpdate", function(frame, dt)
            elapsed = elapsed + dt

            local progress = elapsed / duration

            if progress >= 1 then
                self.frame:SetAlpha(toAlpha)

                if toAlpha == 0 then
                    self.frame:Hide()
                end

                frame:SetScript("OnUpdate", nil)
                frame:Hide()
            else
                local currentAlpha = fromAlpha + (toAlpha - fromAlpha) * progress
                self.frame:SetAlpha(currentAlpha)
            end
        end)
    end

    -- ========================================================================
    -- Публикация класса
    -- ========================================================================
    NSQC4.Course.NSReminder = NSReminder
end)