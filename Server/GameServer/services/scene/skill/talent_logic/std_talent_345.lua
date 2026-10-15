local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_546 = class("std_talent_546", base)

function std_talent_546:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_546:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id == 491 then
        local odd = 5
        local n = math.random(100)
        if n <= odd then
            local data_indexs = { 44377, 44378, 44379, 44380, 44381}
            local data_index = data_indexs[level] or define.INVAILD_ID
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_546