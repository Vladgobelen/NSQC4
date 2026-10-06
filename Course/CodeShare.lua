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
        -- text = "requester|owner|moduleId|variantKey|lineIndex|lineCount|line"

        local requester, owner, moduleIdStr, variantKey, lineIndexStr, lineCountStr, line =
            text:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")

        if not requester then
            return
        end

        local moduleId = tonumber(moduleIdStr)
        local lineIndex = tonumber(lineIndexStr)
        local lineCount = tonumber(lineCountStr)
        local me = UnitName("player") or ""

        if requester ~= me then
            return
        end

        if type(nsCodeViewerRequest[moduleId]) ~= "table" then
            return
        end

        nsCodeViewerData[moduleId] = nsCodeViewerData[moduleId] or {}
        nsCodeViewerData[moduleId][owner] = nsCodeViewerData[moduleId][owner] or {}

        local entry = nsCodeViewerData[moduleId][owner][variantKey]

        if type(entry) ~= "table" then
            entry = { raw = {}, lines = {} }
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