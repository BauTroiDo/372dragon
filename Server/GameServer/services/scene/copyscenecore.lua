local skynet = require "skynet"
local AOI = require "scene.sceneaoi":getinstance()
local configenginer = require "configenginer":getinstance()
local class = require "class"
local define = require "define"
local utils = require "utils"
local scenecore = require "scene.scenecore"
local copyscenecore = class("copyscenecore", scenecore)
local no_human_clean_up_time_diff = 60 * 1

function copyscenecore:getinstance()
    if copyscenecore.instance == nil then copyscenecore.instance = copyscenecore.new() end
    return copyscenecore.instance
end

function copyscenecore:light_init()
    self.now_obj_id = 1
    self.sn = define.INVAILD_ID
    self.chiji_flag = false
    self.timer_count = 0
    self.no_human_time = nil
    self.last_partrol_point_indexs = {}
    self.runtime_inited = false
    self.status = define.SCENE_STATUS.SCENE_STATUS_SLEEP
end

function copyscenecore:init()
    self:light_init()
end

function copyscenecore:get_name()
    local client_res = self.client_res
    local scene_define_ex = configenginer:get_config("scene_define_ex")
    scene_define_ex = scene_define_ex[client_res]
    return scene_define_ex and scene_define_ex.name or "未知场景"
end

function copyscenecore:clean_up()
    assert(self:get_human_count() == 0, self:get_human_count())
    local objs = {}
    for _, obj in pairs(self.objs) do
        table.insert(objs, obj)
    end
    for _, obj in ipairs(objs) do
        self:delete_obj(obj)
    end
    -- [MEM_OPT] 残留对象检查
    local residual = 0
    for _ in pairs(self.objs) do
        residual = residual + 1
    end
    if residual > 0 then
        skynet.logw("[MEM_LEAK] copyscene clean_up residual objs =", residual, ", id =", self.id)
    end
    self.objs = {}
    self.map = nil
    self.sn = define.INVAILD_ID
    self.timer_count = 0
    self.conf = nil
    self.no_human_time = nil
    self.chiji_flag = false
    self.last_partrol_point_indexs = {}
    -- [MEM_OPT] 清理可能残留的配置引用
    self.monster_conf = nil
    self.event_conf = nil
    self.platformf_conf = nil
    self.bus_conf = nil
    self.patrols = nil
    -- [MEM_OPT] 清理场景运行时大表
    self.scn = nil
    self.stallinfo = nil
    self.running_activitys = {}
    self.timers = {}
    self.guid2objs = {}
    self.objs_count = {}
    collectgarbage("collect")
    skynet.logi("[MEM_OPT] copyscene cleanup id =", self.id, ";address =", skynet.self())
    self.status = define.SCENE_STATUS.SCENE_STATUS_SLEEP
end

function copyscenecore:get_type()
    return 1
end

function copyscenecore:register(id)
    local name = string.format(".SCENE_%d", id)
    skynet.register(name)
    self.id = id
    return name
end

function copyscenecore:load(conf)
    -- 延迟重初始化：第一次 load 时才执行重量级初始化
    if not self.runtime_inited then
        self.super.init_conf(self, { name = "副本" })
        self.runtime_inited = true
        skynet.logi("[MEM_OPT] copyscene runtime init id =", self.id)
    end
    -- print("self.scn.System.navmapname =", conf.navmapname)
    -- print("self.scn.System.monsterfile =", conf.monsterfile)
    if conf.navmapname then
        if not self:init_navmap(conf.navmapname) then
            return false
        end
    end
    if conf.patrolpoint then self:init_patrol_point(conf.patrolpoint) end
    if conf.monsterfile then self:init_monster(conf.monsterfile) end
    if conf.eventfile then self:init_event_area(conf.eventfile) end
    if conf.growpointdata and conf.growpointsetup then
        self.growpointenginer:load_data_and_set_up(conf.growpointdata, conf.growpointsetup)
    end
    self.conf = conf
    self.client_res = conf.client_res
    self.pvp_rule = conf.PvpRule or 0
    self.world_id = conf.world_id
    self.chiji_flag = conf.chiji_flag
    self.status = define.SCENE_STATUS.SCENE_STATUS_RUNNING
    self.eventenginer:active()
    self:ready()
    return true
end

function copyscenecore:ready()
    local conf = self.conf
    local source = conf.source
    local script_id = conf.params[1]
    skynet.call(source, "lua", "on_copy_scene_ready", script_id, self.id)
end

function copyscenecore:get_status()
    return self.status
end

function copyscenecore:get_params()
    return self.conf.params
end

function copyscenecore:get_team_leader()
    return self.conf.teamleader
end

function copyscenecore:get_sn()
    if self.conf then
        return self.conf.sn
    else
        return define.INVAILD_ID
    end
end

function copyscenecore:check_need_clean_up()
    if self:get_status() == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
        local human_count = self:get_human_count()
        if human_count == 0 then
            local now = os.time()
            if self.no_human_time then
                local diff = now - self.no_human_time
                --print("diff =", diff, ";no_human_clean_up_time_diff =", no_human_clean_up_time_diff)
                if diff > no_human_clean_up_time_diff then
                    self:clean_up()
                end
            else
                self.no_human_time = now
            end
        else
            self.no_human_time = nil
        end
    end
end

function copyscenecore:log_copy_scene_monsters(delta_time)
    if self:get_status() == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
        self.tick_log_copy_scene_monsters_tick = self.tick_log_copy_scene_monsters_tick or 0
        self.tick_log_copy_scene_monsters_tick = self.tick_log_copy_scene_monsters_tick + delta_time
        if self.tick_log_copy_scene_monsters_tick >= 60000 then
            self.tick_log_copy_scene_monsters_tick = 0
            local monster_count = self:get_monster_count()
            for i = 1, monster_count do
                local obj_id = self:get_monster_obj_id(i)
                local monster = self:get_obj_by_id(obj_id)
                -- skynet.logi("log_copy_scene_monsters i =", i, ";obj_id =", obj_id, ";name =", monster:get_name(), ";world_pos =", table.tostr(monster:get_world_pos()))
            end
        end
    end
end

function copyscenecore:OnCopySceneTimer(delta_time)
    if self.conf then
        self.timer_count = self.timer_count + delta_time
        if self.timer_count >= self.conf.Timer then
            self.timer_count = self.timer_count - self.conf.Timer
            local script_id = self:get_param(1)
            self.scriptenginer:call(script_id, "OnCopySceneTimer", skynet.now() * 10)
        end
    end
end

function copyscenecore:message_update(delta_time)
    if self:get_status() == define.SCENE_STATUS.SCENE_STATUS_RUNNING then
        utils.latency_call(self.objs_update, self)
        utils.latency_call(AOI.message_update, AOI)
        utils.latency_call(self.update_weather, self, delta_time)
        utils.latency_call(self.OnCopySceneTimer, self, delta_time)
        utils.latency_call(self.growpointenginer.heart_beat, self.growpointenginer, delta_time)
        utils.latency_call(self.log_copy_scene_monsters, self, delta_time)
        utils.latency_call(self.check_need_clean_up, self)
    end
end

function copyscenecore:on_player_enter_scene(obj_id)
    print("on_player_enter_scene obj_id =", obj_id)
    if self.conf then
        local script_id = self:get_param(1)
        self.scriptenginer:call(script_id, "OnPlayerEnter", obj_id)
    end
end

function copyscenecore:on_player_leave_scene(obj_id)
    if self.conf then
        local script_id = self:get_param(1)
        self.scriptenginer:call(script_id, "OnPlayerLeave", obj_id)
    end
end

function copyscenecore:get_type()
    return 1
end

function copyscenecore:delete_obj(obj)
    scenecore.delete_obj(self, obj)
    -- skynet.logi("copyscenecore delete obj id =", obj:get_obj_id())
end

function copyscenecore:set_chiji_flag()
    -- self.chiji_flag = true
end

function copyscenecore:leave(guid,del_obj_flag)
	-- local human = self:get_obj_by_id(obj_id)
    local save_data = copyscenecore.super.leave(self,guid,del_obj_flag)
    if self.chiji_flag then
        return
    end
    return save_data
end

function copyscenecore:get_my_save_data(...)
    if self.chiji_flag then
        return
    end
    return copyscenecore.super.get_my_save_data(self, ...)
end

function copyscenecore:char_shop_buy(who, request)
    if self.chiji_flag then
        local human = self:get_obj_by_id(who)
        human:notify_tips("雪原大作战中，不能商店购买")
        return
    end
    return copyscenecore.super.char_shop_buy(self, who, request)
end

function copyscenecore:player_enter_scene(player_data, agent, teaminfo, guildinfo, is_first_login)
    if self.chiji_flag then
        player_data.equip_list = {}
        player_data.pet_bag_list = {}
        player_data.bank_bag_list = {}
        player_data.pet_bank_list = {}
        player_data.prop_bag_list = {}
        player_data.exterior.rides = {}
    end
    return copyscenecore.super.player_enter_scene(self, player_data, agent, teaminfo, guildinfo, is_first_login)
end


return copyscenecore
