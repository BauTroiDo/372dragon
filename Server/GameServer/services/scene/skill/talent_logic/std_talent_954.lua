-- 剑影留痕：破天式(834)飞剑命中目标时，给予目标一个状态
-- 受到自身破天式的伤害时额外附带施放者X%普通攻击伤害
-- 可叠加，持续7秒，最多4层
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_954 = class("std_talent_954", base)
local impacts = {19171, 19172, 19173, 19174, 19175}
local MAX_STACKS = 4
function std_talent_954:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 834 then
        local impact_id = impacts[level]
        if not impact_id then return end
        -- 检查目标是否已有同来源的544叠层debuff
        local impact_list = reciver:get_impact_list()
        for _, existing in ipairs(impact_list) do
            if existing:get_logic_id() == 544 and existing:get_caster_obj_id() == sender:get_obj_id() then
                local stacks = existing._stack_count or 1
                if stacks < MAX_STACKS then
                    existing._stack_count = stacks + 1
                end
                existing:set_continuance_elapsed(0)
                impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
                return
            end
        end
        -- 首次命中：清掉上一轮残留的保存值，发送新debuff
        reciver._saved_544_stack = nil
        impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
    end
end

return std_talent_954
