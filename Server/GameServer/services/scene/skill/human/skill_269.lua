-- skill_269: 断臂渡生 技能5386 护盾链路
-- logic_id=269 对应峨嵋武道771"断臂渡生"的主动技能5386
-- 消耗自身血上限20%血量为15米内小队成员施加护盾
-- 护盾持续30秒，吸收100%伤害，血量低于50%时无法使用，期间不可叠加
local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skynet = require "skynet"
local skill_269 = class("skill_269", base)

function skill_269:ctor()
end

function skill_269:get_shield_impact_id(skill_info, obj_me)
    local talent = obj_me:get_talent_by_skill_id(skill_info:get_skill_id())
    if not talent then
        return define.INVAILD_ID
    end
    local level = talent.level
    local descriptor = skill_info:get_descriptor()
    local key = "buff" .. level
    local impact_id = descriptor[key]
    if not impact_id then
        key = string.format("生效一次的效果%d(自己)", level)
        impact_id = descriptor[key]
    end
    return impact_id or define.INVAILD_ID
end

function skill_269:activate_once(obj_me)
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()

    local impact_id = self:get_shield_impact_id(skill_info, obj_me)
    if not impact_id or impact_id == define.INVAILD_ID or impact_id <= 0 then
        return true
    end

    local shield_hp = math.ceil(obj_me:get_max_hp() * 0.2)
    local pos = obj_me:get_world_pos()

    local operate = {
        obj = obj_me,
        x = pos.x, y = pos.y,
        radious = skill_info:get_radious(),
        target_logic_by_stand = 0,
        target_check_by_obj_type = 0,
        target_must_be_teammate = 1,
        check_can_view = true
    }
    local targets = scene:scan(operate)
    local hit_flag_list = {}

    for i, member in ipairs(targets) do
        if member:impact_get_first_impact_of_specific_data_index(impact_id) then
            hit_flag_list[i] = false
        else
            local imp = impact.new()
            imp:clean_up()
            local ok = impactenginer:init_impact_from_data(impact_id, imp)
            if ok then
                imp.params["护盾生命值"] = shield_hp
                self:register_impact_event(member, obj_me, imp, params:get_delay_time(), false)
                hit_flag_list[i] = true
            else
                hit_flag_list[i] = false
            end
        end
    end

    self:broadcast_target_list_message(obj_me, targets, hit_flag_list)
    return true
end

return skill_269
