-- ============================================================================
-- NSQC4 / Course / UI
-- Класс UI: главное окно курса + окно справки + окно результатов.
-- Публикуется как NSQC4.Course.UI.
-- Инстанс создаётся в Course/Init.lua.
-- ============================================================================

NSQC4.RegisterModule("course", function()

    NSQC4.Course = NSQC4.Course or {}

    -- ========================================================================
    -- Цветовые теги для текста
    -- ========================================================================
    local TEXT_TAGS = {
        h  = "|cFFFFD700",
        k  = "|cFF80FF80",
        c  = "|cFF66CCFF",
        s  = "|cFFFF8080",
        n  = "|cFFFFB830",
        o  = "|cFFCC88FF",
        t  = "|cFFB3B3B3",
        w  = "|cFFFF8080",
        ok = "|cFF00FF00",
    }

    local CODE_TAGS = {
        kw = "|cFF80FF80",
        cm = "|cFF808080",
        st = "|cFFFF8080",
        nu = "|cFFFFB830",
        op = "|cFFCC88FF",
    }

    -- ========================================================================
    -- Вспомогательные функции работы с текстом
    -- ========================================================================
    local function trim(s)
        return (s:match("^%s*(.-)%s*$"))
    end

    local function applyTags(text, tags, closeColor)
        for tag, color in pairs(tags) do
            text = text:gsub("<" .. tag .. ">", color)
            text = text:gsub("</" .. tag .. ">", closeColor)
        end

        return text
    end

    local function escapePipes(s)
        return (s:gsub("|", "||"))
    end

    -- ========================================================================
    -- Подсветка Lua-кода
    -- ========================================================================
    local LUA_KEYWORDS = {
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

    local function highlightLuaCode(code)
        if type(code) ~= "string" or code == "" then
            return ""
        end

        local out = {}
        local i = 1
        local n = #code

        local DEFAULT  = "|cFF66CCFF"
        local KEYWORD  = "|cFF80FF80"
        local COMMENT  = "|cFF808080"
        local STRING   = "|cFFFF8080"
        local NUMBER   = "|cFFFFB830"
        local OPERATOR = "|cFFCC88FF"
        local RESET    = "|r"

        local newlinePattern = "[" .. string.char(13) .. string.char(10) .. "]"

        table.insert(out, DEFAULT)

        while i <= n do
            local c = code:sub(i, i)

            if c == "-" and code:sub(i + 1, i + 1) == "-" then
                local j

                if code:sub(i + 2, i + 3) == "[[" then
                    local close = code:find("]]", i + 4, true)
                    j = close and (close + 2) or (n + 1)
                else
                    local nl = code:find(newlinePattern, i)
                    j = nl or (n + 1)
                end

                local token = code:sub(i, j - 1)
                table.insert(out, COMMENT .. escapePipes(token) .. RESET .. DEFAULT)
                i = j
            elseif c == '"' or c == "'" then
                local quote = c
                local j = i + 1

                while j <= n do
                    local ch = code:sub(j, j)

                    if ch == "\\" then
                        j = j + 2
                    elseif ch == quote then
                        j = j + 1
                        break
                    else
                        j = j + 1
                    end
                end

                local token = code:sub(i, j - 1)
                table.insert(out, STRING .. escapePipes(token) .. RESET .. DEFAULT)
                i = j
            elseif c == "[" and code:sub(i + 1, i + 1) == "[" then
                local close = code:find("]]", i + 2, true)
                local j = close and (close + 2) or (n + 1)

                local token = code:sub(i, j - 1)
                table.insert(out, STRING .. escapePipes(token) .. RESET .. DEFAULT)
                i = j
            elseif c:match("%d") or (c == "." and code:sub(i + 1, i + 1):match("%d")) then
                local num = code:match("^%d+%.%d+", i)
                    or code:match("^%d+", i)
                    or code:match("^%.%d+", i)
                    or c

                table.insert(out, NUMBER .. escapePipes(num) .. RESET .. DEFAULT)
                i = i + #num
            elseif c:match("[%a_]") then
                local word = code:match("^[%a_][%w_]*", i)

                if LUA_KEYWORDS[word] then
                    table.insert(out, KEYWORD .. escapePipes(word) .. RESET .. DEFAULT)
                else
                    table.insert(out, escapePipes(word))
                end

                i = i + #word
            elseif c:match("[%p]") then
                table.insert(out, OPERATOR .. escapePipes(c) .. RESET .. DEFAULT)
                i = i + 1
            else
                table.insert(out, escapePipes(c))
                i = i + 1
            end
        end

        table.insert(out, RESET)

        return table.concat(out)
    end

    local function hasManualCodeTags(text)
        return text:find("<kw>", 1, true)
            or text:find("<cm>", 1, true)
            or text:find("<st>", 1, true)
            or text:find("<nu>", 1, true)
            or text:find("<op>", 1, true)
    end

    local function markupText(text)
        if type(text) ~= "string" or text == "" then
            return ""
        end

        text = escapePipes(text)

        return "|cFFFFFFFF" .. applyTags(text, TEXT_TAGS, "|cFFFFFFFF") .. "|r"
    end

    local function markupPlain(text)
        if type(text) ~= "string" or text == "" then
            return ""
        end

        return "|cFFFFFFFF" .. escapePipes(text) .. "|r"
    end

    local function markupCode(text)
        if type(text) ~= "string" or text == "" then
            return ""
        end

        if hasManualCodeTags(text) then
            text = escapePipes(text)
            return "|cFF66CCFF" .. applyTags(text, CODE_TAGS, "|cFF66CCFF") .. "|r"
        end

        return highlightLuaCode(text)
    end

    -- ========================================================================
    -- Парсинг контента на блоки
    -- ========================================================================
    local function parseContent(raw)
        local blocks = {}

        if type(raw) ~= "string" or raw == "" then
            return blocks
        end

        local pos = 1

        while true do
            local startPos, endPos, codeText = raw:find("<code>(.-)</code>", pos)
            local textPart = trim(startPos and raw:sub(pos, startPos - 1) or raw:sub(pos))

            if textPart ~= "" then
                table.insert(blocks, { type = "text", content = textPart })
            end

            if not startPos then
                break
            end

            table.insert(blocks, { type = "code", content = trim(codeText) })
            pos = endPos + 1
        end

        return blocks
    end

    -- ========================================================================
    -- Работа с блоками
    -- ========================================================================
    local function clearBlocks(blocks)
        for _, block in ipairs(blocks or {}) do
            block:Hide()
            block:SetParent(nil)
        end
    end

    local function updateScroll(scrollFrame, content, bar)
        local maxScroll = math.max(0, content:GetHeight() - (scrollFrame:GetHeight() or 1))

        bar:SetMinMaxValues(0, maxScroll)

        local value = bar:GetValue()

        if value > maxScroll then
            value = maxScroll
        end

        if value < 0 then
            value = 0
        end

        if value ~= bar:GetValue() then
            bar:SetValue(value)
        end

        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, value)
    end

    local function resetScroll(scrollFrame, content, bar)
        if not scrollFrame or not content or not bar then
            return
        end

        bar:SetValue(0)

        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    end

    local function layoutBlocks(blocks, parent, scrollFrame, bar)
        local width = parent:GetWidth() or 560
        local y = -5

        local function layoutEditor(block)
            local editWidth = math.max(10, width - 20)
            local innerY = -10

            block:ClearAllPoints()
            block:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
            block:SetWidth(width)

            block._editBox:ClearAllPoints()
            block._editBox:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
            block._editBox:SetWidth(editWidth)

            block._measure:ClearAllPoints()
            block._measure:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
            block._measure:SetWidth(editWidth)
            block._measure:SetText(block._editBox:GetText() or "")

            local editHeight = math.max(60, (block._measure:GetStringHeight() or 0) + 12)
            block._editBox:SetHeight(editHeight)

            innerY = innerY - editHeight - 4

            if block._charCount then
                block._charCount:ClearAllPoints()
                block._charCount:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
                block._charCount:SetWidth(editWidth)
                innerY = innerY - math.max(14, (block._charCount:GetStringHeight() or 14)) - 6
            else
                innerY = innerY - 8
            end

            block._button:ClearAllPoints()
            block._button:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)

            if block._resultsButton then
                block._resultsButton:ClearAllPoints()
                block._resultsButton:SetPoint("LEFT", block._button, "RIGHT", 8, 0)
                block._resultsButton:SetHeight(block._button:GetHeight() or 22)
            end

            if block._skipButton then
                block._skipButton:ClearAllPoints()
                block._skipButton:SetPoint("LEFT", block._resultsButton, "RIGHT", 8, 0)
                block._skipButton:SetHeight(block._button:GetHeight() or 22)
            end

            innerY = innerY - (block._button:GetHeight() or 22) - 12

            block._previewLabel:ClearAllPoints()
            block._previewLabel:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)

            innerY = innerY - (block._previewLabel:GetStringHeight() or 12) - 4

            block._preview:ClearAllPoints()
            block._preview:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
            block._preview:SetWidth(editWidth)

            local previewHeight = math.max(16, (block._preview:GetStringHeight() or 0) + 4)
            innerY = innerY - previewHeight - 12

            if block._resultMessage:GetText() and block._resultMessage:GetText() ~= "" then
                block._resultMessage:ClearAllPoints()
                block._resultMessage:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
                block._resultMessage:SetWidth(editWidth)
                innerY = innerY - (block._resultMessage:GetStringHeight() or 0) - 10
            else
                block._resultMessage:ClearAllPoints()
            end

            local function layoutResultLine(label, text)
                if text:GetText() and text:GetText() ~= "" then
                    label:ClearAllPoints()
                    label:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
                    innerY = innerY - (label:GetStringHeight() or 12) - 2

                    text:ClearAllPoints()
                    text:SetPoint("TOPLEFT", block, "TOPLEFT", 10, innerY)
                    text:SetWidth(editWidth)

                    innerY = innerY - (text:GetStringHeight() or 0) - 10
                else
                    label:ClearAllPoints()
                    text:ClearAllPoints()
                end
            end

            layoutResultLine(block._expectedLabel, block._expectedText)
            layoutResultLine(block._currentLabel, block._currentText)

            block:SetHeight(math.max(120, -innerY + 10))
            y = y - block:GetHeight() - 8
        end

        for _, block in ipairs(blocks or {}) do
            if block._kind == "editor" then
                layoutEditor(block)
            else
                block:ClearAllPoints()
                block:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                block:SetWidth(width)

                local fs = block._fs

                if block._kind == "code" then
                    fs:SetWidth(math.max(10, width - 24))
                    block:SetHeight(math.max(20, (fs:GetStringHeight() or 0) + 16))
                else
                    fs:SetWidth(math.max(10, width - 10))
                    block:SetHeight(math.max(18, (fs:GetStringHeight() or 0) + 4))
                end

                y = y - block:GetHeight() - 8
            end
        end

        parent:SetHeight(math.max(100, -y + 5))
        updateScroll(scrollFrame, parent, bar)
    end

    -- ========================================================================
    -- Создание блоков
    -- ========================================================================
    local function createTextBlock(parent, raw)
        local block = CreateFrame("Frame", nil, parent)

        local fs = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 5, 0)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetNonSpaceWrap(true)
        fs:SetSpacing(3)
        fs:SetText(markupText(raw))

        block._fs = fs
        block._kind = "text"

        return block
    end

    local function createCodeBlock(parent, raw)
        local block = CreateFrame("Frame", nil, parent)

        local bg = block:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(block)
        bg:SetTexture(0.03, 0.04, 0.07, 1)

        local bar = block:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT")
        bar:SetPoint("BOTTOMLEFT")
        bar:SetWidth(3)
        bar:SetTexture(0.35, 0.55, 0.95, 1)

        local fs = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 12, -8)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetNonSpaceWrap(true)
        fs:SetSpacing(2)
        fs:SetText(markupCode(raw))

        block._fs = fs
        block._kind = "code"

        return block
    end

    -- ========================================================================
    -- Подсчёт символов и проверка длинных строк
    -- ========================================================================
    local MAX_EDITOR_LINE_CHARS = 200

    local function StripLuaComments(s)
        if type(s) ~= "string" or s == "" then
            return ""
        end

        s = s:gsub("%-%-%[=*%[.-%]%=*%]", "")
        s = s:gsub("%-%-[^\n]*", "")

        return s
    end

    local function CountEditorChars(s)
        if type(s) ~= "string" or s == "" then
            return 0
        end

        local n = 0
        for i = 1, #s do
            local b = s:byte(i)
            if b < 128 or b >= 192 then
                n = n + 1
            end
        end

        return n
    end

    local function CountEditorCharsNoComments(s)
        return CountEditorChars(StripLuaComments(s))
    end

    local function GetEditorTooLongLine(code)
        if type(code) ~= "string" or code == "" then
            return false, 0, 0
        end

        local normalized = code:gsub("\r\n", "\n"):gsub("\r", "\n")
        local lineNo = 0

        for line in (normalized .. "\n"):gmatch("(.-)\n") do
            lineNo = lineNo + 1

            local chars = CountEditorChars(line)
            if chars > MAX_EDITOR_LINE_CHARS then
                return true, lineNo, chars
            end
        end

        return false, 0, 0
    end

    local editorCounter = 0

    local function createEditorBlock(parent, data, ui)
        editorCounter = editorCounter + 1

        local block = CreateFrame("Frame", nil, parent)
        block._kind = "editor"
        block._name = data.name or ("editor" .. editorCounter)

        local bg = block:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(block)
        bg:SetTexture(0.03, 0.04, 0.07, 1)

        local bar = block:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT")
        bar:SetPoint("BOTTOMLEFT")
        bar:SetWidth(3)
        bar:SetTexture(0.35, 0.55, 0.95, 1)

        local editBox = CreateFrame("EditBox", nil, block)
        editBox:SetFontObject("GameFontNormal")
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetJustifyH("LEFT")
        editBox:SetText(data.code or "")

        local button = CreateFrame("Button", nil, block, "UIPanelButtonTemplate")
        button:SetSize(130, 22)
        button:SetText(data.buttonText or "Выполнить")

        local resultsButton = CreateFrame("Button", nil, block, "UIPanelButtonTemplate")
        resultsButton:SetSize(240, 22)
        resultsButton:SetText("Результаты других игроков")

        if data.resultsEnabled == true then
            resultsButton:Enable()
            resultsButton:SetAlpha(1)
        else
            resultsButton:Disable()
            resultsButton:SetAlpha(0.45)
        end

        resultsButton:SetScript("OnClick", function()
            if ui and ui.callbacks and ui.callbacks.onShowResults then
                ui.callbacks.onShowResults(block._name)
            end
        end)

        local skipButton = CreateFrame("Button", nil, block, "UIPanelButtonTemplate")
        skipButton:SetSize(160, 22)
        skipButton:SetText(data.skipped == true and "Отменить пропуск" or "Пропустить")

        block._skipped = data.skipped == true

        local skipAllowed = data.skipEnabled ~= false
        local hasSkipCallback = ui and ui.callbacks and type(ui.callbacks.onToggleSkip) == "function"

        if skipAllowed and hasSkipCallback then
            skipButton:Enable()
            skipButton:SetAlpha(1)
        else
            skipButton:Disable()
            skipButton:SetAlpha(0.45)
        end

        skipButton:SetScript("OnClick", function()
            if ui and ui.callbacks and type(ui.callbacks.onToggleSkip) == "function" then
                ui.callbacks.onToggleSkip(block._name)
            end
        end)

        skipButton:SetScript("OnEnter", function(self)
            if not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Пропуск модуля", 1, 1, 1, true)

            if block._skipped then
                GameTooltip:AddLine("Модуль помечен как пропущенный.", 0.6, 0.6, 0.6, true)
                GameTooltip:AddLine("ЛКМ — отменить пропуск.", 0.6, 0.6, 0.6, true)
            else
                local skippedCount = 0
                if ui and ui.GetSkippedCount then
                    skippedCount = ui:GetSkippedCount()
                end

                GameTooltip:AddLine(string.format("Использовано пропусков: %d/5", skippedCount), 0.6, 0.6, 0.6, true)
                GameTooltip:AddLine("ЛКМ — пометить модуль как пропущенный.", 0.6, 0.6, 0.6, true)
            end

            GameTooltip:Show()
        end)

        skipButton:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)

        local previewLabel = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        previewLabel:SetText("|cFFB3B3B3Подсветка кода:|r")

        local preview = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        preview:SetJustifyH("LEFT")
        preview:SetJustifyV("TOP")
        preview:SetNonSpaceWrap(true)
        preview:SetSpacing(2)
        preview:SetText(markupCode(data.code or ""))

        local charCount = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        charCount:SetJustifyH("LEFT")
        charCount:SetJustifyV("MIDDLE")
        charCount:SetTextColor(0.70, 0.70, 0.80, 1)
        charCount:SetText("Символов: 0")

        local resultMessage = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        resultMessage:SetJustifyH("LEFT")
        resultMessage:SetJustifyV("TOP")
        resultMessage:SetNonSpaceWrap(true)
        resultMessage:SetSpacing(2)
        resultMessage:SetText("")

        local expectedLabel = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expectedLabel:SetJustifyH("LEFT")
        expectedLabel:SetText("")

        local expectedText = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expectedText:SetJustifyH("LEFT")
        expectedText:SetJustifyV("TOP")
        expectedText:SetNonSpaceWrap(true)
        expectedText:SetSpacing(2)
        expectedText:SetText("")

        local currentLabel = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        currentLabel:SetJustifyH("LEFT")
        currentLabel:SetText("")

        local currentText = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        currentText:SetJustifyH("LEFT")
        currentText:SetJustifyV("TOP")
        currentText:SetNonSpaceWrap(true)
        currentText:SetSpacing(2)
        currentText:SetText("")

        local measure = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        measure:SetJustifyH("LEFT")
        measure:SetJustifyV("TOP")
        measure:SetNonSpaceWrap(true)
        measure:SetAlpha(0)

        local function updateCharCounter()
            local text = editBox:GetText() or ""
            local totalChars = CountEditorCharsNoComments(text)
            local tooLong, lineNo, lineChars = GetEditorTooLongLine(text)

            if tooLong then
                charCount:SetTextColor(1.0, 0.35, 0.35, 1)
                charCount:SetText(string.format(
                    "Символов: %d | Строка %d: %d/%d (слишком длинная)",
                    totalChars,
                    lineNo,
                    lineChars,
                    MAX_EDITOR_LINE_CHARS
                ))
            else
                charCount:SetTextColor(0.70, 0.70, 0.80, 1)
                charCount:SetText(string.format("Символов: %d", totalChars))
            end

            return tooLong
        end

        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        editBox:SetScript("OnTabPressed", function(self)
            self:Insert("    ")
        end)

        editBox:SetScript("OnEnterPressed", function(self)
            if IsControlKeyDown and IsControlKeyDown() then
                button:Click()
            else
                self:Insert(string.char(10))
            end
        end)

        editBox:SetScript("OnTextChanged", function(self)
            local text = self:GetText() or ""

            if block._settingText then
                preview:SetText(markupCode(text))
                updateCharCounter()

                if ui then
                    ui.layoutDirty = true
                end

                return
            end

            local tooLong = GetEditorTooLongLine(text)

            if tooLong and block._lastValidText and not block._reverting then
                block._reverting = true
                self:SetText(block._lastValidText)
                self:SetCursorPosition(#(block._lastValidText or ""))
                block._reverting = false
                return
            end

            if not tooLong then
                block._lastValidText = text
            end

            preview:SetText(markupCode(text))
            updateCharCounter()

            if ui then
                ui.layoutDirty = true
            end
        end)

        button:SetScript("OnClick", function()
            local code = editBox:GetText() or ""
            local tooLong, lineNo, lineChars = GetEditorTooLongLine(code)

            if tooLong then
                editBox:ClearFocus()

                resultMessage:SetText(
                    "|cFFFF8080"
                    .. escapePipes(string.format(
                        "Код не принят: строка %d содержит %d символов (максимум %d).",
                        lineNo,
                        lineChars,
                        MAX_EDITOR_LINE_CHARS
                    ))
                    .. "|r"
                )

                if ui then
                    ui.layoutDirty = true
                end

                return
            end

            editBox:ClearFocus()
            resultMessage:SetText("")

            if ui then
                ui.layoutDirty = true
            end

            if ui and ui.callbacks and ui.callbacks.onExecute then
                ui.callbacks.onExecute(block._name, code)
            end
        end)

        block._editBox = editBox
        block._button = button
        block._resultsButton = resultsButton
        block._skipButton = skipButton
        block._preview = preview
        block._previewLabel = previewLabel
        block._charCount = charCount
        block._resultMessage = resultMessage
        block._expectedLabel = expectedLabel
        block._expectedText = expectedText
        block._currentLabel = currentLabel
        block._currentText = currentText
        block._measure = measure
        block._updateCharCount = updateCharCounter
        block._settingText = false
        block._reverting = false

        local initialText = editBox:GetText() or ""

        if not GetEditorTooLongLine(initialText) then
            block._lastValidText = initialText
        else
            block._lastValidText = nil
        end

        updateCharCounter()

        return block
    end

    -- ========================================================================
    -- Оформление фреймов
    -- ========================================================================
    local function addBackgroundBorder(frame)
        local border = frame:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
        border:SetTexture(0.25, 0.25, 0.35, 1)

        local bg = frame:CreateTexture(nil, "BORDER")
        bg:SetAllPoints(frame)
        bg:SetTexture(0.08, 0.08, 0.12, 0.97)
    end

    local function createScrollArea(parent, contentWidth, topX, topY, bottomX, bottomY)
        local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
        scrollFrame:SetPoint("TOPLEFT", topX, topY)
        scrollFrame:SetPoint("BOTTOMRIGHT", bottomX, bottomY)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(contentWidth)
        content:SetHeight(100)
        content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)

        scrollFrame:SetScrollChild(content)

        local bar = CreateFrame("Slider", nil, parent)
        bar:SetPoint("TOPRIGHT", -8, topY - 5)
        bar:SetPoint("BOTTOMRIGHT", -8, bottomY + 3)
        bar:SetWidth(16)
        bar:SetOrientation("VERTICAL")
        bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
        bar:SetMinMaxValues(0, 0)
        bar:SetValueStep(1)
        bar:SetValue(0)

        local scrollBg = bar:CreateTexture(nil, "BACKGROUND")
        scrollBg:SetAllPoints(bar)
        scrollBg:SetTexture(0.15, 0.15, 0.20, 1)

        bar:SetScript("OnValueChanged", function(_, value)
            content:ClearAllPoints()
            content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, value)
        end)

        scrollFrame:EnableMouseWheel(true)

        scrollFrame:SetScript("OnMouseWheel", function(_, delta)
            local maxScroll = select(2, bar:GetMinMaxValues())
            local value = math.max(0, math.min(bar:GetValue() - delta * 25, maxScroll))
            bar:SetValue(value)
        end)

        return scrollFrame, content, bar
    end

    local function setButtonEnabled(button, enabled)
        if enabled then
            button:Enable()
            button:SetAlpha(1)
        else
            button:Disable()
            button:SetAlpha(0.45)
        end
    end

    -- ========================================================================
    -- Класс UI
    -- ========================================================================
    local UI = {}
    UI.__index = UI

    function UI:new(parent)
        local self = setmetatable({}, UI)

        self.parent = parent or UIParent        
        self.callbacks = {}

        self.helpModules = nil
        self.helpKey = nil

        self.blocks = {}
        self.helpBlocks = {}
        self.editors = {}
        self.sideRows = {}

        self.moduleStates = {}

        self.currentModuleIndex = nil
        self.currentModuleType = nil

        self.layoutDirty = false
        self.isScaling = false
        self.scaleStartScale = 1
        self.scaleStartX = 0
        self.scaleStartY = 0

        self.baseFrameWidth = 620
        self.sidePanelWidth = 180
        self.sidePanelVisible = false
        self.stateLoaded = false

        self:_CreateMain()

        return self
    end

    -- ========================================================================
    -- Состояние модулей
    -- ========================================================================
    function UI:IsModuleSkipped(index)
        return self:_IsModuleSkipped(index)
    end

    function UI:_IsModuleSkippedByTaskDetails(index)
        local details = self:_GetTaskDetails(index)
        return details.skipped == true
    end

    function UI:_IsModuleSkipped(index)
        index = tonumber(index)

        if not index then
            return false
        end

        local state = self.moduleStates and self.moduleStates[index]

        if type(state) == "table" and state.skipped then
            return true
        end

        return self:_IsModuleSkippedByTaskDetails(index)
    end

    function UI:_IsModuleDoneOrSkipped(index)
        return self:_IsModuleDone(index) or self:_IsModuleSkipped(index)
    end

    function UI:GetSkippedCount()
        local count = 0
        local indices = self:_GetSortedModuleIndices()

        for _, idx in ipairs(indices) do
            if self:_IsModuleSkipped(idx) and not self:_IsModuleDone(idx) then
                count = count + 1
            end
        end

        return count
    end

    function UI:CanSkipModule(index)
        index = tonumber(index)

        if not index then
            return false
        end

        if self:_IsModuleSkipped(index) then
            return true
        end

        if self:_IsModuleDone(index) then
            return false
        end

        return self:GetSkippedCount() < 5
    end

    function UI:SetModuleSkipped(index, skipped)
        index = tonumber(index)

        if not index then
            return
        end

        skipped = skipped and true or false

        self.moduleStates = self.moduleStates or {}
        self.moduleStates[index] = self.moduleStates[index] or {}
        self.moduleStates[index].skipped = skipped

        nsDbc4.course.logic.taskDetails = nsDbc4.course.logic.taskDetails or {}
        nsDbc4.course.logic.taskDetails[index] = nsDbc4.course.logic.taskDetails[index] or {}
        nsDbc4.course.logic.taskDetails[index].skipped = skipped

        self:RefreshSidePanel()
        self:SaveState()
    end

    function UI:SetEditorSkipButtonState(name, skipped, enabled)
        local editor = self:GetEditor(name)

        if not editor or not editor._skipButton then
            return
        end

        editor._skipped = skipped and true or false

        if editor._skipButton.SetText then
            editor._skipButton:SetText(editor._skipped and "Отменить пропуск" or "Пропустить")
        end

        if enabled == nil then
            enabled = true
        end

        setButtonEnabled(editor._skipButton, enabled and true or false)
    end

    -- ========================================================================
    -- Сохранение состояния
    -- ========================================================================
    function UI:SaveState()
        if not self.frame then
            return
        end

        nsDbc4.course.ui.windowState = nsDbc4.course.ui.windowState or {}

        local point, relativeTo, relativePoint, x, y = self.frame:GetPoint(1)

        nsDbc4.course.ui.windowState.point = point or "CENTER"
        nsDbc4.course.ui.windowState.relativeTo =
            (relativeTo and relativeTo.GetName and relativeTo:GetName()) or "UIParent"
        nsDbc4.course.ui.windowState.relativePoint = relativePoint or "CENTER"
        nsDbc4.course.ui.windowState.x = x or 0
        nsDbc4.course.ui.windowState.y = y or 0
        nsDbc4.course.ui.windowState.scale = self.frame:GetScale() or 1
        nsDbc4.course.ui.windowState.sidePanelCollapsed = not self.sidePanelVisible

        nsDbc4.course.ui.moduleStates = self.moduleStates or {}
    end

    function UI:LoadState()
        if not self.frame then
            return
        end

        local saved = nsDbc4.course and nsDbc4.course.ui
        local state = saved and saved.windowState

        if type(state) == "table" then
            local scale = tonumber(state.scale)
            if scale then
                scale = math.max(0.75, math.min(2.0, scale))
                self.frame:SetScale(scale)
            end

            local point = tostring(state.point or "CENTER")
            local relativePoint = tostring(state.relativePoint or point)
            local relativeTo = _G[state.relativeTo or "UIParent"] or UIParent
            local x = tonumber(state.x) or tonumber(state.xOfs) or 0
            local y = tonumber(state.y) or tonumber(state.yOfs) or 0

            self.frame:ClearAllPoints()
            self.frame:SetPoint(point, relativeTo, relativePoint, x, y)
        end

        if type(saved) == "table" and type(saved.moduleStates) == "table" then
            self.moduleStates = saved.moduleStates
        else
            self.moduleStates = self.moduleStates or {}
        end

        local visible = false

        if type(state) == "table" then
            visible = not (state.sidePanelCollapsed == true)
        end

        if self.SetSidePanelVisible then
            self:SetSidePanelVisible(visible, true)
        end

        if self.RefreshSidePanel then
            self:RefreshSidePanel()
        end
    end

    -- ========================================================================
    -- Боковая панель
    -- ========================================================================
    function UI:_CreateSidePanel()
        if self.sidePanel or not self.frame then
            return
        end

        local panel = CreateFrame("Frame", nil, self.frame)
        panel:SetWidth(self.sidePanelWidth or 180)
        panel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -45)
        panel:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 45)

        local bg = panel:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(panel)
        bg:SetTexture(0.06, 0.07, 0.10, 0.95)

        local border = panel:CreateTexture(nil, "ARTWORK")
        border:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
        border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
        border:SetWidth(1)
        border:SetTexture(0.28, 0.30, 0.45, 1)

        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -6)
        label:SetText("|cFFB3B3B3Модули:|r")

        self.sidePanel = panel

        self.sideScroll, self.sideContent, self.sideBar = createScrollArea(
            panel,
            math.max(80, (self.sidePanelWidth or 180) - 36),
            8,
            -26,
            -20,
            8
        )

        panel:Hide()
    end

    function UI:_ApplySidePanelLayout()
        if not self.frame or not self.sidePanel or not self.scrollFrame then
            return
        end

        local visible = self.sidePanelVisible

        if visible then
            self.sidePanel:Show()
        else
            self.sidePanel:Hide()
        end

        if self.sideToggleText then
            self.sideToggleText:SetText(visible and "<" or ">")
        elseif self.sideToggleButton then
            self.sideToggleButton:SetText(visible and "<" or ">")
        end

        local baseWidth = self.baseFrameWidth or 620
        local panelWidth = self.sidePanelWidth or 180
        local newWidth = baseWidth + (visible and panelWidth or 0)

        self.frame:SetWidth(newWidth)

        self.scrollFrame:ClearAllPoints()
        self.scrollFrame:SetPoint(
            "TOPLEFT",
            self.frame,
            "TOPLEFT",
            (visible and (panelWidth + 18) or 18),
            -45
        )
        self.scrollFrame:SetPoint(
            "BOTTOMRIGHT",
            self.frame,
            "BOTTOMRIGHT",
            -28,
            45
        )

        self.layoutDirty = true
    end

    function UI:SetSidePanelVisible(visible, skipSave)
        visible = visible and true or false

        if not self.sidePanel then
            self:_CreateSidePanel()
        end

        if not self.sidePanel then
            return
        end

        if self.sidePanelVisible == visible then
            self:_ApplySidePanelLayout()
            return
        end

        self.sidePanelVisible = visible
        self:_ApplySidePanelLayout()

        if not skipSave then
            self:SaveState()
        end
    end

    function UI:ToggleSidePanel()
        self:SetSidePanelVisible(not self.sidePanelVisible)
    end

    -- ========================================================================
    -- Главное окно
    -- ========================================================================
    function UI:_CreateMain()
        local f = CreateFrame("Frame", nil, self.parent)
        self.frame = f
        f:SetSize(self.baseFrameWidth or 620, 450)
        f:SetPoint("CENTER")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("HIGH")
        addBackgroundBorder(f)

        local titleBg = f:CreateTexture(nil, "ARTWORK")
        titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        titleBg:SetHeight(35)
        titleBg:SetTexture(0.15, 0.15, 0.20, 1)

        local titleSeparator = f:CreateTexture(nil, "ARTWORK")
        titleSeparator:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)
        titleSeparator:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
        titleSeparator:SetHeight(2)
        titleSeparator:SetTexture(0.30, 0.30, 0.50, 1)

        local bottomBg = f:CreateTexture(nil, "ARTWORK")
        bottomBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        bottomBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        bottomBg:SetHeight(38)
        bottomBg:SetTexture(0.12, 0.12, 0.18, 1)

        local bottomSeparator = f:CreateTexture(nil, "ARTWORK")
        bottomSeparator:SetPoint("BOTTOMLEFT", bottomBg, "TOPLEFT", 0, 0)
        bottomSeparator:SetPoint("BOTTOMRIGHT", bottomBg, "TOPRIGHT", 0, 0)
        bottomSeparator:SetHeight(2)
        bottomSeparator:SetTexture(0.30, 0.30, 0.50, 1)

        local sideToggleButton = CreateFrame("Button", nil, f)
        sideToggleButton:EnableMouse(true)
        sideToggleButton:SetSize(24, 24)
        sideToggleButton:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)

        local toggleBg = sideToggleButton:CreateTexture(nil, "BACKGROUND")
        toggleBg:SetAllPoints(sideToggleButton)
        toggleBg:SetTexture(0.18, 0.18, 0.24, 1)

        local toggleText = sideToggleButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        toggleText:SetAllPoints(sideToggleButton)
        toggleText:SetText(">")
        toggleText:SetTextColor(0.80, 0.80, 0.20, 1)

        local toggleHighlight = sideToggleButton:CreateTexture(nil, "HIGHLIGHT")
        toggleHighlight:SetAllPoints(sideToggleButton)
        toggleHighlight:SetTexture(0.35, 0.35, 0.50, 0.40)

        sideToggleButton:SetScript("OnClick", function()
            self:ToggleSidePanel()
        end)

        self.sideToggleButton = sideToggleButton
        self.sideToggleText = toggleText

        local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            self:HideHelp()
            if self.callbacks.onClose then
                self.callbacks.onClose()
            end
            f:Hide()
        end)

        local helpButton = CreateFrame("Button", nil, f)
        helpButton:SetSize(24, 24)
        helpButton:SetPoint("TOPRIGHT", -30, -5)

        local helpButtonText = helpButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        helpButtonText:SetAllPoints(helpButton)
        helpButtonText:SetText("?")
        helpButtonText:SetTextColor(0.8, 0.8, 0.2, 1)

        helpButton:SetScript("OnClick", function()
            if self.callbacks.onHelp then
                self.callbacks.onHelp(self.helpModules)
            end
        end)

        self.helpButton = helpButton

        self.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.titleText:SetPoint("LEFT", sideToggleButton, "RIGHT", 8, 0)
        self.titleText:SetPoint("RIGHT", helpButton, "LEFT", -8, 0)
        self.titleText:SetPoint("TOP", titleBg, "TOP", 0, -8)
        self.titleText:SetJustifyH("LEFT")

        self.scrollFrame, self.contentFrame, self.scrollBar = createScrollArea(
            f,
            560,
            18,
            -45,
            -28,
            45
        )

        self:_CreateSidePanel()

        self.moduleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.moduleText:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
        self.moduleText:SetTextColor(0.6, 0.6, 0.7, 1)

        self.prevButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        self.prevButton:SetSize(110, 24)
        self.prevButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 8)
        self.prevButton:SetText("<  Назад")
        self.prevButton:SetScript("OnClick", function()
            if self.callbacks.onPrev then
                self.callbacks.onPrev()
            end
        end)

        self.nextButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        self.nextButton:SetSize(110, 24)
        self.nextButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 8)
        self.nextButton:SetText("Вперед  >")
        self.nextButton:SetScript("OnClick", function()
            if self.currentModuleIndex then
                self:MarkModuleReadIfInfo(self.currentModuleIndex)
            end
            if self.callbacks.onNext then
                self.callbacks.onNext()
            end
        end)

        local scaleButton = CreateFrame("Button", nil, f)
        scaleButton:SetSize(18, 18)
        scaleButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
        scaleButton:SetFrameLevel(f:GetFrameLevel() + 10)
        scaleButton:EnableMouse(true)

        local scaleTexture = scaleButton:CreateTexture(nil, "ARTWORK")
        scaleTexture:SetAllPoints(scaleButton)
        scaleTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

        scaleButton:SetScript("OnEnter", function()
            scaleTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end)
        scaleButton:SetScript("OnLeave", function()
            scaleTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        end)

        scaleButton:RegisterForDrag("LeftButton")
        scaleButton:SetScript("OnDragStart", function()
            self.isScaling = true
            self.scaleStartScale = f:GetScale() or 1
            self.scaleStartX, self.scaleStartY = GetCursorPosition()
        end)
        scaleButton:SetScript("OnDragStop", function()
            self.isScaling = false
            self:SaveState()
        end)

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)
        f:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            self:SaveState()
        end)

        f:SetScript("OnUpdate", function()
            if self.layoutDirty then
                self.layoutDirty = false
                self:Layout()
            end
            if self.isScaling then
                local mx, my = GetCursorPosition()
                local dx = mx - self.scaleStartX
                local dy = my - self.scaleStartY
                local newScale = self.scaleStartScale + (dx - dy) / 1000
                newScale = math.max(0.75, math.min(2.0, newScale))
                local currentScale = f:GetScale() or 1
                if math.abs(newScale - currentScale) > 0.001 then
                    f:SetScale(newScale)
                end
            end

            local isOver = f:IsMouseOver()
            if isOver and not self._mainMouseOver then
                self._mainMouseOver = true
                f:SetFrameStrata("FULLSCREEN")
            elseif not isOver and self._mainMouseOver then
                self._mainMouseOver = false
                f:SetFrameStrata("HIGH")
            end
        end)

        f:SetScript("OnShow", function()
            if not self.stateLoaded then
                self.stateLoaded = true
                self:LoadState()
            end
            self.layoutDirty = true
        end)

        self:_ApplySidePanelLayout()
        self:LoadState()

        f:SetScript("OnHide", function()
            self.isScaling = false
            self:SaveState()
        end)
        f:Hide()
    end

    -- ========================================================================
    -- Окно справки
    -- ========================================================================
    function UI:_CreateHelp()
        if self.helpFrame then return end

        local f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(700, 580)
        f:SetPoint("CENTER", 40, 0)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("DIALOG")
        addBackgroundBorder(f)

        local titleBg = f:CreateTexture(nil, "ARTWORK")
        titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        titleBg:SetHeight(30)
        titleBg:SetTexture(0.15, 0.15, 0.20, 1)

        local titleSeparator = f:CreateTexture(nil, "ARTWORK")
        titleSeparator:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)
        titleSeparator:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
        titleSeparator:SetHeight(2)
        titleSeparator:SetTexture(0.30, 0.30, 0.50, 1)

        local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            f:Hide()
        end)

        local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("LEFT", f, "LEFT", 15, 0)
        titleText:SetPoint("RIGHT", closeButton, "LEFT", -8, 0)
        titleText:SetPoint("TOP", titleBg, "TOP", 0, -5)
        titleText:SetText("Справка")

        self.helpScroll, self.helpContent, self.helpBar = createScrollArea(
            f,
            650,
            15,
            -40,
            -25,
            15
        )

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)
        f:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
        end)

        f:SetScript("OnUpdate", function(frame)
            local isOver = frame:IsMouseOver()
            if isOver and not self._helpMouseOver then
                self._helpMouseOver = true
                frame:SetFrameStrata("FULLSCREEN")
            elseif not isOver and self._helpMouseOver then
                self._helpMouseOver = false
                frame:SetFrameStrata("DIALOG")
            end

            if self._helpLayoutDirty then
                self._helpLayoutDirty = false
                self:LayoutHelp()
            end
        end)

        self.helpFrame = f
        f:Hide()
    end

    -- ========================================================================
    -- Публичные методы окна
    -- ========================================================================
    function UI:SetCallbacks(callbacks)
        self.callbacks = callbacks or {}
    end

    function UI:Show()
        self.frame:Show()
    end

    function UI:Hide()
        self:HideHelp()
        self:HideCodeViewer()
        self.frame:Hide()
    end

    function UI:IsShown()
        return self.frame:IsShown()
    end

    function UI:HideHelp()
        if self.helpFrame then
            self.helpFrame:Hide()
        end
    end

    function UI:SetTitle(text)
        self.titleText:SetText(text or "")
    end

    function UI:SetPrevEnabled(enabled)
        setButtonEnabled(self.prevButton, enabled)
    end

    function UI:SetNextEnabled(enabled)
        setButtonEnabled(self.nextButton, enabled)
    end

    function UI:SetHelpData(helpModules)
        self.helpModules = (type(helpModules) == "table" and #helpModules > 0) and helpModules or nil
        setButtonEnabled(self.helpButton, self.helpModules ~= nil)
    end

    -- ========================================================================
    -- Лейаут
    -- ========================================================================
    function UI:Layout()
        if not self.contentFrame then
            return
        end

        layoutBlocks(self.blocks, self.contentFrame, self.scrollFrame, self.scrollBar)

        if self.pendingScrollValue then
            local maxScroll = select(2, self.scrollBar:GetMinMaxValues()) or 0
            local value = math.max(0, math.min(self.pendingScrollValue, maxScroll))
            self.scrollBar:SetValue(value)
            self.pendingScrollValue = nil
        end
    end

    function UI:LayoutHelp()
        if not self.helpContent then
            return
        end

        layoutBlocks(self.helpBlocks, self.helpContent, self.helpScroll, self.helpBar)
    end

    -- ========================================================================
    -- Рендер основного контента
    -- ========================================================================
    function UI:Render(blocks, resetScrollToTop)
        if resetScrollToTop == nil then
            resetScrollToTop = true
        end

        if self.editors then
            for _, editor in pairs(self.editors) do
                if editor._editBox then
                    editor._editBox:ClearFocus()
                end
            end
        end

        clearBlocks(self.blocks)

        self.blocks = {}
        self.editors = {}

        for _, data in ipairs(blocks or {}) do
            local block

            if data.type == "code" then
                block = createCodeBlock(self.contentFrame, data.content or "")
            elseif data.type == "editor" then
                block = createEditorBlock(self.contentFrame, data, self)
                self.editors[block._name] = block
            else
                block = createTextBlock(self.contentFrame, data.content or "")
            end

            table.insert(self.blocks, block)
        end

        self:Layout()

        if resetScrollToTop then
            resetScroll(self.scrollFrame, self.contentFrame, self.scrollBar)
            self.pendingScrollValue = nil
        end

        self.layoutDirty = true
    end

    function UI:RenderHelp(raw)
        clearBlocks(self.helpBlocks)
        self.helpBlocks = {}
        for _, data in ipairs(parseContent(raw)) do
            local block
            if data.type == "code" then
                block = createCodeBlock(self.helpContent, data.content or "")
            else
                block = createTextBlock(self.helpContent, data.content or "")
            end
            table.insert(self.helpBlocks, block)
        end
        self:LayoutHelp()
        resetScroll(self.helpScroll, self.helpContent, self.helpBar)

        self._helpLayoutDirty = true
    end

    -- ========================================================================
    -- Типы модулей
    -- ========================================================================
    function UI:_IsPracticeType(moduleType)
        moduleType = moduleType and tostring(moduleType):match("^%s*(.-)%s*$") or ""

        return moduleType == "vartest"
            or moduleType == "printtest"
            or moduleType == "customtest"
            or moduleType == "commenttest"
    end

    function UI:_IsModuleInfo(moduleOrType)
        local moduleType = moduleOrType

        if type(moduleOrType) == "table" then
            moduleType = moduleOrType.type
        end

        return not self:_IsPracticeType(moduleType)
    end

    -- ========================================================================
    -- Данные модулей и заданий
    -- ========================================================================
    function UI:_GetModuleById(index)
        local db = ns_llua and ns_llua['lua'] or {}
        return db[index]
    end

    function UI:_GetTaskDetails(index)
        local saved = nsDbc4
            and nsDbc4.course
            and nsDbc4.course.logic
            and nsDbc4.course.logic.taskDetails

        if type(saved) ~= "table" then
            return {}
        end

        local details = saved[index]

        if details == nil then
            details = saved[tostring(index)]
        end

        if details == nil then
            details = saved[tonumber(index)]
        end

        return type(details) == "table" and details or {}
    end

    function UI:_IsModuleDoneByTaskDetails(index)
        local m = self:_GetModuleById(index)

        if type(m) ~= "table" then
            return false
        end

        local details = self:_GetTaskDetails(index)
        local mtype = m.type and tostring(m.type):match("^%s*(.-)%s*$") or ""

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

            if mtype == "vartest" and m.formatTask and details.formatDone ~= true then
                return false
            end

            return true
        end

        return details.read == true or details.completed == true
    end

    function UI:_IsModuleDone(index)
        index = tonumber(index)

        if not index then
            return false
        end

        if type(self.completedChecker) == "function" then
            local ok, done = pcall(self.completedChecker, index)

            if ok and done then
                return true
            end
        end

        if self.callbacks and type(self.callbacks.isModuleCompleted) == "function" then
            local ok, done = pcall(self.callbacks.isModuleCompleted, index)

            if ok and done then
                return true
            end
        end

        if self:_IsModuleDoneByTaskDetails(index) then
            return true
        end

        local state = self.moduleStates and self.moduleStates[index]

        if type(state) == "table" then
            if state.completed then
                return true
            end

            if self:_IsModuleInfo(self:_GetModuleById(index)) and state.read then
                return true
            end
        end

        return false
    end

    function UI:SetCompletedChecker(fn)
        if type(fn) == "function" then
            self.completedChecker = fn
        else
            self.completedChecker = nil
        end

        self:RefreshSidePanel()
    end

    function UI:SetModuleState(index, state)
        index = tonumber(index)

        if not index or type(state) ~= "table" then
            return
        end

        self.moduleStates = self.moduleStates or {}
        self.moduleStates[index] = self.moduleStates[index] or {}

        if state.completed ~= nil then
            self.moduleStates[index].completed = state.completed and true or false
        end

        if state.read ~= nil then
            self.moduleStates[index].read = state.read and true or false
        end

        nsDbc4.course.logic.taskDetails = nsDbc4.course.logic.taskDetails or {}
        nsDbc4.course.logic.taskDetails[index] = nsDbc4.course.logic.taskDetails[index] or {}

        if state.read ~= nil then
            nsDbc4.course.logic.taskDetails[index].read = state.read and true or false
        end

        if state.completed ~= nil then
            nsDbc4.course.logic.taskDetails[index].completed = state.completed and true or false
        end

        self:RefreshSidePanel()
        self:SaveState()
    end

    function UI:SetModuleCompleted(index, completed)
        self:SetModuleState(index, {
            completed = completed ~= false,
        })
    end

    function UI:MarkModuleRead(index)
        self:SetModuleState(index, {
            read = true,
        })
    end

    function UI:MarkModuleReadIfInfo(index)
        index = tonumber(index)

        if not index then
            return
        end

        local m = self:_GetModuleById(index)

        local moduleType = self.currentModuleType

        if moduleType == nil and type(m) == "table" then
            moduleType = m.type
        end

        if self:_IsPracticeType(moduleType) then
            return
        end

        if type(m) ~= "table" and moduleType == nil then
            return
        end

        self:MarkModuleRead(index)
    end

    -- ========================================================================
    -- Список модулей
    -- ========================================================================
    function UI:_GetSortedModuleIndices()
        local db = ns_llua and ns_llua["lua"] or {}
        local indices = {}

        for k in pairs(db) do
            if type(k) == "number" then
                table.insert(indices, k)
            end
        end

        table.sort(indices)

        return indices
    end

    function UI:_GetModulePosition(index, indices)
        index = tonumber(index)

        if not index then
            return nil
        end

        indices = indices or self:_GetSortedModuleIndices()

        for pos, idx in ipairs(indices) do
            if idx == index then
                return pos
            end
        end

        return nil
    end

    function UI:_GetFirstIncompleteModuleIndex(indices)
        indices = indices or self:_GetSortedModuleIndices()

        for _, idx in ipairs(indices) do
            if not self:_IsModuleDoneOrSkipped(idx) then
                return idx
            end
        end

        return nil
    end

    function UI:CanSelectModule(index, indices, firstIncomplete)
        index = tonumber(index)

        if not index then
            return false
        end

        local db = ns_llua and ns_llua["lua"] or {}

        if db[index] == nil then
            return false
        end

        local current = tonumber(self.currentModuleIndex)

        if current == nil then
            return true
        end

        if index == current then
            return true
        end

        indices = indices or self:_GetSortedModuleIndices()
        firstIncomplete = firstIncomplete or self:_GetFirstIncompleteModuleIndex(indices)

        local currentPos = self:_GetModulePosition(current, indices)
        local targetPos = self:_GetModulePosition(index, indices)

        if not currentPos or not targetPos then
            if index < current then
                if self:_IsModuleDoneOrSkipped(index) then
                    return true
                end

                return index == firstIncomplete
            end

            if not self:_IsModuleDoneOrSkipped(current) then
                return false
            end

            return self:_IsModuleDoneOrSkipped(index)
        end

        if targetPos < currentPos then
            if self:_IsModuleDoneOrSkipped(index) then
                return true
            end

            return index == firstIncomplete
        end

        if not self:_IsModuleDoneOrSkipped(current) then
            return false
        end

        for pos = currentPos + 1, targetPos do
            if not self:_IsModuleDoneOrSkipped(indices[pos]) then
                return false
            end
        end

        return true
    end

    function UI:RefreshSidePanel()
        if not self.sidePanel or not self.sideContent then
            return
        end

        self.moduleStates = self.moduleStates or {}

        clearBlocks(self.sideRows)
        self.sideRows = {}

        local db = ns_llua and ns_llua["lua"] or {}
        local indices = self:_GetSortedModuleIndices()
        local firstIncomplete = self:_GetFirstIncompleteModuleIndex(indices)
        local currentIndex = tonumber(self.currentModuleIndex)

        local width = math.max(
            10,
            self.sideContent:GetWidth() or ((self.sidePanelWidth or 180) - 40)
        )

        local y = -2
        local contentLevel = self.sideContent:GetFrameLevel() or 0

        for _, idx in ipairs(indices) do
            local m = db[idx] or {}
            local isInfo = self:_IsModuleInfo(m)
            local done = self:_IsModuleDone(idx)
            local skipped = self:_IsModuleSkipped(idx)
            local allowed = self:CanSelectModule(idx, indices, firstIncomplete)

            local button = CreateFrame("Button", nil, self.sideContent)
            button:EnableMouse(true)
            button:RegisterForClicks("LeftButtonUp")
            button:RegisterForDrag("LeftButton")

            button:SetScript("OnDragStart", function() end)
            button:SetScript("OnDragStop", function() end)

            button:SetHeight(20)
            button:SetWidth(width)
            button:SetPoint("TOPLEFT", self.sideContent, "TOPLEFT", 0, y)
            button:SetFrameLevel(contentLevel + 5)
            button:SetAlpha(allowed and 1.0 or 0.55)

            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(button)

            if currentIndex == idx then
                bg:SetTexture(0.20, 0.28, 0.45, 0.90)
            else
                bg:SetTexture(0.10, 0.11, 0.16, 0.60)
            end

            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(button)
            highlight:SetTexture(0.30, 0.35, 0.55, 0.35)

            local fs = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("LEFT", button, "LEFT", 8, 0)
            fs:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            fs:SetJustifyH("LEFT")
            fs:SetJustifyV("MIDDLE")

            local title = tostring(m.title or ("Модуль " .. idx))

            title = (title:gsub("<[^>]+>", ""))
            title = (title:gsub("\n", " "))
            title = (title:gsub("\r", " "))

            local prefix = (currentIndex == idx and "> " or "")

            local textColor

            if done then
                textColor = "|cFF00FF00"
            elseif skipped then
                textColor = "|cFFFFD700"
            elseif not allowed then
                textColor = "|cFF555555"
            else
                textColor = "|cFF999999"
            end

            fs:SetText(textColor .. prefix .. idx .. ". " .. escapePipes(title) .. "|r")

            local statusText
            local statusR, statusG, statusB

            if done then
                statusText = "Пройден"
                statusR, statusG, statusB = 0.2, 1.0, 0.2
            elseif skipped then
                statusText = "Пропущен"
                statusR, statusG, statusB = 1.0, 0.85, 0.0
            elseif not allowed then
                statusText = "Недоступен"
                statusR, statusG, statusB = 0.80, 0.35, 0.35
            elseif isInfo then
                statusText = "Не прочитан"
                statusR, statusG, statusB = 0.7, 0.7, 0.7
            else
                statusText = "Не пройден"
                statusR, statusG, statusB = 0.7, 0.7, 0.7
            end

            button:SetScript("OnEnter", function()
                if not GameTooltip then
                    return
                end

                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(escapePipes(title), 1, 1, 1, true)
                GameTooltip:AddLine(statusText, statusR, statusG, statusB, true)

                if skipped then
                    GameTooltip:AddLine("Модуль помечен как пропущенный.", 0.80, 0.70, 0.20, true)
                end

                if allowed then
                    GameTooltip:AddLine("ЛКМ — открыть", 0.6, 0.6, 0.6, true)
                else
                    GameTooltip:AddLine("Модуль пока недоступен", 0.65, 0.35, 0.35, true)
                end

                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function()
                if GameTooltip then
                    GameTooltip:Hide()
                end
            end)

            button:SetScript("OnClick", function()
                if not self:CanSelectModule(idx) then
                    return
                end

                if self.callbacks and type(self.callbacks.onSelectModule) == "function" then
                    self.callbacks.onSelectModule(idx)
                else
                    self.currentModuleIndex = idx
                    self:RefreshSidePanel()
                end
            end)

            table.insert(self.sideRows, button)

            y = y - 22
        end

        self.sideContent:SetHeight(math.max(100, -y + 4))
        updateScroll(self.sideScroll, self.sideContent, self.sideBar)
    end

    function UI:SetModuleInfo(index, total, position)
        local indexText = tostring(index or "?")
        local totalText = tostring(total or "?")
        local positionNumber = tonumber(position)

        if positionNumber and positionNumber > 0 then
            self.moduleText:SetText(string.format(
                "Модуль %s(%d) из %s",
                indexText,
                positionNumber,
                totalText
            ))
        else
            self.moduleText:SetText(string.format(
                "Модуль %s из %s",
                indexText,
                totalText
            ))
        end
    end

    function UI:SetModuleContent(data)
        data = data or {}

        self:HideHelp()

        local moduleIndex = tonumber(data.index) or data.index

        local sameModule = self.currentModuleIndex ~= nil
            and self.currentModuleIndex == moduleIndex
            and self.frame
            and self.frame:IsShown()

        if sameModule and self.scrollBar then
            self.pendingScrollValue = self.scrollBar:GetValue()
        else
            self.pendingScrollValue = nil
        end

        self.currentModuleIndex = moduleIndex

        local moduleType = data.moduleType

        if moduleType == nil and moduleIndex ~= nil then
            local db = ns_llua and ns_llua['lua'] or {}
            local m = db[moduleIndex]

            if type(m) == "table" then
                moduleType = m.type
            end
        end

        self.currentModuleType = moduleType

        self:SetTitle(data.title)
        self:SetModuleInfo(data.index, data.total, data.position)
        self:SetPrevEnabled(data.prevEnabled)
        self:SetNextEnabled(data.nextEnabled)
        self:SetHelpData(data.helpModules)

        if data.rawContent then
            self:Render(parseContent(data.rawContent), not sameModule)
        else
            self:Render(data.blocks, not sameModule)
        end

        if self.RefreshSidePanel then
            self:RefreshSidePanel()
        end

        self:Show()
    end

    -- ========================================================================
    -- Окно справки (данные)
    -- ========================================================================
    function UI:ShowHelp(helpModules)
        if type(helpModules) ~= "table" or #helpModules == 0 then
            return
        end

        self:_CreateHelp()

        local db = ns_llua and ns_llua['lua'] or {}

        local keyParts = {}
        local helpTexts = {}
        local seen = {}

        local function resolveModule(id)
            if id == nil then
                return nil, nil
            end

            if type(id) == "number" then
                if db[id] ~= nil then
                    return db[id], id
                end
            end

            local num = tonumber(id)
            if num ~= nil and db[num] ~= nil then
                return db[num], num
            end

            if db[id] ~= nil then
                return db[id], id
            end

            return nil, id
        end

        local function getHelpText(module)
            if type(module) ~= "table" then
                return ""
            end

            local text = module.content

            if type(text) ~= "string" or text == "" then
                text = module.instruction
            end

            if type(text) ~= "string" or text == "" then
                if type(module.title) == "string" and module.title ~= "" then
                    text = "<h>" .. module.title .. "</h>"
                else
                    text = ""
                end
            end

            return text
        end

        for _, moduleId in ipairs(helpModules) do
            local module, resolvedId = resolveModule(moduleId)
            local key = tostring(resolvedId ~= nil and resolvedId or moduleId)

            table.insert(keyParts, key)

            if module and not seen[key] then
                local text = getHelpText(module)

                if text ~= "" then
                    seen[key] = true
                    table.insert(helpTexts, text)
                end
            end
        end

        local key = table.concat(keyParts, ",")

        if self.helpFrame:IsShown() and self.helpKey == key then
            self.helpFrame:Hide()
            return
        end

        self.helpKey = key

        local raw = table.concat(
            helpTexts,
            "\n<c>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</c>\n"
        )

        if raw == "" then
            self.helpFrame:Hide()
            return
        end

        self:RenderHelp(raw)
        self.helpFrame:Show()
    end

    -- ========================================================================
    -- Редакторы
    -- ========================================================================
    function UI:GetEditor(name)
        if not self.editors then
            return nil
        end

        return self.editors[name]
    end

    function UI:GetEditorText(name)
        local editor = self:GetEditor(name)

        if not editor or not editor._editBox then
            return ""
        end

        return editor._editBox:GetText() or ""
    end

    function UI:SetEditorText(name, code)
        local editor = self:GetEditor(name)
        if not editor or not editor._editBox then
            return
        end

        code = code ~= nil and tostring(code) or ""

        local valid = not GetEditorTooLongLine(code)

        editor._settingText = true
        editor._editBox:SetText(code)
        editor._settingText = false

        editor._preview:SetText(markupCode(code))

        if valid then
            editor._lastValidText = code
        else
            editor._lastValidText = nil
        end

        if editor._updateCharCount then
            editor._updateCharCount()
        end

        self.layoutDirty = true
    end

    function UI:ClearEditorResult(name)
        local editor = self:GetEditor(name)

        if not editor then
            return
        end

        editor._resultMessage:SetText("")
        editor._expectedLabel:SetText("")
        editor._expectedText:SetText("")
        editor._currentLabel:SetText("")
        editor._currentText:SetText("")

        self.layoutDirty = true
    end

    function UI:SetEditorButtonEnabled(name, enabled)
        local editor = self:GetEditor(name)

        if not editor or not editor._button then
            return
        end

        setButtonEnabled(editor._button, enabled)
    end

    function UI:SetEditorResult(name, result)
        local editor = self:GetEditor(name)

        if not editor then
            return
        end

        result = result or {}

        local status = result.status or "info"
        local color = "|cFFFFFFFF"

        if status == "success" then
            color = "|cFF00FF00"
        elseif status == "error" then
            color = "|cFFFF8080"
        elseif status == "diff" then
            color = "|cFFFFB830"
        end

        local message = result.message ~= nil and tostring(result.message) or ""
        local expected = result.expected ~= nil and tostring(result.expected) or ""
        local current = result.current ~= nil and tostring(result.current) or ""

        if message ~= "" then
            editor._resultMessage:SetText(color .. escapePipes(message) .. "|r")
        else
            editor._resultMessage:SetText("")
        end

        if expected ~= "" then
            editor._expectedLabel:SetText("|cFFFFD700Ожидаемый результат:|r")
            editor._expectedText:SetText(markupPlain(expected))
        else
            editor._expectedLabel:SetText("")
            editor._expectedText:SetText("")
        end

        if current ~= "" then
            if result.footerSuccess then
                editor._currentLabel:SetText("|cFFFFD700Результат выполнения:|r")
                editor._currentText:SetText(
                    "|cFFFFFFFF" .. escapePipes(current) .. "|r\n|cFF00FF00Задание выполнено!|r"
                )
            else
                editor._currentLabel:SetText("|cFFFFD700Текущий результат:|r")
                editor._currentText:SetText(markupPlain(current))
            end
        else
            if result.footerSuccess then
                editor._currentLabel:SetText("")
                editor._currentText:SetText("|cFF00FF00Задание выполнено!|r")
            else
                editor._currentLabel:SetText("")
                editor._currentText:SetText("")
            end
        end

        self.layoutDirty = true
    end

    function UI:SetEditorResultsButtonEnabled(name, enabled)
        local editor = self:GetEditor(name)

        if not editor or not editor._resultsButton then
            return
        end

        setButtonEnabled(editor._resultsButton, enabled)
    end

    -- ========================================================================
    -- Окно результатов других игроков
    -- ========================================================================
    function UI:_CreateCodeViewer()
        if self.codeViewerFrame then
            return
        end
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(720, 580)
        f:SetPoint("CENTER", -40, 0)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("DIALOG")
        addBackgroundBorder(f)

        local titleBg = f:CreateTexture(nil, "ARTWORK")
        titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        titleBg:SetHeight(30)
        titleBg:SetTexture(0.15, 0.15, 0.20, 1)

        local titleSeparator = f:CreateTexture(nil, "ARTWORK")
        titleSeparator:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, 0)
        titleSeparator:SetPoint("TOPRIGHT", titleBg, "BOTTOMRIGHT", 0, 0)
        titleSeparator:SetHeight(2)
        titleSeparator:SetTexture(0.30, 0.30, 0.50, 1)

        local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function()
            self:HideCodeViewer()
        end)

        local titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("LEFT", f, "LEFT", 15, 0)
        titleText:SetPoint("RIGHT", closeButton, "LEFT", -8, 0)
        titleText:SetPoint("TOP", titleBg, "TOP", 0, -5)
        titleText:SetText("Результаты других игроков")
        self.codeViewerTitle = titleText

        self.codeViewerScroll, self.codeViewerContent, self.codeViewerBar = createScrollArea(
            f,
            680,
            15,
            -40,
            -25,
            15
        )

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)
        f:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
        end)

        f:SetScript("OnUpdate", function(frame)
            local isOver = frame:IsMouseOver()
            if isOver and not self._codeViewerMouseOver then
                self._codeViewerMouseOver = true
                frame:SetFrameStrata("FULLSCREEN")
            elseif not isOver and self._codeViewerMouseOver then
                self._codeViewerMouseOver = false
                frame:SetFrameStrata("DIALOG")
            end
        end)

        self.codeViewerFrame = f
        self.codeViewerBlocks = {}

        if self.frame and self.frame.HookScript then
            self.frame:HookScript("OnHide", function()
                self:HideCodeViewer()
            end)
        end

        f:Hide()
    end

    function UI:HideCodeViewer()
        if self.codeViewerFrame then
            self.codeViewerFrame:Hide()
        end
    end

    function UI:ShowCodeViewer(moduleId)
        self:_CreateCodeViewer()

        self.codeViewerModule = tonumber(moduleId)

        if self.codeViewerTitle then
            self.codeViewerTitle:SetText(
                "Результаты других игроков: модуль " .. tostring(moduleId)
            )
        end

        self.codeViewerFrame:Show()
        self:RefreshCodeViewer()
    end

    function UI:RefreshCodeViewer()
        if not self.codeViewerFrame then
            return
        end

        if not self.codeViewerFrame:IsShown() then
            return
        end

        if not self.codeViewerModule then
            return
        end

        self.codeViewerBlocks = self.codeViewerBlocks or {}

        clearBlocks(self.codeViewerBlocks)
        self.codeViewerBlocks = {}

        local moduleData = nsCodeViewerData and nsCodeViewerData[self.codeViewerModule]
        local hasContent = false

        if type(moduleData) ~= "table" or next(moduleData) == nil then
            table.insert(
                self.codeViewerBlocks,
                createTextBlock(self.codeViewerContent, "<t>Ожидание ответов от сервера...</t>")
            )
        else
            local owners = {}

            for owner in pairs(moduleData) do
                table.insert(owners, owner)
            end

            table.sort(owners, function(a, b)
                return tostring(a):lower() < tostring(b):lower()
            end)

            for _, owner in ipairs(owners) do
                local ownerData = moduleData[owner]

                local variants = {}

                if type(ownerData) == "table" then
                    if type(ownerData.lines) == "table" then
                        variants["1"] = ownerData
                    else
                        variants = ownerData
                    end
                end

                local variantKeys = {}

                for k in pairs(variants) do
                    table.insert(variantKeys, k)
                end

                table.sort(variantKeys, function(a, b)
                    local na = tonumber(a)
                    local nb = tonumber(b)

                    if na and nb then
                        return na < nb
                    end

                    return tostring(a) < tostring(b)
                end)

                if #variantKeys > 0 then
                    hasContent = true
                end

                for _, variantKey in ipairs(variantKeys) do
                    local entry = variants[variantKey]
                    local lines = entry and entry.lines or {}
                    local code = table.concat(lines, "\n")

                    local safeOwner = tostring(owner):gsub("<", "")

                    table.insert(
                        self.codeViewerBlocks,
                        createTextBlock(
                            self.codeViewerContent,
                            "<h>Игрок: " .. safeOwner .. " | Вариант " .. tostring(variantKey) .. "</h>"
                        )
                    )

                    if code == "" then
                        table.insert(
                            self.codeViewerBlocks,
                            createTextBlock(self.codeViewerContent, "<t>Код пуст.</t>")
                        )
                    else
                        table.insert(
                            self.codeViewerBlocks,
                            createCodeBlock(self.codeViewerContent, code)
                        )
                    end
                end
            end

            if not hasContent then
                table.insert(
                    self.codeViewerBlocks,
                    createTextBlock(self.codeViewerContent, "<t>Нет данных.</t>")
                )
            end
        end

        layoutBlocks(
            self.codeViewerBlocks,
            self.codeViewerContent,
            self.codeViewerScroll,
            self.codeViewerBar
        )

        resetScroll(
            self.codeViewerScroll,
            self.codeViewerContent,
            self.codeViewerBar
        )
    end

    -- ========================================================================
    -- Публикация класса
    -- ========================================================================
    NSQC4.Course.UI = UI
    NSQC4.Course.parseContent = parseContent
    NSQC4.Course.StripLuaComments = StripLuaComments
end)