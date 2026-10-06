-- ============================================================================
-- NSQC4 / Course / CodeShare
-- Приём ответов от других игроков по обмену кодом.
-- Публикует NSQC4.Course.nsModuleCode.
-- Регистрация триггера — в Course/Triggers.lua.
-- ============================================================================

NSQC4.RegisterModule("course", function()

    NSQC4.Course = NSQC4.Course or {}

    nsCodeViewerData = nsCodeViewerData or {}
    nsCodeViewerRequest = nsCodeViewerRequest or {}

    local function nsModuleCode(channel, text, sender, prefix)
        local tokens = {}

        for token in tostring(prefix or ""):gmatch("%S+") do
            table.insert(tokens, token)
        end

        if tokens[1] ~= "nsModuleCode" then
            return
        end

        local requester = tokens[2]
        local owner = tokens[3]
        local moduleId = tonumber(tokens[4])
        local variantKey = tostring(tokens[5] or "1")
        local lineIndex = tonumber(tokens[6])
        local lineCount = tonumber(tokens[7])

        if not requester or not owner or not moduleId then
            return
        end

        local me = (type(UnitName) == "function") and UnitName("player") or ""

        if requester ~= me then
            return
        end

        if type(nsCodeViewerRequest[moduleId]) ~= "table" then
            return
        end

        local line = tostring(text or "")

        nsCodeViewerData[moduleId] = nsCodeViewerData[moduleId] or {}
        nsCodeViewerData[moduleId][owner] = nsCodeViewerData[moduleId][owner] or {}

        local entry = nsCodeViewerData[moduleId][owner][variantKey]

        if type(entry) ~= "table" then
            entry = {
                raw = {},
                lines = {},
            }

            nsCodeViewerData[moduleId][owner][variantKey] = entry
        end

        entry.raw = entry.raw or {}
        entry.lines = entry.lines or {}

        if lineIndex ~= nil then
            if line ~= "" then
                entry.raw[lineIndex] = line
            end

            if lineCount ~= nil then
                entry.lineCount = lineCount
            end

            local lines = {}
            local i = 1

            while entry.raw[i] ~= nil and (entry.lineCount == nil or i <= entry.lineCount) do
                lines[i] = entry.raw[i]
                i = i + 1
            end

            entry.lines = lines
        else
            if line ~= "" then
                table.insert(entry.lines, line)
            end
        end

        local courseLogic = NSQC4.Course and NSQC4.Course.logic
        local ui = (courseLogic and courseLogic.ui) or NSQC4.Course.ui

        if ui and ui.RefreshCodeViewer then
            ui:RefreshCodeViewer()
        end
    end

    NSQC4.Course.nsModuleCode = nsModuleCode
end)