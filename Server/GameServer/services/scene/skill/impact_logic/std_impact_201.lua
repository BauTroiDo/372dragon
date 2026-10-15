local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local std_impact_201 = class("std_impact_201", base)

function std_impact_201:is_over_timed()
    return true
end

function std_impact_201:is_intervaled()
    return false
end

function std_impact_201:get_refix_model_id(_, args, obj)
    local equip_container = obj:get_equip_container()
    local soul = equip_container:get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if soul then
        local item_index = soul:get_index()
        local pet_soul_base = configenginer:get_config("pet_soul_base")
        pet_soul_base = pet_soul_base[item_index]
        if pet_soul_base then
            local pet_soul_level = soul:get_pet_equip_data():get_pet_soul_level()
            args.replace = pet_soul_base.model_id[pet_soul_level + 1]
        end
    end
end

return std_impact_201