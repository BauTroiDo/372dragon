local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_266 = class("std_talent_266", base)
local skill_id = 3598
function std_talent_266:on_active(talent, level, human)
    if not human:have_skill(skill_id) then
        human:add_skill(skill_id)
        human:send_skill_list()
    end
end

function std_talent_266:on_remove(talent, level, human)
    if human:have_skill(skill_id) then
        human:del_skill(skill_id)
    end
end

function std_talent_266:get_add_skill()
    return skill_id
end

return std_talent_266