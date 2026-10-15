local skynet = require "skynet"
require "skynet.manager"
local configenginer = require "configenginer":getinstance()
local define = require "define"
local class = require "class"
local scenemanager_core = class("scenemanager_core")

local function timeout_call(timeout, addr, typename, ...)
    local co = coroutine.running()
    local ret = nil
    local timed_out = false
    skynet.fork(function(...)
        local r = table.pack(pcall(skynet.call, addr, typename, ...))
        if not timed_out then
            ret = r
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

function scenemanager_core:getinstance()
    if scenemanager_core.instance == nil then
        scenemanager_core.instance = scenemanager_core.new()
    end
    return scenemanager_core.instance
end

function scenemanager_core:ctor()

end

function scenemanager_core:init(conf)
    self.scenes = {}
    self.scene_map = {}
    self.scene_info_cache = {}
    self.world_id = conf.world_id
    configenginer:loadmany({"scene_info"})
    self:createScenes()
    skynet.timeout(6000, function() self:health_check_loop() end)
end

function scenemanager_core:get_all_scenes()
    return self.scenes
end

function scenemanager_core:reload_scripts()
    print("scriptenginer:reload_scripts")
    for i, scene in ipairs(self.scenes) do
        print("scriptenginer:reload_scripts scene =", scene)
        local r, err = pcall(skynet.send, scene, "lua", "reload_scripts")
        if not r then
            print("reload_scripts error =", err)
        end
        if i % 10 == 0 then
            skynet.sleep(1)
        end
    end
end

function scenemanager_core:reload_shop_table()
    skynet.logi("[SceneManager] reload_shop_table: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_shop_table")
    if not ok then
        skynet.logi("[SceneManager] reload_shop_table: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("shop_table", skynet.call(".CfgDB", "lua", "get_shop_table"))
    skynet.logi("[SceneManager] reload_shop_table: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, scene in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, scene, "lua", "reload_shop_table")
        if not r then
            fail = fail + 1
            skynet.logi("[SceneManager] reload_shop_table scene error:", err)
        end
    end
    skynet.logi("[SceneManager] reload_shop_table done, total=", #self.scenes, " fail=", fail)
end

function scenemanager_core:reload_std_impact()
    skynet.logi("[SceneManager] reload_std_impact: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_std_impact")
    if not ok then
        skynet.logi("[SceneManager] reload_std_impact: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[SceneManager] reload_std_impact: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, scene in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, scene, "lua", "reload_std_impact")
        if not r then
            fail = fail + 1
            skynet.logi("[SceneManager] reload_std_impact scene error:", err)
        end
    end
    skynet.logi("[SceneManager] reload_std_impact done, total=", #self.scenes, " fail=", fail)
end

function scenemanager_core:reload_drop_rate()
    skynet.logi("[SceneManager] reload_drop_rate: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_drop_rate")
    if not ok then
        skynet.logi("[SceneManager] reload_drop_rate: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[SceneManager] reload_drop_rate: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, scene in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, scene, "lua", "reload_drop_rate")
        if not r then
            fail = fail + 1
            skynet.logi("[SceneManager] reload_drop_rate scene error:", err)
        end
    end
    skynet.logi("[SceneManager] reload_drop_rate done, total=", #self.scenes, " fail=", fail)
end

function scenemanager_core:reload_equip_base()
    skynet.logi("[SceneManager] reload_equip_base: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_equip_base")
    if not ok then
        skynet.logi("[SceneManager] reload_equip_base: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("equip_base", skynet.call(".CfgDB", "lua", "get_equip_base"))
    skynet.logi("[SceneManager] reload_equip_base: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, scene in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, scene, "lua", "reload_equip_base")
        if not r then
            fail = fail + 1
            skynet.logi("[SceneManager] reload_equip_base scene error:", err)
        end
    end
    skynet.logi("[SceneManager] reload_equip_base done, total=", #self.scenes, " fail=", fail)
end

function scenemanager_core:reload_monster_attr_ex()
    skynet.logi("[SceneManager] reload_monster_attr_ex: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_monster_attr_ex")
    if not ok then
        skynet.logi("[SceneManager] reload_monster_attr_ex: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[SceneManager] reload_monster_attr_ex: CfgDB OK, broadcasting to", #self.scenes, "scenes")
    local fail = 0
    for _, scene in ipairs(self.scenes) do
        local r, err = xpcall(skynet.call, debug.traceback, scene, "lua", "reload_monster_attr_ex")
        if not r then
            fail = fail + 1
            skynet.logi("[SceneManager] reload_monster_attr_ex scene error:", err)
        end
    end
    skynet.logi("[SceneManager] reload_monster_attr_ex done, total=", #self.scenes, " fail=", fail)
end


function scenemanager_core:world_timer_update(timer)
    for _, scene in ipairs(self.scenes) do
        pcall(skynet.send, scene, "lua", "world_timer_update", timer)
    end
end

-- 启动时预创建所有普通场景（active=1, type=0），scene_info_cache 保留作为防御性兜底
function scenemanager_core:createScenes()
    local sceneInfo = skynet.call(".CfgDB", "lua", "get_scene_info")
    local created = 0
    for key, info in pairs(sceneInfo) do
        if info.active == 1 and info.type == 0 then
            local id = string.match(key, "scene(%d+)")
            id = tonumber(id)
            info.id = id
            info.world_id = self.world_id
            self.scene_info_cache[id] = table.clone(info)
            local scene = skynet.newservice("scene", info.name)
            local load_ok, load_err = pcall(skynet.call, scene, "lua", "load", info)
            if load_ok and load_err then
                table.insert(self.scenes, scene)
                self.scene_map[id] = scene
                created = created + 1
           	else
                skynet.loge(string.format("[SCENE_CREATE_FAIL] 场景 %s(id=%s) 创建/加载失败: %s", tostring(info.name), tostring(id), tostring(load_err)))
                pcall(skynet.call, ".launcher", "lua", "KILL", scene) -- 2026-09-11: bỏ service cảnh lỗi để .SCENE_<id> không trỏ tới cảnh nửa vời
           	end
            if created % 3 == 0 then
                skynet.sleep(1)
            end
        end
    end
    skynet.logi("[SceneManager] scene startup done, total =", created)
    collectgarbage("collect")
end

function scenemanager_core:is_scene_alive(sceneid)
    local handle = self.scene_map[sceneid]
    if not handle then return false end
    local ok, health = timeout_call(300, handle, "lua", "get_scene_health")
    return ok and type(health) == "table" and (health.tick_age or 0) <= 3000
end

function scenemanager_core:rebuild_scene(sceneid)
    local info = self.scene_info_cache[sceneid]
    if not info then
        skynet.loge(string.format("[SCENE_REBUILD_FAIL] 场景 %s 无缓存配置，无法重建", tostring(sceneid)))
        return false
    end
    skynet.logi("[SCENE_REBUILD] 重建场景 =", sceneid)
    local old_handle = self.scene_map[sceneid]
    if old_handle then
        pcall(skynet.call, ".launcher", "lua", "KILL", old_handle)
        for i, h in ipairs(self.scenes) do
            if h == old_handle then
                table.remove(self.scenes, i)
                break
            end
        end
    end
    local scene = skynet.newservice("scene", info.name)
    local load_ok, load_err = pcall(skynet.call, scene, "lua", "load", info)
    if load_ok and load_err then
        table.insert(self.scenes, scene)
        self.scene_map[sceneid] = scene
        skynet.logi("[SCENE_REBUILD] 场景", sceneid, "重建成功")
        return true
   	else
        skynet.loge(string.format("[SCENE_REBUILD_FAIL] 场景 %s 重建加载失败: %s", tostring(sceneid), tostring(load_err)))
        pcall(skynet.call, ".launcher", "lua", "KILL", scene) -- 2026-09-11: bỏ service cảnh lỗi để .SCENE_<id> không trỏ tới cảnh nửa vời
        return false
   	end
end

function scenemanager_core:health_check_loop()
    skynet.timeout(6000, function() self:health_check_loop() end)
    local dead_scenes = {}
    local stale_tick = 3000
    for sceneid, handle in pairs(self.scene_map) do
        local ok, health = timeout_call(300, handle, "lua", "get_scene_health")
        if not ok or type(health) ~= "table" then
            table.insert(dead_scenes, sceneid)
        elseif (health.tick_age or 0) > stale_tick then
            skynet.loge(string.format("[SCENE_HEALTH] scene %s tick stale, age=%s mqlen=%s humans=%s monsters=%s",
                tostring(sceneid), tostring(health.tick_age), tostring(health.mqlen),
                tostring(health.human_count), tostring(health.monster_count)))
            table.insert(dead_scenes, sceneid)
        end
    end
    for _, sceneid in ipairs(dead_scenes) do
        skynet.loge(string.format("[SCENE_HEALTH] 场景 %s 无响应，尝试重建", tostring(sceneid)))
        self:rebuild_scene(sceneid)
    end
    if #dead_scenes > 0 then
        skynet.logi("[SCENE_HEALTH] 健康检查完成，死亡场景:", #dead_scenes)
    end
end

-- 按需创建非核心场景，返回 true 表示场景已就绪
function scenemanager_core:ensure_scene(sceneid)
    if self.scene_map[sceneid] then
        local ok, health = timeout_call(300, self.scene_map[sceneid], "lua", "get_scene_health")
        if ok and type(health) == "table" and (health.tick_age or 0) <= 3000 then
            return true
        end

        skynet.loge(string.format("[SCENE_RECOVERY] scene %s no response, rebuild", tostring(sceneid)))
        local old_handle = self.scene_map[sceneid]
        pcall(skynet.call, ".launcher", "lua", "KILL", old_handle)
        for i, h in ipairs(self.scenes) do
            if h == old_handle then
                table.remove(self.scenes, i)
                break
            end
        end
        self.scene_map[sceneid] = nil
    end

    local info = self.scene_info_cache[sceneid]
    if not info then
        return false
    end

    skynet.logi("[MEM_OPT] on-demand create scene =", sceneid)
    local scene = skynet.newservice("scene", info.name)
    local load_ok, load_err = pcall(skynet.call, scene, "lua", "load", info)
    if load_ok and load_err then
        table.insert(self.scenes, scene)
        self.scene_map[sceneid] = scene
        collectgarbage("collect")
        return true
    end

    skynet.loge(string.format("[SCENE_CREATE_FAIL] scene %s create failed: %s", tostring(sceneid), tostring(load_err)))
    pcall(skynet.call, ".launcher", "lua", "KILL", scene) -- 2026-09-11: bỏ service cảnh lỗi để .SCENE_<id> không trỏ tới cảnh nửa vời
    return false
end

function scenemanager_core:span_close()

end
return scenemanager_core
