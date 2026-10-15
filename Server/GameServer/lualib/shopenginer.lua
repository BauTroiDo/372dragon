local class = require "class"
local skynet = require "skynet"
local sharetable = require "skynet.sharetable"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local shopenginer = class("shopenginer")
local shop = class("shop")
function shop:ctor()
    self.merchadise_list = {}
    self.serial_num = 0
    self.shop_id = nil
    self.scale = nil
    self.shop_type = nil
end

function shop:get_serial_num()
    return self.serial_num
end

function shop:update_serial_num()
    self.serial_num = (self.serial_num + 1) % 255
end

function shop:get_merchadise_by_id(id)
    for i, merchadise in ipairs(self.merchadise_list) do
        if merchadise.id == id then
            return i, merchadise
        end
    end
end

function shop:get_merchadise_by_index(index)
    return self.merchadise_list[index]
end

local shop_mgr = class("shop_mgr")
function shop_mgr:ctor(sceneid)
    self.shops = {}
    self.unique_id = nil
    self:gen_unique_id(sceneid)
end

function shop_mgr:gen_unique_id(sceneid)
    self.npc_id = self.npc_id or define.INVAILD_ID
    local value = sceneid << 16
    local tid = self.npc_id & 0xffff
    self.unique_id = value + tid
end

function shop_mgr:clean_up()
    self.shops = {}
end

function shop_mgr:get_shop_by_id(shop_id)
    return self.shops[shop_id]
end

function shop_mgr:get_unique_id()
    return self.unique_id
end

local static_shop_mgr = class("static_shop_mgr", shop_mgr)
function static_shop_mgr:init()

end

function static_shop_mgr:load_shop_from_config(config)
    for id, shop_config in pairs(config) do
        local sp = shop.new()
        sp.merchadise_list = shop_config.merchadise_list
        sp.shop_type = shop_config.shop_type
        sp.shop_id = id
        sp.is_yuanbao_shop = shop_config.is_yuanbao_shop
        self.shops[id] = sp
    end
end

function static_shop_mgr:get_shop_by_shop_type_and_item_index(shop_type, item_index)
    for _, sp in pairs(self.shops) do
        if sp.shop_type == shop_type then
            local index, merchadise = sp:get_merchadise_by_id(item_index)
            if index then
                return sp, index, merchadise
            end
        end
    end
end

local dynamic_shop_mgr = class("dynamic_shop_mgr", shop_mgr)
function dynamic_shop_mgr:ctor(monster, sceneid)
    self.monster = monster
    self.npc_id = monster:get_obj_id()
    self:gen_unique_id(sceneid)
end

function dynamic_shop_mgr:init()

end

function dynamic_shop_mgr:add_dynamic_shop(shop_id)

end
function shopenginer:getinstance()
    if shopenginer.instance == nil then
        shopenginer.instance = shopenginer.new()
    end
    return shopenginer.instance
end

function shopenginer:ctor()
    self.shop_table = nil
    self.static_shop_mgr = nil
    self.inited = false
    self.shop_cfg_version = 0
end

function shopenginer:set_scene(scene)
    self.scene = scene
end

function shopenginer:ensure_inited()
    if self.inited then return end
    if not self.scene or not self.scene.get_id then
        return
    end
    local sceneid = self.scene:get_id()
    if not sceneid then
        return
    end
    -- [audit 2026-09-10] chi danh dau inited SAU khi tao xong; truoc day neu get_config/load nem loi
    -- thi inited=true ma static_shop_mgr=nil vinh vien -> moi shop trong scene do "index a nil value"
    local shop_table = configenginer:get_config("shop_table")
    if type(shop_table) ~= "table" then
        skynet.logw("[shopenginer] shop_table chua san sang, scene=", tostring(sceneid))
        return
    end
    local mgr = static_shop_mgr.new(sceneid)
    mgr:load_shop_from_config(shop_table)
    self.shop_table = shop_table
    self.static_shop_mgr = mgr
    self.inited = true
end

function shopenginer:init()
    self:ensure_inited()
end

function shopenginer:get_static_shop_mgr()
    self:ensure_inited()
    return self.static_shop_mgr
end

function shopenginer:create_dynamic_shop_mgr(monster)
    local mgr = dynamic_shop_mgr.new(monster, self.scene:get_id())
    mgr:init()
    return mgr
end

function shopenginer:reload()
    -- 从 CfgDB 获取最新数据，由场景侧发布到 sharetable
    local new_config = skynet.call(".CfgDB", "lua", "get_shop_table")
    if new_config then
        sharetable.loadtable("shop_table", new_config)
    end
    configenginer:invalidate_config("shop_table")
    self.inited = false
    self:ensure_inited()
    self.shop_cfg_version = self.shop_cfg_version + 1
    skynet.logd("[shopenginer] reloaded, version =", self.shop_cfg_version)
end

function shopenginer:get_shop_cfg_version()
    return self.shop_cfg_version
end

return shopenginer
