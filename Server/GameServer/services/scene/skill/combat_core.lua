-- 战斗核心模块
-- 负责处理游戏中的战斗伤害计算、命中率、暴击率等核心战斗逻辑

local class = require "class"
local skynet = require "skynet"
local define = require "define"
local configs = require "scene.configs"
local configenginer = require "configenginer":getinstance()
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local enum_damage_type = damage_impact_logic.enum_DAMAGE_TYPE
local combat_core = class("combat_core")

-- 伤害特效ID枚举
-- 用于标识不同类型的伤害特效，用于客户端显示
combat_core.enum_DamageSEID = {
    DAMAGE_SPECIAL_EFFECT_PHYSICAL=0,  -- 物理伤害特效
    DAMAGE_SPECIAL_EFFECT_MAGIC=1,     -- 魔法伤害特效
    DAMAGE_SPECIAL_EFFECT_COLD=2,      -- 冰属性伤害特效
    DAMAGE_SPECIAL_EFFECT_FIRE=3,      -- 火属性伤害特效
    DAMAGE_SPECIAL_EFFECT_LIGHT=4,     -- 雷属性伤害特效
    DAMAGE_SPECIAL_EFFECT_POISON=5     -- 毒属性伤害特效
}

-- 构造函数
function combat_core:ctor()
    self:reset()
end

-- 重置所有额外属性值
-- 在每次战斗计算前调用，确保属性值清零
function combat_core:reset()
    self.additional_attac_physics = 0   -- 额外物理攻击力
    self.additional_attack_magic = 0    -- 额外魔法攻击力
    self.additional_attack_cold = 0     -- 额外冰属性攻击力
    self.additional_attack_fire = 0     -- 额外火属性攻击力
    self.additional_attack_light = 0    -- 额外雷属性攻击力
    self.additional_attack_poison = 0   -- 额外毒属性攻击力
    self.additional_defence_physics = 0 -- 额外物理防御力
    self.additional_defence_magic = 0   -- 额外魔法防御力
    self.additional_defence_cold = 0    -- 额外冰属性防御力
    self.additional_defence_fire = 0    -- 额外火属性防御力
    self.additional_defence_light = 0   -- 额外雷属性防御力
    self.additional_defence_poison = 0  -- 额外毒属性防御力
    self.additional_attack_direct = 0    -- 额外直接伤害
end

-- 设置额外物理防御力
function combat_core:set_additional_defence_physics(additional_defence_physics)
    self.additional_defence_physics = additional_defence_physics
end

-- 设置额外魔法防御力
function combat_core:set_additional_defence_magic(additional_defence_magic)
    self.additional_defence_magic = additional_defence_magic
end

-- 设置额外魔法攻击力
function combat_core:set_additional_attack_magic(additional_attack_magic)
    self.additional_attack_magic = additional_attack_magic
end

-- 获取额外魔法攻击力
function combat_core:get_additional_attack_magic()
    return self.additional_attack_magic
end

-- 计算命中率
-- @param hit 命中次数
-- @param miss 未命中次数
-- @return 命中率（0-1之间的小数）
function combat_core:calculate_hit_rate(hit, miss)
	if hit == 0 and miss == 0 then
		return 0.5  -- 如果没有数据，默认50%命中率
	end
    return hit / (hit + miss)
end

-- 计算暴击率
-- @param mind_attack 攻击者的精神属性
-- @param mind_defend 防御者的精神属性
-- @return 暴击率（0-1之间的小数）
function combat_core:calculate_critical_rate(mind_attack, mind_defend)
	if not mind_defend or mind_defend == 0 then
		mind_defend = 1  -- 防止除零错误
	end
    return mind_attack / (mind_defend * 20)
    -- 备选公式: return mind_attack / (mind_defend + mind_attack)
end

-- 判断是否命中
-- @param accuracy 命中率（0-1之间的小数）
-- @param rand 随机数（0-100）
-- @return 是否命中
function combat_core:is_hit(accuracy, rand)
    local result = rand <= accuracy * 100
    -- skynet.error("[DBG_COMBAT] is_hit: accuracy=", accuracy, " rand=", rand, " threshold=", accuracy and (accuracy * 100) or "nil", " result=", result)
    return result
end

-- 判断是否暴击
-- @param critical_rate 暴击率（0-1之间的小数）
-- @param rand 随机数（0-100）
-- @return 是否暴击
function combat_core:is_critical_hit(critical_rate, rand)
	if critical_rate >= 1 then
		return true  -- 暴击率100%时必定暴击
	end
    return rand <= critical_rate * 100
end

-- 获取战斗结果
-- 计算攻击者对防御者造成的所有类型伤害，并返回伤害结果
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param imp 伤害影响对象
-- @return 伤害影响对象
function combat_core:get_result_impact(attacker, defencer, imp)
    if not attacker then
        return
    end
    -- 触发攻击者的战斗结果回调
    if imp then
        attacker:on_impact_get_combat_result(imp, self, defencer)
    end
    local damage
    local max_damage
    local specific_effect_id
    local logic = damage_impact_logic.new()
    local attck_traits = configenginer:get_config("attck_traits")
    local atype = attacker:get_attack_traits_type()
    local traits = attck_traits[atype]
    
    -- 累加技能带来的额外攻击力
    self.additional_attac_physics = self.additional_attac_physics + logic:get_attack_phy(imp)
    self.additional_attack_magic  = self.additional_attack_magic + logic:get_attack_magic(imp)
    self.additional_attack_cold	  = self.additional_attack_cold + logic:get_attack_cold(imp)
    self.additional_attack_fire	  = self.additional_attack_fire + logic:get_attack_fire(imp)
    self.additional_attack_light  = self.additional_attack_light + logic:get_attack_light(imp)
    self.additional_attack_poison = self.additional_attack_poison + logic:get_attack_posion(imp)
    self.additional_attack_direct = self.additional_attack_direct + logic:get_attack_direct(imp)
    
    -- 获取伤害浮动值
    local fluctuation = configs:get_fluctuation()
    if attacker:get_obj_type() == "human" then
        local menpai = attacker:get_menpai()
        fluctuation = configs:get_menpai_fluctuation(menpai)
		-- 如果攻击类型大于等于10，调整攻击类型
		-- CYS-PVP: human:get_attack_traits_type already resolves CY identities.
    end
    
    -- 计算伤害浮动系数（-fluctuation 到 +fluctuation）
    local rand = 50
    rand = rand - math.random(100)
    fluctuation = 2 * fluctuation * rand / 100
    
    -- 计算物理伤害
    damage = self:physical_damage(attacker, defencer, self.additional_attac_physics, self.additional_defence_physics, traits)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_phy(imp, damage)
    max_damage = damage
    specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_PHYSICAL;

    -- 计算魔法伤害
    damage = self:magic_damage(attacker, defencer, self.additional_attack_magic, self.additional_defence_magic, traits)
    damage	= damage + damage * fluctuation / 100
    logic:set_damage_magic(imp, damage)
    if damage > max_damage then
        max_damage = damage
        specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_MAGIC;
    end

    -- 计算冰属性伤害
    damage = self:cold_damage(attacker, defencer, self.additional_attack_cold, self.additional_defence_cold, traits)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_cold(imp, damage)
    if damage > max_damage then
        max_damage = damage
        specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_COLD;
    end

    -- 计算火属性伤害
    damage = self:fire_damage(attacker, defencer, self.additional_attack_fire, self.additional_defence_fire, traits)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_fire(imp, damage)
    if damage > max_damage then
        max_damage = damage
        specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_FIRE;
    end

    -- 计算雷属性伤害
    damage = self:light_damage(attacker, defencer, self.additional_attack_light, self.additional_defence_light, traits)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_light(imp, damage)
    if damage > max_damage then
        max_damage = damage
        specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_LIGHT;
    end

    -- 计算毒属性伤害
    damage = self:posion_damage(attacker, defencer, self.additional_attack_poison, self.additional_defence_poison, traits)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_posion(imp, damage)
    if damage > max_damage then
        specific_effect_id = self.enum_DamageSEID.DAMAGE_SPECIAL_EFFECT_POISON;
    end

    -- 计算直接伤害
    damage = self:direct_damage(attacker, defencer, self.additional_attack_direct)
    damage = damage + damage * fluctuation / 100
    logic:set_damage_direct(imp, damage)
    require("cy_four_combat.release").scale_damage(attacker,imp,logic)
    if imp._cy_four_landing_direct then
        for _,name in ipairs({"phy","magic","cold","fire","light","posion"})do logic["set_damage_"..name](logic,imp,0)end
        logic:set_damage_direct(imp,imp._cy_four_landing_direct)
    end
    --imp:set_impact_id(specific_effect_id)  -- 设置最大伤害的特效ID
    return imp
end

-- 计算物理伤害
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 物理伤害值
function combat_core:physical_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_physics() + addition_attack
    local defence = defencer:get_defence_physics() + addition_defence
    local ignorerate = 0  -- 免伤率
    local trait = traits[enum_damage_type.IDX_DAMAGE_PHY]
    
    -- 获取防御者的物理免伤率（仅玩家）
    if defencer:get_obj_type() == "human" then
        ignorerate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_IMMUNITY_P)
    end
    
    -- 检查技能是否忽略防御
    local skill_info = attacker:get_skill_info()
	if skill_info and skill_info.id then
		local ignore_defence = skill_info:get_is_ignore_defence()
		if ignore_defence then
			defence = 0  -- 忽略防御，防御力设为0
		end
	end
	
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_PHYSIC_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_PHYSIC_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    
    -- 计算基础伤害：攻击力平方除以攻击力与防御力之和
    if attack + defence == 0 then
        damage = 0
    else
        damage = attack * attack / (attack + defence) * trait / 1000000
    end
    
    -- 应用免伤率
    ignorerate = ignorerate < 0 and 0 or ignorerate
    ignorerate = ignorerate > 100 and 100 or ignorerate
    damage = damage - damage * ignorerate / 100
    
    -- 应用百分比加成
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算魔法伤害
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 魔法伤害值
function combat_core:magic_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_magic() + addition_attack
    local defence = defencer:get_defence_magic() + addition_defence
    local ignorerate = 0  -- 免伤率
    local trait = traits[enum_damage_type.IDX_DAMAGE_MAGIC]
    
    -- 获取防御者的魔法免伤率（仅玩家）
    if defencer:get_obj_type() == "human" then
        ignorerate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_IMMUNITY_M)
    end
    
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_MAGIC_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_MAGIC_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    
    -- 计算基础伤害
    if attack + defence == 0 then
        damage = 0
    else
        damage = attack * attack / (attack + defence) * trait / 1000000
    end
    
    -- 应用免伤率
    ignorerate = ignorerate < 0 and 0 or ignorerate
    ignorerate = ignorerate > 100 and 100 or ignorerate
    damage = damage - damage * ignorerate / 100
    
    -- 应用百分比加成
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算冰属性伤害
-- 冰属性伤害使用抗性计算方式，与物理/魔法伤害不同
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 冰属性伤害值
function combat_core:cold_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_cold() + addition_attack
    local reduce_def = attacker:get_reduce_def_cold()  -- 降低防御值
    local reduce_def_low_limit = attacker:get_reduce_def_cold_low_limit()  -- 降低防御下限
    local defence = defencer:get_defence_cold() + addition_defence
    
    -- 如果降低防御值超过防御值，触发进阶效果（ID=22）
	if reduce_def > defence then
		local subdef = reduce_def - defence
		local effect_value,feature_rate = attacker:get_dw_jinjie_effect_details(22)
		if effect_value > 0 and feature_rate and feature_rate > 0 then
			effect_value = effect_value / feature_rate / 200 * subdef
			reduce_def_low_limit = reduce_def_low_limit + effect_value
			-- attacker:features_effect_notify_client(22)
		end
	end
	
    local trait = traits[enum_damage_type.IDX_DAMAGE_COLD]
    local resit = defence - reduce_def  -- 实际抗性
    local real_reduce_def_low_limit = (-1 * reduce_def_low_limit + (defence > 0 and 0 or defence))
    resit = resit < real_reduce_def_low_limit and (real_reduce_def_low_limit) or resit
    -- 调试输出已屏蔽
    -- print("cold_damage resit =", resit, ", defence =", defence)
    
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_COLD_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_COLD_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    
    -- 计算伤害：抗性越高伤害越低，抗性>=100时免疫
    if resit >= 100 then
        damage = 0
    else
        damage = attack * (100 - resit) / 100 * trait / 1000000
    end
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算火属性伤害
-- 火属性伤害使用抗性计算方式，与冰属性类似
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 火属性伤害值
function combat_core:fire_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_fire() + addition_attack
    local reduce_def = attacker:get_reduce_def_fire()  -- 降低防御值
    local reduce_def_low_limit = attacker:get_reduce_def_fire_low_limit()  -- 降低防御下限
    local defence = defencer:get_defence_fire() + addition_defence
    
    -- 如果降低防御值超过防御值，触发进阶效果（ID=23）
	if reduce_def > defence then
		local subdef = reduce_def - defence
		local effect_value,feature_rate = attacker:get_dw_jinjie_effect_details(23)
		if effect_value > 0 and feature_rate and feature_rate > 0 then
			effect_value = effect_value / feature_rate / 200 * subdef
			reduce_def_low_limit = reduce_def_low_limit + effect_value
			-- attacker:features_effect_notify_client(23)
		end
	end
	
    local trait = traits[enum_damage_type.IDX_DAMAGE_FIRE]
    local resit = defence - reduce_def  -- 实际抗性
    local real_reduce_def_low_limit = (-1 * reduce_def_low_limit + (defence > 0 and 0 or defence))
    resit = resit < real_reduce_def_low_limit and (real_reduce_def_low_limit) or resit
    -- 调试输出已屏蔽
    -- print("fire_damage resit =", resit, ", defence =", defence)
    
    -- 计算伤害：抗性越高伤害越低
    if resit >= 100 then
        damage = 0
    else
        damage = attack * (100 - resit) / 100 * trait / 1000000
    end
    
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_FIRE_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_FIRE_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算雷属性伤害
-- 雷属性伤害使用抗性计算方式，与冰/火属性类似
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 雷属性伤害值
function combat_core:light_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_light() + addition_attack
    local reduce_def = attacker:get_reduce_def_light()  -- 降低防御值
    local reduce_def_low_limit = attacker:get_reduce_def_light_low_limit()  -- 降低防御下限
    local defence = defencer:get_defence_light() + addition_defence
    
    -- 如果降低防御值超过防御值，触发进阶效果（ID=24）
	if reduce_def > defence then
		local subdef = reduce_def - defence
		local effect_value,feature_rate = attacker:get_dw_jinjie_effect_details(24)
		if effect_value > 0 and feature_rate and feature_rate > 0 then
			effect_value = effect_value / feature_rate / 200 * subdef
			reduce_def_low_limit = reduce_def_low_limit + effect_value
			-- attacker:features_effect_notify_client(24)
		end
	end
	
    local trait = traits[enum_damage_type.IDX_DAMAGE_LIGHT]
    local resit = defence - reduce_def  -- 实际抗性
    local real_reduce_def_low_limit = (-1 * reduce_def_low_limit + (defence > 0 and 0 or defence))
    resit = resit < real_reduce_def_low_limit and (real_reduce_def_low_limit) or resit
    -- 调试输出已屏蔽
    -- print("light_damage resit =", resit, ", defence =", defence)
    
    -- 计算伤害：抗性越高伤害越低
    if resit >= 100 then
        damage = 0
    else
        damage = attack * (100 - resit) / 100 * trait / 1000000
    end
    
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_LIGHT_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_LIGHT_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算毒属性伤害
-- 毒属性伤害使用抗性计算方式，与冰/火/雷属性类似
-- @param attacker 攻击者对象
-- @param defencer 防御者对象
-- @param addition_attack 额外攻击力
-- @param addition_defence 额外防御力
-- @param traits 攻击特性配置
-- @return 毒属性伤害值
function combat_core:posion_damage(attacker, defencer, addition_attack, addition_defence, traits)
    local damage
    local attack = attacker:get_attack_posion() + addition_attack
    local reduce_def = attacker:get_reduce_def_posion()  -- 降低防御值
    local reduce_def_low_limit = attacker:get_reduce_def_posion_low_limit()  -- 降低防御下限
    local defence = defencer:get_defence_posion() + addition_defence
    
    -- 如果降低防御值超过防御值，触发进阶效果（ID=25）
	if reduce_def > defence then
		local subdef = reduce_def - defence
		local effect_value,feature_rate = attacker:get_dw_jinjie_effect_details(25)
		if effect_value > 0 and feature_rate and feature_rate > 0 then
			effect_value = effect_value / feature_rate / 200 * subdef
			reduce_def_low_limit = reduce_def_low_limit + effect_value
			-- attacker:features_effect_notify_client(25)
		end
	end
	
    local trait = traits[enum_damage_type.IDX_DAMAGE_POISON]
    local resit = defence - reduce_def  -- 实际抗性
    local real_reduce_def_low_limit = (-1 * reduce_def_low_limit + (defence > 0 and 0 or defence))
    resit = resit < real_reduce_def_low_limit and (real_reduce_def_low_limit) or resit
    
    -- 计算伤害：抗性越高伤害越低
    if resit >= 100 then
        damage = 0
    else
        damage = attack * (100 - resit) / 100 * trait / 1000000
    end
    
    -- 获取攻击和防御的百分比加成（仅玩家）
    local kfs_wg_attack_rate = 0
    local kfs_wg_defence_rate = 0
    if attacker:get_obj_type() == "human" then
        kfs_wg_attack_rate = attacker:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_POISION_DAMAGE_RATE)
    end
    if defencer:get_obj_type() == "human" then
        kfs_wg_defence_rate = defencer:item_value(define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_POISION_DEFENCE_RATE)
    end
    kfs_wg_attack_rate = kfs_wg_attack_rate - kfs_wg_defence_rate
    kfs_wg_attack_rate = math.max(-10000, kfs_wg_attack_rate)
    damage = damage * (10000 + kfs_wg_attack_rate) / 10000
    damage = damage < 0 and 0 or damage
    return damage
end

-- 计算直接伤害
-- 直接伤害不受防御力影响，直接返回额外攻击值
-- @param attacker 攻击者对象（未使用）
-- @param defencer 防御者对象（未使用）
-- @param addition_attack 额外攻击力
-- @return 直接伤害值
function combat_core:direct_damage(attacker, defencer, addition_attack)
    local damage = addition_attack
    return damage
end


return combat_core