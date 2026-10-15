-- 俱寂无声：获得技能3595
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_934 = class("std_talent_934", base)
local skill_id = 3595

function std_talent_934:on_active(talent, level, human)
    if not human:have_skill(skill_id) then
        human:add_skill(skill_id)
        human:send_skill_list()
    end
end

function std_talent_934:on_remove(talent, level, human)
    if human:have_skill(skill_id) then
        human:del_skill(skill_id)
    end
end

function std_talent_934:get_add_skill()
    return skill_id
end

return std_talent_934
