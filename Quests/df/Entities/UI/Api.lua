-- ============================================================================
-- NSQC4 / Quests / df / Entities / UI / Api
-- ЕДИНСТВЕННЫЙ визуал существа — spec.entity для поля.
--
-- ВАЖНО (шаг 5b — через API поля):
--   Api БОЛЬШЕ НЕ лезет в btn._crSpec и НЕ зовёт RenderCell со своим spec.
--   Api только:
--     - строит spec.entity из entity.opts (BuildEntitySpec)
--     - отдаёт его полю через QuestsField:SetCellEntitySpec(index, spec)
--     - MoveAnchor → QuestsField:MoveCellEntity (двигает temp)
--     - StopMoving → RenderCellFromStorage (перерисовать в покое)
--     - ClearAllVisuals → no-op (всё чистит ClearCellRender/RenderCell)
--
-- Слои CellRender (снизу вверх): bg → terrain → build → loot → anchor → temp.
-- Существо всегда выше лута.
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

    local DEFAULT_ALPHA = 1.0

    local function Valid(index)
        index = tonumber(index) or 0
        return (index >= 1 and index <= TOTAL) and index or nil
    end

    -- ========================================================================
    -- Сборка spec.entity из entity
    --   Возвращает таблицу или nil (нет существа).
    -- ========================================================================
    function UIApi:BuildEntitySpec(entity)
        if not entity or not entity.opts then return nil end

        local opts = entity.opts
        local texture = opts.icon or opts.texture
        if not texture then return nil end

        -- В пути: temp по posX/posY
        if entity.nextIndex then
            return {
                anchor   = opts.anchor or "TOPLEFT",
                expanded = opts.expanded and true or false,
                texture  = texture,
                alpha    = opts.alpha or DEFAULT_ALPHA,
                moving   = true,
                posX     = entity.posX or 0,
                posY     = entity.posY or 0,
            }
        end

        -- В покое: anchor в клетке
        return {
            anchor   = opts.anchor or "TOPLEFT",
            expanded = opts.expanded and true or false,
            texture  = texture,
            alpha    = opts.alpha or DEFAULT_ALPHA,
            moving   = false,
        }
    end

    -- ========================================================================
    -- Рендер клетки: отдать поле готовый entity-spec.
    --   Поле (SetCellEntitySpec) само:
    --     - берёт btn._crSpec
    --     - заменяет .entity
    --     - обновляет btn._crLastEntity
    --     - зовёт RenderCell (spec сохраняется обратно)
    -- ========================================================================
    function UIApi:RenderCellFromStorage(index)
        index = Valid(index)
        if not index then return false end

        local Grid = NSQC4.QuestsDfGrid
        local entity = Grid and Grid:GetEntity(index)

        return QuestsField:SetCellEntitySpec(index, self:BuildEntitySpec(entity))
    end

    -- ========================================================================
    -- Движение temp (в пути) — прокси в QuestsField:MoveCellEntity.
    --   Если temp не создан (например, RenderCell ещё не звали с moving=true),
    --   MoveCellEntity вернёт false — это ок, следующий RenderCell создаст.
    -- ========================================================================
    function UIApi:MoveAnchor(entity, x, y)
        if not entity or not x or not y then return false end
        local index = entity.index
        if not index then return false end
        return QuestsField:MoveCellEntity(index, x, y)
    end

    -- ========================================================================
    -- Остановка движения: перерисовать клетку в покое (entity = anchor).
    --   index — клетка, где существо оказалось (или его entity.index).
    -- ========================================================================
    function UIApi:StopMoving(entity, index)
        if not entity then return false end
        local idx = index or entity.index
        if not idx then return false end
        return self:RenderCellFromStorage(idx)
    end

    -- ========================================================================
    -- @deprecated
    -- HideAnchorAt: раньше прятал фрейм существа. Теперь — просто перерисовать
    -- клетку (RenderCell увидит entity=nil и снимет слой entity).
    -- ========================================================================
    function UIApi:HideAnchorAt(index)
        index = Valid(index)
        if not index then return false end
        return self:RenderCellFromStorage(index)
    end

    -- ========================================================================
    -- @deprecated
    -- ClearAllVisuals: раньше чистил _entityFrames. Теперь чистить нечего —
    -- при смене этажа Entities:Clear/Grid:ClearAll + ClearAll на поле
    -- снимут слои. Оставлено no-op, чтобы старые вызовы не падали.
    -- ========================================================================
    function UIApi:ClearAllVisuals()
        dbg("ClearAllVisuals: no-op (всё чистит ClearCellRender/RenderCell)")
        return true
    end

    -- ========================================================================
    -- Рендер всех клеток
    -- ========================================================================
    function UIApi:RenderAll()
        for i = 1, TOTAL do
            self:RenderCellFromStorage(i)
        end
    end

    -- ========================================================================
    -- @deprecated
    -- Render(index, opts): раньше принимал opts {icon, anchor, expanded, alpha}.
    -- Теперь — просто RenderCellFromStorage(index): опции берутся из entity.
    -- ========================================================================
    function UIApi:Render(index, opts)
        index = Valid(index)
        if not index then return false end
        return self:RenderCellFromStorage(index)
    end

    -- ========================================================================
    -- Отладка
    -- ========================================================================
    SLASH_NSENTUI1 = "/ns_entui"
    SlashCmdList["NSENTUI"] = function(msg)
        local cmd = (msg or ""):lower():match("^(%S*)")
        if cmd == "" or cmd == "on" then
            UIApi.DEBUG = true
            print("[ENT-UI] DEBUG = true")
        elseif cmd == "off" then
            UIApi.DEBUG = false
            print("[ENT-UI] DEBUG = false")
        elseif cmd == "layers" then
            local Entities = NSQC4.QuestsDfEntities
            if not Entities then return end
            for _, e in ipairs(Entities:GetAll()) do
                local btn = QuestsField.cells and QuestsField.cells[e.index]
                local cr = btn and btn._cr
                local anchorTex = cr and cr.anchor
                local temp = cr and cr.temp
                print(string.format("[ENT-UI] %s idx=%s next=%s anchor=%s temp=%s",
                    tostring(e.opts and e.opts.name), tostring(e.index),
                    tostring(e.nextIndex),
                    tostring(anchorTex and anchorTex:IsShown() or "nil"),
                    tostring(temp and temp.frame:IsShown() or "nil")))
            end
        elseif cmd == "clear" then
            local Entities = NSQC4.QuestsDfEntities
            if Entities and Entities.Clear then Entities:Clear() end
            print("[ENT-UI] clear: через Entities:Clear")
        else
            print("[ENT-UI] /ns_entui on | off | layers | clear")
        end
    end

    print("|cff00ffff[ENT-UI]|r Entities/UI/Api загружен (шаг 5b: через QuestsField:SetCellEntitySpec, без btn._crSpec).")

end)