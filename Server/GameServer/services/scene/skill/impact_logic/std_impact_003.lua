local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local define = require "define"
local std_impact_003 = class("std_impact_003", base)
std_impact_003.enum_DAMAGE_TYPE =
{
    IDX_DAMAGE_PHY    = 0,
    IDX_DAMAGE_MAGIC  = 1,
    IDX_DAMAGE_COLD   = 2,
    IDX_DAMAGE_FIRE   = 3,
    IDX_DAMAGE_LIGHT  = 4,
    IDX_DAMAGE_POISON = 5,
    IDX_DAMAGE_DIRECHT = 6
}
--备忘：可增不不减，不可换位置(位置为索引)，可改变量名
std_impact_003.enum_DAMAGE_TYPE_RATE =
{
	"wg_rate",
	"ng_rate",
	"bg_rate",
	"hg_rate",
	"xg_rate",
	"dg_rate",
	"damage_rate",
}
--备忘：可增不不减，不可换位置(位置为索引)，可改变量名
std_impact_003.enum_DAMAGE_TYPE_POINT =
{
	"wg_point",
	"ng_point",
	"bg_point",
	"hg_point",
	"xg_point",
	"dg_point",
	"damage_point",
}
--备忘：可增不不减，不可换位置(位置为索引)，可改变量名
std_impact_003.enum_DAMAGE_TYPE_BACK =
{
	"back_impact",
	"back_talent",
	"recover_dmg_rate",
	"recover_hp_rate",
	"recover_mp_rate",
	"add_dmg_mp_rate",
	"recover_nq_rate",
	"add_dmg_hp_rate",
}

std_impact_003.ID = 3
function std_impact_003:ctor()
end

function std_impact_003:is_over_timed()
    return false
end

function std_impact_003:is_intervaled()
    return false
end

function std_impact_003:get_attack_phy(imp)
    return imp.params["物理攻击+"] or 0
end

function std_impact_003:set_attack_phy(imp, value)
    imp.params["物理攻击+"] = value
end

function std_impact_003:get_attack_magic(imp)
    return imp.params["魔法攻击+"] or 0
end

function std_impact_003:set_attack_magic(imp, value)
    imp.params["魔法攻击+"] = value
end

function std_impact_003:get_attack_cold(imp)
    return imp.params["冰系攻击"] or 0
end

function std_impact_003:set_attack_cold(imp, value)
    imp.params["冰系攻击"] = value
end

function std_impact_003:get_attack_fire(imp)
    return imp.params["火系攻击"] or 0
end

function std_impact_003:set_attack_fire(imp, value)
    imp.params["火系攻击"] = value
end

function std_impact_003:get_attack_light(imp)
    return imp.params["电系攻击"] or 0
end

function std_impact_003:set_attack_light(imp, value)
    imp.params["电系攻击"] = value
end

function std_impact_003:get_attack_posion(imp)
    return imp.params["毒系攻击"] or 0
end

function std_impact_003:set_attack_posion(imp, value)
    imp.params["毒系攻击"] = value
end

function std_impact_003:get_attack_direct(imp)
    return (imp.params["伤害数值"] or imp.params["伤害数值+"]) or 0
end

function std_impact_003:set_attack_direct(imp, value)
    imp.params["伤害数值"] = value
end


function std_impact_003:get_damage_phy(imp)
    return imp.params["物理伤害"] or 0
end

function std_impact_003:set_damage_phy(imp, value)
    imp.params["物理伤害"] =  value
end

function std_impact_003:get_damage_magic(imp)
    return imp.params["魔法伤害"] or 0
end

function std_impact_003:set_damage_magic(imp, value)
    imp.params["魔法伤害"] =  value
end

function std_impact_003:get_damage_cold(imp)
    return imp.params["冰系伤害"] or 0
end

function std_impact_003:set_damage_cold(imp, value)
    imp.params["冰系伤害"] = value
end

function std_impact_003:get_damage_fire(imp)
    return imp.params["火系伤害"] or 0
end

function std_impact_003:set_damage_fire(imp, value)
    imp.params["火系伤害"] = value
end

function std_impact_003:get_damage_light(imp)
    return imp.params["电系伤害"] or 0
end

function std_impact_003:set_damage_light(imp, value)
    imp.params["电系伤害"] = value
end

function std_impact_003:get_damage_posion(imp)
    return imp.params["毒系伤害"] or 0
end

function std_impact_003:set_damage_posion(imp, value)
    imp.params["毒系伤害"] = value
end

function std_impact_003:get_damage_direct(imp)
    return (imp.params["直接伤害"]) or 0
end

function std_impact_003:set_damage_direct(imp, value)
    imp.params["直接伤害"] = value
end





function std_impact_003:set_trigger_index(imp, index)
    imp.params["触发Index"] = index
end

function std_impact_003:get_trigger_index(imp)
    return imp.params["触发Index"]
end

function std_impact_003:get_value_of_damage_up(imp)
    return imp.params["伤害提升+"] or 0
end

function std_impact_003:set_value_of_damage_up(imp,value)
	imp.params["伤害提升+"] = value
end

function std_impact_003:on_active(imp, obj)
    if not imp or not obj then
        return
	elseif not obj:is_alive() then
		return
    end
	local targetid = imp:get_caster_obj_id()
	local sender = obj:get_scene():get_obj_by_id(targetid)
	if not sender then
		return
	end
	local skill_id = imp:get_skill_id()
	local is_critical_hit = imp:is_critical_hit()
	
    local damages = {hp_damage = 1}
	if skill_id and skill_id ~= -1 and define.CHUANCI_SKILL[skill_id] then
		local chuanci = obj:get_chuanci_damage(sender,is_critical_hit)
		if chuanci > 0 then
			damages.chuanci = chuanci
		end
	end
	
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY] = self:get_damage_phy(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC] = self:get_damage_magic(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_COLD] = self:get_damage_cold(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_FIRE] = self:get_damage_fire(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_LIGHT] = self:get_damage_light(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_POISON] = self:get_damage_posion(imp)
    damages[self.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = self:get_damage_direct(imp)
	
	for _,j in ipairs(self.enum_DAMAGE_TYPE_RATE) do
		damages[j] = imp.params[j] or 100
	end
	for _,j in ipairs(self.enum_DAMAGE_TYPE_POINT) do
		damages[j] = imp.params[j] or 0
	end
	for _,j in ipairs(self.enum_DAMAGE_TYPE_BACK) do
		damages[j] = {}
	end
    -- skynet.error("[DBG_COMBAT] on_active: skill=", skill_id, " hp_dmg=", damages.hp_damage)
    obj:on_damages(damages, targetid, is_critical_hit, skill_id, imp)
end
--暴击
function std_impact_003:critical_refix(imp,obj)
	local rate = 120 -- 暴击倍率: +120% = 2.2倍
	-- if imp:get_features(20) then
		local targetid = imp:get_caster_obj_id()
		if targetid ~= -1 then
			local sender = obj:get_scene():get_obj_by_id(targetid)
			if sender then
				local effect_value,feature_rate = sender:get_dw_jinjie_effect_details(20)
				if effect_value > 0 and math.random(100) <= 25 then
					rate = rate + effect_value / feature_rate
					sender:features_effect_notify_client(20)
				end
			end
		end
	-- end
	local cy_sender = obj:get_scene():get_obj_by_id(imp:get_caster_obj_id())
	rate = require("cy_four_combat.hooks").critical_rate(cy_sender, rate, imp:get_skill_id())
	for _,j in ipairs(self.enum_DAMAGE_TYPE_RATE) do
		imp:add_rate_params(j,rate)
	end
    imp:mark_critical_hit_flag()
end
--伤害比例
function std_impact_003:refix_power_by_rate(imp, rate)
    if rate == 0 then
        return false
    end
	for _,j in ipairs(self.enum_DAMAGE_TYPE_RATE) do
		imp:add_rate_params(j,rate)
	end
    return true
end
--属性比例
function std_impact_003:refix_skill_power_by_rate(imp, rate)
    if rate == 0 then
        return false
    end
    rate = rate + 100
    self:set_attack_phy(imp, self:get_attack_phy(imp) * rate / 100)
    self:set_attack_magic(imp, self:get_attack_magic(imp) * rate / 100)
    self:set_attack_cold(imp, self:get_attack_cold(imp) * rate / 100)
    self:set_attack_fire(imp, self:get_attack_fire(imp) * rate / 100)
    self:set_attack_light(imp, self:get_attack_light(imp) * rate / 100)
    self:set_attack_posion(imp, self:get_attack_posion(imp) * rate / 100)
    return true
end

function std_impact_003:get_value_of_refix_attrib_att_magic(imp)
    return imp.params["魔法攻击+"] or 0
end

function std_impact_003:set_value_of_refix_attrib_att_magic(imp, value)
    imp.params["魔法攻击+"] = value
end


return std_impact_003
