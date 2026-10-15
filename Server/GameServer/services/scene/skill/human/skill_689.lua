local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skill_689 = class("skill_689", base)
function skill_689:ctor()

end

function skill_689:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value = 609
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    if value ~= define.INVAILD_ID then
        -- print("skill_689:effect_on_unit_once impact value =", value, "skill_id", skill_info:get_skill_id())
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        -- if imp:get_logic_id() == DI_DamagesByValue_T.ID then
            -- local co = combat_core.new()
            -- co:get_result_impact(obj_me, obj_tar, imp)
        -- end
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
end

return skill_689