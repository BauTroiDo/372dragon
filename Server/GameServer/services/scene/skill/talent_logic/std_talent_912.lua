-- 风云再起：使用借力返施(技能829)时，减少横剑疆场(技能815)X秒冷却时间
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_912 = class("std_talent_912", base)

function std_talent_912:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 829 then
        local params = talent.params[level]
        local reduce = (params[1] or 0) * 1000
        local template = skillenginer:get_skill_template(815)
        if template then
            local cool_down_id = template.cool_down_id
            human:update_cool_down_by_cool_down_id(cool_down_id, reduce)
        end
    end
end

return std_talent_912
