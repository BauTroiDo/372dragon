local class = require "class"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.skill.base"
local skill_5 = class("skill_5", base)

function skill_5:get_script_id(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["脚本ID"] or define.INVAILD_ID
end

function skill_5:effect_on_unit_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local script_id = self:get_script_id(skill_info)
    if script_id ~= define.INVAILD_ID then
        local arg_1 = params:get_script_arg_1()
        local arg_2 = params:get_script_arg_2()
        local arg_3 = params:get_script_arg_3()
		local selfId = obj_me:get_obj_id() * -1
        scriptenginer:call(script_id, "skill_effect_on_uint_once", selfId, arg_1, arg_2, arg_3)
    end
end

return skill_5