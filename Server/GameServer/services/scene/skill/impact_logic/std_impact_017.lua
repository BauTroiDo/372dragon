local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_017 = class("std_impact_017", base)

function std_impact_017:is_over_timed()
    return false
end

function std_impact_017:is_intervaled()
    return true
end

function std_impact_017:get_immuno_level(imp)
    return imp.params["免疫级别"] or 0
end

function std_impact_017:get_immuno_by_index(imp, index)
    local key = string.format("免疫集合%d", index)
    return imp.params[key] or 0
end

function std_impact_017:get_recover_hp_rate(imp)
    return imp.params["每秒恢复血量比例"] or 0
end

function std_impact_017:set_recover_hp_rate(imp, rate)
    imp.params["每秒恢复血量比例"] = rate
end

-- local skynet = require "skynet"
function std_impact_017:on_filtrate_impact(imp, obj_me, need_check_imp)
	if not need_check_imp then return end
	local rate = imp.params["触发机率"] or 0
	if rate > 0 then
		if rate < math.random(100) then
			return false
		end
	end
    if need_check_imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
        local immuno_level = self:get_immuno_level(imp) / 10
		local skill_level = need_check_imp:get_skill_level() or 1
		if immuno_level >= skill_level then
			local COLLECTION_COUNT = 8
			local collection_ids = {}
			local collection_id
			for i = 1, COLLECTION_COUNT do
				collection_id = self:get_immuno_by_index(imp, i)
				if collection_id ~= 0 then
					table.insert(collection_ids,collection_id)
						-- if impactenginer:is_impact_in_collection(need_check_imp, collection_id) then
							-- return define.MissFlag_T.FLAG_IMMU
						-- end
				end
			end
			if impactenginer:is_impact_in_collection_ex(need_check_imp,collection_ids) then
				return define.MissFlag_T.FLAG_IMMU
			end
		end
    end
    return false
end

function std_impact_017:on_interval_over(imp, obj)
	-- skynet.logi("on_interval_over")
    if not obj:is_alive() then
        return
    end
    local rate = self:get_recover_hp_rate(imp)
    if rate > 0 then
        local recover_hp = math.ceil(obj:get_max_hp() * rate / 100)
        obj:health_increment(recover_hp, obj, false)
    end
end

return std_impact_017