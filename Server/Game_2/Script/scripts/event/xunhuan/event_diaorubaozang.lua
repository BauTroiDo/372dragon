local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local event_diaorubaozang = class("event_diaorubaozang", script_base)
event_diaorubaozang.script_id = 229021
event_diaorubaozang.g_CopySceneName = "宝藏"
event_diaorubaozang.g_client_res = 110
event_diaorubaozang.g_CopySceneGrowPointData = "muxue_growpoint.txt"
event_diaorubaozang.g_CopySceneGrowSetUp = "muxue_growpointsetup.txt"
event_diaorubaozang.g_MissionId = 702
event_diaorubaozang.g_MissionIdPre = 701
event_diaorubaozang.g_IfMissionElite = 1
event_diaorubaozang.g_MissionKind = 13
event_diaorubaozang.g_MissionLevel = 7
event_diaorubaozang.g_MissionName = ""
event_diaorubaozang.g_MissionInfo = ""
event_diaorubaozang.g_MissionTarget = ""
event_diaorubaozang.g_ContinueInfo = ""
event_diaorubaozang.g_MissionComplete = ""
event_diaorubaozang.g_MoneyBonus = 1
event_diaorubaozang.g_Param_huan = 0
event_diaorubaozang.g_Param_ok = 1
event_diaorubaozang.g_Param_sceneid = 2
event_diaorubaozang.g_Param_guid = 3
event_diaorubaozang.g_Param_killcount = 4
event_diaorubaozang.g_Param_time = 5
event_diaorubaozang.g_CopySceneType = ScriptGlobal.FUBEN_BAOZANG
event_diaorubaozang.g_LimitMembers = 1
event_diaorubaozang.g_TickTime = 5
event_diaorubaozang.g_LimitTotalHoldTime = 36000
event_diaorubaozang.g_LimitTimeSuccess = 50000
event_diaorubaozang.g_CloseTick = 210
event_diaorubaozang.g_NoUserTime = 300
event_diaorubaozang.g_DeadTrans = 0
event_diaorubaozang.g_Fuben_X = 23
event_diaorubaozang.g_Fuben_Z = 23
event_diaorubaozang.g_Back_X = 160
event_diaorubaozang.g_Back_Z = 150
event_diaorubaozang.g_TotalNeedKill = 1000
event_diaorubaozang.g_MissionIdPre = 701
event_diaorubaozang.g_CopySceneTotalTime = 6000

function event_diaorubaozang:OnDefaultEvent(selfId, targetId) end

function event_diaorubaozang:OnEnumerate(caller, selfId, targetId, arg, index) end

function event_diaorubaozang:CheckTeamLeader(selfId) end

function event_diaorubaozang:CheckAccept(selfId) return 1 end

function event_diaorubaozang:OnAccept(selfId)
    self:MakeCopyScene(selfId, 0)
end

function event_diaorubaozang:OnAbandon(selfId) end

function event_diaorubaozang:MakeCopyScene(selfId)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "muxue.nav"
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
	config.NoUserCloseTime = self.g_NoUserTime*1000
    config.Timer = self.g_TickTime*1000
	config.params = {}
	config.params[0] = self.g_CopySceneType
	config.params[1] = self.script_id
	config.params[2] = 0
    config.params[3] = -1
	config.params[4] = 0
    config.params[5] = 0
    config.params[6] = leaderguid
    config.params[7] = 0
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    local playerLevel = self:GetLevel(selfId)
    if playerLevel < 10 then
        iniLevel = 10
    elseif playerLevel < PlayerMaxLevel then
        iniLevel = math.floor(playerLevel / 10) * 10
    else
        iniLevel = PlayerMaxLevel
    end
    config.monsterfile = "muxue_monster_" .. tostring(iniLevel) .. ".ini"
    config.params[define.CopyScene_LevelGap] = playerLevel - iniLevel
    config.eventfile = "muxue_area.ini"
    config.patrolpoint = "muxue_patrolpoint.ini"
    config.growpointdata = self.g_CopySceneGrowPointData
    config.growpointsetup = self.g_CopySceneGrowSetUp
    config.sn = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Phó bản tạo thất bại!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_diaorubaozang:OnContinue(selfId, targetId) end

function event_diaorubaozang:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
end

function event_diaorubaozang:OnSubmit(selfId, targetId, selectRadioId) end

function event_diaorubaozang:OnKillObject(selfId, objdataId, objId) end

function event_diaorubaozang:OnCopySceneReady(destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
end

function event_diaorubaozang:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, 2, self.g_Fuben_X, self.g_Fuben_Z)
end

function event_diaorubaozang:OnHumanDie(selfId)
    if self.g_DeadTrans == 1 then
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function event_diaorubaozang:OnCopySceneTimer()
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
    leaveTickCount = leaveTickCount + 1
    self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
    if leaveTickCount == self.g_CloseTick then
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:NewWorld(mems[i], oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
        end
    elseif leaveTickCount > self.g_CloseTick - 4 then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:BeginEvent(self.script_id)
            local strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!", (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(mems[i])
        end
    elseif TickCount == self.g_CopySceneTotalTime then
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

return event_diaorubaozang
