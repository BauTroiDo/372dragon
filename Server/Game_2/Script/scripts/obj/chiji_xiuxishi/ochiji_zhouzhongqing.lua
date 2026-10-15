local skynet = require "skynet"
local class = require "class"
local define = require "define"
local utils = require "utils"
local script_base = require "script_base"
local ochiji_zhouzhongqing = class("ochiji_zhouzhongqing", script_base)
ochiji_zhouzhongqing.script_id = 3000008
ochiji_zhouzhongqing.g_eventList = { }
ochiji_zhouzhongqing.begin_users_count = 2
ochiji_zhouzhongqing.g_CopySceneCloseTime = 3000
ochiji_zhouzhongqing.g_TickTime = 5
ochiji_zhouzhongqing.poss = {
    [229] = {
        {x = 45, y = 41}, {x = 39, y = 46}, {x = 59, y = 47}, {x = 98, y = 73}, {x = 132, y = 72}, {x = 132, y = 53}, {x = 142, y = 21}, {x = 158, y = 28}, {x = 187, y = 47}, {x = 202, y = 61},
        {x = 48, y = 96}, {x = 69, y = 102}, {x = 98, y = 91}, {x = 154, y = 96}, {x = 123, y = 110}, {x = 162, y = 99}, {x = 192, y = 112}, {x = 199, y = 130}, {x = 217, y = 131}, {x = 232, y = 144},
        {x = 37, y = 219}, {x = 34, y = 190}, {x = 107, y = 219}, {x = 139, y = 160}, {x = 171, y = 191}, {x = 196, y = 220}, {x = 215, y = 154}, {x = 223, y = 209}, {x = 129, y = 154}, {x = 235, y = 223},
    }
}
function ochiji_zhouzhongqing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{HSLJ_190919_09}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ochiji_zhouzhongqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ochiji_zhouzhongqing:OnEventRequest(selfId, targetId, arg, index)
end

function ochiji_zhouzhongqing:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function ochiji_zhouzhongqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ochiji_zhouzhongqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ochiji_zhouzhongqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ochiji_zhouzhongqing:OnDie(selfId, killerId)
end

function ochiji_zhouzhongqing:OnSceneTimer()
    local human_count = self:LuaFnGetCopyScene_HumanCount()
    if human_count >= self.begin_users_count then
        local msg = "Đủ người, Đại chiến tuyết nguyên mở ngay!"
        for i = 1, human_count do
            local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:notify_tips(playerId, msg)
        end
        self:BeginGame()
    else
        local msg = string.format("Đăng ký Đại chiến tuyết nguyên: hiện %d, cần %d", human_count, self.begin_users_count)
        for i = 1, human_count do
            local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:notify_tips(playerId, msg)
        end
    end
end

function ochiji_zhouzhongqing:BeginGame()
    local dest_scene_id, sn = self:CreateGameScene()
    local human_count = self:LuaFnGetCopyScene_HumanCount()
    local array = self.poss[229]
    array = utils.random_array(array)
    local poss = array
    for i = 1, human_count do
        local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
        local pos = table.remove(poss, 1)
        self:NewWorld(playerId, dest_scene_id, sn, pos.x, pos.y)
    end
end

function ochiji_zhouzhongqing:CreateGameScene()
	local config = {}
	config.navmapname = "luoyang.nav"
	config.client_res = 229
	config.teamleader = define.INVAILD_ID
	config.NoUserCloseTime = self.g_CopySceneCloseTime
	config.PvpRule = 9
	config.Timer = self.g_TickTime * 1000
	config.params = {}
	config.params[0] = define.INVAILD_ID
	config.params[1] = 3000009
	config.params[2] = 0
	config.params[3] = 0
	config.params[4] = 0
	config.params[5] = 0
	config.params[6] = 0
	config.params[7] = 0
	config.sn 		 = self:LuaFnGenCopySceneSN()
    config.chiji_flag = true
	local CopySceneID = self:LuaFnCreateCopyScene(config)				-- 初始化完成后调用创建副本函数
    return CopySceneID, config.sn
end

return ochiji_zhouzhongqing
