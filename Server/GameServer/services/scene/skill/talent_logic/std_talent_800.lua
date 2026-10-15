local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_800 = class("std_talent_800", base)

function std_talent_800:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_800:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id ~= 450 then
        return
    end
    if math.random(100) > self:get_refix_value(talent, level) then
        return
    end
    local scene = sender:get_scene()
    if not scene then return end
    local curse_ids = {}
    local impacts = reciver:get_impact_list()
    for _, imp in ipairs(impacts) do
        if imp:get_stand_flag() < 0 then
            local data_index = imp:get_data_index()
            if not curse_ids[data_index] then
                curse_ids[data_index] = true
            end
            imp:set_continuance_elapsed(0)
        end
    end
    local position = reciver:get_world_pos()
    local operate = {
        obj = sender,
        x = position.x,
        y = position.y,
        radious = 5,
        count = 3,
        target_logic_by_stand = 1
    }
    local nearbys = scene:scan(operate)
    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() and nb:is_alive() and nb ~= reciver then
            for id, _ in pairs(curse_ids) do
                impactenginer:send_impact_to_unit(nb, id, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_800