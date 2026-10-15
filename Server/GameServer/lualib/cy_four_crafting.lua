local config = require "cy_four_crafting_config"
local M = {}

-- Recipe instruction is included in profession tuition. This also serves
-- characters who learned their profession before this additive layer existed.
function M.learn(human, faction)
    local school = config.factions[faction]
    if not school or human:get_menpai() ~= faction then
        return false, "Công thức không thuộc môn phái của bạn."
    end
    local ability = human:get_ability(school.ability)
    if not ability then return false, "Bạn cần học nghề môn phái trước." end
    local count = 0
    for _, id in ipairs(school.recipes) do
        local row = config.recipes[id]
        if row.level <= ability.level and not human:is_prescription_have_learnd(id) then
            human:study_prescription(id, true)
            count = count + 1
        end
    end
    return true, "Đã học thêm "..count.." công thức phù hợp với cấp nghề hiện tại."
end

return M
