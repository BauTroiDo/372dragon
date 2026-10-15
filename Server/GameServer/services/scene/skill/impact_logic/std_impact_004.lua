local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_004 = class("std_impact_004", base)
local impactenginer = require "impactenginer":getinstance()
local equip_dress_bonus = require "equip_dress_bonus"

function std_impact_004:ctor()

end

function std_impact_004:is_over_timed()
    return false
end

function std_impact_004:is_intervaled()
    return false
end

function std_impact_004:get_hp_modify(imp)
    return imp.params["HP修改量"] or 0
end

function std_impact_004:set_hp_modify(imp, modify)
    imp.params["HP修改量"] = modify
end

function std_impact_004:get_mp_modify(imp)
    return imp.params["MP修改量"] or 0
end

function std_impact_004:set_mp_modify(imp, modify)
    imp.params["MP修改量"] = modify
end

function std_impact_004:get_rage_modify(imp)
    return imp.params["Rage修改量"] or 0
end

function std_impact_004:set_rage_modify(imp,value)
    imp.params["Rage修改量"] = value
end

function std_impact_004:get_strike_point_modify(imp)
    return imp.params["StrikePoint修改量"] or 0
end

function std_impact_004:get_datura_flower_modify(imp)
    return imp.params["DaturaFlower修改量"] or 0
end

function std_impact_004:get_hp_modify_rate(imp)
    return imp.params["HP修改量%"] or 0
end

function std_impact_004:get_mp_modify_rate(imp)
    return imp.params["MP修改量%"] or 0
end

function std_impact_004:get_rage_to(imp)
    return imp.params["Rage降低至"] or 0
end

function std_impact_004:get_add_buff(imp)
    return imp.params["给予BUFF"] or -1
end

function std_impact_004:set_rage_to(imp,value)
    imp.params["Rage降低至"] = value
end

function std_impact_004:set_add_buff(imp,value)
    imp.params["给予BUFF"] = value
end

function std_impact_004:set_absorb_rage(imp,value)
    imp.params["吸取怒气"] = value
end

function std_impact_004:get_absorb_rage(imp)
    return imp.params["吸取怒气"] or 0
end

function std_impact_004:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local caster_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_id)
    local hp_modify = self:get_hp_modify(imp)
    local hp_before = obj:get_attrib("hp")
    -- print("std_impact_004:on_active name =", obj:get_name(), ";hp_modify =", hp_modify)
	if hp_modify ~= 0 then
		obj:health_increment(hp_modify, sender)
	end
    local hp_modify_rate = self:get_hp_modify_rate(imp)
    if hp_modify_rate ~= 0 then
        local hp_max = obj:get_max_hp()
        local recover_hp = math.ceil(hp_max * hp_modify_rate / 100)
        obj:health_increment(recover_hp, sender)
    end
    local effective_heal = math.max(0, obj:get_attrib("hp") - hp_before)
    if sender and effective_heal > 0 then
        sender:on_heal_target(imp:get_skill_id(), effective_heal, obj:get_obj_id())
    end
    local mp_modify_rate = self:get_mp_modify_rate(imp)
    if mp_modify_rate ~= 0 then
        local mp_max = obj:get_max_hp()
        local recover_hp = math.ceil(mp_max * mp_modify_rate / 100)
        obj:mana_increment(recover_hp, sender)
    end
    if obj:get_obj_type() == "human" then
        local mp_modify = self:get_mp_modify(imp)
		if mp_modify ~= 0 then
			obj:mana_increment(mp_modify, sender)
		end
        if imp:get_data_index() == 36 or imp:get_skill_id() == 35 then
            local sit_rate = equip_dress_bonus.get_xiuyi_sit_recover_rate(obj)
            if sit_rate > 0 and equip_dress_bonus.is_sit_recover_allowed(obj) then
                local recover_hp = math.ceil(obj:get_max_hp() * sit_rate / 100)
                local recover_mp = math.ceil(obj:get_max_mp() * sit_rate / 100)
                if recover_hp > 0 then
                    obj:health_increment(recover_hp, sender)
                end
                if recover_mp > 0 then
                    obj:mana_increment(recover_mp, sender)
                end
            end
        end
        local rage_modify = self:get_rage_modify(imp)
		if rage_modify ~= 0 then
			local sub_rage = obj:rage_increment(rage_modify, sender)
			if sender and sub_rage and sub_rage > 0 then
				local rage_to = self:get_rage_to(imp)
				if rage_to > 0 then
					local max_rage = obj:get_max_rage()
					rage_to = rage_to * max_rage / 100
					local cur_rage = obj:get_rage()
					if cur_rage + rage_modify <= rage_to then
						local buffid = self:get_add_buff(imp)
						if buffid ~= -1 then
							impactenginer:send_impact_to_unit(obj, buffid, sender, 0, false, 0)
						end
					end
				end
				local absorb_rage = self:get_absorb_rage(imp)
				if absorb_rage > 0 then
					absorb_rage = absorb_rage * sub_rage / 100
					sender:rage_increment(absorb_rage, sender)
				end
			end
		end
        local strike_point_modify = self:get_strike_point_modify(imp)
		if strike_point_modify ~= 0 then
			obj:strike_point_increment(strike_point_modify, sender)
		end

        local datura_flower_modify = self:get_datura_flower_modify(imp)
		if datura_flower_modify ~= 0 then
			obj:datura_flower_increment(datura_flower_modify, sender)
		end
    end
end

return std_impact_004
