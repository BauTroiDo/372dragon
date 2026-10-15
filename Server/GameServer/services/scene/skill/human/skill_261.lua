local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local impact = require "scene.skill.impact"
local SOT_XiaoYaoTraps_T = require "scene.skill.impact_logic.std_impact_052"
local special_obj = require "scene.special_obj.base"
local base = require "scene.skill.base"
local skill_261 = class("skill_261", base)

function skill_261:get_impact_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["瞬发效果ID"] or -1
end

function skill_261:get_trap_class(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["引爆的陷阱类型ID"] or -1
end
-- local skynet = require "skynet"
function skill_261:effect_on_unit_once(obj_me, _, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local impact_data_index = self:get_impact_data_index(skill_info)
	if impact_data_index ~= -1 then
		impactenginer:send_impact_to_unit(obj_me, impact_data_index, obj_me, params:get_delay_time(), is_critical)
	end
    local imp = obj_me:impact_get_first_impact_of_specific_impact_id(SOT_XiaoYaoTraps_T.IMPACT_ID)
    if not imp then
        return true
    end
	local special_obj_data = configenginer:get_config("special_obj_data")
    local collections_config = configenginer:get_config("id_collections")
	local trap_class = self:get_trap_class(skill_info)
	collections_config = collections_config[trap_class]
	if not collections_config then
		return true
	end
    for i = 1, SOT_XiaoYaoTraps_T.MAX_TRAP_COUNT do
        local trap_obj_id = SOT_XiaoYaoTraps_T:get_trap_by_index(imp, i)
        if trap_obj_id ~= define.INVAILD_ID then
            local trap = obj_me:get_scene():get_obj_by_id(trap_obj_id)
            if trap and trap:get_obj_type() == "special" then
                local logic = trap:get_logic()
                if logic then
                    if logic:get_type() == special_obj.eSpecailObjType.TRAP_OBJ then
						local trapid = trap:get_data_id()
						-- skynet.logi("trapid = ",trapid)
						local data = special_obj_data[trapid]
						if data then
							local key = data.class
						-- skynet.logi("key = ",key)
							if collections_config.ids[key] then
								logic:force_activate(trap)
							end
						end
                    end
                end
            end
        end
    end
    return true
end

return skill_261