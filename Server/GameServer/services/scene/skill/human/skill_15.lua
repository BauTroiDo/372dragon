local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local base = require "scene.skill.base"
local skill_15 = class("skill_15", base)

function skill_15:ctor()

end

function skill_15:effect_on_unit_once(obj_me)
    local ski = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local pos_tar = params:get_target_position()
    obj_me:fly_to(pos_tar)
    local msg = packet_def.GCCharFly.new()
    msg.m_objID = obj_me:get_obj_id()
    obj_me:add_logic_count()
    msg.logic_count = obj_me:get_logic_count()
    msg.skill_id = ski:get_skill_id()
    msg.from = obj_me:get_world_pos()
    msg.to = pos_tar
    obj_me:get_scene():broadcast(obj_me, msg, true)
end

return skill_15