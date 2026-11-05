-- ============================================================================
-- NSQC4 / Quests / df / Terrain / UI / Api
-- Ландшафт — владелец клетки.
--
-- void рисуется чёрным квадратом: текстура WHITE8x8 (из Terrain/Data/Void),
-- затемняется через ApplyTint(index, {0,0,0,1}) после рендера клетки.
--
-- Тултип клетки:
--   - тип ландшафта
--   - для water — «Глубина: N / 10» (Grid:GetDepth)
--   - для не-void (кроме water) — «Прочность: X / Y» (Grid:GetHardness)
--   - лут в клетке (список)
--   - если в клетке существо (активное или спящее) — его тултип + в конце
--     клетка+лут
--   - если существа нет — только клетка+лут
--
-- Клики:
--   - ЛКМ: если в клетке есть лут — НЕ вешаем (не выделяем клетку с лутом).
--   - ПКМ: если в клетке есть лут и НЕТ существа — НЕ вешаем.
--          Если есть существо (даже спящее) — вешаем (меню Спать/Разбудить/
--          Осмотреть). Без этого нельзя разбудить спящее существо на клетке
--          с лутом.
--   - Если существ нет и лута нет — вешаем по terrain (Actions).
--
-- ВЫДЕЛЕНИЕ КЛЕТКИ (highlight):
--   Цвет подсветки выделенной клетки при рендере — HIGHLIGHT_SELECTED.
--   Сейчас { 0.7, 0.56, 0.0, 1.0 } — на 30% темнее исходного { 1.0, 0.8, 0.0 }.
--   Применяется через ApplyTint → SetVertexColor на текстуре клетки.
--   Void — всегда чёрный (отдельный ApplyTint после highlight).
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsField
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Terrain/UI/Api: ядро поля не загружено.")
        return
    end

    local CONST = NSQC4.QuestsFieldConst
    if not CONST then return end
    local TOTAL = CONST.COLS * CONST.ROWS

    local UIApi = {}
    NSQC4.QuestsDfTerrainUIApi = UIApi

    UIApi.DEBUG = false

    local function dbg(...)
        if UIApi.DEBUG then print("|cff00ffff[TUIA]|r", ...) end
    end

    -- ========================================================================
    -- Подсветка выделенной клетки (при рендере).
    --   { R, G, B, A } — умножается на текстуру клетки (SetVertexColor).
    --   Сейчас — на 30% темнее исходного жёлто-оранжевого {1.0, 0.8, 0.0}.
    -- ========================================================================
    local HIGHLIGHT_SELECTED = { 0.7, 0.56, 0.0, 1.0 }

    local DEFAULTS = {
        text     = nil,
        color    = { 0.85, 0.85, 0.85 },
        textSize = 9,
        anchors  = {},
    }

    local function MergeOpts(opts)
        opts = opts or {}
        return {
            texture  = opts.texture,
            text     = opts.text ~= nil and opts.text or DEFAULTS.text,
            color    = opts.color    or DEFAULTS.color,
            textSize = opts.textSize or DEFAULTS.textSize,
            anchors  = opts.anchors  or DEFAULTS.anchors,
        }
    end

    local function ApplyTint(index, rgb)
        local cell = QuestsField.cells and QuestsField.cells[index]
        if not cell or not cell.texture then return end
        if rgb then
            cell.texture:SetVertexColor(rgb[1], rgb[2], rgb[3], rgb[4] or 1)
        else
            cell.texture:SetVertexColor(1, 1, 1, 1)
        end
    end

    local function ResolveTooltip(entity)
        if not entity or not entity.opts then return nil end
        local Entities = NSQC4.QuestsDfEntities
        local kind = entity.kind or entity.opts.kind
        if Entities and Entities.GetTooltip and kind then
            local builder = Entities:GetTooltip(kind)
            if builder then
                local ok, fn = pcall(builder, entity.opts)
                if ok and type(fn) == "function" then return fn end
            end
        end
        return nil
    end

    -- ========================================================================
    -- Лут: строки для тултипа
    -- ========================================================================
    local LOOT_NAMES = {
        earth = "Земля",
        wood  = "Дерево",
        stone = "Камень",
        herb  = "Трава",
    }

    local function LootLines(index)
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Drops then return nil end
        local all = Drops:GetAll(index)
        if not all or #all == 0 then return nil end

        local counts = {}
        local order = {}
        for _, d in ipairs(all) do
            local id = d.id or "?"
            if not counts[id] then
                counts[id] = 0
                order[#order + 1] = id
            end
            counts[id] = counts[id] + 1
        end

        local parts = {}
        for _, id in ipairs(order) do
            local name = LOOT_NAMES[id] or id
            parts[#parts + 1] = string.format("%s ×%d", name, counts[id])
        end
        return table.concat(parts, ", ")
    end

    -- ========================================================================
    -- Строка клетки: terrain, глубина/прочность, лут
    -- ========================================================================
    local function CellLines(index, terrainId)
        local Grid = NSQC4.QuestsDfGrid
        local Data = NSQC4.QuestsDfTerrainData
        if not Grid then return nil end

        local lines = {}

        local tname = terrainId or "?"
        local tcolor = { 0.85, 0.85, 0.85 }
        if Data then
            local def = terrainId and Data:Get(terrainId)
            if def and def.color then tcolor = def.color end
        end
        lines[#lines + 1] = {
            text = "Клетка: " .. tname,
            r = tcolor[1] or 0.85, g = tcolor[2] or 0.85, b = tcolor[3] or 0.85,
        }

        -- глубина воды (water)
        if terrainId == "water" then
            local d = nil
            if Grid.GetDepth then
                d = Grid:GetDepth(index)
            end
            if d then
                lines[#lines + 1] = {
                    text = string.format("Глубина: %d / %d", d, Grid.DEPTH_MAX or 10),
                    r = 0.55, g = 0.75, b = 1.00,
                }
            end
        end

        -- прочность (не void, не water)
        if terrainId and terrainId ~= "void" and terrainId ~= "water" then
            local curH = Grid:GetHardness(index)
            local maxH = nil
            if Data then
                local def = Data:Get(terrainId)
                maxH = def and def.hardness
            end
            if curH and maxH and maxH > 0 then
                local pct = (curH / maxH) * 100
                lines[#lines + 1] = {
                    text = string.format("Прочность: %d / %d (%.0f%%)",
                        math.floor(curH + 0.5), math.floor(maxH + 0.5), pct),
                    r = 0.85, g = 0.85, b = 0.85,
                }
            end
        end

        -- лут
        local loot = LootLines(index)
        if loot then
            lines[#lines + 1] = {
                text = "Лут: " .. loot,
                r = 0.8, g = 1.0, b = 0.8,
            }
        end

        return lines
    end

    local function ShowCellTooltip(index, terrainId)
        local lines = CellLines(index, terrainId)
        if not lines or #lines == 0 then return end
        GameTooltip:AddLine(lines[1].text, lines[1].r, lines[1].g, lines[1].b)
        for i = 2, #lines do
            GameTooltip:AddLine(lines[i].text, lines[i].r, lines[i].g, lines[i].b)
        end
        GameTooltip:Show()
    end

    -- ========================================================================
    -- Render (визуал клетки)
    -- ========================================================================
    function UIApi:Render(index, opts)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        if not opts then
            QuestsField:SetCellTexture(index, nil)
            QuestsField:ClearCellText(index)
            QuestsField:ClearAnchorTextures(index)
            ApplyTint(index, nil)
            return true
        end

        local v = MergeOpts(opts)

        QuestsField:SetCellTexture(index, v.texture)

        if v.text and v.text ~= "" then
            local c = v.color or { 1, 1, 1 }
            QuestsField:SetCellText(index, v.text, nil, c[1], c[2], c[3], v.textSize)
        else
            QuestsField:ClearCellText(index)
        end

        QuestsField:ClearAnchorTextures(index)
        if v.anchors then
            for pos, tex in pairs(v.anchors) do
                if tex then
                    QuestsField:SetAnchorTexture(index, pos, tex)
                end
            end
        end

        ApplyTint(index, opts.highlight)
        return true
    end

    -- ========================================================================
    -- RenderCellFromStorage
    -- ========================================================================
    function UIApi:RenderCellFromStorage(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return false end

        local Grid = NSQC4.QuestsDfGrid
        local Data = NSQC4.QuestsDfTerrainData

        local terrainId = Terrain:GetAt(index)

        if not terrainId then
            self:Render(index, nil)
        else
            local data = Data and Data:Get(terrainId) or {}
            local logic = Terrain:GetType(terrainId) or {}

            local selected = false
            if Grid and Grid.IsTerrainSelected then
                selected = Grid:IsTerrainSelected(index, terrainId) and true or false
            end
            dbg("cell", index, "terrain", terrainId, "selected", selected and 1 or 0)

            self:Render(index, {
                texture   = data.texture   or logic.texture,
                text      = data.text      or logic.text,
                color     = data.color     or logic.color,
                textSize  = data.textSize  or logic.textSize,
                anchors   = data.anchors   or logic.anchors,
                highlight = selected and HIGHLIGHT_SELECTED or nil,
            })

            -- void — чёрный квадрат (WHITE8x8 из Data, затемняем в чёрный)
            if terrainId == "void" then
                ApplyTint(index, { 0, 0, 0, 1 })
            end
        end

        local EntitiesApi = NSQC4.QuestsDfEntitiesUIApi
        local entity = Grid and Grid:GetEntity(index)

        if entity and entity.opts and EntitiesApi and EntitiesApi.Render then
            EntitiesApi:Render(index, {
                icon     = entity.opts.icon or entity.opts.texture,
                anchor   = entity.opts.anchor,
                expanded = entity.opts.expanded,
                alpha    = entity.opts.alpha,
            })
        elseif EntitiesApi and EntitiesApi.Render then
            EntitiesApi:Render(index, nil)
        end

        -- Лут: перерисовать
        local Drops = NSQC4.QuestsDfTransformDrops
        if Drops then Drops:Render(index) end

        -- ====================================================================
        -- Тултип и клики
        -- ====================================================================
        local sleeping     = entity and entity.opts and entity.opts.sleeping
        local hasEntity    = entity ~= nil
        local hasActive    = entity and not sleeping
        local hasLoot      = Drops and Drops:HasAny(index) or false

        if hasEntity then
            entity.opts._landscape = { index = index, terrainId = terrainId }

            local tooltipFn = ResolveTooltip(entity)
            if tooltipFn then
                QuestsField:SetCellTooltip(index, function(btn)
                    tooltipFn(btn)
                    local lines = CellLines(index, terrainId)
                    if lines and #lines > 0 then
                        GameTooltip:AddLine(" ")
                        for _, ln in ipairs(lines) do
                            GameTooltip:AddLine(ln.text, ln.r, ln.g, ln.b)
                        end
                    end
                end)
            else
                QuestsField:SetCellTooltip(index, function(btn)
                    ShowCellTooltip(index, terrainId)
                end)
            end
        else
            QuestsField:SetCellTooltip(index, function(btn)
                ShowCellTooltip(index, terrainId)
            end)
        end

        -- ЛКМ: лут блокирует выделение (клетку с лутом не выделяем).
        if hasLoot then
            QuestsField:SetCellOnMouseClick(index, "LeftButton", nil)
            if not hasEntity then
                QuestsField:SetCellOnMouseClick(index, "RightButton", nil)
                return true
            end
        end

        -- Клики по terrain (Actions вешают свои обработчики).
        local Actions = NSQC4.QuestsDfTerrainActions
        local T = Actions and Actions.Types and terrainId and Actions.Types[terrainId]

        if T and T.Check and T.Check(index) then
            if T.LeftClickSelf then T.LeftClickSelf(index) end
            if T.RightClickEntities then T.RightClickEntities(index) end
        else
            if not hasEntity then
                QuestsField:SetCellOnMouseClick(index, "LeftButton",  nil)
                QuestsField:SetCellOnMouseClick(index, "RightButton", nil)
            end
        end

        return true
    end

    function UIApi:RenderAll()
        for i = 1, TOTAL do
            self:RenderCellFromStorage(i)
        end
    end

end)