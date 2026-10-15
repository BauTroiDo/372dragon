-- 解春愁：在自身释放的七霞映日(819)状态下，受到控制时，减少春光四沐(821)X秒冷却
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_919 = class("std_talent_919", base)

-- 控制类 mutex_id
local CONTROL_MUTEX = { [11]=true, [13]=true, [15]=true, [17]=true, [19]=true, [21]=true, [122]=true }

local function has_impact_of_skill(human, skill_id)
    local list = human:get_impact_list()
    for i = 1, #list do
        if list[i]:get_skill_id() == skill_id then
            return true
        end
    end
    return false
end

function std_talent_919:on_be_skill(talent, level, human, sender, skill_id, behaviortype)
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then return end
    if not has_impact_of_skill(human, 819) then return end
    -- 检查技能是否包含控制效果
    local scene = human:get_scene()
    local sk = scene:get_skill_enginer()
    local template = sk:get_skill_template(skill_id)
    if not template then return end
    local level_skills = template.level_skills
    if not level_skills or not level_skills[1] then return end
    local info = sk:get_skill_info(level_skills[1])
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
    -- 减少821冷却
    local params = talent.params[level]
    local reduce = (params[1] or 0) * 1000
    local template_821 = skillenginer:get_skill_template(821)
    if template_821 then
        human:update_cool_down_by_cool_down_id(template_821.cool_down_id, reduce)
    end
end

return std_talent_919
