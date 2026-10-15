-- 寒光如沐：玉女穿梭(技能385)触发定身效果时，有N%概率对目标周围5米范围最多4个目标造成一次普攻伤害
-- 定身effect data_index=1331（玉女穿梭定身，logic_id=14，持续5000ms）
-- 概率参数 params[level][1]：7/14/21/28/35%（来自SectDesc.txt 757行）
-- 触发检测：on_damage_target中检查skill_id==385且受击目标已挂定身buff(1331)
local class = require "class"
local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_757 = class("std_talent_757", base)

-- 玉女穿梭技能ID
local YUNV_SKILL_ID = 385
-- 玉女穿梭定身buff的 data_index（固定，各等级SkillData均指向同一条目）
local DINGSHEN_DATA_INDEX = 1331
-- 普攻伤害 data_index（StandardImpact第0行，永久有效）
local NORMAL_ATTACK_DATA_INDEX = 0
-- AOE扫描半径（米）
local AOE_RADIUS = 5
-- AOE最大命中数
local AOE_MAX_COUNT = 4

function std_talent_757:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    -- 仅拦截玉女穿梭造成的伤害
    if skill_id ~= YUNV_SKILL_ID then
        return
    end
    -- 检查受击目标身上是否挂有定身buff（即定身已成功触发）
    local dingshen_buff = reciver:impact_get_first_impact_of_specific_data_index_2(DINGSHEN_DATA_INDEX, DINGSHEN_DATA_INDEX)
    if not dingshen_buff then
        return
    end
    -- 读取天赋概率参数（百分比）
    local params = talent.params[level]
    local prob = params and params[1] or 0
    if prob <= 0 then
        return
    end
    -- 概率判断
    if math.random(100) > prob then
        return
    end
    -- 以受击目标为中心进行AOE范围扫描
    local ok, err = pcall(function()
        local reciver_pos = reciver:get_world_pos()
        local operate = {
            obj = reciver,
            x = reciver_pos.x,
            y = reciver_pos.y,
            radious = AOE_RADIUS,
            count = AOE_MAX_COUNT,
            target_logic_by_stand = 1
        }
        local nearbys = sender:get_scene():scan(operate)
        for _, nb in ipairs(nearbys) do
            if nb:is_character_obj() and sender:is_enemy(nb) and nb:is_alive() then
                impactenginer:send_impact_to_unit(nb, NORMAL_ATTACK_DATA_INDEX, sender, 0, false, 0, YUNV_SKILL_ID)
            end
        end
    end)
    if not ok then
        skynet.error("[std_talent_757] send_impact_to_unit error:", err)
    end
end

return std_talent_757
