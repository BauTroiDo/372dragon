local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_133 = class("std_talent_133", base)
function std_talent_133:is_specific_skill(skill_id)
    return skill_id == 480
end

function std_talent_133:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_133:on_use_skill_success_fully(talent, level, skill_info, human)
    if self:is_specific_skill(skill_info.id) then
        local data_index = 63024 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
    end
end

return std_talent_133