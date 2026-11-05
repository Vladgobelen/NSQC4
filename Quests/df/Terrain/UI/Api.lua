-- ============================================================================
-- NSQC4 / Quests / df / Terrain / UI / Api
-- Ландшафт — владелец клетки.
--
-- opts._landscape для тултипа: { index, terrainId, hardness, maxHardness }.
-- hardness в тултипе читается заново (Tooltip.Build → Grid:GetHardness),
-- поэтому здесь важно передать index и terrainId.
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
                highlight = selected and { 1.0, 0.8, 0.0, 1.0 } or nil,
            })
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

        -- Тултип: отдаём index и terrainId, hardness читается в OnEnter заново
        if entity and entity.opts and not entity.opts.sleeping then
            entity.opts._landscape = {
                index     = index,
                terrainId = terrainId,
            }

            local tooltipFn = ResolveTooltip(entity)
            if tooltipFn then
                QuestsField:SetCellTooltip(index, tooltipFn)
            else
                QuestsField:ClearCellTooltip(index)
            end
        else
            QuestsField:ClearCellTooltip(index)
        end

        local Actions = NSQC4.QuestsDfTerrainActions
        local T = Actions and Actions.Types and terrainId and Actions.Types[terrainId]

        if T and T.Check and T.Check(index) then
            if T.LeftClickSelf then T.LeftClickSelf(index) end
            if T.RightClickEntities then T.RightClickEntities(index) end
        else
            QuestsField:SetCellOnMouseClick(index, "LeftButton",  nil)
            QuestsField:SetCellOnMouseClick(index, "RightButton", nil)
        end

        return true
    end

    function UIApi:RenderAll()
        for i = 1, TOTAL do
            self:RenderCellFromStorage(i)
        end
    end

end)