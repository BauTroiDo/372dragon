local class = require "class"
local define = require "define"
local utils = require "utils"
local packet_def = require "game.packet"
local obj_base = require "scene.obj.base"
local bus_attrib  = class("bus_attrib")
function bus_attrib:ctor(bus, attrib)
    self.bus = bus
    self.db_attribs = attrib
end

function bus_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

function bus_attrib:set_db_attrib(set_list)
    for key, val in pairs(set_list) do
        self.db_attribs[key] = val
    end
end

local bus = class("bus", obj_base)
function bus:ctor(conf)
    self.obj_id = conf.obj_id
    self.patrol_id = conf.patrol_id
    self.passengers = {}
    self.db = bus_attrib.new(self, conf)
end

function bus:start()
    self.stop_time_timer = nil
    self:start_patrol()
end

function bus:get_obj_type()
    return "bus"
end

function bus:get_data_id()
    return self.db:get_db_attrib("data_id")
end

function bus:get_athwart()
    return self.db:get_db_attrib("athwart")
end

function bus:set_athwart(athwart)
    assert(athwart == 0 or athwart == 1, athwart)
    self.db:set_db_attrib({ athwart = athwart })
end

function bus:get_stop_time()
    return self.db:get_db_attrib("stop_time")
end

function bus:get_name()
    return self.db:get_db_attrib("name")
end

function bus:get_aoi_mode()
    return "wm"
end

function bus:is_moving()
    return self.move_path ~= nil
end

function bus:start_patrol()
    local patrol_id = self:get_patrol_id()
    local partol = self:get_scene():get_patrol_path_by_index(patrol_id)
    if partol then
        self.move_path = self:get_athwart_path(partol)
        self:send_move_to()
    end
end

function bus:get_patrol_id()
    return self.patrol_id
end

function bus:get_speed()
    return self.db:get_db_attrib("speed")
end

function bus:get_athwart_path(partol)
    local athwart = self:get_athwart()
    if athwart == 1 then
        return table.clone(partol.path)
    elseif athwart == 0 then
        local path = {}
        for i = #partol.path, 1, -1 do
            table.insert(path, partol.path[i])
        end
        return path
    else
        assert(false, athwart)
    end
end

function bus:send_move_to()
    local world_pos = self:get_world_pos()
    local msg = packet_def.GCBusMove.new()
    msg.m_objID = self:get_obj_id()
    msg.world_pos = world_pos
    msg.next_pos = self.move_path[1]
    self:get_scene():broadcast(self, msg, true)
end

function bus:update(delta_time)
    if self:is_moving() then
        self:logic_move(delta_time)
        if #self.move_path == 0 then
            self.move_path = nil
            self:on_arrive_dest()
        end
    end
    if self.stop_time_timer then
        if self.stop_time_timer > 0 then
            self.stop_time_timer = self.stop_time_timer - delta_time
        else
            self.stop_time_timer = nil
            self:start_patrol()
        end
    end
end

function bus:on_arrive_dest()
    self.stop_time_timer = self:get_stop_time()
    local athwart = self:get_athwart()
    if athwart == 0 then
        athwart = 1
    else
        athwart = 0
    end
    self:set_athwart(athwart)
    self:passengers_off()
end

function bus:passengers_off()
    for _, passenger_id in ipairs(self.passengers) do
        local passenger = self:get_scene():get_obj_by_id(passenger_id)
        if passenger then
            passenger:off_bus()
        end
    end
    self.passengers = {}
    local msg = packet_def.GCBusRemoveAllPassenger.new()
    msg.bus_id = self:get_obj_id()
    self:get_scene():broadcast(self, msg, true)
end

function bus:passengers_on(passenger_id)
    local passenger = self:get_scene():get_obj_by_id(passenger_id)
    if passenger then
        passenger:on_bus(self:get_obj_id())
        local before_num = #self.passengers
        table.insert(self.passengers, passenger_id)
        local msg = packet_def.GCBusAddPassenger.new()
        msg.bus_id = self:get_obj_id()
        msg.m_objID = passenger_id
        msg.before_num = before_num
        self:get_scene():broadcast(self, msg, true)
    end
end

function bus:is_full()
    return #self.passengers >= self.db:get_db_attrib("can_carry_passenger_count")
end

function bus:has_poisition()
    return self.db:get_db_attrib("can_carry_passenger_count") - #self.passengers
end

function bus:logic_move(utime)
    local pos = self.move_path[1]
    if pos == nil then
        return false
    end
    local cur_pos = self:get_world_pos()
    local tar_pos = pos
    local speed = self:get_speed()
    assert(speed > 0.1 and speed < 20.0, speed)
    local move_dist = speed * utime / 1000
    if move_dist <= 0.01 then
        return true
    end
    local dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
    while true do
        if move_dist > dist_to_tar then
            if #(self.move_path) == 1 then
                local pos_must_to = {}
                pos_must_to.x = tar_pos.x
                pos_must_to.y = tar_pos.y
                pos_must_to.z = tar_pos.z
                self:set_world_pos(pos_must_to)
                table.remove(self.move_path, 1)
                break
            else
                move_dist = move_dist - dist_to_tar
                cur_pos = tar_pos
                self:set_world_pos(cur_pos)
                table.remove(self.move_path, 1)
                tar_pos = self.move_path[1]
                dist_to_tar = utils.my_sqrt(cur_pos, tar_pos)
                self:send_move_to()
            end
        else
            local cur = {}
            if dist_to_tar > 0.01 then
                cur.x = cur_pos.x + (move_dist * (tar_pos.x - cur_pos.x)) / dist_to_tar
                cur.y = cur_pos.y + (move_dist * (tar_pos.y - cur_pos.y)) / dist_to_tar
                cur.z = tar_pos.z
            else
                cur.x = tar_pos.x
                cur.y = tar_pos.y
                cur.z = tar_pos.z
            end
            self:set_world_pos(cur)
            break
        end
    end
end

function bus:set_world_pos(world_pos)
    self.super.set_world_pos(self, world_pos)
    for _, passenger_id in ipairs(self.passengers) do
        local passenger = self:get_scene():get_obj_by_id(passenger_id)
        if passenger then
            passenger:set_world_pos(world_pos)
        end
    end
end

function bus:create_new_obj_packet()
    --print("bus create_new_obj_packet =", self:get_obj_id())
    if self:is_moving() then
        local msg = packet_def.GCNewBus_Move.new()
        msg.m_objID = self:get_obj_id()
        msg.world_pos = self:get_world_pos()
        msg.next_pos = self.move_path[1]
        msg.path = {}
        msg.data_id = self:get_data_id()
        return msg
    else
        local msg = packet_def.GCNewBus.new()
        msg.m_objID = self:get_obj_id()
        msg.world_pos = self:get_world_pos()
        msg.path = {}
        msg.data_id = self:get_data_id()
        return msg
    end
end

function bus:get_name()
    return "bus"
end

function bus:get_obj_type()
    return "bus"
end

return bus