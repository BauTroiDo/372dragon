-- 常相见：若化气式的目标为玩家，有X%概率使其65级门派技能进入冷却
-- 若目标的该技能已进入冷却，则使其重新开始计时
-- skill_751已额外注册真正目标的skill_hit_event，on_hit_target中reciver即为真正目标
local skynet = require "skynet"
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_970 = class("std_talent_970", base)

-- 化气式(833)释放时会将skill_info替换为门派绝学(836-846)
local HUAQI_SKILL_IDS = {
    [833] = true,
    [836] = true, [837] = true, [838] = true, [839] = true, [840] = true,
    [841] = true, [842] = true, [843] = true, [844] = true, [845] = true,
    [846] = true,
}

-- 门派ID → {skill_id=65级技能ID, cd_id=冷却ID}
local MENPAI_SKILL_65 = {
    [0]  = {skill_id = 301, cd_id = 70},  -- 少林 易筋锻骨
    [1]  = {skill_id = 331, cd_id = 70},  -- 明教 纯阳无极
    [2]  = {skill_id = 361, cd_id = 70},  -- 丐帮 天下无狗
    [3]  = {skill_id = 391, cd_id = 70},  -- 武当 天外飞仙
    [4]  = {skill_id = 421, cd_id = 70},  -- 峨眉 九阴神爪
    [5]  = {skill_id = 451, cd_id = 70},  -- 星宿 化骨绵掌
    [6]  = {skill_id = 481, cd_id = 70},  -- 大理 少泽剑
    [7]  = {skill_id = 511, cd_id = 70},  -- 天山 同生共死
    [8]  = {skill_id = 541, cd_id = 70},  -- 逍遥 鲲跃北溟
    [10] = {skill_id = 785, cd_id = 133}, -- 曼陀山庄 弦弄花影
    [11] = {skill_id = 810, cd_id = 68},  -- 恶人谷 判指阴阳
}

function std_talent_970:on_hit_target(talent, level, sender, reciver, skill_id)
    if not HUAQI_SKILL_IDS[skill_id] then return end
    -- 跳过自身（化气式原始targets里的自己）
    if reciver:get_obj_id() == sender:get_obj_id() then return end
    if reciver:get_obj_type() ~= "human" then return end

    local params = talent.params[level]
    if not params then return end
    local chance = params[1] or 0
    if chance <= 0 then return end
    if math.random(100) > chance then return end

    -- 根据目标门派获取对应的65级绝学信息
    local menpai = reciver:get_menpai()
    local info = MENPAI_SKILL_65[menpai]
    if not info then return end

    -- 从技能数据表读取实际冷却时长（SkillData_V1）
    local template = skillenginer:get_skill_template(info.skill_id)
    local skill_data_id = template and template.level_skills and template.level_skills[1]
    local skill_data = skill_data_id and skillenginer:get_skill_info(skill_data_id)
    local cd_time = skill_data and skill_data.cool_down_time or 120000

    reciver:set_cool_down(info.cd_id, cd_time)

    skynet.error(string.format("[天赋970] 常相见触发: sender=%d target=%d menpai=%d skill=%d cd_id=%d cd=%dms",
        sender:get_obj_id(), reciver:get_obj_id(), menpai, info.skill_id, info.cd_id, cd_time))
end

return std_talent_970
