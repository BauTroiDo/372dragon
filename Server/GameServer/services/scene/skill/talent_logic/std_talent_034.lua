local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_034 = class("std_talent_034", base)
local impact_id_1 = 50024
local impact_id_2 = 50025
function std_talent_034:on_damages(talent, level, damages, obj_me)
    local last_time = obj_me:get_talent_trigger_time(talent.name)
    if last_time == nil or os.time() - last_time > 10 then
        local have_impact_1 = obj_me:impact_get_first_impact_of_specific_data_index(impact_id_1) ~= nil
        local have_impact_2 = obj_me:impact_get_first_impact_of_specific_data_index(impact_id_2) ~= nil
        if have_impact_1 or have_impact_2 then
        else
            obj_me:set_talent_trigger_time(talent.name)
            impactenginer:send_impact_to_unit(obj_me, impact_id_1, obj_me, 0, false, 0)
        end
    end
end

return std_talent_034