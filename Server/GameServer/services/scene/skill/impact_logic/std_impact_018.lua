local class = require "class"
local define = require "define"
local configenginer= require "configenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_018 = class("std_impact_018", base)

function std_impact_018:is_over_timed()
    return false
end

function std_impact_018:is_intervaled()
    return false
end

function std_impact_018:get_dispel_level(imp)
    return imp.params["驱散级别"]
end

function std_impact_018:get_dispel_count(imp)
    return imp.params["驱散个数"]
end

function std_impact_018:get_collection_by_index(imp, index)
    local key = string.format("驱散集合%d", index)
    return imp.params[key] or define.INVAILD_ID
end
function std_impact_018:get_skill_by_index(imp, index)
    local key = string.format("不可驱散技能%d", index)
    return imp.params[key] or define.INVAILD_ID
end

function std_impact_018:on_active(imp, obj_me)
    local collections_config = configenginer:get_config("id_collections")
    local dispel_level = self:get_dispel_level(imp)
    local dispel_count = self:get_dispel_count(imp)
    assert(dispel_level, imp:get_data_index())
	local skill = {}
    local SKILL_NUMBER = 2
    for i = 1, SKILL_NUMBER do
		local skill_id = self:get_skill_by_index(imp, i)
		if skill_id ~= define.INVAILD_ID then
			table.insert(skill,skill_id)
		end
	end
    local COLLECTION_NUMBER = 4
    local dispeld = 0
    assert(dispel_level, imp:get_data_index())
    for i = 1, COLLECTION_NUMBER do
        local collection_id = self:get_collection_by_index(imp, i)
        if collection_id ~= define.INVAILD_ID then
            local collections = collections_config[collection_id]
            if collections then
                dispeld = dispeld + obj_me:dispel_Impact_in_specific_collection(collection_id, dispel_level, dispel_count, skill)
                if dispeld >= dispel_count then
                    break
                end
            end
        end
    end
end

return std_impact_018