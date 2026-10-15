local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_talent_744 = class("std_talent_744", base)

function std_talent_744:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if skill_id ~= 378 then return end
    if not reciver or not sender then return end
    if not reciver:is_alive() then return end
    if reciver:get_obj_type() ~= "human" then return end
    local params = talent.params[level]
    local percent = params[1] or 0
    if percent <= 0 then return end
    local max_mp = reciver:get_attrib("mp_max") or 0
    if max_mp <= 0 then return end
    local absorb = math.ceil(max_mp * percent / 100)
    if absorb <= 0 then return end
    local r_id = reciver:get_obj_id()
    local s_id = sender:get_obj_id()
    local scene = reciver:get_scene()
    local impact_id = imp:get_impact_id()
    skynet.fork(function()
        while true do
            local t = scene:get_obj_by_id(r_id)
            local s = scene:get_obj_by_id(s_id)
            if not t or not s then return end
            if not t:is_alive() then return end
            if not t:impact_get_first_impact_of_specific_impact_id(impact_id) then return end
            local drained = t:mana_increment(-absorb, s)
            if drained and drained > 0 then
                s:mana_increment(drained, s)
            end
            skynet.sleep(100)
        end
    end)
end

return std_talent_744