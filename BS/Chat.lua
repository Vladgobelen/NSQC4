-- ============================================================================
-- NSQC4 / BS / Chat
-- Команда "-илвл [Ник]" в гильд-чате. Модуль "bs_chat".
-- ============================================================================

NSQC4.RegisterModule("bs_chat", function()

    -- ========================================================================
    -- Обработчик
    -- ========================================================================
    local function OnGuildMessage(words, sender, text, channel, prefix)
        local lower = text:lower()
        if not lower:find("^-илвл", 1, false) then return end

        local targetNick = words[2]
        local myName = UnitName("player")

        if targetNick and targetNick ~= "" then
            targetNick = targetNick:match("^([^%-]+)") or targetNick
            if targetNick ~= myName then return end
        else
            if sender ~= myName then return end
        end

        -- Проверяем доступность ChatHandler и модуля БС игрока
        if not NSQC4.ChatHandler then
            -- Некуда отвечать, ChatHandler не загружен
            return
        end

        if not NSQC4.BS or not NSQC4.BS.GetPlayerScoreLine then
            SendChatMessage(myName .. " — БС-модуль игрока выключен.", "OFFICER")
            return
        end

        local line = NSQC4.BS.GetPlayerScoreLine("player")
        SendChatMessage(myName .. " — " .. line, "OFFICER")
    end

    -- ========================================================================
    -- Регистрация
    -- ========================================================================
    if not NSQC4.ChatHandler then return end

    NSQC4.ChatHandler:Register("GUILD:-илвл", {
        func = OnGuildMessage,
        stopOnMatch = true,
    })

end)