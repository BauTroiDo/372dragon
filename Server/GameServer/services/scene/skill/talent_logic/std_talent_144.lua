local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_144 = class("std_talent_144", base)
local impact_data_index = 63026 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
function std_talent_144:on_active(talent, level, human)
    if human:impact_get_first_impact_of_specific_data_index(impact_data_index) == nil then
        impactenginer:send_impact_to_unit(human, impact_data_index, human, 0, false, 0)
    end
end

function std_talent_144:on_remove(talent, level, human)
    if human:impact_get_first_impact_of_specific_data_index(impact_data_index) then
        local imp = human:impact_get_first_impact_of_specific_data_index(impact_data_index)
        if imp then
            human:on_impact_fade_out(imp)
            human:remove_impact(imp)
        end
    end
end

return std_talent_144