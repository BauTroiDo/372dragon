local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_339 = class("std_impact_339", base)

function std_impact_339:is_over_timed()
    return true
end

function std_impact_339:is_intervaled()
    return false
end

function std_impact_339:refix_skill(imp, obj, skill_info)
    if skill_info:get_skill_id() == 2 then
        skill_info:set_charge_time(0)
    end
end

function std_impact_339:on_call_up_pet_success(imp, owner, pet)
    if pet then
        local impactenginer = require "impactenginer":getinstance()
        impactenginer:send_impact_to_unit(pet, 63004, owner, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
    end
    if owner then
        owner:on_impact_fade_out(imp)
        owner:remove_impact(imp)
    end
end


return std_impact_339