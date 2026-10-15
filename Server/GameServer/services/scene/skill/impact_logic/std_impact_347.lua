local class = require "class"
local skynet = require "skynet"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_347 = class("std_impact_347", base)
std_impact_347.ID = 347

function std_impact_347:ctor()

end

function std_impact_347:is_over_timed()
    return true
end

function std_impact_347:is_intervaled()
    return true
end

function std_impact_347:get_mind_defend_mult(imp)
    return imp.params["会心防御的倍数伤害"] or 1
end

function std_impact_347:set_mind_defend_mult(imp,value)
    imp.params["会心防御的倍数伤害"] = value
end

function std_impact_347:get_add_buff(imp)
    return imp.params["附加BUFF"] or -1
end

function std_impact_347:set_add_buff(imp,buffid)
    imp.params["附加BUFF"] = buffid
end


function std_impact_347:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    if obj:get_obj_type() ~= "human" then
        return
    end
    local mind_def = obj:get_mind_defend()
    local mult = self:get_mind_defend_mult(imp)
    local damage_value = mind_def * mult
    skynet.error(string.format("[佛光] 会心防御=%s 倍率=%s 伤害=%s 目标=%s",
        tostring(mind_def), tostring(mult), tostring(damage_value), tostring(obj:get_name() or obj:get_obj_id())))
    local radious = 5
    local affect_count = 3
    local position = obj:get_world_pos()
    local operate = {obj = obj, x = position.x, y = position.y, radious = radious, count = affect_count, target_logic_by_stand = 1 }
    local nearbys = obj:get_scene():scan(operate)
    for _, nb in ipairs(nearbys) do
        -- print("nb.classname =", nb.classname)
        -- if nb:is_character_obj() then
           if obj:is_enemy(nb) and not nb:is_unbreakable() then
				local buffid = self:get_add_buff(imp)
				if buffid ~= -1 then
					impactenginer:send_impact_to_unit(nb, buffid, obj, 0, false, 0)
				end
                nb:health_increment(-1 * damage_value, obj, false)
           end
        -- end
    end
end


return std_impact_347