local skynet = require "skynet"
local queue = require "skynet.queue"
require "skynet.manager"
local configenginer = require "configenginer":getinstance()
local define = require "define"
local class = require "class"
local dynamicscenemanager_core = class("dynamicscenemanager_core")

local function same_number(left, right)
    local left_number = tonumber(left)
    local right_number = tonumber(right)
    return left_number ~= nil and right_number ~= nil and left_number == right_number
end

local function timeout_call(timeout, addr, typename, ...)
    local co = coroutine.running()
    local ret
    local timed_out = false
    skynet.fork(function(...)
        local result = table.pack(pcall(skynet.call, addr, typename, ...))
        if not timed_out then
            ret = result
            skynet.wakeup(co)
        end
    end, ...)
    skynet.timeout(timeout, function()
        if ret == nil then
            timed_out = true
            skynet.wakeup(co)
        end
    end)
    skynet.wait(co)
    if ret then
        return table.unpack(ret)
    end
    return false, "timeout"
end

function dynamicscenemanager_core:getinstance()
    if dynamicscenemanager_core.instance == nil then
        dynamicscenemanager_core.instance = dynamicscenemanager_core.new()
    end
    return dynamicscenemanager_core.instance
end

function dynamicscenemanager_core:ctor()

end

function dynamicscenemanager_core:init(conf)
    self.scenes = {}
    self.scene_map = {}
    self.city_lock = queue()
    self.world_id = conf.world_id
    configenginer:loadmany({"scene_info", "city_info", "city_building"})
    self:loadcitys()
    self:createScenes()
end

function dynamicscenemanager_core:reload_scripts()
    print("scriptenginer:reload_scripts")
    for i, entry in ipairs(self.scenes) do
        print("scriptenginer:reload_scripts scene =", entry.scene)
        local r, err = pcall(skynet.send, entry.scene, "lua", "reload_scripts")
        if not r then
            print("reload_scripts error =", err)
        end
        if i % 10 == 0 then
            skynet.sleep(1)
        end
    end
end

function dynamicscenemanager_core:reload_shop_table()
    skynet.logi("[DynamicSceneManager] reload_shop_table: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_shop_table")
    if not ok then
        skynet.logi("[DynamicSceneManager] reload_shop_table: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("shop_table", skynet.call(".CfgDB", "lua", "get_shop_table"))
    skynet.logi("[DynamicSceneManager] reload_shop_table: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, entry in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, entry.scene, "lua", "reload_shop_table")
        if not r then
            fail = fail + 1
            skynet.logi("[DynamicSceneManager] reload_shop_table scene error:", err)
        end
    end
    skynet.logi("[DynamicSceneManager] reload_shop_table done, total=", #self.scenes, " fail=", fail)
end

function dynamicscenemanager_core:reload_std_impact()
    skynet.logi("[DynamicSceneManager] reload_std_impact: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_std_impact")
    if not ok then
        skynet.logi("[DynamicSceneManager] reload_std_impact: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[DynamicSceneManager] reload_std_impact: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, entry in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, entry.scene, "lua", "reload_std_impact")
        if not r then
            fail = fail + 1
            skynet.logi("[DynamicSceneManager] reload_std_impact scene error:", err)
        end
    end
    skynet.logi("[DynamicSceneManager] reload_std_impact done, total=", #self.scenes, " fail=", fail)
end

function dynamicscenemanager_core:reload_drop_rate()
    skynet.logi("[DynamicSceneManager] reload_drop_rate: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_drop_rate")
    if not ok then
        skynet.logi("[DynamicSceneManager] reload_drop_rate: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[DynamicSceneManager] reload_drop_rate: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, entry in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, entry.scene, "lua", "reload_drop_rate")
        if not r then
            fail = fail + 1
            skynet.logi("[DynamicSceneManager] reload_drop_rate scene error:", err)
        end
    end
    skynet.logi("[DynamicSceneManager] reload_drop_rate done, total=", #self.scenes, " fail=", fail)
end

function dynamicscenemanager_core:reload_equip_base()
    skynet.logi("[DynamicSceneManager] reload_equip_base: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_equip_base")
    if not ok then
        skynet.logi("[DynamicSceneManager] reload_equip_base: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("equip_base", skynet.call(".CfgDB", "lua", "get_equip_base"))
    skynet.logi("[DynamicSceneManager] reload_equip_base: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, entry in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, entry.scene, "lua", "reload_equip_base")
        if not r then
            fail = fail + 1
            skynet.logi("[DynamicSceneManager] reload_equip_base scene error:", err)
        end
    end
    skynet.logi("[DynamicSceneManager] reload_equip_base done, total=", #self.scenes, " fail=", fail)
end

function dynamicscenemanager_core:reload_monster_attr_ex()
    skynet.logi("[DynamicSceneManager] reload_monster_attr_ex: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_monster_attr_ex")
    if not ok then
        skynet.logi("[DynamicSceneManager] reload_monster_attr_ex: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[DynamicSceneManager] reload_monster_attr_ex: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, entry in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, entry.scene, "lua", "reload_monster_attr_ex")
        if not r then
            fail = fail + 1
            skynet.logi("[DynamicSceneManager] reload_monster_attr_ex scene error:", err)
        end
    end
    skynet.logi("[DynamicSceneManager] reload_monster_attr_ex done, total=", #self.scenes, " fail=", fail)
end




function dynamicscenemanager_core:loadcitys()
    local response = skynet.call(".db", "lua", "findAll",  {collection = "city",query = nil, selector = nil, skip = 0, sorter = { {["id"] = 1} }})
    print("load citys =", table.tostr(response))
    self.citys = response or {}
    for _, city in ipairs(self.citys) do
        if not self:gen_default_buildings(city) then
            skynet.loge("[CITY_DATA_INVALID] unable to complete buildings, city_id =", city.id)
        end
    end
end

function dynamicscenemanager_core:gen_default_buildings(city, persist)
    local id = city.id
    local sceneid = self:get_city_scene_id(id)
    if not sceneid then return false end
    local city_building = configenginer:get_config("city_building")
    local scene_buildings = {}
    for _, building in pairs(city_building) do
        if same_number(building["CityID"], sceneid) then
            local building_type = tonumber(building["BuildingType"]) or building["BuildingType"]
            scene_buildings[building_type] = building
        end
    end
    local buildings = table.clone(city.buildings or {})
    local changed = false
    for building_type, build_index in pairs(define.CITY_INIT_BUILDINGS) do
        local key = tostring(build_index)
        local building = buildings[key]
        if type(building) ~= "table" or not building.id then
            local scene_building = scene_buildings[building_type]
            if not scene_building then
                return false
            end
            buildings[key] = { id = scene_building["ID"], level = 1 }
            changed = true
        end
    end
    city.buildings = buildings
    if changed and persist ~= false then
        self:db_update_city_buildings(city, buildings)
    end
    return true
end

function dynamicscenemanager_core:reload_citys()
    self:loadcitys()
end

function dynamicscenemanager_core:is_city_scene_apply(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return true
        end
    end
    return false
end

function dynamicscenemanager_core:get_scene_city_buildings(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.buildings
        end
    end
end

function dynamicscenemanager_core:get_city_name(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.name
        end
    end
end

function dynamicscenemanager_core:get_scene_city_name(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.name
        end
    end
end

function dynamicscenemanager_core:get_scene_guild_id(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.guild_id
        end
    end
end

function dynamicscenemanager_core:get_scene_city_id(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.id
        end
    end
end

function dynamicscenemanager_core:get_scene_city_level(sceneid)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            return city.level
        end
    end
end

function dynamicscenemanager_core:get_scene_city_client_res(sceneid)
    local this_city
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), sceneid) then
            this_city = city
        end
    end
    if not this_city then return end
    local city_info = configenginer:get_config("city_info")
    city_info = city_info and city_info[tonumber(this_city.id)]
    if not city_info then return end
    local level = tonumber(this_city.level)
    if not level then return end
    local key = string.format("%d级城市", level)
    return city_info[key]
end

function dynamicscenemanager_core:get_city_scene_id(city_id)
    city_id = tonumber(city_id)
    if not city_id then return end
    local city_info = configenginer:get_config("city_info")
    city_info = city_info and city_info[city_id]
    if not city_info then return end
    return tonumber(city_info["场景ID"])
end

function dynamicscenemanager_core:get_city_by_id(city_id)
    city_id = tonumber(city_id)
    for _, city in ipairs(self.citys) do
        if tonumber(city.id) == city_id then
            return city
        end
    end
end

function dynamicscenemanager_core:get_city_by_scene_id(scene_id)
    scene_id = tonumber(scene_id)
    for _, city in ipairs(self.citys) do
        if same_number(self:get_city_scene_id(city.id), scene_id) then
            return city
        end
    end
end

function dynamicscenemanager_core:get_city_list()
    return self.citys
end

function dynamicscenemanager_core:is_city_occupied(city_id)
    for _, city in ipairs(self.citys) do
        if same_number(city.id, city_id) then
            return true
        end
    end
    return false
end

function dynamicscenemanager_core:get_empty_city_by_city_enter_group(city_enter_group)
    local city_info = configenginer:get_config("city_info")
    for i = 1, define.MAX_CITY_SCENE do
        local this_city_info = city_info[i]
        if this_city_info and same_number(this_city_info["入口组"], city_enter_group) then
            if not self:is_city_occupied(i) then
                return i
            end
        end
    end
end

function dynamicscenemanager_core:occupie_city(guild_id, city_enter_group, city_name)
    return self.city_lock(function()
        return self:occupie_city_locked(guild_id, city_enter_group, city_name)
    end)
end

function dynamicscenemanager_core:occupie_city_locked(guild_id, city_enter_group, city_name)
    guild_id = tonumber(guild_id)
    city_enter_group = tonumber(city_enter_group)
    if not guild_id or not city_enter_group or type(city_name) ~= "string" or city_name == "" then
        skynet.loge("[CITY_APPLY_FAIL] invalid apply data, guild_id =", guild_id,
            ", enter_group =", city_enter_group)
        return
    end
    local city_id = self:get_empty_city_by_city_enter_group(city_enter_group)
    if city_id == nil then
        skynet.loge("[CITY_APPLY_FAIL] no free city, guild_id =", guild_id,
            ", enter_group =", city_enter_group)
        return
    end
    local new_city = { id = city_id, name = city_name, guild_id = guild_id, level = 1}
    if not self:gen_default_buildings(new_city, false) then
        skynet.loge("[CITY_APPLY_FAIL] default buildings unavailable, city_id =", city_id)
        return
    end
    local insert_ok, insert_err = self:db_insert_city(new_city)
    if not insert_ok then
        skynet.loge("[CITY_APPLY_FAIL] database insert failed, city_id =", city_id,
            ", error =", tostring(insert_err))
        return
    end
    self:reload_citys()

    local create_ok, scene_id = pcall(self.run_city_scene, self, city_id)
    if not create_ok or not scene_id then
        skynet.loge("[CITY_APPLY_FAIL] scene create failed, city_id =", city_id,
            ", error =", tostring(scene_id))
        self:release_city(city_id, guild_id)
        return
    end
    return city_id
end

function dynamicscenemanager_core:get_port_scene_id_by_guild_id(guild_id)
    for _, city in ipairs(self.citys) do
        if same_number(city.guild_id, guild_id) then
            return self:get_city_port_scene_id(city)
        end
    end
end

function dynamicscenemanager_core:get_city_port_scene_id(city)
    local city_info = configenginer:get_config("city_info")
    city_info = city_info and city_info[tonumber(city.id)]
    return city_info and tonumber(city_info["入口场景ID"])
end

function dynamicscenemanager_core:db_insert_city(city)
    return skynet.call(".db", "lua", "safe_insert", { collection = "city", doc = city })
end

function dynamicscenemanager_core:db_delete_city(city_id)
    skynet.call(".db", "lua", "delete", {
        collection = "city",
        selector = { id = city_id },
        single = true,
    })
end

function dynamicscenemanager_core:release_city(city_id, guild_id)
    city_id = tonumber(city_id)
    local city = self:get_city_by_id(city_id)
    if not city or (guild_id ~= nil and not same_number(city.guild_id, guild_id)) then
        return false
    end

    local scene_id = self:get_city_scene_id(city_id)
    if scene_id then
        local handle = self:remove_scene_entry(scene_id) or
            skynet.localname(string.format(".SCENE_%d", scene_id))
        if handle then
            pcall(skynet.call, ".launcher", "lua", "KILL", handle)
        end
    end
    self:db_delete_city(city.id)
    self:reload_citys()
    skynet.logi("[DynamicSceneManager] city released, city_id =", city_id,
        ", guild_id =", tostring(guild_id))
    return true
end

function dynamicscenemanager_core:db_update_city_buildings(city, buildings)
    local selector = {["id"] = city.id }
    local updater = {}
    updater["$set"] = { buildings = buildings }
    local sql = { collection = "city", selector = selector,update = updater,upsert = false,multi = false}
    print("db_update_city_buildings sql =", table.tostr(sql))
    local ret = skynet.call(".db", "lua", "update", sql)
    print("db_update_city_buildings city.id =", city.id, ";ret =", table.tostr(ret))
end

function dynamicscenemanager_core:createScenes()
    local created = 0
    for index, city in ipairs(self.citys) do
        if self:run_city_scene(city.id) then
            created = created + 1
        end
        if index % 3 == 0 then
            skynet.sleep(1)
        end
    end
    skynet.logi("[DynamicSceneManager] city scene startup done, total =", created)
    collectgarbage("collect")
end

function dynamicscenemanager_core:remove_scene_entry(scene_id)
    local old = self.scene_map[scene_id]
    self.scene_map[scene_id] = nil
    for i = #self.scenes, 1, -1 do
        local entry = self.scenes[i]
        if entry.scene_id == scene_id or (old and entry.scene == old) then
            table.remove(self.scenes, i)
        end
    end
    return old
end

function dynamicscenemanager_core:is_scene_handle_ready(handle, scene_id, city_id)
    scene_id = tonumber(scene_id)
    city_id = tonumber(city_id)
    if not handle then return false, "missing handle" end
    if not scene_id or not city_id then return false, "invalid expected id" end
    local alias = skynet.localname(string.format(".SCENE_%d", scene_id))
    if alias ~= handle then return false, "scene alias mismatch" end
    local ok, health = timeout_call(300, handle, "lua", "get_scene_health")
    if not ok then return false, "health check timeout or error" end
    if type(health) ~= "table" then return false, "invalid health response" end
    if health.loaded ~= true then return false, "scene load failed" end
    if not same_number(health.sceneid, scene_id) then
        return false, string.format("scene id mismatch: actual=%s", tostring(health.sceneid))
    end
    local tick_age = tonumber(health.tick_age)
    if not tick_age or tick_age > 3000 then
        return false, string.format("scene heartbeat timeout: tick_age=%s", tostring(health.tick_age))
    end
    local city_ok, running_city_id = timeout_call(300, handle, "lua", "get_city_id")
    if not city_ok then return false, "city id check timeout or error" end
    if not same_number(running_city_id, city_id) then
        return false, string.format("city id mismatch: actual=%s", tostring(running_city_id))
    end
    return true
end

function dynamicscenemanager_core:is_city_scene_running(city_id)
    city_id = tonumber(city_id)
    local scene_id = self:get_city_scene_id(city_id)
    if not scene_id then return false end
    local handle = self.scene_map[scene_id]
    local ready, reason = self:is_scene_handle_ready(handle, scene_id, city_id)
    if ready then
        return true
    end
    if handle then
        skynet.loge("[CITY_SCENE_NOT_READY] city_id =", city_id, ", scene_id =", scene_id,
            ", reason =", tostring(reason))
    end
    self:remove_scene_entry(scene_id)
    return false
end

function dynamicscenemanager_core:recover_city_record(city_id)
    return self.city_lock(function()
        return self:recover_city_record_locked(city_id)
    end)
end

function dynamicscenemanager_core:recover_city_record_locked(city_id)
    city_id = tonumber(city_id)
    if not city_id or self:get_city_by_id(city_id) then
        return self:get_city_by_id(city_id)
    end

    local owner_ok, owner = pcall(skynet.call, ".Guildmanager", "lua", "get_city_owner_info", city_id)
    if not owner_ok or type(owner) ~= "table" or not same_number(owner.city_id, city_id) then
        skynet.loge("[CITY_RECOVER_FAIL] owner not found, city_id =", city_id)
        return
    end
    local city = {
        id = city_id,
        name = owner.city_name,
        guild_id = owner.guild_id,
        level = 1,
    }
    if not city.guild_id or not city.name or not self:gen_default_buildings(city, false) then
        skynet.loge("[CITY_RECOVER_FAIL] owner data incomplete, city_id =", city_id)
        return
    end
    local insert_ok, insert_err = self:db_insert_city(city)
    if not insert_ok then
        skynet.loge("[CITY_RECOVER_FAIL] database insert failed, city_id =", city_id,
            ", error =", tostring(insert_err))
        return
    end
    self:reload_citys()
    skynet.logi("[DynamicSceneManager] city record recovered, city_id =", city_id,
        ", guild_id =", tostring(city.guild_id))
    return self:get_city_by_id(city_id)
end

function dynamicscenemanager_core:run_city_scene(city_id)
    city_id = tonumber(city_id)
    local city = self:get_city_by_id(city_id)
    if not city then
        skynet.loge("[CITY_SCENE_CREATE_FAIL] city record not found, city_id =", city_id)
        return
    end
    local id = self:get_city_scene_id(city_id)
    if not id then
        skynet.loge("[CITY_SCENE_CREATE_FAIL] city config not found, city_id =", city_id)
        return
    end
    if self:is_city_scene_running(city_id) then
        return id
    end

    local scene_name = string.format(".SCENE_%d", id)
    local existing = skynet.localname(scene_name)
    if existing then
        local existing_ready, existing_reason = self:is_scene_handle_ready(existing, id, city_id)
        if existing_ready then
            self.scene_map[id] = existing
            table.insert(self.scenes, { scene = existing, scene_id = id })
            return id
        end
        skynet.loge("[CITY_SCENE_NOT_READY] replacing scene, city_id =", city_id,
            ", scene_id =", id, ", reason =", tostring(existing_reason))
        pcall(skynet.call, ".launcher", "lua", "KILL", existing)
        skynet.sleep(1)
    end

    local sceneInfo = skynet.call(".CfgDB", "lua", "get_scene_info")
    local key = string.format("scene%d", id)
    local info = sceneInfo and sceneInfo[key]
    if not info or tonumber(info.active) ~= 1 or tonumber(info.type) ~= 4 then
        skynet.loge("[CITY_SCENE_CREATE_FAIL] invalid SceneInfo, city_id =", city_id, ", scene_id =", id)
        return
    end
    info = table.clone(info)
    info.city_name = city.name
    info.city_level = tonumber(city.level) or city.level
    info.clientres = self:get_scene_city_client_res(id)
    info.id = id
    info.buildings = city.buildings
    info.world_id = self.world_id
    info.guild_id = tonumber(city.guild_id) or city.guild_id
    info.city_id = tonumber(city.id) or city.id
    if not info.clientres or not self:gen_default_buildings(city) or not info.guild_id then
        skynet.loge("[CITY_SCENE_CREATE_FAIL] incomplete city data, city_id =", city_id, ", scene_id =", id)
        return
    end
    info.buildings = city.buildings

    local scene = skynet.newservice("dynamicscene")
    local load_ok, loaded = pcall(skynet.call, scene, "lua", "load", info)
    local ready, ready_reason
    if load_ok and loaded == true then
        ready, ready_reason = self:is_scene_handle_ready(scene, id, city_id)
    end
    if not load_ok or loaded ~= true or not ready then
        skynet.loge("[CITY_SCENE_CREATE_FAIL] load failed, city_id =", city_id,
            ", scene_id =", id, ", result =", tostring(loaded),
            ", reason =", tostring(ready_reason))
        pcall(skynet.call, ".launcher", "lua", "KILL", scene)
        return
    end

    table.insert(self.scenes, { scene = scene, scene_id = id })
    self.scene_map[id] = scene
    skynet.logi("[DynamicSceneManager] city scene ready, city_id =", city_id, ", scene_id =", id)
    return id
end

function dynamicscenemanager_core:check_city_running(city_id)
    city_id = tonumber(city_id)
    if not city_id or city_id == define.INVAILD_ID then return end
    if not self:get_city_by_id(city_id) and not self:recover_city_record(city_id) then
        return
    end
    if not self:is_city_scene_running(city_id) then
        return self:run_city_scene(city_id)
    end
    return self:get_city_scene_id(city_id)
end

function dynamicscenemanager_core:ensure_city_scene(scene_id)
    scene_id = tonumber(scene_id)
    if not scene_id then return end
    local city = self:get_city_by_scene_id(scene_id)
    if not city then
        for city_id = 1, define.MAX_CITY_SCENE do
            if same_number(self:get_city_scene_id(city_id), scene_id) then
                city = self:recover_city_record(city_id)
                break
            end
        end
    end
    if not city then return end
    return self:check_city_running(city.id)
end

function dynamicscenemanager_core:world_timer_update(timer)
    for _, entry in ipairs(self.scenes) do
        skynet.send(entry.scene, "lua", "world_timer_update", timer)
    end
end

return dynamicscenemanager_core
