-- ============================================================================
-- NSQC4 / Quests / df / Entities / UI / Api
-- ОДИН визуал: в пути temp, в покое anchor.
--
-- СЛОИ (по frame level, ВСЕГДА выше лута и его бордера):
--   btn+10 — текстуры клетки, лут (OVERLAY/3), бордер лута (OVERLAY/2)
--   btn+20 — фрейм существа (anchor в покое, temp в пути)
--
-- Раньше anchor/temp были ТЕКСТУРАМИ на btn (btn+10), и бордер лута —
-- фрейм btn+11 — их перекрывал. Теперь существо — ФРЕЙМ btn+20,
-- внутри него текстура на весь фрейм. Frame level важнее sublevel,
-- поэтому существо всегда сверху.
--
-- ФИКС свёрнутой в центре:
--   RefreshTempAt ставит фрейм существом CENTER в (x, y) из Move.
--   Для свёрнутой x,y = TOPLEFT + ins + size/2 — верхний левый угол.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Entities/UI/Api: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local UIApi = {}
    NSQC4.QuestsDfEntitiesUIApi = UIApi
    UIApi.DEBUG = false

    local function dbg(...)
        if UIApi.DEBUG then print("|cff00ffff[ENT-UI]|r", ...) end
    end

    local DEFAULT_ALPHA  = 1.0
    local ENTITY_LEVEL_OFFSET = 20   -- btn+20, выше лута (btn+10) и его бордера

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    local function HostFor(entity)
        if not entity then return nil end
        local btn = QuestsField.cells and QuestsField.cells[entity.index]
        return btn or QuestsField.frame
    end

    -- ========================================================================
    -- Фрейм существа + текстура внутри. Один фрейм на id.
    -- ========================================================================
    local function EnsureEntityFrame(entity)
        if not entity or not entity.id then return nil, nil end
        local host = HostFor(entity)
        if not host then return nil, nil end

        if not UIApi._entityFrames then UIApi._entityFrames = {} end
        local rec = UIApi._entityFrames[entity.id]

        if rec and rec.frame and rec.frame:GetParent() ~= host then
            rec.frame:Hide()
            rec.tex:SetTexture(nil)
            rec.frame:ClearAllPoints()
            UIApi._entityFrames[entity.id] = nil
            rec = nil
        end

        if not rec then
            local f = CreateFrame("Frame", nil, host)
            f:SetFrameLevel(host:GetFrameLevel() + ENTITY_LEVEL_OFFSET)
            f:EnableMouse(false)
            f:Hide()

            local tex = f:CreateTexture(nil, "OVERLAY", nil, 0)
            tex:SetTexture(nil)
            tex:SetTexCoord(0, 1, 0, 1)
            tex:SetVertexColor(1, 1, 1, 1)
            tex:SetAlpha(DEFAULT_ALPHA)
            tex:SetAllPoints(f)
            tex:Hide()

            rec = { frame = f, tex = tex }
            UIApi._entityFrames[entity.id] = rec
        end
        return rec.frame, rec.tex
    end

    local function HideEntityVisual(entity)
        if not entity or not entity.id then return end
        if not UIApi._entityFrames then return end
        local rec = UIApi._entityFrames[entity.id]
        if rec then
            if rec.frame then rec.frame:Hide() end
            if rec.tex then rec.tex:SetTexture(nil) end
        end
    end

    -- ========================================================================
    -- Размер текстуры существа
    -- ========================================================================
    local function TempSize(entity)
        local btn = QuestsField.cells and QuestsField.cells[entity.index]
        local cellW = btn and btn:GetWidth()  or 32
        local cellH = btn and btn:GetHeight() or 32
        local opts = entity.opts or {}
        if opts.expanded then
            return cellW * 0.9, cellH * 0.9
        else
            local w = cellW / 3 - 1
            local h = cellH / 3 - 1
            if w < 1 then w = 1 end
            if h < 1 then h = 1 end
            return w, h
        end
    end

    -- ========================================================================
    -- Позиция в движении: фрейм центром в (x, y) — координаты поля.
    -- ========================================================================
    local function RefreshTempAt(entity, x, y)
        if not entity or not entity.opts then return end
        local frame, tex = EnsureEntityFrame(entity)
        if not frame or not tex then return end

        local opts = entity.opts
        local w, h = TempSize(entity)

        frame:ClearAllPoints()
        frame:SetSize(w, h)
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        frame:Show()

        tex:SetTexture(opts.icon or opts.texture)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetAlpha(opts.alpha or DEFAULT_ALPHA)
        tex:Show()
    end

    -- ========================================================================
    -- В покое: фрейм существом в штатной точке клетки.
    --   свёрнутая — TOPLEFT + ins + size/2 (угол)
    --   развёрнутая — CENTER клетки
    -- ========================================================================
    local function ApplyAnchor(index, opts)
        if not opts or not opts.icon then
            local Grid = NSQC4.QuestsDfGrid
            local entity = Grid and Grid:GetEntity(index)
            if entity then HideEntityVisual(entity) end
            return
        end

        local Grid = NSQC4.QuestsDfGrid
        local entity = Grid and Grid:GetEntity(index)
        if not entity then return end

        local frame, tex = EnsureEntityFrame(entity)
        if not frame or not tex then return end

        local btn = QuestsField.cells and QuestsField.cells[index]
        if not btn then return end

        local w, h = TempSize(entity)

        frame:ClearAllPoints()
        frame:SetSize(w, h)

        if opts.expanded then
            frame:SetPoint("CENTER", btn, "CENTER", 0, 0)
        else
            -- TOPLEFT + inset + size/2 — но мы ставим ЦЕНТР фрейма в эту точку
            local ins = CONST.ANCHOR_INSET or 0
            frame:SetPoint("CENTER", btn, "TOPLEFT", ins + w / 2, -(ins + h / 2))
        end
        frame:Show()

        tex:SetTexture(opts.icon)
        tex:SetTexCoord(0, 1, 0, 1)
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetAlpha(opts.alpha or DEFAULT_ALPHA)
        tex:Show()
    end

    function UIApi:HideAnchorAt(index)
        if not index then return end
        local Grid = NSQC4.QuestsDfGrid
        local entity = Grid and Grid:GetEntity(index)
        if entity then HideEntityVisual(entity) end
    end

    function UIApi:Render(index, opts)
        index = Valid(index)
        if not index then return false end

        local Grid = NSQC4.QuestsDfGrid
        local entity = Grid and Grid:GetEntity(index)

        if entity and entity.nextIndex then
            if opts and opts.icon then
                RefreshTempAt(entity, entity.posX or 0, entity.posY or 0)
            else
                HideEntityVisual(entity)
            end
            return true
        end

        if not opts then
            if entity then HideEntityVisual(entity) end
            return true
        end
        ApplyAnchor(index, opts)
        return true
    end

    function UIApi:RenderCellFromStorage(index)
        index = Valid(index)
        if not index then return false end
        local Grid = NSQC4.QuestsDfGrid
        if not Grid then return false end
        local entity = Grid:GetEntity(index)
        if not entity or not entity.opts then
            self:Render(index, nil)
            return true
        end
        local opts = entity.opts
        self:Render(index, {
            icon     = opts.icon or opts.texture,
            expanded = opts.expanded,
            alpha    = opts.alpha,
        })
        return true
    end

    function UIApi:MoveAnchor(entity, x, y)
        if not entity or not entity.opts then return false end
        if not x or not y then return false end
        RefreshTempAt(entity, x, y)
        return true
    end

    function UIApi:StopMoving(entity, index)
        if not entity then return false end
        if index then
            self:RenderCellFromStorage(index)
        else
            self:RenderCellFromStorage(entity.index)
        end
        return true
    end

    function UIApi:RenderAll()
        for i = 1, TOTAL do
            self:RenderCellFromStorage(i)
        end
    end

    SLASH_NSENTUI1 = "/ns_entui"
    SlashCmdList["NSENTUI"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then UIApi.DEBUG = true; print("[ENT-UI] DEBUG = true")
        elseif cmd == "off" then UIApi.DEBUG = false; print("[ENT-UI] DEBUG = false")
        elseif cmd == "layers" then
            local Grid = NSQC4.QuestsDfGrid
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            for _, e in ipairs(Entities:GetAll()) do
                local rec = UIApi._entityFrames and UIApi._entityFrames[e.id]
                if rec then
                    print(string.format("[ENT-UI] %s idx=%s frameLevel=%s parent=%s",
                        tostring(e.opts and e.opts.name), tostring(e.index),
                        tostring(rec.frame:GetFrameLevel()),
                        tostring(rec.frame:GetParent() and rec.frame:GetParent():GetName() or "?")))
                else
                    print(string.format("[ENT-UI] %s idx=%s — нет фрейма",
                        tostring(e.opts and e.opts.name), tostring(e.index)))
                end
            end
        else print("[ENT-UI] /ns_entui on | off | layers") end
    end

    print("|cff00ffff[ENT-UI]|r Entities/UI/Api загружен (фрейм существа btn+20, выше лута)")
end)