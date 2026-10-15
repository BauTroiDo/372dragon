local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local impactenginer = require "impactenginer":getinstance()
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local YU_LEI_YONG_YU_SKILL_1 = 3779
local YU_LEI_YONG_YU_SKILL_2 = 3780
local YU_LEI_YONG_YU_SKILL_3 = 3781
local YU_LEI_YONG_YU_SKILL_4 = 3782
local skill_441 = class("skill_441", base)
skill_441.IMPACT_NUMBER = 2


function skill_441:ctor()

end

function skill_441:get_activate_impact(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["生效BUFFid"] or define.INVAILD_ID
end

function skill_441:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value = self:get_activate_impact(skill_info)
    local tar_imp = impact.new()
    local self_imp = impact.new()
    tar_imp:clean_up()
    self_imp:clean_up()
    impactenginer:init_impact_from_data(value, tar_imp)
    impactenginer:init_impact_from_data(value, self_imp)
    local tar_logic = impactenginer:get_logic(tar_imp)
    local self_logic = impactenginer:get_logic(self_imp)
    tar_logic:set_shield_hp(tar_imp, math.ceil(obj_tar:get_max_hp() * tar_logic:get_make_shield_from_hp_rate(tar_imp) / 100))
    self_logic:set_shield_hp(self_imp, math.ceil(obj_me:get_max_hp() * self_logic:get_make_shield_from_hp_rate(self_imp) / 100))
    self:register_impact_event(obj_tar, obj_me, tar_imp, params:get_delay_time(), is_critical)
    self:register_impact_event(obj_me, obj_me, self_imp, params:get_delay_time(), is_critical)
    obj_me:skill_charge(obj_tar:get_world_pos())
end

return skill_441