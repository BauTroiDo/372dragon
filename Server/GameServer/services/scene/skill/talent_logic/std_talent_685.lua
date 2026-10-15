local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_685 = class("std_talent_685", base)
local std_impacts = { 50019, 50020, 50021, 50022, 51623 }
function std_talent_685:is_specific_skill(skill_id)
    return skill_id == 287
end

function std_talent_685:get_give_impact(level)
    return std_impacts[level] or define.INVAILD_ID
end

function std_talent_685:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        local impact = self:get_give_impact(level)
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
        end
    end
end

return std_talent_685