local skynet = require "skynet"
local define = require "define"
local class = require "class"
local playershop = require "playershop"
local shop_guid = require "shop_guid"
local configenginer = require "configenginer":getinstance()
local playershopmanager = class("playershopmanager")

function playershopmanager:getinstance()
    if playershopmanager.instance == nil then
        playershopmanager.instance = playershopmanager.new()
    end
    return playershopmanager.instance
end

function playershopmanager:ctor()
    self.player_shops = {}
    self.com_factor = 0.5
    self.server = tonumber(skynet.getenv("process_id"))
    self.world = 1
end

function playershopmanager:load(scene)
    local sql = {collection = "shop", query = {["guid.world"]=self.world,["guid.server"]=self.server,["guid.scene"]=scene:get_id()}}
    print("playershopmanager load sql =", table.tostr(sql))
    local shops = skynet.call(".db", "lua", "findAll", sql) or {}
    return shops
end

function playershopmanager:init(scene)
    self.scene = scene
    self.player_shops = {}
    local shops = self:load(scene)
    for _, shop in ipairs(shops) do
        local guid = shop.guid
        if guid.world == self.world and guid.server == self.server and guid.scene == scene:get_id() then
            local sp = playershop.new(self)
            sp:load(shop)
            table.insert(self.player_shops, sp)
        end
    end
end

function playershopmanager:get_scene()
    return self.scene
end

function playershopmanager:get_com_factor()
    return self.com_factor
end

function playershopmanager:update_com_factor()
    local cur_com_fact = 0.5
    local shop_num = #self.player_shops
    if shop_num < 200 then
        cur_com_fact = cur_com_fact + shop_num * 0.002
    elseif shop_num >= 200 and shop_num < 250 then
        cur_com_fact = cur_com_fact + 200 * 0.002
        cur_com_fact = cur_com_fact + (shop_num - 200) * 0.003
    else
        cur_com_fact = cur_com_fact + 200 * 0.002
        cur_com_fact = cur_com_fact + 50 * 0.003
        cur_com_fact = cur_com_fact + (shop_num - 250) * 0.004
    end
    self.com_factor = cur_com_fact
end

function playershopmanager:clamp_com_factor()
end

function playershopmanager:heart_beat(...)
    for _, shop in ipairs(self.player_shops) do
        shop:heart_beat(..., self.com_factor)
    end
end

function playershopmanager:get_player_shop_by_guid(sg)
    for _, shop in ipairs(self.player_shops) do
        if shop:get_guid() == sg then
            return shop
        end
    end
end

function playershopmanager:get_player_shops()
    return self.player_shops
end

function playershopmanager:get_shop_infos()
    local shop_infos = {}
    for i, shop in ipairs(self.player_shops) do
        local shop_info = {}
        shop_info.id = i
        shop_info.name = shop:get_name()
        shop_info.stall_open_num = shop:get_stall_opend_num()
        shop_info.stall_close_num = 10 - shop_info.stall_open_num
        shop_info.type = shop:get_type()
        shop_info.guid = shop:get_guid()
        shop_info.owner_guid = shop:get_owner_guid()
        shop_info.owner_name = shop:get_owner_name()
        shop_info.founded_day = shop:get_founded_day()
        shop_info.desc = shop:get_desc()
        shop_info.is_in_favor = 0
        table.insert(shop_infos, shop_info)
    end
    return shop_infos
end

function playershopmanager:new_player_shop(scene)
    local count = #self.player_shops
    if count < define.MAX_PLAYER_SHOP_COUNT then
        local shop = playershop.new(self)
        table.insert(self.player_shops, shop)
        local guid = shop_guid.new()
        guid:set({ world = self.world, server = self.server, scene = scene:get_id(), pollpos = #self.player_shops})
        shop:set_guid(guid)
        return shop
    end
end

function playershopmanager:get_id_by_guid(guid)
    for i, shop in ipairs(self.player_shops) do
        if shop:get_guid() == guid then
            return i
        end
    end
end

return playershopmanager