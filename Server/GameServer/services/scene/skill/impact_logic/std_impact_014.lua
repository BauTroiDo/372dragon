local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local impactenginer = require "impactenginer":getinstance()
local std_impact_014 = class("std_impact_014", base)
local IMPACT_530 = require "scene.skill.impact_logic.std_impact_530"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_014:is_over_timed()
    return true
end

function std_impact_014:is_intervaled()
    return false
end

function std_impact_014:get_refix_can_action_1(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否使用任何技能（CanAction1标记，-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_014:get_refix_can_action_2(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否使用任何技能（CanAction2标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_014:get_refix_can_move(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否移动（CanMove标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_014:get_refix_unbreakable(imp, args)
    args.replace = args.replace or 0
    if args.replace == 0 then
        local value = imp.params["无敌否（Unbreakable标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_014:is_unbreakable_impact(imp)
    local value = imp.params["无敌否（Unbreakable标记,-1为无效）"]
    return value == 1
end

function std_impact_014:get_refix_stealth_level(imp, args)
    args.replace = args.replace or 0
    local value = imp.params["隐身级别修正（0为无效）"]
    if value ~= 0 then
        args.replace = value > args.replace and value or args.replace
    end
end

function std_impact_014:is_stealth_impact(imp)
    local value = imp.params["隐身级别修正（0为无效）"]
    return value ~= 0
end

function std_impact_014:get_refix_detect_level(imp, args)
    args.replace = args.replace or 0
    local value = imp.params["反隐级别修正（0为无效）"]
    if value ~= 0 then
        args.replace = value > args.replace and value or args.replace
    end
end

-- transform-model 17/09: `imp.params` CHỈ có nhãn mà chính dòng StandardImpact đó khai
-- (`cfghelper:read_std_impact` đổ theo cặp 参数N说明/参数值). Dòng logic 14 nào không khai `变身ID(-1为无效)`
-- sẽ cho `value = nil`, mà `nil ~= -1` là TRUE ⇒ bản cũ ghi `args.replace = nil` và **xoá luôn** giá trị mà
-- một impact biến thân đứng trước trong danh sách vừa đặt. Trên bảng sống có đúng 2 dòng như vậy
-- (`5700 坐骑：初级年兽`, `5702 坐骑：高级年兽` — nhãn bị hỏng thành `-2为无效`/`-0为无效`).
-- Thêm `value and` để nil = "dòng này không nói gì về model", không phải "gỡ biến thân".
function std_impact_014:get_refix_model_id(imp, args)
    local value = imp.params["变身ID(-1为无效)"]
    if value and value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_014:get_refix_ride_model(imp, args)
    local value = imp.params["骑乘ID(-1为无效)"]
    if value and value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_014:get_refix_speed(imp, args)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    args.rate = (args.rate or 0) + value
end

function std_impact_014:get_value_of_refix_speed(imp)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    return value
end

function std_impact_014:set_value_of_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_014:set_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_014:get_refix_reduce_def_fire_low_limit(imp, args)
    local value = imp.params["火减抗下限"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_014:set_value_of__refix_reduce_def_fire_low_limit(imp, value)
    imp.params["火减抗下限"] = value
end

function std_impact_014:get_refix_mind_defend(imp, args)
    local value = imp.params["会心防御修正(0为无效)"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_014:set_value_of_refix_mind_defend(imp, rate)
    imp.params["会心防御修正(0为无效)"] = rate
end

function std_impact_014:set_disable_treatment(imp)
    return imp.params["禁止治疗"] == 1
end

function std_impact_014:get_refix_skill_accuracy(imp)
    return imp.params["命中率%"] or 0
end

function std_impact_014:get_mind_attack_damage_up_rate(imp)
    return imp.params["会心伤害%"] or 0
end

function std_impact_014:refix_skill(imp, obj, skill_info)
	local rate_up = self:get_refix_skill_accuracy(imp)
	if rate_up > 0 then
        local accuracy_up_rate = skill_info:get_accuracy_rate_up()
        skill_info:set_accuracy_rate_up(accuracy_up_rate + rate_up)
	end
end

function std_impact_014:on_damage_target(imp, obj, target, damages)
	if damages and damages.damage_rate then
		damages.imm_recover_hp = damages.imm_recover_hp or self:set_disable_treatment(imp)
		local rate = self:get_mind_attack_damage_up_rate(imp)
		if rate > 0 and imp:is_critical_hit() then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + rate
			end
		end
	end
end

function std_impact_014:on_be_heal(imp, obj_me, sender, health, skill_id)
    if self:set_disable_treatment(imp) then
        health.hp_modify = 0
    end
end

function std_impact_014:on_active(imp, obj)
	local is_human = obj:get_obj_type() == "human"
	local stand_flag = imp:get_stand_flag()
    if stand_flag == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_AMITY and self:is_unbreakable_impact(imp) then
        obj:dispel_hostility_impact()
	elseif stand_flag == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
		if is_human then
			if impactenginer:is_impact_in_collection_ex(imp,IMPACT_530.control_effect) then
				imp:set_chonglou_sash()
				obj:update_chonglou_sash(imp)
			end
		end
    end
    if is_human then
        obj:send_refresh_attrib()
    end
end
function std_impact_014:on_fade_out(imp, obj)
    -- if not obj:is_alive() then
        -- return
    -- end
	local value1 = imp.params["消失时关联BUFFID1"] or -1
	local value2 = imp.params["消失时关联BUFFID2"] or -1
	if value1 ~= -1 or value2 ~= -1 then
		local buffid
		local impact_list = obj:get_impact_list()
		for _,have in ipairs(impact_list) do
			buffid = have:get_data_index()
			if buffid == value1 or buffid == value2 then
				if have:is_can_be_cancled() then
					obj:on_impact_fade_out(have)
					obj:remove_impact(have)
				end
			end
		end
	end
end


return std_impact_014