-- CY faction IDs. Ordinary level-10 combat weapons, not level-1 illusion unlocks.
local M = {}
M.weapons = {
    [0]=10101001, [1]=10100001, [2]=10101001, [3]=10102001,
    [4]=10102001, [5]=10103001, [6]=10105001, [7]=10103001,
    [8]=10104001, [10]=10102001, [11]=10106001, [12]=10107001,
    [13]=10108001, [14]=10116001, [15]=10117001,
}

function M.prepare(script, human, menpai)
    if human:get_menpai() ~= 9 then return true, false end
    local weapon = M.weapons[menpai]
    if not weapon then return false, "starter_weapon_not_configured" end
    -- Keep the costume and summons queued by legacy NPCs. Validate the complete
    -- batch so the last free slot cannot be promised to two different gifts.
    script.add_item_list = script.add_item_list or {}
    script:AddItem(weapon, 1, true)
    if not script:EndAddItem(human:get_obj_id()) then
        return false, "starter_bag_full"
    end
    return true, true
end

return M
