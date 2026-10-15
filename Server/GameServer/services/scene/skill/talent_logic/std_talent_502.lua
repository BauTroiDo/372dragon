local class = require "class"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_502 = class("std_talent_502", base)

function std_talent_502:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_502:on_impact_fade_out(talent, level, imp, human)
    if imp:get_impact_id() == 145 then
        local percent = self:get_refix_percent(talent, level)
        local max_hp = human:get_max_hp()
        local recover_hp = math.ceil(max_hp * percent / 100)
        local radious = 10
        local affect_count = 6
        local position = human:get_world_pos()
        local operate = {obj = human, x = position.x, y = position.y, radious = radious, count = affect_count, target_logic_by_stand = 2 }
        local nearbys = human:get_scene():scan(operate)
        table.insert(nearbys, human)
        for _, nb in ipairs(nearbys) do
            if nb:is_character_obj() then
                nb:health_increment(recover_hp, human, false)
            end
        end
    end
end

return std_talent_502