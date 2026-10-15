local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_188 = class("std_talent_188", base)

function std_talent_188:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 落英剑命中时10%触发欺烟困雨
function std_talent_188:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 521 then
        local odd = self:get_refix_value(talent, level)
        if math.random(100) <= odd then
            impactenginer:send_impact_to_unit(sender, 63031, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    elseif skill_id == 525 then
        impactenginer:send_impact_to_unit(sender, 63031, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
    elseif skill_id == 544 then
        if sender:impact_get_first_impact_of_specific_data_index(63031) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, 63032, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    elseif skill_id == 545 then
        if sender:impact_get_first_impact_of_specific_data_index(63031) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(reciver, 63033, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

-- 八阵图/诛仙阵范围从4米增至7米
function std_talent_188:refix_skill_info(talent, level, skill_info, sender)
    if skill_info:get_skill_id() == 527 or skill_info:get_skill_id() == 529 then
        if sender:impact_get_first_impact_of_specific_data_index(63031) then -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            skill_info:set_radious(7)
        end
    end
end

return std_talent_188