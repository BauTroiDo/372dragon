local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_817 = class("std_talent_817", base)

function std_talent_817:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_817:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() ~= 480 then
        return
    end
    impactenginer:send_impact_to_unit(human, 63079, human, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
end

function std_talent_817:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_data_index() == 51740 then
        local value = self:get_refix_value(talent, level)
        if value > 0 then
            imp:set_continuance(20000)
            local logic = impactenginer:get_logic(imp)
            if logic then
                logic:set_value_of_reduce_def_cold(imp, value)
                logic:set_value_of_reduce_def_fire(imp, value)
                logic:set_value_of_reduce_def_light(imp, value)
                logic:set_value_of_reduce_def_poison(imp, value)
            end
        end
    end
end

return std_talent_817