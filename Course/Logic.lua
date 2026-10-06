-- ============================================================================
-- NSQC4 / Course / Logic
-- Класс Logic: проверка кода, прогресс курса, ManageCourse, обмен кодом.
-- Публикуется как NSQC4.Course.Logic.
-- Инстанс создаётся в Course/Init.lua.
-- ============================================================================

NSQC4.RegisterModule("course", function()

    NSQC4.Course = NSQC4.Course or {}

    -- ========================================================================
    -- Вспомогательные функции
    -- ========================================================================
    local function TrimString(s)
        return (tostring(s or ""):match("^%s*(.-)%s*$"))
    end

    local function NormalizeLines(s)
        s = tostring(s or "")
        s = s:gsub("\r\n", "\n")

        local lines = {}

        for line in s:gmatch("[^\n]+") do
            line = TrimString(line)
            if line ~= "" then
                table.insert(lines, line)
            end
        end

        return table.concat(lines, "\n")
    end

    local function CountSolutionChars(code)
        if code == nil then
            return 0
        end

        local s = NSQC4.Course.StripLuaComments(code)
        s = s:gsub("\r\n", "\n")

        local n = 0
        for i = 1, #s do
            local b = s:byte(i)
            if b < 128 or b >= 192 then
                n = n + 1
            end
        end

        return n
    end

    local function CompareModuleIds(a, b)
        local sa = tostring(a)
        local sb = tostring(b)

        local pa = {}
        for part in sa:gmatch("[^.]+") do
            table.insert(pa, part)
        end

        local pb = {}
        for part in sb:gmatch("[^.]+") do
            table.insert(pb, part)
        end

        local maxLen = math.max(#pa, #pb)

        for i = 1, maxLen do
            local va = pa[i]
            local vb = pb[i]

            if va == nil then
                return true
            end

            if vb == nil then
                return false
            end

            local na = tonumber(va)
            local nb = tonumber(vb)

            if na and nb then
                if na ~= nb then
                    return na < nb
                end
            else
                if va ~= vb then
                    return va < vb
                end
            end
        end

        return sa < sb
    end

    -- ========================================================================
    -- Класс Logic
    -- ========================================================================
    local Logic = {}
    Logic.__index = Logic

    function Logic:BuildOrder()
        local order = {}

        for id, module in pairs(self.db or {}) do
            if type(id) == "number" and type(module) == "table" then
                table.insert(order, id)
            end
        end

        table.sort(order, CompareModuleIds)

        self.order = order
        self.total = #order
        self.orderIndex = {}

        for i, id in ipairs(order) do
            self.orderIndex[id] = i
        end
    end

    function Logic:IsModuleSkipped(moduleId)
        local id = tonumber(moduleId)

        if not id then
            return false
        end

        if self.ui and type(self.ui.IsModuleSkipped) == "function" then
            return self.ui:IsModuleSkipped(id)
        end

        self:EnsureSaved()

        local details = nsDbc4.course.logic.taskDetails[id]

        if details == nil then
            details = nsDbc4.course.logic.taskDetails[tostring(id)]
        end

        return type(details) == "table" and details.skipped == true
    end

    function Logic:GetSkippedCount()
        if self.ui and type(self.ui.GetSkippedCount) == "function" then
            return self.ui:GetSkippedCount()
        end

        if not self.order or #self.order == 0 then
            self:BuildOrder()
        end

        local count = 0

        for _, id in ipairs(self.order or {}) do
            if self:IsModuleSkipped(id) and not self:IsModuleCompleted(id) then
                count = count + 1
            end
        end

        return count
    end

    function Logic:CanSkipModule(moduleId)
        local id = tonumber(moduleId)

        if not id then
            return false
        end

        if self:IsModuleSkipped(id) then
            return true
        end

        if self:IsModuleCompleted(id) then
            return false
        end

        return self:GetSkippedCount() < 5
    end

    function Logic:ToggleModuleSkip(editorName)
        local id = tonumber(self.current)

        if not id then
            return
        end

        editorName = editorName or "commenttest"

        local wasSkipped = self:IsModuleSkipped(id)
        local newSkipped = not wasSkipped

        if newSkipped and not self:CanSkipModule(id) then
            local message

            if self:IsModuleCompleted(id) then
                message = "Пропуск недоступен: модуль уже пройден."
            else
                message = "Нельзя пропустить: уже пропущено 5 модулей."
            end

            if self.ui and type(self.ui.SetEditorResult) == "function" then
                self.ui:SetEditorResult(editorName, {
                    status = "error",
                    message = message,
                })
            end

            return
        end

        if self.ui and type(self.ui.SetModuleSkipped) == "function" then
            self.ui:SetModuleSkipped(id, newSkipped)
        else
            self:EnsureSaved()

            nsDbc4.course.logic.taskDetails[id] = nsDbc4.course.logic.taskDetails[id] or {}
            nsDbc4.course.logic.taskDetails[id].skipped = newSkipped
        end

        if self.ui and type(self.ui.RefreshSidePanel) == "function" then
            self.ui:RefreshSidePanel()
        end

        if self.ui and type(self.ui.SetEditorSkipButtonState) == "function" then
            local enabled = newSkipped or not self:IsModuleCompleted(id)
            self.ui:SetEditorSkipButtonState(editorName, newSkipped, enabled)
        end

        if self.ui and type(self.ui.SetNextEnabled) == "function" then
            local m = self.db and self.db[id] or {}
            local mtype = TrimString(m.type)
            local nextEnabled = true

            if mtype == "commenttest" then
                nextEnabled = (self.commentTestPassed == true) or newSkipped
            elseif mtype == "vartest" or mtype == "customtest" or mtype == "printtest" then
                nextEnabled = newSkipped or self.allDone == true
            end

            self.ui:SetNextEnabled(nextEnabled)
        end
    end

    function Logic:FindModuleIndex(moduleId)
        local id = tonumber(moduleId)

        if id == nil then
            return nil
        end

        if self.orderIndex and self.orderIndex[id] then
            return self.orderIndex[id]
        end

        return nil
    end

    function Logic:EnsureSaved()
        nsDbc4.course.logic = nsDbc4.course.logic or {}
        nsDbc4.course.logic.currentModule = nsDbc4.course.logic.currentModule or 1
        nsDbc4.course.logic.taskDetails = nsDbc4.course.logic.taskDetails or {}
    end

    function Logic:SaveModuleProgress()
        self:EnsureSaved()

        local n = self.current

        nsDbc4.course.logic.taskDetails[n] = nsDbc4.course.logic.taskDetails[n] or {}

        local done = {}

        if self.done then
            for i, v in pairs(self.done) do
                done[i] = v
            end
        end

        nsDbc4.course.logic.taskDetails[n].done = done
        nsDbc4.course.logic.taskDetails[n].formatDone = self.formatDone == true

        if self.allDone == true and nsDbc4.course.logic.taskDetails[n].skipped == true then
            nsDbc4.course.logic.taskDetails[n].skipped = false

            if self.ui and type(self.ui.SetModuleSkipped) == "function" then
                self.ui:SetModuleSkipped(n, false)
            end
        end
    end

    function Logic:IsInfoModule(moduleOrType)
        local mtype = moduleOrType

        if type(moduleOrType) == "table" then
            mtype = moduleOrType.type
        end

        mtype = TrimString(mtype)

        return mtype ~= "vartest"
            and mtype ~= "printtest"
            and mtype ~= "customtest"
            and mtype ~= "commenttest"
    end

    function Logic:MarkInfoRead(moduleId)
        local id = tonumber(moduleId) or moduleId
        local m = self.db and self.db[id]

        if type(m) ~= "table" then
            return
        end

        if not self:IsInfoModule(m) then
            return
        end

        self:EnsureSaved()

        nsDbc4.course.logic.taskDetails[id] = nsDbc4.course.logic.taskDetails[id] or {}

        if nsDbc4.course.logic.taskDetails[id].read ~= true then
            nsDbc4.course.logic.taskDetails[id].read = true

            if self.ui and self.ui.RefreshSidePanel then
                self.ui:RefreshSidePanel()
            end
        end
    end

    function Logic:IsModuleCompleted(moduleId)
        local id = tonumber(moduleId)

        if not id then
            return false
        end

        local m = self.db and self.db[id]

        if type(m) ~= "table" then
            return false
        end

        local mtype = TrimString(m.type)

        self:EnsureSaved()

        local details = nsDbc4.course.logic.taskDetails[id]

        if details == nil then
            details = nsDbc4.course.logic.taskDetails[tostring(id)]
        end

        details = type(details) == "table" and details or {}

        if id == self.current then
            if mtype == "commenttest" then
                return self.commentTestPassed == true
            end

            if mtype == "vartest" or mtype == "customtest" or mtype == "printtest" then
                if type(m.tasks) == "table" then
                    self.done = self.done or {}

                    for i in ipairs(m.tasks) do
                        if not self.done[i] then
                            return false
                        end
                    end
                else
                    if not (self.allDone == true or details.completed == true) then
                        return false
                    end
                end

                if mtype == "vartest" and m.formatTask then
                    return self.formatDone == true
                end

                return true
            end

            return details.read == true or details.completed == true
        end

        if mtype == "commenttest" then
            return details.completed == true or details.commentTestPassed == true
        end

        if mtype == "vartest" or mtype == "customtest" or mtype == "printtest" then
            if type(m.tasks) == "table" then
                for i in ipairs(m.tasks) do
                    local done = details.done and (details.done[i] or details.done[tostring(i)])

                    if not done then
                        return false
                    end
                end
            else
                if details.completed ~= true then
                    return false
                end
            end

            if mtype == "vartest" and m.formatTask then
                if details.formatDone ~= true then
                    return false
                end
            end

            return true
        end

        return details.read == true or details.completed == true
    end

    function Logic:SaveCommentTest(code, passed)
        self:EnsureSaved()

        local n = self.current

        nsDbc4.course.logic.taskDetails[n] = nsDbc4.course.logic.taskDetails[n] or {}
        nsDbc4.course.logic.taskDetails[n].currentCode = code

        if passed ~= nil then
            nsDbc4.course.logic.taskDetails[n].commentTestPassed = passed == true
            nsDbc4.course.logic.taskDetails[n].completed = passed == true
        end

        local passedNow = self.commentTestPassed == true

        if passed ~= nil then
            passedNow = passed == true
        end

        if passedNow then
            if nsDbc4.course.logic.taskDetails[n].skipped == true then
                nsDbc4.course.logic.taskDetails[n].skipped = false

                if self.ui and type(self.ui.SetModuleSkipped) == "function" then
                    self.ui:SetModuleSkipped(n, false)
                end
            end

            if self.ui and type(self.ui.SetEditorSkipButtonState) == "function" then
                self.ui:SetEditorSkipButtonState("commenttest", false, false)
            end
        end

        if self.ui and self.ui.RefreshSidePanel then
            self.ui:RefreshSidePanel()
        end
    end

    function Logic:InstallRunScript()
        if self._runScriptInstalled then
            return
        end

        self._runScriptInstalled = true

        local function resetIfModuleChanged()
            if self.runtimeModule ~= self.current then
                self.runtimeModule = self.current
                self.lastExecutedCode = nil
                self.lastPrintMessage = nil
                self.pendingConcatCount = nil
                self.insideRunScript = false
            end
        end

        self._originalPrint = _G.NSQC4_OriginalPrint or print
        _G.NSQC4_OriginalPrint = self._originalPrint

        print = function(...)
            resetIfModuleChanged()

            local parts = {}

            for i = 1, select("#", ...) do
                local value = select(i, ...)
                parts[i] = tostring(value)
            end

            self.lastPrintMessage = table.concat(parts, "\t")

            if not self.insideRunScript then
                self.lastExecutedCode = nil
                self.pendingConcatCount = nil
            end

            local result = self._originalPrint(...)

            self:CheckPrintTasks()

            return result
        end

        self._originalRunScript = _G.NSQC4_OriginalRunScript or RunScript
        _G.NSQC4_OriginalRunScript = self._originalRunScript

        if type(self._originalRunScript) == "function" then
            RunScript = function(code)
                resetIfModuleChanged()

                code = tostring(code or "")

                self.lastExecutedCode = code

                local concatCount = 0

                for _ in code:gmatch("%.%.") do
                    concatCount = concatCount + 1
                end

                self.pendingConcatCount = concatCount > 0 and concatCount or nil
                self.lastPrintMessage = nil
                self.insideRunScript = true

                local result = self._originalRunScript(code)

                self.insideRunScript = false

                return result
            end
        end
    end

    function Logic:IsCodeLineLengthValid(code)
        if code == nil then
            return true
        end

        local s = tostring(code)
        s = s:gsub("\r\n", "\n"):gsub("\r", "\n")

        for line in (s .. "\n"):gmatch("(.-)\n") do
            if CountSolutionChars(line) > 200 then
                return false
            end
        end

        return true
    end

    function Logic:SendCodeLines(code)
        if type(SendAddonMessage) ~= "function" then
            return false
        end

        if not self:IsCodeLineLengthValid(code) then
            return false
        end

        local s = tostring(code or "")
        s = s:gsub("\r\n", "\n"):gsub("\r", "\n")

        local prefix = string.format("nsCode %s", tostring(self.current or 0))

        for line in s:gmatch("[^\n]+") do
            if line:match("^%s*$") == nil then
                SendAddonMessage(prefix, line, "GUILD")
            end
        end

        SendAddonMessage(prefix, "__NS_CODE_END__", "GUILD")

        return true
    end

    function Logic:RequestOtherResults(editorName)
        local m = self.db and self.db[self.current]

        if not m then
            return
        end

        local mtype = TrimString(m.type)

        if mtype ~= "commenttest" then
            return
        end

        if self.commentTestPassed ~= true then
            if self.ui and self.ui.SetEditorResultsButtonEnabled then
                self.ui:SetEditorResultsButtonEnabled(editorName or "commenttest", false)
            end

            return
        end

        local moduleId = self.current

        nsCodeViewerData = nsCodeViewerData or {}
        nsCodeViewerRequest = nsCodeViewerRequest or {}

        nsCodeViewerData[moduleId] = {}
        nsCodeViewerRequest[moduleId] = {
            requester = (type(UnitName) == "function") and UnitName("player") or "",
            time = (type(GetTime) == "function") and GetTime() or 0,
        }

        if type(SendAddonMessage) == "function" then
            SendAddonMessage("nsGetCode", tostring(moduleId), "GUILD")
        end

        if self.ui and self.ui.ShowCodeViewer then
            self.ui:ShowCodeViewer(moduleId)
        end
    end

    function Logic:SendWinMessage(code)
        if type(SendAddonMessage) ~= "function" then
            return
        end

        if not self:IsCodeLineLengthValid(code) then
            return
        end

        local chars = CountSolutionChars(code)
        local payload = tostring(self.current or 0) .. ":" .. tostring(chars)

        SendAddonMessage("ns_Win", payload, "GUILD")

        self:SendCodeLines(code)

        local m = self.db and self.db[self.current]

        if m and TrimString(m.type) == "commenttest" then
            if self.ui and self.ui.SetEditorResultsButtonEnabled then
                self.ui:SetEditorResultsButtonEnabled("commenttest", true)
            end
        end
    end

    function Logic:CheckPrintTasks()
        local m = self.db and self.db[self.current]

        if not m then
            return
        end

        if TrimString(m.type) ~= "printtest" then
            return
        end

        if not m.tasks then
            return
        end

        self.done = self.done or {}

        local msg = self.lastPrintMessage

        if not msg then
            return
        end

        local function normText(s)
            return tostring(s or ""):gsub("%s+", "")
        end

        local function normCode(s)
            s = tostring(s or "")

            s = s:gsub("%-%-%[%[.-%]%]", "")
            s = s:gsub("%-%-[^\n]*", "")

            s = s:gsub("%s+", "")
            s = s:gsub(";+$", "")

            return s
        end

        local changed = false

        for i, task in ipairs(m.tasks) do
            if not self.done[i] then
                local outputOk = true

                if task.pattern then
                    outputOk = normText(msg) == normText(task.pattern)
                end

                local codeOk = true
                local code = normCode(self.lastExecutedCode or "")

                if task.expectedExpression then
                    codeOk = false

                    if self.lastExecutedCode then
                        if type(task.expectedExpression) == "table" then
                            for _, expr in ipairs(task.expectedExpression) do
                                if code == normCode(expr) then
                                    codeOk = true
                                    break
                                end
                            end
                        else
                            codeOk = code == normCode(task.expectedExpression)
                        end
                    end
                end

                if task.requireKeywords then
                    for _, keyword in ipairs(task.requireKeywords) do
                        local cleanKeyword = tostring(keyword):gsub("%s+", "")

                        if cleanKeyword ~= "" and not code:find(cleanKeyword, 1, true) then
                            codeOk = false
                            break
                        end
                    end
                end

                if codeOk and task.forbidKeywords then
                    for _, keyword in ipairs(task.forbidKeywords) do
                        local cleanKeyword = tostring(keyword):gsub("%s+", "")

                        if cleanKeyword ~= "" and code:find(cleanKeyword, 1, true) then
                            codeOk = false
                            break
                        end
                    end
                end

                local concatOk = true

                if task.requireConcat then
                    concatOk = (self.pendingConcatCount or 0) >= (tonumber(task.requiredConcatCount) or 0)
                end

                if outputOk and codeOk and concatOk then
                    self.done[i] = true
                    changed = true

                    if PlaySoundFile then
                        PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\punto.ogg")
                    end
                end

                break
            end
        end

        if not changed then
            return
        end

        local all = true

        for i in ipairs(m.tasks) do
            if not self.done[i] then
                all = false
                break
            end
        end

        self.allDone = all

        self:SaveModuleProgress()
        self:SendModuleToUI()

        if all then
            if PlaySoundFile then
                PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\fin.ogg")
            end

            self:SendWinMessage(self.lastExecutedCode)
        end
    end

    function Logic:new(ui, modules)
        local self = setmetatable({}, Logic)

        self.ui = ui
        self.db = modules or {}
        self.order = {}
        self.orderIndex = {}

        self:BuildOrder()

        self.current = self.order[1] or 1
        self.currentIndex = self.orderIndex[self.current] or 1
        self.total = self.total or 0

        self.done = {}
        self.formatDone = false
        self.timer = nil
        self.nilSeen = {}
        self.allDone = false
        self.commentTestPassed = false

        self.lastExecutedCode = nil
        self.lastPrintMessage = nil
        self.pendingConcatCount = nil
        self.insideRunScript = false
        self.runtimeModule = nil

        self.ui:SetCallbacks({
            onNext = function()
                self:MarkInfoRead(self.current)
                self:ManageCourse("next")
            end,

            onPrev = function()
                self:ManageCourse("prev")
            end,

            onHelp = function(helpModules)
                self.ui:ShowHelp(helpModules)
            end,

            onExecute = function(editorName, code)
                self:CheckCode(editorName, code)
            end,

            onSelectModule = function(index)
                self:ManageCourse(index)
            end,

            onShowResults = function(editorName)
                self:RequestOtherResults(editorName)
            end,

            onToggleSkip = function(editorName)
                self:ToggleModuleSkip(editorName)
            end,

            isModuleCompleted = function(index)
                return self:IsModuleCompleted(index)
            end,
        })

        self:InstallRunScript()

        return self
    end

    function Logic:ManageCourse(signal)
        self:BuildOrder()

        if self.total == 0 then
            return
        end

        self:EnsureSaved()

        if signal == "next" or signal == "prev" then
            local idx = self:FindModuleIndex(nsDbc4.course.logic.currentModule)
                or self:FindModuleIndex(self.current)

            if idx then
                if signal == "next" then
                    idx = idx + 1

                    if idx > self.total then
                        idx = self.total
                    end
                else
                    idx = idx - 1

                    if idx < 1 then
                        idx = 1
                    end
                end
            else
                idx = 1
            end

            self.current = self.order[idx]
        else
            local desired = tonumber(signal)

            if desired == nil then
                desired = tonumber(nsDbc4.course.logic.currentModule)
            end

            local idx = self:FindModuleIndex(desired)

            if not idx then
                idx = 1
            end

            self.current = self.order[idx]
        end

        self.currentIndex = self:FindModuleIndex(self.current) or 1
        nsDbc4.course.logic.currentModule = self.current

        self.runtimeModule = self.current
        self.lastExecutedCode = nil
        self.lastPrintMessage = nil
        self.pendingConcatCount = nil
        self.insideRunScript = false

        if self.timer then
            if self.timer.Hide then
                self.timer:Hide()
            end

            if self.timer.Cancel then
                self.timer:Cancel()
            end

            self.timer = nil
        end

        self.allDone = false
        self.nilSeen = {}
        self.commentTestPassed = false

        local m = self.db[self.current]
        local saved = nsDbc4.course.logic.taskDetails[self.current]

        self.done = {}
        self.formatDone = false

        if m and saved then
            if m.tasks and type(saved.done) == "table" then
                for i in ipairs(m.tasks) do
                    if saved.done[i] or saved.done[tostring(i)] then
                        self.done[i] = true
                    end
                end
            end

            self.formatDone = saved.formatDone == true
            self.commentTestPassed = saved.commentTestPassed == true
        end

        if m and m.preloadVars then
            for _, v in ipairs(m.preloadVars) do
                local var = TrimString(v.var)

                if var ~= "" then
                    _G[var] = v.value
                end
            end
        end

        if m and m.tasks then
            for i, task in ipairs(m.tasks) do
                local var = TrimString(task.var)
                local taskType = TrimString(task.type)

                if taskType == "nil"
                    and var ~= ""
                    and not self.done[i]
                    and _G[var] == nil then
                    _G[var] = true
                end
            end
        end

        self:SendModuleToUI()

        local mtype = TrimString(m and m.type)

        if m and (mtype == "vartest" or mtype == "customtest") and m.tasks then
            local f = CreateFrame("Frame", nil, UIParent)
            local t = 0

            f:SetScript("OnUpdate", function(_, dt)
                t = t + dt

                if t >= 0.5 then
                    t = 0
                    self:CheckVars()
                end
            end)

            self.timer = f
            self:CheckVars()
        end

        self.ui:Show()
    end

    function Logic:SendModuleToUI()
        local n = self.current or 1
        local m = self.db and self.db[n]

        if not m then
            return
        end

        self:EnsureSaved()

        self.done = self.done or {}
        self.formatDone = self.formatDone or false

        local mtype = TrimString(m.type)
        local skipped = self:IsModuleSkipped(n)

        local practice = mtype == "vartest"
            or mtype == "printtest"
            or mtype == "customtest"

        local raw = m.content or ""

        if practice and raw == "" then
            raw = "<h>" .. (m.title or "Практика") .. "</h>"
        end

        if practice then
            if m.preloadVars then
                for _, v in ipairs(m.preloadVars) do
                    local var = TrimString(v.var)
                    local info = TrimString(v.desc or var)

                    if var ~= "" and not info:find("<k>", 1, true) then
                        info = info:gsub(var, "<k>" .. var .. "</k>")
                    end

                    raw = raw .. "\n<c>[i] " .. info .. "</c>"
                end
            end

            if m.tasks then
                for i, task in ipairs(m.tasks) do
                    local var = TrimString(task.var)
                    local desc = TrimString(task.desc or var or ("Задание " .. i))

                    if var ~= "" and not desc:find("<k>", 1, true) then
                        desc = desc:gsub(var, "<k>" .. var .. "</k>")
                    end

                    if self.done[i] then
                        raw = raw .. "\n<ok>[x] " .. desc .. "</ok>"
                    else
                        raw = raw .. "\n<t>[ ] " .. desc .. "</t>"
                    end
                end
            end

            if m.formatTask then
                local desc = TrimString(m.formatTask.instruction or "")

                raw = raw .. "\n<h>Задание на форматирование</h>\n"

                if self.formatDone then
                    raw = raw .. "<ok>[x] " .. desc .. "</ok>"
                else
                    raw = raw .. "<t>[ ] " .. desc .. "</t>"
                end
            end
        end

        local nextEnabled = true

        if mtype == "vartest" or mtype == "customtest" or mtype == "printtest" then
            if m.tasks then
                for i in ipairs(m.tasks) do
                    if not self.done[i] then
                        nextEnabled = false
                        break
                    end
                end
            end

            if mtype == "vartest" and m.formatTask then
                nextEnabled = nextEnabled and self.formatDone == true
            end

            if skipped then
                nextEnabled = true
            end
        end

        if mtype == "commenttest" then
            nextEnabled = (self.commentTestPassed == true) or skipped
        end

        local currentIndex = self.currentIndex or 1

        if self.FindModuleIndex then
            currentIndex = self:FindModuleIndex(n) or currentIndex
        end

        local data = {
            title = m.title or "",
            index = n,
            position = currentIndex,
            total = self.total or 0,
            prevEnabled = currentIndex > 1,
            nextEnabled = nextEnabled,
            helpModules = m.helpModules,
            moduleType = m.type,
        }

        if mtype == "commenttest" then
            local saved = nsDbc4.course.logic.taskDetails[n]
            local code = (saved and saved.currentCode) or m.initialCode or ""

            if type(code) ~= "string" then
                code = tostring(code)
            end

            local blocks = {}

            for _, block in ipairs(NSQC4.Course.parseContent(m.instruction or "")) do
                table.insert(blocks, block)
            end

            table.insert(blocks, {
                type = "editor",
                name = "commenttest",
                buttonText = "Проверить",
                code = code,
                resultsEnabled = self.commentTestPassed == true,
                skipped = skipped,
                skipEnabled = skipped or not self:IsModuleCompleted(n),
            })

            data.blocks = blocks
        else
            data.rawContent = raw
        end

        self.ui:SetModuleContent(data)

        if mtype == "commenttest" then
            if self.ui and type(self.ui.SetEditorButtonEnabled) == "function" then
                self.ui:SetEditorButtonEnabled("commenttest", true)
            end

            if self.ui and type(self.ui.SetEditorResultsButtonEnabled) == "function" then
                self.ui:SetEditorResultsButtonEnabled(
                    "commenttest",
                    self.commentTestPassed == true
                )
            end

            if self.ui and type(self.ui.SetEditorSkipButtonState) == "function" then
                self.ui:SetEditorSkipButtonState(
                    "commenttest",
                    skipped,
                    skipped or not self:IsModuleCompleted(n)
                )
            end
        end
    end

    local function CheckCodeKeywords(code, requireKeywords, onlyKeywords, singleLine)
        code = tostring(code or "")

        local noComments = code:gsub("%-%-%[%[.-%]%]", "")
        noComments = noComments:gsub("%-%-[^\n]*", "")

        local cleanCode = noComments:gsub("%s+", ""):gsub(";+$", "")

        if singleLine then
            local lines = 0

            for line in noComments:gmatch("[^\r\n]+") do
                if line:match("%S") then
                    lines = lines + 1
                end
            end

            if lines > 1 then
                return false, "Можно использовать только одну строку кода."
            end

            if cleanCode:find(";", 1, true) then
                return false, "Нельзя использовать несколько команд через точку с запятой."
            end
        end

        for _, keyword in ipairs(requireKeywords or {}) do
            local cleanKeyword = tostring(keyword):gsub("%s+", "")

            if cleanKeyword ~= "" and not cleanCode:find(cleanKeyword, 1, true) then
                return false, "В коде не хватает обязательного слова: " .. cleanKeyword
            end
        end

        if onlyKeywords then
            local tokens = {}

            for _, keyword in ipairs(requireKeywords or {}) do
                local cleanKeyword = tostring(keyword):gsub("%s+", "")

                if cleanKeyword ~= "" then
                    table.insert(tokens, cleanKeyword)
                end
            end

            table.sort(tokens, function(a, b)
                return #a > #b
            end)

            local check = cleanCode

            for _, token in ipairs(tokens) do
                local escaped = token:gsub("([^%w])", "%%%1")
                check = check:gsub(escaped, "")
            end

            if check ~= "" then
                return false, "Можно использовать только указанные слова и символы."
            end        end

        return true
    end

    function Logic:CheckVars()
        self.done = self.done or {}
        self.nilSeen = self.nilSeen or {}

        local m = self.db and self.db[self.current]
        if not m then
            return
        end

        local mtype = TrimString(m.type)
        if mtype ~= "vartest" and mtype ~= "customtest" then
            return
        end

        if not m.tasks then
            return
        end

        local changed = false

        for i, task in ipairs(m.tasks) do
            local var = TrimString(task.var)
            local taskType = TrimString(task.type)

            local value = nil
            if var ~= "" then
                value = _G[var]
            end

            local ok = false

            if task.check then
                local success, result = pcall(task.check, value)
                ok = success and result
            elseif taskType == "nil" then
                if var ~= "" and value ~= nil then
                    self.nilSeen[var] = true
                end

                ok = var ~= ""
                    and self.nilSeen[var] == true
                    and type(value) == "nil"
            elseif taskType ~= "" then
                ok = type(value) == taskType
            end

            if ok and not self.done[i] then
                self.done[i] = true
                changed = true

                if PlaySoundFile then
                    PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\punto.ogg")
                end
            end
        end

        local allTasks = true
        for i in ipairs(m.tasks) do
            if not self.done[i] then
                allTasks = false
                break
            end
        end

        if mtype == "vartest" and m.formatTask and allTasks and not self.formatDone then
            local msg = self.lastPrintMessage
            local code = self.lastExecutedCode

            if msg and code then
                local function normLine(s)
                    return tostring(s or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
                end

                local outputOk = normLine(msg) == normLine(m.formatTask.pattern)

                local codeOk = true

                if m.formatTask.requireKeywords
                    or m.formatTask.onlyCodePatterns
                    or m.formatTask.onlyKeywords
                    or m.formatTask.singleLine then
                    codeOk = CheckCodeKeywords(
                        code,
                        m.formatTask.requireKeywords,
                        m.formatTask.onlyCodePatterns or m.formatTask.onlyKeywords,
                        m.formatTask.singleLine
                    )
                end

                if outputOk and codeOk then
                    self.formatDone = true
                    changed = true

                    if PlaySoundFile then
                        PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\punto.ogg")
                    end
                end
            end
        end

        local all = allTasks
        if mtype == "vartest" and m.formatTask then
            all = all and self.formatDone == true
        end

        local wasAllDone = self.allDone == true

        if all then
            self.allDone = true

            if self.timer then
                if self.timer.Hide then
                    self.timer:Hide()
                end

                if self.timer.Cancel then
                    self.timer:Cancel()
                end

                self.timer = nil
            end
        else
            self.allDone = false
        end

        if changed then
            self:SaveModuleProgress()
            self:SendModuleToUI()

            if all and not wasAllDone and mtype == "vartest" then
                if PlaySoundFile then
                    PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\fin.ogg")
                end

                self:SendWinMessage(self.lastExecutedCode)
            end
        end
    end

    function Logic:CheckCode(editorName, code)
        local function Trim(s)
            return (tostring(s or ""):match("^%s*(.-)%s*$"))
        end

        local function Normalize(s)
            s = tostring(s or ""):gsub("\r\n", "\n")

            local lines = {}

            for line in s:gmatch("[^\n]+") do
                line = Trim(line)

                if line ~= "" then
                    table.insert(lines, line)
                end
            end

            return table.concat(lines, "\n")
        end

        local m = self.db and self.db[self.current]
        local mtype = Trim(m and m.type)

        if not m or mtype ~= "commenttest" then
            return
        end

        editorName = editorName or "commenttest"
        code = code or ""

        local alreadyPassed = self.commentTestPassed == true

        local function RefreshEditorButtons()
            if self.ui and type(self.ui.SetEditorButtonEnabled) == "function" then
                self.ui:SetEditorButtonEnabled(editorName, true)
            end

            if self.ui and type(self.ui.SetEditorResultsButtonEnabled) == "function" then
                self.ui:SetEditorResultsButtonEnabled(editorName, self.commentTestPassed == true)
            end
        end

        local function ApplyFailState()
            if alreadyPassed then
                self.commentTestPassed = true
                self:SaveCommentTest(code, nil)

                if self.ui and self.ui.SetNextEnabled then
                    self.ui:SetNextEnabled(true)
                end
            else
                self.commentTestPassed = false
                self:SaveCommentTest(code, false)

                if self.ui and self.ui.SetNextEnabled then
                    self.ui:SetNextEnabled(false)
                end
            end

            RefreshEditorButtons()
        end

        if type(self.IsCodeLineLengthValid) == "function" and not self:IsCodeLineLengthValid(code) then
            ApplyFailState()

            self.ui:SetEditorResult(editorName, {
                status = "diff",
                message = "Код не принят: есть строки длиннее 200 символов.",
                expected = m.expectedCode or m.expectedOutput or "",
                current = code,
            })

            return
        end

        if m.preloadVars then
            for _, v in ipairs(m.preloadVars) do
                local var = Trim(v.var)

                if var ~= "" then
                    _G[var] = v.value
                end
            end
        end

        if m.requireKeywords or m.onlyCodePatterns or m.onlyKeywords or m.singleLine then
            local keywordOk, keywordErr = CheckCodeKeywords(
                code,
                m.requireKeywords,
                m.onlyCodePatterns or m.onlyKeywords,
                m.singleLine
            )

            if not keywordOk then
                ApplyFailState()

                self.ui:SetEditorResult(editorName, {
                    status = "diff",
                    message = keywordErr or "Неверный код.",
                    expected = m.expectedCode or m.expectedOutput or "",
                    current = code,
                })

                return
            end
        end

        local keywords = {
            ["and"] = true,
            ["break"] = true,
            ["do"] = true,
            ["else"] = true,
            ["elseif"] = true,
            ["end"] = true,
            ["false"] = true,
            ["for"] = true,
            ["function"] = true,
            ["if"] = true,
            ["in"] = true,
            ["local"] = true,
            ["nil"] = true,
            ["not"] = true,
            ["or"] = true,
            ["repeat"] = true,
            ["return"] = true,
            ["then"] = true,
            ["true"] = true,
            ["until"] = true,
            ["while"] = true,
            ["print"] = true,
            ["string"] = true,
            ["table"] = true,
            ["math"] = true,
            ["pairs"] = true,
            ["ipairs"] = true,
            ["type"] = true,
            ["tostring"] = true,
            ["tonumber"] = true,
            ["select"] = true,
            ["unpack"] = true,
            ["pcall"] = true,
            ["loadstring"] = true,
        }

        local function FormatValue(value, depth)
            depth = depth or 0

            local valueType = type(value)

            if valueType == "string" then
                return '"' .. value .. '"'
            elseif valueType == "number" then
                return tostring(value)
            elseif valueType == "boolean" then
                return tostring(value)
            elseif valueType == "nil" then
                return "nil"
            elseif valueType == "table" then
                if depth >= 1 then
                    return "{...}"
                end

                local parts = {}
                local arraySize = #value

                if arraySize > 0 then
                    local maxSize = math.min(arraySize, 5)

                    for i = 1, maxSize do
                        table.insert(parts, FormatValue(value[i], depth + 1))
                    end

                    if arraySize > 5 then
                        table.insert(parts, "...")
                    end

                    return "{" .. table.concat(parts, ", ") .. "}"
                end

                local count = 0

                for k, v in pairs(value) do
                    count = count + 1

                    if count > 5 then
                        table.insert(parts, "...")
                        break
                    end

                    table.insert(parts, tostring(k) .. "=" .. FormatValue(v, depth + 1))
                end

                if count == 0 then
                    return "{}"
                end

                return "{" .. table.concat(parts, ", ") .. "}"
            end

            return "<" .. valueType .. ">"
        end

        local iterationLines = {}
        local iterationCount = 0
        local traceOverflow = false
        local MAX_TRACE_LINES = 100

        local oldTraceLoop = _G.__ns_trace_loop
        local oldTraceWhile = _G.__ns_trace_while

        local function AddIterationLine(line)
            if #iterationLines < MAX_TRACE_LINES then
                table.insert(iterationLines, line)
            elseif not traceOverflow then
                traceOverflow = true
                table.insert(iterationLines, "...")
            end
        end

        _G.__ns_trace_loop = function(label, ...)
            iterationCount = iterationCount + 1

            local argCount = select("#", ...)

            if argCount == 0 then
                AddIterationLine("Итерация " .. iterationCount .. ": " .. tostring(label))
                return
            end

            local parts = {}

            for i = 1, argCount do
                parts[i] = FormatValue(select(i, ...))
            end

            AddIterationLine(
                "Итерация " .. iterationCount .. ": " .. tostring(label) .. " = " .. table.concat(parts, ", ")
            )
        end

        _G.__ns_trace_while = function(condText, vars)
            iterationCount = iterationCount + 1

            local parts = {}

            if type(vars) == "table" then
                local keys = {}

                for k in pairs(vars) do
                    table.insert(keys, k)
                end

                table.sort(keys)

                for _, k in ipairs(keys) do
                    if type(vars[k]) ~= "function" then
                        table.insert(parts, tostring(k) .. " = " .. FormatValue(vars[k]))
                    end
                end
            end

            if #parts > 0 then
                AddIterationLine(
                    "Итерация " .. iterationCount .. ": while " .. tostring(condText) .. " | " .. table.concat(parts, ", ")
                )
            else
                AddIterationLine("Итерация " .. iterationCount .. ": while " .. tostring(condText))
            end
        end

        local function InstrumentCode(source)
            local out = {}

            for line in source:gmatch("[^\r\n]+") do
                table.insert(out, line)

                local indent = line:match("^%s*") or ""
                local header = Trim(line)
                header = Trim((header:gsub("%-%-.*$", "")))

                if header ~= "" then
                    local vars = header:match("^for%s+(.-)%s+in%s+.-%s+do%s*$")

                    if vars then
                        local args = vars:gsub("%s+", "")

                        table.insert(
                            out,
                            indent .. "    __ns_trace_loop(" .. string.format("%q", args) .. ", " .. args .. ")"
                        )
                    else
                        local numVar = header:match("^for%s+(%w+)%s*=%s*.-do%s*$")

                        if numVar then
                            table.insert(
                                out,
                                indent .. "    __ns_trace_loop(" .. string.format("%q", numVar) .. ", " .. numVar .. ")"
                            )
                        else
                            local cond = header:match("^while%s+(.-)%s+do%s*$")

                            if cond then
                                local names = {}
                                local seen = {}

                                for word in cond:gmatch("[%a_][%w_]*") do
                                    if not keywords[word] and not seen[word] then
                                        seen[word] = true
                                        table.insert(names, word)
                                    end
                                end

                                local varParts = {}

                                for _, word in ipairs(names) do
                                    table.insert(varParts, word .. " = " .. word)
                                end

                                table.insert(
                                    out,
                                    indent .. "    __ns_trace_while("
                                    .. string.format("%q", cond)
                                    .. ", {" .. table.concat(varParts, ", ") .. "})"
                                )
                            end
                        end
                    end
                end
            end

            return table.concat(out, "\n")
        end

        local env = nil

        if type(m.mockGlobals) == "table" then
            env = setmetatable({}, {__index = _G})

            for name, fn in pairs(m.mockGlobals) do
                env[name] = fn
            end
        end

        local function ExecuteSource(source, useEnv)
            local output = {}

            local oldPrint = print

            if useEnv and env then
                env.print = function(...)
                    local parts = {}

                    for i = 1, select("#", ...) do
                        parts[i] = tostring(select(i, ...))
                    end

                    table.insert(output, table.concat(parts, " "))
                end
            else
                print = function(...)
                    local parts = {}

                    for i = 1, select("#", ...) do
                        parts[i] = tostring(select(i, ...))
                    end

                    table.insert(output, table.concat(parts, " "))
                end
            end

            local fn, compileErr

            if type(loadstring) == "function" then
                fn, compileErr = loadstring(source)
            else
                compileErr = "loadstring недоступен"
            end

            local ok, runErr = false, nil

            if fn then
                if useEnv and env and setfenv then
                    setfenv(fn, env)
                end

                ok, runErr = pcall(fn)
            else
                runErr = compileErr
            end

            if not useEnv then
                print = oldPrint
            end

            return ok, runErr, table.concat(output, "\n")
        end

        local candidateOrder = {}
        local candidateSeen = {}

        local function AddCandidate(name)
            name = Trim(name)

            if name == "" then
                return
            end

            if candidateSeen[name] then
                return
            end

            if keywords[name] then
                return
            end

            if not name:match("^[%a_][%w_]*$") then
                return
            end

            candidateSeen[name] = true
            table.insert(candidateOrder, name)
        end

        if type(m.reportVars) == "table" then
            for _, name in ipairs(m.reportVars) do
                AddCandidate(name)
            end
        end

        if type(m.preloadVars) == "table" then
            for _, v in ipairs(m.preloadVars) do
                AddCandidate(v.var)
            end
        end

        local searchText = tostring(m.instruction or "") .. "\n" .. tostring(m.content or "")

        for name in searchText:gmatch("<k>([%a_][%w_]*)</k>") do
            AddCandidate(name)
        end

        if type(m.requireKeywords) == "table" then
            for _, keyword in ipairs(m.requireKeywords) do
                for name in tostring(keyword):gmatch("[%a_][%w_]*") do
                    AddCandidate(name)
                end
            end
        end

        local oldValues = {}

        for _, name in ipairs(candidateOrder) do
            oldValues[name] = _G[name]
        end

        local function ResetInputs()
            if m.preloadVars then
                for _, v in ipairs(m.preloadVars) do
                    local var = Trim(v.var)

                    if var ~= "" then
                        _G[var] = v.value
                    end
                end
            end

            for _, name in ipairs(candidateOrder) do
                _G[name] = oldValues[name]
            end
        end

        local useEnv = (env ~= nil)

        local instrumentedCode = InstrumentCode(code)

        local ok, runErr, rawOutput = ExecuteSource(instrumentedCode, useEnv)

        if not ok and instrumentedCode ~= code then
            iterationLines = {}
            iterationCount = 0
            traceOverflow = false

            ResetInputs()

            ok, runErr, rawOutput = ExecuteSource(code, useEnv)
        end

        _G.__ns_trace_loop = oldTraceLoop or function() end
        _G.__ns_trace_while = oldTraceWhile or function() end

        local problems = {}

        local outputOk = true

        if m.expectedOutput then
            outputOk = Normalize(rawOutput) == Normalize(m.expectedOutput)

            if not outputOk then
                table.insert(problems, "Неверный вывод.")
            end
        end

        local printCount = 0
        local templateOk = true
        local needPrint = tonumber(m.requiredPrintCount)

        if needPrint then
            local codeForCheck = code:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''")
            local searchPos = 1

            while true do
                local startPos, endPos = codeForCheck:find("print", searchPos, true)

                if not startPos then
                    break
                end

                local before = startPos > 1 and codeForCheck:sub(startPos - 1, startPos - 1) or ""
                local after = codeForCheck:sub(endPos + 1, endPos + 1) or ""

                local beforeIsWord = before ~= "" and before:match("[%w_]") ~= nil
                local afterIsWord = after ~= "" and after:match("[%w_]") ~= nil

                if not beforeIsWord and not afterIsWord then
                    printCount = printCount + 1
                end

                searchPos = endPos + 1
            end

            if printCount ~= needPrint then
                templateOk = false

                table.insert(
                    problems,
                    ("В коде должно быть %d слов print. Найдено: %d."):format(needPrint, printCount)
                )
            end
        end

        local runtimeOk = true
        local checkDetails = nil

        if type(m.checkCode) == "function" then
            if not ok then
                runtimeOk = false
            else
                local success, result = pcall(m.checkCode, env)

                if success and result == true then
                    runtimeOk = true
                else
                    runtimeOk = false

                    if type(result) == "string" then
                        checkDetails = result
                    end
                end
            end

            if not runtimeOk then
                table.insert(problems, "Проверка результата не пройдена.")
            end
        end

        local runOk = true

        if not ok and not m.expectedOutput and type(m.checkCode) ~= "function" then
            runOk = false
            table.insert(problems, "Ошибка выполнения кода.")
        end

        local passed = outputOk and templateOk and runtimeOk and runOk

        local reportLines = {}

        if #iterationLines > 0 then
            table.insert(reportLines, "Итерации:")

            for _, line in ipairs(iterationLines) do
                table.insert(reportLines, "  " .. line)
            end
        end

        if rawOutput ~= "" then
            table.insert(reportLines, "Вывод:")

            for line in rawOutput:gmatch("[^\n]+") do
                table.insert(reportLines, "  " .. line)
            end
        end

        local finalLines = {}

        for _, name in ipairs(candidateOrder) do
            local newValue

            if useEnv and env then
                newValue = env[name]
            else
                newValue = _G[name]
            end

            if type(newValue) ~= "function" and newValue ~= nil then
                table.insert(finalLines, name .. " = " .. FormatValue(newValue))
            end
        end

        if #finalLines > 0 then
            table.insert(reportLines, "Итог:")

            for _, line in ipairs(finalLines) do
                table.insert(reportLines, "  " .. line)
            end
        end

        if checkDetails then
            table.insert(reportLines, "Детали проверки:")

            for line in checkDetails:gmatch("[^\n]+") do
                table.insert(reportLines, "  " .. line)
            end
        end

        if #reportLines == 0 and ok then
            table.insert(reportLines, "Код выполнен без ошибок.")
        end

        local reportText = table.concat(reportLines, "\n")

        local displayCurrent = reportText

        if not ok then
            if displayCurrent ~= "" then
                displayCurrent = displayCurrent .. "\n"
            end

            displayCurrent = displayCurrent .. "Ошибка: " .. tostring(runErr)
        end

        if passed then
            self.commentTestPassed = true
            self:SaveCommentTest(code, true)

            self.ui:SetEditorResult(editorName, {
                status = "success",
                message = "",
                expected = "",
                current = reportText,
                footerSuccess = true,
            })

            self.ui:SetNextEnabled(true)

            RefreshEditorButtons()

            if PlaySoundFile then
                PlaySoundFile("Interface\\AddOns\\NSQC4\\Media\\Sounds\\fin.ogg")
            end

            self:SendWinMessage(code)
        else
            ApplyFailState()

            local message = table.concat(problems, " ")

            if message == "" then
                message = "Неверно."
            end

            self.ui:SetEditorResult(editorName, {
                status = "diff",
                message = message,
                expected = m.expectedCode or m.expectedOutput or "",
                current = displayCurrent,
            })
        end
    end

    -- ========================================================================
    -- Публикация класса
    -- ========================================================================
    NSQC4.Course.Logic = Logic
end)