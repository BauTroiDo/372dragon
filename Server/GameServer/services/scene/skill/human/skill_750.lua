-- 彼行我释
-- 根据自身蓄气状态不同，释放不同控制效果到目标
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local skill_750 = class("skill_750", base)

-- 从 descriptor 中读取6组 {蓄气集合ID, 目标效果ID}
function skill_750:get_mappings(skill_info)
    local descriptor = skill_info:get_descriptor()
    local mappings = {}
    for idx = 1, 6 do
        local coll_key = string.format("个体拥有这些BUFF时使用效果%d", idx)
        local eff_key = string.format("给目标的效果%d", idx)
        local collection_id = descriptor[coll_key]
        local effect_id = descriptor[eff_key]
        if collection_id and collection_id > 0 and effect_id and effect_id > 0 then
            mappings[#mappings + 1] = { collection_id = collection_id, effect_id = effect_id }
        end
    end
    return mappings
end

function skill_750:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer_inst = scene:get_impact_enginer()
    local mappings = self:get_mappings(skill_info)

    -- 按顺序检查自身是否存在对应蓄气状态，取第一个匹配的
    for _, map in ipairs(mappings) do
        if obj_me:impact_have_impact_in_specific_collection(map.collection_id) then
            -- 清除自身对应蓄气buff
            obj_me:get_get_collection_state_count(map.collection_id, true)
            -- 给目标施加控制效果
            local imp = impact.new()
            imp:clean_up()
            if impactenginer_inst:init_impact_from_data(map.effect_id, imp) then
                self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
            end
            return
        end
    end
end

return skill_750
