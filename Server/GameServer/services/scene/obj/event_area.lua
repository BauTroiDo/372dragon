local class = require "class"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local obj_base = require "scene.obj.base"
local event_area_attrib  = class("event_area_attrib")
function event_area_attrib:ctor(area, attrib)
    self.db_attribs = attrib
end

function event_area_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

local event_area = class("event_area", obj_base)
function event_area:ctor(conf)
    self.obj_id = conf.obj_id
    self.script_id = conf.script_id
    conf.x = conf.x or (conf.left + conf.right) / 2
    conf.z = conf.z or (conf.top + conf.bottom) / 2
    conf.radious = conf.radious or ( math.abs(conf.left - conf.right) / 2)
    local world_pos = { x = conf.x, y = conf.z, radious = conf.radious }
    self.db = event_area_attrib.new(self, { world_pos = world_pos })
    self.radious = conf.radious
    self.stay_times = setmetatable({}, {__mode = "kv"})
end

function event_area:get_obj_type()
    return "event_area"
end

function event_area:get_aoi_mode()
    return "wm"
end

function event_area:on_obj_enter_view(obj)
    if obj:get_obj_type() ~= "human" then
        return
    end
    self.super.on_obj_enter_view(self, obj)
end

function event_area:on_obj_leave_view(obj)
    self.stay_times[obj] = nil
    self.super.on_obj_leave_view(self, obj)
end

function event_area:on_obj_leave_area(obj)
    self.stay_times[obj] = nil
    if self.script_id ~= define.INVAILD_ID and scriptenginer:have_function(self.script_id, "OnLeaveArea") then
        scriptenginer:call(self.script_id, "OnLeaveArea", obj:get_obj_id())
    end
end

function event_area:on_obj_enter_area(obj)
    self.stay_times[obj] = 0
    -- [audit 2026-09-10] script chuansong/eSceneAreaTransfer chi co on_enter_area (goi o update),
    -- khong co OnEnterArea/OnTimer -> chi goi API cu khi script thuc su dinh nghia
    if self.script_id ~= define.INVAILD_ID and scriptenginer:have_function(self.script_id, "OnEnterArea") then
        scriptenginer:call(self.script_id, "OnEnterArea", obj:get_obj_id())
    end
end

function event_area:on_timer(obj, delta_time)
    if self.script_id ~= define.INVAILD_ID and scriptenginer:have_function(self.script_id, "OnTimer") then
        scriptenginer:call(self.script_id, "OnTimer", obj:get_obj_id())
    end
    self.stay_times[obj] = self.stay_times[obj] + delta_time
end

function event_area:on_new_obj_enter_view()
end

function event_area:update(...)
    local delta_time = ...
    local scene = self.scene
    for o in pairs(self.view) do
        if o:get_obj_type() == "human" then
            local staytime = self.stay_times[o]
            local pos = o:get_world_pos()
            local dis_sq = scene:calculate_dist_sq(pos, self:get_world_pos())
            local radious_sq = self.radious * self.radious
            if staytime == nil then
                if dis_sq < radious_sq then
                    self:on_obj_enter_area(o)
                end
            else
                if dis_sq < radious_sq then
                    if staytime == -1 then
                    elseif staytime >= 1000 then
                        scriptenginer:call(self.script_id, "on_enter_area", scene, o)
                        self.stay_times[o] = -1
                    else
                        self:on_timer(o, delta_time)
                    end
                else
                    self:on_obj_leave_area(o)
                end
            end
        end
    end
    self.super.update(self, ...)
end

function event_area:get_name()
    return "event_area"
end

return event_area