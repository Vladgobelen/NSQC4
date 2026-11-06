-- ============================================================================
-- NSQC4 / Quests / Field / UI / API / Textures
-- @deprecated Обёртки над QuestsField:RenderCell(index, spec).
--
-- В новой модели ВСЁ рисование клетки идёт через RenderCell (см.
-- Field/UI/API/CellRender.lua). Этот файл оставлен для совместимости:
-- старые вызовы SetCellTexture/SetCellBuild/SetCellHoverTexture работают,
-- но внутри только ДОПОЛНЯЮТ накопленный spec и зовут RenderCell.
--
-- Накопление: btn._crSpec хранит последний spec клетки. Обёртки читают
-- его, меняют СВОЙ слой (terrain/build/hover) и пишут обратно. Так
-- SetCellTexture не затрёт build, а SetCellBuild — terrain.
--
-- Слои (см. CellRender.lua):
--   spec.terrain = { texture, r,g,b,a, alpha }   — LOW 0
--   spec.build   = { texture, r,g,b,a, alpha }   — MEDIUM 0
--   spec.highlight = { r,g,b,a }                 — tint поверх terrain
--
-- Ховер как отдельная текстура (SetCellHoverTexture) в новой модели НЕ
-- используется: подсветка — это spec.highlight (tint на terrain). Старый
-- вызов SetCellHoverTexture оставлен как no-op с предупреждением — чтобы
-- не падало, если где-то ещё зовут.
-- ============================================================================

NSQC4.RegisterModule("quests", function()

    local QuestsField = NSQC4.QuestsFieldClass
    if not QuestsField then
        print("|cffff0000[NSQC4]|r Textures: ядро поля не загружено.")
        return
    end

    if not QuestsField.RenderCell then
        print("|cffff0000[NSQC4]|r Textures: QuestsField:RenderCell не найден " ..
              "(CellRender.lua не загружен?). Обёртки работать не будут.")
        return
    end

    local function GetSpec(btn)
        return (btn and btn._crSpec) or {}
    end

    local function EnsureTable(t)
        if type(t) ~= "table" then return {} end
        return t
    end

    -- ========================================================================
    -- @deprecated
    -- SetCellTexture(index, texture, alpha)
    --   ставит/снимает ландшафтный слой (spec.terrain).
    --   texture = nil → снять terrain (весь слой).
    -- ========================================================================
    function QuestsField:SetCellTexture(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = GetSpec(btn)

        if texture then
            spec.terrain = {
                texture = texture,
                alpha   = alpha,
                -- r,g,b,a не задаём — CellRender возьмёт дефолт (1,1,1,1),
                -- если не было highlight. Цвет задаёт вызывающий через
                -- RenderCell (spec.terrain.r/g/b) или spec.highlight.
            }
        else
            spec.terrain = nil
        end

        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- SetCellBuild(index, texture, alpha)
    --   ставит/снимает слой строения (spec.build).
    -- ========================================================================
    function QuestsField:SetCellBuild(index, texture, alpha)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = GetSpec(btn)

        if texture then
            spec.build = {
                texture = texture,
                alpha   = alpha,
            }
        else
            spec.build = nil
        end

        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- SetCellHoverTexture(index, texture, alpha)
    --   В новой модели ховер = spec.highlight (tint на terrain).
    --   Отдельной hover-текстуры больше нет. Метод оставлен как no-op,
    --   чтобы старый код не падал. Если нужен «ховер» — используй
    --   RenderCell с spec.highlight = {r,g,b,a}.
    -- ========================================================================
    function QuestsField:SetCellHoverTexture(index, texture, alpha)
        -- no-op: см. комментарий в шапке файла
        if texture then
            print("|cffffaa00[NSQC4]|r SetCellHoverTexture: " ..
                  "устарел (ховер = spec.highlight). Игнорирую.")
        end
        return false
    end

    -- ========================================================================
    -- @deprecated
    -- Дополнительный хелпер: задать цвет ландшафта (spec.terrain.r/g/b/a).
    -- Удобно для void (0,0,0) без пересборки spec целиком.
    -- ========================================================================
    function QuestsField:SetCellTerrainColor(index, r, g, b, a)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = GetSpec(btn)
        if not spec.terrain then
            -- нет terrain — нечего красить
            return false
        end
        spec.terrain.r = r
        spec.terrain.g = g
        spec.terrain.b = b
        spec.terrain.a = a

        return self:RenderCell(index, spec)
    end

    -- ========================================================================
    -- @deprecated
    -- Задать/снять подсветку выделения (spec.highlight).
    --   nil → снять подсветку (terrain вернётся к своему r/g/b)
    -- ========================================================================
    function QuestsField:SetCellHighlight(index, r, g, b, a)
        self:EnsureFrame()
        local btn = self.cells and self.cells[index]
        if not btn then return false end

        local spec = GetSpec(btn)
        if r then
            spec.highlight = { r = r, g = g or r, b = b or r, a = a or 1 }
        else
            spec.highlight = nil
        end

        return self:RenderCell(index, spec)
    end

end)