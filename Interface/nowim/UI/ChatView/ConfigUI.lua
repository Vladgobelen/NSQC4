-- ============================================================================
-- NSQC4 / nowim / UI / ConfigUI
-- ============================================================================

NSQC4.RegisterModule("nowim", function()
    NSQC4.Nowim.UI = NSQC4.Nowim.UI or {}

    NSQC4.Nowim.UI.Const = {
        -- ОКНО
        EDGE_PADDING   = 6,    
        PANEL_HEIGHT   = 26,   
        LEFT_WIDTH     = 150,  
        RIGHT_WIDTH    = 38,   
        BTN_ALPHA      = 0.01, 
        TAB_WIDTH      = 34,   
        TAB_HEIGHT     = 26,   

        -- ЧАТ (ОБЛАКА)
        BUBBLE_PADDING = 6,    
        GAP            = 6,    
        CHAT_PADDING_L = 0,    -- было 4, теперь вплотную к левому краю
        CHAT_PADDING_R = 0,    -- было 4, теперь вплотную к правому краю
        
        -- Отступы ScrollFrame
        CHAT_PAD_TOP    = 4,   
        CHAT_PAD_BOTTOM = 0,   -- было 2, теперь вплотную к низу
        CHAT_PAD_PANEL  = 0,   
        CHAT_RIGHT_PAD  = 0,   -- было 6, скроллбар прижат к правому краю

        -- ВВОД
        INPUT_HEIGHT   = 32,   
    }
end)