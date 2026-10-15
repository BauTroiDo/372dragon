-- 流风化羽：获得技能3594
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_933 = class("std_talent_933", base)
local skill_id = 3594

function std_talent_933:on_active(talent, level, human)
    if not human:have_skill(skill_id) then
        human:add_skill(skill_id)
        human:send_skill_list()
    end
end

function std_talent_933:on_remove(talent, level, human)
    if human:have_skill(skill_id) then
        human:del_skill(skill_id)
    end
end

function std_talent_933:get_add_skill()
    return skill_id
end

return std_talent_933
