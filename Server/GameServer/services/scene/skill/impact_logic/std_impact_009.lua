local skynet = require "skynet"
local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_009 = class("std_impact_009", base)


function std_impact_009:is_over_timed()
    return false
end

function std_impact_009:is_intervaled()
    return false
end

function std_impact_009:get_impact_scene_id(imp)
    return imp.params["场景ID"]
end

function std_impact_009:get_impact_x(imp)
    return imp.params["X坐标"]
end

function std_impact_009:get_impact_y(imp)
    return imp.params["Z坐标"]
end

function std_impact_009:set_impact_x(imp, x)
    imp.params["X坐标"] = x
end

function std_impact_009:set_impact_y(imp, y)
    imp.params["Z坐标"] = y
end

function std_impact_009:on_active(imp, obj)
    if imp:get_data_index() == 61148 then
        skynet.logi("[skill_840] impact 61148 on_active obj=", obj:get_obj_id(), "x=", self:get_impact_x(imp),
            "y=", self:get_impact_y(imp), "scene=", self:get_impact_scene_id(imp), "alive=", obj:is_alive())
    end
    if not obj:is_alive() then
        return
    end
    local x = self:get_impact_x(imp)
    local y = self:get_impact_y(imp)
    local sceneid = self:get_impact_scene_id(imp)
    if sceneid ~= define.INVAILD_ID and sceneid ~= obj:get_scene_id() then
        obj:change_scene(sceneid, {x = x, y = y})
    else
        if x == 0 or y == 0 then
            return
        end
        local target_position = { x = x, y = y }
        obj:on_teleport(target_position)
    end
end

return std_impact_009