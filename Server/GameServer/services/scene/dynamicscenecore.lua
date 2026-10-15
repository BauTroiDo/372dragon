local skynet = require "skynet"
local define = require "define"
local packet_def = require "game.packet"
local class = require "class"
local scenecore = require "scene.scenecore"
local dynamicscenecore = class("dynamicscenecore", scenecore)

function dynamicscenecore:getinstance()
    if dynamicscenecore.instance == nil then dynamicscenecore.instance = dynamicscenecore.new() end
    return dynamicscenecore.instance
end

function dynamicscenecore:init_conf(conf)
    self.conf.city_id = tonumber(conf.city_id) or conf.city_id
    self.conf.guild_id = tonumber(conf.guild_id) or conf.guild_id
    self.conf.city_name = conf.city_name or ""
    self.conf.city_level = tonumber(conf.city_level) or conf.city_level or 1
    self.conf.buildings = conf.buildings or {}
    self.super.init_conf(self, conf)
end

function dynamicscenecore:init_human(obj, player_data, teaminfo, guildinfo, obj_id)
    self.super.init_human(self, obj, player_data, teaminfo, guildinfo, obj_id)
    self:send_city_name(obj)
    self:send_buildings(obj)
end

function dynamicscenecore:send_enter_scene(whos, to)
    local obj = self.objs[whos]
    local ret = packet_def.GCEnterScene.new()
    ret.m_byEnterType = 0
    ret.m_objID = whos
    ret.m_posWorld = obj:get_world_pos()
    ret.client_res = self.client_res
    ret.server_time = os.time()
    ret.sceneid = self.id
    ret.is_city = 1
    ret.unknow_5 = 0
    ret.unknow_6 = 0
    ret.unknow_8 = 0
    ret.server_id = 1
    self:send2client(to, ret)

    print("GCEnterScene ret =", table.tostr(ret))

    ret = packet_def.GCChatDecryption.new()
    ret.key = 25179465
    self:send2client(to, ret)
end

function dynamicscenecore:send_city_name(obj)
    local msg = packet_def.GCCityAttr.new()
    msg.flag = 2
    msg.city_name = self.conf.city_name
    self:send2client(obj, msg)
end

function dynamicscenecore:get_guild_id()
    return self.conf.guild_id or define.INVAILD_ID
end

function dynamicscenecore:get_city_id()
    return self.conf.city_id or define.INVAILD_ID
end

function dynamicscenecore:send_buildings(obj)
    local buildings = self.conf.buildings or {}
    for i = 0, define.BUILDING_TYPE.BUILDING_MAX do
        local key = tostring(i)
        local building = buildings[key]
        if building then
            local msg = packet_def.GCCityAttr.new()
            msg.flag = 4
            msg.building_index = i
            msg.building_id = building.id
            self:send2client(obj, msg)
        end
    end
end

return dynamicscenecore
