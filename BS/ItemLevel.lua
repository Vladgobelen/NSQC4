-- ============================================================================
-- NSQC4 / BS / ItemLevel
-- Средний уровень предметов (ilvl). Модуль "itemlevel".
-- ============================================================================

NSQC4 = NSQC4 or {}

local function InitModule()
    if not NSQC4.Settings.IsModuleEnabled("itemlevel") then return end

    -- ========================================================================
    -- Функция среднего илвла
    -- ========================================================================
    function NSQC4.BS.GetAverageItemLevel(unit)
        unit = unit or "player"
        local totalIlvl = 0
        local mainHandEquipLoc, offHandEquipLoc

        for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            if slot ~= INVSLOT_BODY and slot ~= INVSLOT_TABARD then
                local id = GetInventoryItemID(unit, slot)
                if id then
                    local _, _, _, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(id)
                    if itemLevel then
                        totalIlvl = totalIlvl + itemLevel
                        if slot == INVSLOT_MAINHAND then
                            mainHandEquipLoc = itemEquipLoc
                        elseif slot == INVSLOT_OFFHAND then
                            offHandEquipLoc = itemEquipLoc
                        end
                    end
                end
            end
        end

        local numSlots
        if mainHandEquipLoc and offHandEquipLoc then
            numSlots = 17
        else
            local equippedItemLoc = mainHandEquipLoc or offHandEquipLoc
            local _, class = UnitClass(unit)
            local isFury = (class == "WARRIOR")
            numSlots = (
                equippedItemLoc == "INVTYPE_WEAPON" or
                equippedItemLoc == "INVTYPE_WEAPONMAINHAND" or
                (equippedItemLoc == "INVTYPE_2HWEAPON" and isFury)
            ) and 17 or 16
        end

        if numSlots == 0 then return 0 end
        return math.floor(totalIlvl / numSlots)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "NSQC4" then return end
    self:UnregisterEvent("ADDON_LOADED")
    InitModule()
end)