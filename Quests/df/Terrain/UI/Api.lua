-- ============================================================================
-- NSQC4 / Quests / df / Terrain / UI / Api
-- Порядок: ландшафт → строение → текст → ЛУТ → СУЩЕСТВО.
--
-- ФИКС: при рендере применяется HIGHLIGHT_SELECTED к текстуре клетки,
-- если Grid:IsTerrainSelected(index). Раньше выделение ставилось в
-- Grid, но не перекрашивало текстуру — «выделений нет».
--
-- ФИКС: T.LeftClickSelf / T.RightClickEntities зовутся только при
-- СМЕНЕ состояния клетки (_lastStateKey). Иначе SetCellOnMouseClick
-- перевешивается каждый рендер.
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

    local HIGHLIGHT_SELECTED = { 0.7, 0.56, 0.0, 1.0 }
    local DEFAULT_BG = { 0, 0, 0, 1 }

    local MATERIAL_TINT = {
        wood  = { 0.55, 0.35, 0.20, 1 },
        stone = { 0.60, 0.60, 0.60, 1 },
        metal = { 0.80, 0.80, 0.90, 1 },
        gold  = { 1.00, 0.85, 0.10, 1 },
    }

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

    local function BuildingOwnerName(b)
        if not b or not b.by then return nil end
        if b.byName then return b.byName end
        local E = NSQC4.QuestsDfEntities
        if E and E.Get then
            local e = E:Get(b.by)
            if e and e.opts and e.opts.name then return e.opts.name end
        end
        return tostring(b.by)
    end

    local LOOT_NAMES = { earth="Земля", wood="Дерево", stone="Камень", herb="Трава" }

    local function LootLines(index)
        local Drops = NSQC4.QuestsDfTransformDrops
        if not Drops then return nil end
        local all = Drops:GetAll(index)
        if not all or #all == 0 then return nil end
        local counts, order = {}, {}
        for _, d in ipairs(all) do
            local id = d.id or "?"
            if not counts[id] then counts[id] = 0; order[#order+1] = id end
            counts[id] = counts[id] + 1
        end
        local parts = {}
        for _, id in ipairs(order) do
            parts[#parts+1] = string.format("%s ×%d", LOOT_NAMES[id] or id, counts[id])
        end
        return table.concat(parts, ", ")
    end

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
        lines[#lines+1] = { text = "Клетка: " .. tname, r = tcolor[1] or 0.85, g = tcolor[2] or 0.85, b = tcolor[3] or 0.85 }

        if terrainId == "water" then
            local d = Grid.GetDepth and Grid:GetDepth(index)
            if d then lines[#lines+1] = { text = string.format("Глубина: %d / %d", d, Grid.DEPTH_MAX or 10), r = 0.55, g = 0.75, b = 1.00 } end
        end

        if Grid.IsBuilding and Grid:IsBuilding(index) then
            local b = Grid:GetBuilding(index)
            if b then
                local hp  = tonumber(b.hp)  or 0
                local max = tonumber(b.max) or 1000
                local pct = (max > 0) and (hp / max * 100) or 0
                lines[#lines+1] = { text = string.format("Постройка: %d / %d (%.0f%%)", math.floor(hp+0.5), math.floor(max+0.5), pct), r = 0.55, g = 1.00, b = 0.55 }
                if b.material then
                    lines[#lines+1] = { text = "Материал: " .. tostring(b.material), r = 0.80, g = 0.80, b = 0.80 }
                end
                local ownerName = BuildingOwnerName(b)
                if ownerName then
                    lines[#lines+1] = { text = "Строит: " .. ownerName, r = 1.00, g = 0.82, b = 0.00 }
                end
            end
        else
            if terrainId and terrainId ~= "void" and terrainId ~= "water" then
                local curH = Grid:GetHardness(index)
                local maxH = nil
                if Data then
                    local def = Data:Get(terrainId)
                    maxH = def and def.hardness
                end
                if curH and maxH and maxH > 0 then
                    local pct = (curH / maxH) * 100
                    lines[#lines+1] = { text = string.format("Прочность: %d / %d (%.0f%%)", math.floor(curH+0.5), math.floor(maxH+0.5), pct), r = 0.85, g = 0.85, b = 0.85 }
                end
            end
        end

        local loot = LootLines(index)
        if loot then lines[#lines+1] = { text = "Лут: " .. loot, r = 0.8, g = 1.0, b = 0.8 } end
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
    -- State key: чтобы не перевешивать клики каждый рендер.
    -- ========================================================================
    local function StateKey(terrainId, hasEntity, entityId, hasLoot, selected)
        return tostring(terrainId).."|"..
               tostring(hasEntity).."|"..
               tostring(entityId).."|"..
               tostring(hasLoot).."|"..
               tostring(selected)
    end

    function UIApi:RenderCellFromStorage(index)
        index = tonumber(index) or 0
        if index < 1 or index > TOTAL then return false end

        local Terrain = NSQC4.QuestsDfTerrain
        if not Terrain then return false end

        local Grid = NSQC4.QuestsDfGrid
        local Data = NSQC4.QuestsDfTerrainData

        local terrainId = Terrain:GetAt(index)
        local isBuilding = (terrainId == "ladder")
            and Grid and Grid.IsBuilding and Grid:IsBuilding(index)

        local alpha, buildingTint = nil, nil
        local material = "wood"
        if isBuilding then
            alpha = 0.5
            local b = Grid:GetBuilding(index)
            if b and b.material then
                material = b.material
                buildingTint = MATERIAL_TINT[material]
            end
        end

        local cell = QuestsField.cells and QuestsField.cells[index]

        -- ПОДЛОЖКА
        if cell and cell.bg then
            if terrainId == "ladder" then
                cell.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                cell.bg:SetVertexColor(DEFAULT_BG[1], DEFAULT_BG[2], DEFAULT_BG[3], DEFAULT_BG[4])
                cell.bg:Show()
            else
                cell.bg:Hide()
            end
        end

        -- ЛАНДШАФТ + СТРОЕНИЕ
        if not terrainId then
            QuestsField:SetCellTexture(index, nil)
            if QuestsField.SetCellBuild then QuestsField:SetCellBuild(index, nil) end
            QuestsField:ClearCellText(index)
            QuestsField:ClearAnchorTextures(index)
        else
            local data = Data and Data:Get(terrainId) or {}
            local logic = Terrain:GetType(terrainId) or {}

            QuestsField:SetCellTexture(index, data.texture or logic.texture, nil)

            if QuestsField.SetCellBuild then
                if terrainId == "ladder" then
                    QuestsField:SetCellBuild(index, data.texture or logic.texture, alpha)
                else
                    QuestsField:SetCellBuild(index, nil)
                end
            end

            if data.text and data.text ~= "" then
                local c = data.color or { 1, 1, 1 }
                QuestsField:SetCellText(index, data.text, nil, c[1], c[2], c[3], data.textSize)
            else
                QuestsField:ClearCellText(index)
            end

            if terrainId == "ladder" and cell and cell.build then
                if buildingTint then
                    cell.build:SetVertexColor(buildingTint[1], buildingTint[2], buildingTint[3], buildingTint[4] or 1)
                else
                    cell.build:SetVertexColor(1, 1, 1, 1)
                end
            end

            if terrainId == "void" then
                ApplyTint(index, { 0, 0, 0, 1 })
            end
        end

        -- ЛУТ
        local Drops = NSQC4.QuestsDfTransformDrops
        if Drops then Drops:Render(index) end

        -- СУЩЕСТВО
        local entity = Grid and Grid:GetEntity(index)
        local EntitiesApi = NSQC4.QuestsDfEntitiesUIApi
        if EntitiesApi and EntitiesApi.Render then
            if entity and entity.opts then
                EntitiesApi:Render(index, {
                    icon     = entity.opts.icon or entity.opts.texture,
                    anchor   = entity.opts.anchor,
                    expanded = entity.opts.expanded,
                    alpha    = entity.opts.alpha,
                })
            else
                EntitiesApi:Render(index, nil)
            end
        end

        -- ФИКС: выделение — перекрасить текстуру
        local isSel = Grid and Grid:IsTerrainSelected(index)
        if isSel then
            ApplyTint(index, HIGHLIGHT_SELECTED)
        else
            ApplyTint(index, nil)
        end

        -- ТУЛТИП
        local sleeping   = entity and entity.opts and entity.opts.sleeping
        local hasEntity  = entity ~= nil
        local hasLoot    = Drops and Drops:HasAny(index) or false

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
                QuestsField:SetCellTooltip(index, function(btn) ShowCellTooltip(index, terrainId) end)
            end
        else
            QuestsField:SetCellTooltip(index, function(btn) ShowCellTooltip(index, terrainId) end)
        end

        if hasLoot then
            QuestsField:SetCellOnMouseClick(index, "LeftButton", nil)
            if not hasEntity then
                QuestsField:SetCellOnMouseClick(index, "RightButton", nil)
                return true
            end
        end

        -- ФИКС: клики — только при смене состояния.
        local Actions = NSQC4.QuestsDfTerrainActions
        local T = Actions and Actions.Types and terrainId and Actions.Types[terrainId]
        local entityId = entity and entity.id or "nil"
        local key = StateKey(terrainId, hasEntity, entityId, hasLoot, isSel)

        if cell and cell._lastStateKey ~= key then
            cell._lastStateKey = key

            if T and T.Check and T.Check(index) then
                if T.LeftClickSelf then T.LeftClickSelf(index) end
                if T.RightClickEntities then T.RightClickEntities(index) end
            else
                if not hasEntity then
                    QuestsField:SetCellOnMouseClick(index, "LeftButton",  nil)
                    QuestsField:SetCellOnMouseClick(index, "RightButton", nil)
                end
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