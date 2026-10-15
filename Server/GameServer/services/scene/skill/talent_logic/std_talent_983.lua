-- 云归海：春光四沐(技能821)冷却时间减少X秒
-- 升至5级后受到控制时有35%概率免疫此次控制，并使春光四沐进入5秒冷却
-- 该效果每60秒只能生效一次
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_983 = class("std_talent_983", base)

-- 控制类 mutex_id
local CONTROL_MUTEX = { [11]=true, [13]=true, [15]=true, [17]=true, [19]=true, [21]=true, [122]=true }

function std_talent_983:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info:get_skill_id() == 821 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        cool_down_time = cool_down_time - reduce
    end
    return cool_down_time
end

-- 5级免控逻辑：被控制技能命中时概率免疫
function std_talent_983:on_be_skill(talent, level, human, sender, skill_id, behaviortype)
    if level < 5 then return end
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then return end
    -- 60秒内置CD
    local last = human._983_last_trigger or 0
    local now = os.time()
    if now - last < 60 then return end
    -- 检查技能是否包含控制效果
    local scene = human:get_scene()
    local skillenginer_inst = scene:get_skill_enginer()
    local template = skillenginer_inst:get_skill_template(skill_id)
    if not template then return end
    local level_skills = template.level_skills
    if not level_skills or not level_skills[1] then return end
    local info = skillenginer_inst:get_skill_info(level_skills[1])
    if not info or not info.impacts then return end
    local has_control = false
    local impact_ids = {}
    if info.impacts.effect_once then
        for _, v in pairs(info.impacts.effect_once) do
            if type(v) == "number" and v >= 0 then impact_ids[#impact_ids+1] = v end
        end
    end
    if info.impacts.give_target and info.impacts.give_target.id and info.impacts.give_target.id >= 0 then
        impact_ids[#impact_ids+1] = info.impacts.give_target.id
    end
    for _, data_index in ipairs(impact_ids) do
        local imp_data = impactenginer:get_data_by_data_index(data_index)
        if imp_data and imp_data.mutex_id and CONTROL_MUTEX[imp_data.mutex_id] then
            has_control = true
            break
        end
    end
    if not has_control then return end
    -- 35%概率免疫
    if math.random(100) > 35 then return end
    human._983_last_trigger = now
    -- 春光四沐(821)进入5秒冷却
    local template_821 = skillenginer:get_skill_template(821)
    if template_821 then
        human:set_cool_down_by_cool_down_id(template_821.cool_down_id, 5000)
    end
end

return std_talent_983
