local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_325 = class("std_impact_325", base)

function std_impact_325:is_over_timed()
    return true
end

function std_impact_325:is_intervaled()
    return false
end

function std_impact_325:is_specific_skill(skill_id)
    return skill_id == 461
end

function std_impact_325:get_increase_probability(imp)
    return imp.params["增加机率"] or 0
end

function std_impact_325:set_increase_probability(imp,value)
    imp.params["增加机率"] = value
end

function std_impact_325:get_talent_818_value(imp)
    return imp.params["增加下次机率"] or 0
end

function std_impact_325:set_talent_818_value(imp,value)
    imp.params["增加下次机率"] = value
end

function std_impact_325:get_talent_818_have(imp)
    return imp.params["武道增加机率"] or 0
end

function std_impact_325:set_talent_818_have(imp,value)
    imp.params["武道增加机率"] = value
end

function std_impact_325:get_talent_820_value(imp)
    return imp.params["触发两种效果概率"] or 0
end

function std_impact_325:set_talent_820_value(imp,value)
    imp.params["触发两种效果概率"] = value
end

function std_impact_325:get_talent_822_value(imp)
    return imp.params["属性对比修正"] or 0
end

function std_impact_325:set_talent_822_value(imp,value)
    imp.params["属性对比修正"] = value
end

function std_impact_325:get_talent_821_value(imp)
    return imp.params["增加机率821"] or 0
end

function std_impact_325:set_talent_821_value(imp,value)
    imp.params["增加机率821"] = value
end



function std_impact_325:on_damage_target(imp, sender, reciver, damages, skill)
    if self:is_specific_skill(skill) then
        local num = math.random(100)
		local rate = 10 + self:get_talent_818_value(imp) + self:get_talent_821_value(imp)
		if imp:is_critical_hit() then
			rate = rate + self:get_increase_probability(imp)
		end
        if num <= rate then
            local impacts = {}
			rate = self:get_talent_822_value(imp)
			if rate > 0 then
				if sender:get_attack_cold() > reciver:get_attack_cold() * rate then
					table.insert(impacts, 50055)
				end
				if sender:get_attack_fire() > reciver:get_attack_fire() * rate then
					table.insert(impacts, 50056)
				end
				if sender:get_attack_light() > reciver:get_attack_light() * rate then
					table.insert(impacts, 50057)
				end
				if sender:get_attack_posion() > reciver:get_attack_posion() * rate then
					table.insert(impacts, 50058)
				end
			else
				if sender:get_attack_cold() > reciver:get_attack_cold() then
					table.insert(impacts, 50055)
				end
				if sender:get_attack_fire() > reciver:get_attack_fire() then
					table.insert(impacts, 50056)
				end
				if sender:get_attack_light() > reciver:get_attack_light() then
					table.insert(impacts, 50057)
				end
				if sender:get_attack_posion() > reciver:get_attack_posion() then
					table.insert(impacts, 50058)
				end
			end
            if #impacts > 0 then
				self:set_talent_818_value(imp,0)
                local n = math.random(1, #impacts)
                local impact_id = table.remove(impacts,n)
                if impact_id == 50056 then
                    impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
                else
                    impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
                end
				rate = self:get_talent_820_value(imp)
				if rate > 0 and #impacts > 0 then
					if math.random(100) <= rate then
						local n = math.random(1, #impacts)
						impact_id = impacts[n]
						if impact_id == 50056 then
							impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
						else
							impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
						end
					end
				end
			else
				local have = self:get_talent_818_have(imp)
				self:set_talent_818_value(imp,have)
            end
        end
    end
end

return std_impact_325