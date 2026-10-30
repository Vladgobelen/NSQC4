NSQC4.RegisterModule("nowim", function()
    local UI = NSQC4.Nowim.UI
    UI.ChatView = UI.ChatView or {}
    local V = UI.ChatView
    local parent = UI.Content

    -- Создаем ScrollFrame
    local scroll = CreateFrame("ScrollFrame", "NSQC4_NowimChatScroll", parent)
    V.Scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(300, 1)
    scroll:SetScrollChild(content)
    V.Content = content

    -- Создаем ручной скроллбар (без шаблонов)
    local scrollBar = CreateFrame("Slider", "NSQC4_NowimChatScrollBar", parent)
    scrollBar:SetWidth(8) -- Тонкий ползунок
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetAlpha(0.01) -- Прозрачный в покое (1%)
    
    -- Текстура ползунка (тонкая полоска)
    local thumb = scrollBar:CreateTexture(nil, "ARTWORK")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetSize(8, 30) -- Высота бегунка
    thumb:SetVertexColor(0.6, 0.6, 0.6, 1) -- Серый цвет
    scrollBar:SetThumbTexture(thumb)

    -- Разрешаем мышь
    scrollBar:EnableMouse(true)
    
    -- Поведение прозрачности
    scrollBar:SetScript("OnEnter", function(self) 
        self:SetAlpha(1) 
    end)
    scrollBar:SetScript("OnLeave", function(self) 
        if not scroll:IsMouseOver() then 
            self:SetAlpha(0.01) 
        end 
    end)
    
    -- Логика прокрутки при перетаскивании
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value)
    end)

    -- Прокрутка колесиком
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local offset = scroll:GetVerticalScroll() or 0
        local maxScroll = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
        local newOffset = math.max(0, math.min(offset - (delta * 30), maxScroll))
        scroll:SetVerticalScroll(newOffset)
        scrollBar:SetValue(newOffset)
    end)
    
    -- Синхронизация скроллбара при прокрутке чата
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", self, "TOPLEFT", 0, offset)
        scrollBar:SetValue(offset) -- Обновляем значение ползунка
    end)
    
    -- Показываем скроллбар при наведении на чат
    scroll:SetScript("OnEnter", function()
        scrollBar:SetAlpha(1)
    end)
    scroll:SetScript("OnLeave", function()
        if not scrollBar:IsMouseOver() then
            scrollBar:SetAlpha(0.01)
        end
    end)
    
    -- Функция для прокрутки в самый низ
    function V.ScrollToBottom()
        -- ВАЖНО: сначала обновляем высоту контента, чтобы GetHeight() вернул правильное значение
        scroll:UpdateScrollChildRect()
        
        local maxScroll = math.max(0, (content:GetHeight() or 0) - (scroll:GetHeight() or 0))
        scroll:SetVerticalScroll(maxScroll)
        scrollBar:SetValue(maxScroll)
        
        -- Обновляем границы скроллбара (важно, чтобы ползунок правильно позиционировался)
        scrollBar:SetMinMaxValues(0, maxScroll)
    end
end)