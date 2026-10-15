-- 剑意茫茫：七霞映日(819)额外使范围内最多6个敌对目标受到自身伤害提升X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_957 = class("std_talent_957", base)
local impacts = {19136, 19137, 19138, 19139, 19140}

function std_talent_957:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 819 then
        local impact_id = impacts[level]
        if impact_id then
            local position = human:get_world_pos()
            local operate = {
                obj     = human,
                x       = position.x,
                y       = position.y,
                radious = 10,
                count   = 6,
            }
            local nearbys = human:get_scene():scan(operate)
            for _, nb in ipairs(nearbys) do
                if nb:is_character_obj() and human:is_enemy(nb) and nb:is_alive() then
                    impactenginer:send_impact_to_unit(nb, impact_id, human, 0, false, 0)
                end
            end
        end
    end
end

return std_talent_957
