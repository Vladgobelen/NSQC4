-- ============================================================================
-- NSQC4 / WIMGuard
-- Защита от падения Blizzard при вызове ChatFrame_OpenChat, когда
-- активен WIM-евский едитбокс (у него нет поля chatFrame).
-- ============================================================================

NSQC4.RegisterModule("wim_guard", function()

    local function PatchWIMFrames()
        local patched = 0
        for name, obj in pairs(_G) do
            if type(name) == "string" 
               and name:match("^WIM%d*_msgFrame%d+") 
               and obj 
               and obj.GetObjectType 
               and obj:GetObjectType() == "EditBox" 
            then
                if obj.chatFrame == nil then
                    obj.chatFrame = ChatFrame1
                    patched = patched + 1
                end
            end
        end
        if patched > 0 then
            print("|cff00ff00[NSQC4]|r WIMGuard: пропатчено едитбоксов WIM: " .. patched)
        end
    end

    -- 1. Патчим фреймы через 3 секунды после входа (когда WIM их создаст)
    local login = CreateFrame("Frame")
    login:RegisterEvent("PLAYER_LOGIN")
    login:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        local t = CreateFrame("Frame")
        local e = 0
        t:SetScript("OnUpdate", function(self2, dt)
            e = e + dt
            if e >= 3 then
                self2:SetScript("OnUpdate", nil)
                PatchWIMFrames()
            end
        end)
    end)

    -- 2. Глобальный хук: если Blizzard пытается активировать WIM-едитбокс, 
    --    подменяем его на стандартный.
    if not NSQC4._wimGuardHooked then
        NSQC4._wimGuardHooked = true
        local orig = ChatEdit_SetLastActiveWindow
        ChatEdit_SetLastActiveWindow = function(editBox)
            if editBox and editBox.GetName then
                local n = editBox:GetName() or ""
                if n:match("^WIM%d*_msgFrame%d+") then
                    editBox = ChatFrame1EditBox
                end
            end
            if not editBox then editBox = ChatFrame1EditBox end
            return orig(editBox)
        end
    end

    NSQC4.SetModuleMeta("wim_guard", {
        label   = "Защита WIM",
        tooltip = "Предотвращает ошибку 'attempt to index field chatFrame' при использовании WIM.",
        order   = 310,
    })
end)