-- PetEquipItemAptRate: attack P, defence P, attack M, defence M, miss, hit.
local IA = require('define').ITEM_ATTRIBUTE
local rows = require 'cys_pet_apt_data'
local slot = {
    [IA.IATTRIBUTE_BASE_ATTACK_P]=1, [IA.IATTRIBUTE_BASE_DEFENCE_P]=2,
    [IA.IATTRIBUTE_BASE_MAGIC_P]=3, [IA.IATTRIBUTE_BASE_DEFENCE_M]=4,
    [IA.IATTRIBUTE_BASE_MISS]=5, [IA.IATTRIBUTE_BASE_HIT]=6,
}
local M = {}
function M.quality_bonus(raw, ia, base)
    local i = slot[ia]
    local q = i and raw.qualifications and raw.qualifications[i]
    local row = type(q)=='number' and rows[q]
    local rate = row and row[i]
    if not rate or rate <= 0 or not base or base <= 0 then return 0 end
    -- Item::PetEquipItemEffectFlush 980eff..980f28: base*rate/100, Float2Int.
    -- Added attributes are accumulated separately and never multiplied here.
    return math.floor((base * rate + 50) / 100)
end
return M
