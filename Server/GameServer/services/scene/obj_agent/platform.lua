local class = require "class"
local utils = require "utils"
local scriptenginer = require "scriptenginer":getinstance()
local packet_def = require "game.packet"
local obj_base = require "scene.obj.base"
local platform_attrib  = class("platform_attrib")
function platform_attrib:ctor(area, attrib)
    self.db_attribs = attrib
end

function platform_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

local platform = class("platform", obj_base)
function platform:ctor(conf)
    self.obj_id = conf.obj_id
    self.class = conf.index
    self.script_id = conf.script_id
    self.Tip = conf.Tip
    self.dir = utils.idir2fdir(conf.dir)
    local world_pos = { x = conf.pos_X, y = conf.pos_Z }
    self.db = platform_attrib.new(self, { world_pos = world_pos })
end

function platform:get_dir()
    return self.dir
end

function platform:get_aoi_mode()
    return "wm"
end

function platform:update()
end

function platform:create_new_obj_packet()
    local msg = packet_def.GCNewPlatform.new()
    msg.m_objID = self:get_obj_id()
    msg.world_pos = self:get_world_pos()
    msg.dir = self:get_dir()
    msg.class = self.class
    msg.desc = self.Tip
    return msg
end

function platform:get_script_id()
    return self.script_id
end

function platform:default_event(selfId)
    scriptenginer:call(self:get_script_id(), "OnDefaultEvent", selfId,
                                   self:get_obj_id())
end

function platform:get_name()
    return "platform"
end

function platform:get_obj_type()
    return "platform"
end

return platform