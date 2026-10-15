local skynet = require "skynet"
local queue = require "skynet.queue"
require "skynet.manager"
local server_conf = require "server_conf"
local define = require "define"
local class = require "class"
local copyscenemanager_core = class("copyscenemanager_core")

function copyscenemanager_core:getinstance()
    if copyscenemanager_core.instance == nil then
        copyscenemanager_core.instance = copyscenemanager_core.new()
    end
    return copyscenemanager_core.instance
end

function copyscenemanager_core:ctor()
    self.load = {}
    self.selectd = {}
    self.sleeping = {}
    self.loading = {}
    self.select_lock = queue()
    self.delta_time = 10
    self.cursor = 0
    self.sn = 0
end

function copyscenemanager_core:create_one_copy_scene(index)
    local handle = skynet.newservice("copyscene")
    skynet.call(handle, "lua", "register", index + define.COPY_SCENE_BEGIN)
    skynet.call(handle, "lua", "init")
    self.load[index] = handle
    self.sleeping[handle] = index
end

function copyscenemanager_core:init(conf)
    self.world_id = conf.world_id
    local prewarm = server_conf.PREWARM_COPY_SCENE or 3
    for i = 1, prewarm do
        self:create_one_copy_scene(i)
    end
    skynet.logi("[MEM_OPT] copyscene prewarm =", prewarm, ", max =", server_conf.MAX_COPY_SCENE)
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

function copyscenemanager_core:reload_scripts()
    -- print("scriptenginer:reload_scripts")
    for i, scene in ipairs(self.load) do
        -- print("scriptenginer:reload_scripts scene =", scene)
        local r, err = pcall(skynet.send, scene, "lua", "reload_scripts")
        if not r then
            print("reload_scripts error =", err)
        end
        if i % 10 == 0 then
            skynet.sleep(1)
        end
    end
end

function copyscenemanager_core:reload_shop_table()
    skynet.logi("[CopySceneManager] reload_shop_table: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_shop_table")
    if not ok then
        skynet.logi("[CopySceneManager] reload_shop_table: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("shop_table", skynet.call(".CfgDB", "lua", "get_shop_table"))
    skynet.logi("[CopySceneManager] reload_shop_table: CfgDB OK, broadcasting to", #self.load, "scenes")
    local fail = 0
    for _, scene in ipairs(self.load) do
        local r, err = pcall(skynet.call, scene, "lua", "reload_shop_table")
        if not r then
            fail = fail + 1
            skynet.logi("[CopySceneManager] reload_shop_table scene error:", err)
        end
    end
    skynet.logi("[CopySceneManager] reload_shop_table done, total=", #self.load, " fail=", fail)
end

function copyscenemanager_core:reload_std_impact()
    skynet.logi("[CopySceneManager] reload_std_impact: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_std_impact")
    if not ok then
        skynet.logi("[CopySceneManager] reload_std_impact: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[CopySceneManager] reload_std_impact: CfgDB OK, broadcasting to", #self.load, "scenes")
    local fail = 0
    for _, scene in ipairs(self.load) do
        local r, err = pcall(skynet.call, scene, "lua", "reload_std_impact")
        if not r then
            fail = fail + 1
            skynet.logi("[CopySceneManager] reload_std_impact scene error:", err)
        end
    end
    skynet.logi("[CopySceneManager] reload_std_impact done, total=", #self.load, " fail=", fail)
end

function copyscenemanager_core:reload_drop_rate()
    skynet.logi("[CopySceneManager] reload_drop_rate: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_drop_rate")
    if not ok then
        skynet.logi("[CopySceneManager] reload_drop_rate: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[CopySceneManager] reload_drop_rate: CfgDB OK, broadcasting to", #self.load, "scenes")
    local fail = 0
    for _, scene in ipairs(self.load) do
        local r, err = pcall(skynet.call, scene, "lua", "reload_drop_rate")
        if not r then
            fail = fail + 1
            skynet.logi("[CopySceneManager] reload_drop_rate scene error:", err)
        end
    end
    skynet.logi("[CopySceneManager] reload_drop_rate done, total=", #self.load, " fail=", fail)
end

function copyscenemanager_core:reload_equip_base()
    skynet.logi("[CopySceneManager] reload_equip_base: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_equip_base")
    if not ok then
        skynet.logi("[CopySceneManager] reload_equip_base: CfgDB FAILED, abort")
        return
    end
    -- costume-20260904: nap lai sharetable cuc bo cua node nay (configenginer:load chi hoi CfgDB khi chua co)
    require("skynet.sharetable").loadtable("equip_base", skynet.call(".CfgDB", "lua", "get_equip_base"))
    skynet.logi("[CopySceneManager] reload_equip_base: CfgDB OK, broadcasting to", #self.load, "scenes")
    local fail = 0
    for _, scene in ipairs(self.load) do
        local r, err = pcall(skynet.call, scene, "lua", "reload_equip_base")
        if not r then
            fail = fail + 1
            skynet.logi("[CopySceneManager] reload_equip_base scene error:", err)
        end
    end
    skynet.logi("[CopySceneManager] reload_equip_base done, total=", #self.load, " fail=", fail)
end

function copyscenemanager_core:reload_monster_attr_ex()
    skynet.logi("[CopySceneManager] reload_monster_attr_ex: calling CfgDB...")
    local ok = skynet.call(".CfgDB", "lua", "reload_monster_attr_ex")
    if not ok then
        skynet.logi("[CopySceneManager] reload_monster_attr_ex: CfgDB FAILED, abort")
        return
    end
    skynet.logi("[CopySceneManager] reload_monster_attr_ex: CfgDB OK, broadcasting to", #self.load, "scenes")
    local fail = 0
    for _, scene in ipairs(self.load) do
        local r, err = pcall(skynet.call, scene, "lua", "reload_monster_attr_ex")
        if not r then
            fail = fail + 1
            skynet.logi("[CopySceneManager] reload_monster_attr_ex scene error:", err)
        end
    end
    skynet.logi("[CopySceneManager] reload_monster_attr_ex done, total=", #self.load, " fail=", fail)
end


function copyscenemanager_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("copyscenemanager_core:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function copyscenemanager_core:message_update()
    for i = 1, 10 do
        self.cursor = self.cursor + 1
        if self.cursor > #self.load then
            self.cursor = 1
        end
        local handle = self.load[self.cursor]
        if handle then
            local status = skynet.call(handle, "lua", "get_status")
            local loading_since = self.loading[handle]
            if loading_since then
                if status == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
                    self.loading[handle] = nil
                elseif status == define.SCENE_STATUS.SCENE_STATUS_SLEEP then
                    -- Calls to this scene are ordered after the asynchronous load.
                    -- A sleeping scene here therefore means that load failed.
                    self.loading[handle] = nil
                    self.sleeping[handle] = self.cursor
                    skynet.logw("copy scene load failed; release handle =", string.format(":%08x", handle))
                end
            elseif self.sleeping[handle] == nil and status == define.SCENE_STATUS.SCENE_STATUS_SLEEP then
                self.sleeping[handle] = self.cursor
                skynet.logi("mark handle =", string.format(":%08x", handle), "sleeping")
            end
        end
    end
end

function copyscenemanager_core:select_locked(conf)
    assert(type(conf) == "table")
    assert(conf.sn)
    assert(conf.source)
    assert(conf.params[1])
    local handle = next(self.sleeping)
    if handle == nil then
        -- 按需扩容：无空闲副本且未到上限时创建新副本
        if #self.load < server_conf.MAX_COPY_SCENE then
            local index = #self.load + 1
            self:create_one_copy_scene(index)
            handle = self.load[index]
            skynet.logi("[MEM_OPT] copyscene on-demand create index =", index)
        else
            return define.INVAILD_ID
        end
    end
    local id = self.sleeping[handle]
    self.sleeping[handle] = nil
    self.loading[handle] = skynet.now()
    conf.world_id = self.world_id
    skynet.send(handle, "lua", "load", conf)
    return id + define.COPY_SCENE_BEGIN
end

function copyscenemanager_core:select(conf)
    return self.select_lock(function()
        return self:select_locked(conf)
    end)
end

function copyscenemanager_core:find_copy_scene_id_by_copy_scene_params(copy_scene_type, index, arg)
    for i = 1, #self.load do
        local handle = self.load[i] or define.INVAILD_ID
        if handle ~= define.INVAILD_ID then
            if skynet.call(handle, "lua", "get_status") == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
                local params = skynet.call(handle, "lua", "get_params")
                if params[0] == copy_scene_type and params[index] == arg then
                    return handle
                end
            end
        end
    end
    return define.INVAILD_ID
end

function copyscenemanager_core:world_timer_update(timer)
    for i = 1, #self.load do
        local handle = self.load[i]
        if skynet.call(handle, "lua", "get_status") == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
            skynet.send(handle, "lua", "world_timer_update", timer)
        end
    end
end

function copyscenemanager_core:gen_sn()
    self.sn = self.sn + 1
    return self.sn
end


return copyscenemanager_core
