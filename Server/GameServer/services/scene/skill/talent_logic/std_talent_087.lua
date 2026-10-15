local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_087 = class("std_talent_087", base)
local impact_ids = { 50012, 50013, 50014, 50015, 50016 }
function std_talent_087:is_sanhuan_taoyue_skill(skill_info)
    return skill_info.id == 374
end

function std_talent_087:on_use_skill_success_fully(talent, level, skill_info, human)
    if self:is_sanhuan_taoyue_skill(skill_info) then
        local id = impact_ids[level]
        if id then
            impactenginer:send_impact_to_unit(human, id, human, 0, false,  0)
        end
    end
end

return std_talent_087