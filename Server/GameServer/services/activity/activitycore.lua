local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mc = require "skynet.multicast"
require "skynet.manager"
local gbk = require "wire_charset"
local packet_def = require "game.packet"
local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local activitycore = class("activitycore")

function activitycore:getinstance()
    if activitycore.instance == nil then
        activitycore.instance = activitycore.new()
    end
    return activitycore.instance
end

function activitycore:init()
    self.open_activitys = {}
    self.delta_time = 100
    self:load_config()
    self._timex = os.date("*t")
    self._timex_accum = 0
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

function activitycore:load_config()
    configenginer:loadmany({"activity_notice", "activity_ruler"})
    self.activity_notice = configenginer:get_config("activity_notice")
    self.activity_ruler = configenginer:get_config("activity_ruler")
end

function activitycore:message_update()
    self._timex_accum = self._timex_accum + self.delta_time * 10
    if self._timex_accum >= 1000 then
        self._timex_accum = 0
        self._timex = os.date("*t")
    end
    for _, activity in pairs(self.activity_notice) do
        self:check_activity(activity)
    end
end

function activitycore:check_activity(activity)
    local is_active = self:is_active(activity)
    local id = activity.id
    if is_active and self.open_activitys[id] == nil then
        self:activity_open(activity)
    end
    if not is_active and self.open_activitys[id] then
        self:activity_close(activity)
    end
end

function activitycore:send_broad_msg(activity)
    local NotifyMsg = activity.slow_broad
    if type(NotifyMsg) == "string" then
        NotifyMsg = string.trim(NotifyMsg)
    end
    if NotifyMsg and NotifyMsg ~= "" and tonumber(NotifyMsg) ~= define.INVAILD_ID and tonumber(NotifyMsg) ~= 0 then
        NotifyMsg = "@*;SrvMsg;SCA:" .. NotifyMsg
        local msg = packet_def.GCChat.new()
        msg.ChatType = define.ENUM_CHAT_TYPE.CHAT_TYPE_SYSTEM
        NotifyMsg = gbk.fromutf8(NotifyMsg)
        msg:set_content(NotifyMsg)
        skynet.send(".world", "lua", "multicast", msg)
    end
end

function activitycore:activity_open(activity)
    local id = activity.id
    local sceneids = self:get_trigger_scenes(activity)
    self.open_activitys[id] = sceneids or {}
    self:send_broad_msg(activity)
    self:send_all_scenes_activity_open(activity)
end

function activitycore:activity_close(activity)
    self:send_all_scenes_activity_close(activity)
    local id = activity.id
    self.open_activitys[id] = nil
end

function activitycore:is_active(activity)
    if activity.time_type == 0 then
        return self:is_active_type_0(activity)
    elseif activity.time_type == 1 then
        return self:is_active_type_1(activity)
    elseif activity.time_type == 2 then
        return self:is_active_type_2(activity)
    elseif activity.time_type == 3 then
        return self:is_active_type_3(activity)
    end
end

function activitycore:is_active_type_0(activity)
    local date = self._timex
    local yday = date.yday
    local ke = (date.hour * 60 + date.min) // 15
    local num = yday * 100 + ke
    return (activity.opt_type == 1 or num == activity.time_start) and num >= activity.time_start and num < activity.time_invalid
end

function activitycore:is_active_type_1(activity)
    local date = self._timex
    local ke = (date.hour * 60 + date.min) // 15
    --print("activitycore:is_active_type_1 id =", activity.id, ";ke =", ke)
    return (activity.opt_type == 1 or ke == activity.time_start) and ke >= activity.time_start and ke < activity.time_invalid
end

function activitycore:is_active_type_2(activity)
    local date = self._timex
    local wday = date.wday - 1
    local ke = (date.hour * 60 + date.min) // 15
    local num = wday * 100 + ke
    return num >= activity.time_start and num < activity.time_invalid
end

function activitycore:is_active_type_3(activity)
    local date = self._timex
    local mday = date.day - 1
    local ke = (date.hour * 60 + date.min) // 15
    local num = mday * 100 + ke
    return num >= activity.time_start and num < activity.time_invalid
end

function activitycore:get_trigger_scenes(activity)
    local ruler = self.activity_ruler[activity.id]
    if activity.ruler == -1 then
        return { activity.sceneid }
    else
        if ruler then
            local sceneids = ruler.sceneids
            if activity.ruler == 0 then
                return sceneids
            else
                return self:get_random_scene(sceneids, activity.ruler)
            end
        end
    end
end

function activitycore:get_random_scene(sceneids, count)
    local scene_with_randoms = {}
    for _, sceneid in ipairs(sceneids) do
        if sceneid ~= define.INVAILD_ID then
            table.insert(scene_with_randoms, { scene = sceneid, random = math.random(100)})
        end
    end
    table.sort(scene_with_randoms, function(s1, s2) return s1.random < s2.random end)
    local ret_scene = {}
    for i, sr in ipairs(scene_with_randoms) do
        if i <= count then
            table.insert(ret_scene, sr.scene)
        end
    end
    return ret_scene
end

function activitycore:send_all_scenes_activity_open(activity)
    local sceneids = self.open_activitys[activity.id]
    for _, scene in ipairs(sceneids) do
        -- 确保延迟加载的场景已创建，否则消息会被静默丢弃
        pcall(skynet.call, ".SceneManager", "lua", "ensure_scene", scene)
        local name = string.format(".SCENE_%d", scene)
        skynet.send(name, "lua", "activity_open", activity)
    end
end

function activitycore:send_all_scenes_activity_close(activity)
    local sceneids = self.open_activitys[activity.id]
    for _, scene in ipairs(sceneids) do
        local name = string.format(".SCENE_%d", scene)
        skynet.send(name, "lua", "activity_close", activity)
    end
end

function activitycore:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("activitycore:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

-- 重载活动配置，关闭所有当前活动，等待定时器按计划时间自然刷新
function activitycore:reload_config()
    skynet.logi("[activitycore] reload_config START")
    -- 1. 关闭所有当前正在运行的活动
    local close_count = 0
    for id, _ in pairs(self.open_activitys) do
        local activity = self.activity_notice[id]
        if activity then
            skynet.logi("[activitycore] reload_config: closing activity id =", id)
            local r, err = xpcall(self.activity_close, debug.traceback, self, activity)
            if not r then
                skynet.logw("[activitycore] reload_config: activity_close error id =", id, ", err =", err)
            end
        else
            -- 活动配置已不存在，直接清空状态
            self.open_activitys[id] = nil
        end
        close_count = close_count + 1
    end
    skynet.logi("[activitycore] reload_config: closed", close_count, "activities")
    -- 2. 清空 open_activitys
    self.open_activitys = {}
    -- 3. 使 configenginer 缓存失效，重新从 sharetable 加载最新配置
    configenginer:invalidate_config("activity_notice")
    configenginer:invalidate_config("activity_ruler")
    self.activity_notice = configenginer:get_config("activity_notice")
    self.activity_ruler = configenginer:get_config("activity_ruler")
    local notice_count = 0
    local ruler_count = 0
    if self.activity_notice then
        for _ in pairs(self.activity_notice) do notice_count = notice_count + 1 end
    end
    if self.activity_ruler then
        for _ in pairs(self.activity_ruler) do ruler_count = ruler_count + 1 end
    end
    skynet.logi("[activitycore] reload_config done, loaded", notice_count, "activities,", ruler_count, "rulers. Timer will check activation naturally.")
    return true, string.format("活动配置已重载(%d条活动), 将按计划时间自然生效", notice_count)
end

-- 重载活动配置，并立即强制检查所有活动使符合条件的活动马上生效
-- 若传入 scriptid，则只关闭并重新激活匹配该 scriptid 的活动
function activitycore:reload_config_now(scriptid)
    skynet.logi("[activitycore] reload_config_now START, scriptid =", scriptid or "all")
    local ok, msg = self:reload_config()
    if not ok then
        return ok, msg
    end

    if scriptid then
        -- 只激活指定 scriptid 的活动
        return self:reload_activity_by_scriptid(scriptid)
    else
        -- 立即执行一次活动检查，让符合条件的活动马上激活
        skynet.logi("[activitycore] reload_config_now: forcing immediate activity check...")
        local r, err = xpcall(self.message_update, debug.traceback, self)
        if not r then
            skynet.logw("[activitycore] reload_config_now: message_update error =", err)
            return false, "活动配置已重载但立即检查时出错: " .. tostring(err)
        end
        local open_count = 0
        for _ in pairs(self.open_activitys) do open_count = open_count + 1 end
        skynet.logi("[activitycore] reload_config_now done,", open_count, "activities now open")
        return true, string.format("活动配置已重载并立即生效, 当前开启活动数: %d", open_count)
    end
end

-- 按 scriptid 刷新单个活动（不重载配置，只关闭并重新检查匹配该 scriptid 的活动）
function activitycore:reload_activity_by_scriptid(scriptid)
    scriptid = tonumber(scriptid)
    skynet.logi("[activitycore] reload_activity_by_scriptid START, scriptid =", scriptid)

    -- 1. 在 activity_notice 中查找匹配 scriptid 的活动
    local target_activities = {}
    for id, activity in pairs(self.activity_notice) do
        if tonumber(activity.scriptid) == scriptid then
            table.insert(target_activities, activity)
        end
    end

    if #target_activities == 0 then
        skynet.logw("[activitycore] reload_activity_by_scriptid: no activity found for scriptid =", scriptid)
        return false, string.format("未找到 scriptid=%d 的活动", scriptid)
    end

    -- 2. 关闭匹配的活动（如果当前正在运行）
    for _, activity in ipairs(target_activities) do
        if self.open_activitys[activity.id] then
            skynet.logi("[activitycore] reload_activity_by_scriptid: closing activity id =", activity.id)
            local r, err = xpcall(self.activity_close, debug.traceback, self, activity)
            if not r then
                skynet.logw("[activitycore] reload_activity_by_scriptid: close error:", err)
            end
        end
    end

    -- 3. 强制开启这些活动（跳过时间检查，直接调用 activity_open）
    for _, activity in ipairs(target_activities) do
        skynet.logi("[activitycore] reload_activity_by_scriptid: force opening activity id =", activity.id)
        local r, err = xpcall(self.activity_open, debug.traceback, self, activity)
        if not r then
            skynet.logw("[activitycore] reload_activity_by_scriptid: open error:", err)
        end
    end

    skynet.logi("[activitycore] reload_activity_by_scriptid DONE, scriptid =", scriptid, ", count =", #target_activities)
    return true, string.format("scriptid=%d 的 %d 个活动已刷新", scriptid, #target_activities)
end

return activitycore