local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shimen_0901 = class("shimen_0901", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
shimen_0901.script_id = 228906
shimen_0901.g_MissionId = 2121
shimen_0901.g_MissionName = "Hạo Nguyệt Châu"
shimen_0901.g_MissionInfo = "#{MTSZSMRW_20220621_28}"
shimen_0901.g_MissionTarget = "#{MTSZSMRW_20220621_29}"
shimen_0901.g_ContinueInfo = "Ngươi hãy tiếp tục nỗ lực a!"
shimen_0901.g_MissionComplete = "Đa tạ."
shimen_0901.g_client_res = 593
shimen_0901.g_Param_ok = 1
shimen_0901.g_Param_sceneid = 2
shimen_0901.g_Param_teamid = 3
shimen_0901.g_Param_killcount = 4
shimen_0901.g_Param_time = 5
shimen_0901.g_CopySceneType = ScriptGlobal.FUBEN_HAOYUEZHOU
shimen_0901.g_LimitMembers = 1
shimen_0901.g_TickTime = 5
shimen_0901.g_LimitTotalHoldTime = 360
shimen_0901.g_LimitTimeSuccess = 500
shimen_0901.g_CloseTick = 6
shimen_0901.g_NoUserTime = 300
shimen_0901.g_DeadTrans = 0
shimen_0901.g_Fuben_X = 29
shimen_0901.g_Fuben_Z = 29
shimen_0901.g_Back_X = 129
shimen_0901.g_Back_Z = 108
shimen_0901.g_TotalNeedKill = 10
function shimen_0901:OnDefaultEvent(selfId, targetId,arg,index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local bDone = self:CheckSubmit(selfId)
        if bDone == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("Nhiệm vụ thất bại, xin hãy từ bỏ rồi nhận lại.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif bDone == 1 then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionComplete)
            self:EndEvent()
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
        end
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("Mục tiêu nhiệm vụ:")
        self:AddText(self.g_MissionTarget)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function shimen_0901:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 10, 0)
    else
        local ret = self:CallScriptFunction(229000, "IsFubenMission", selfId, targetId)
        if ret > 0 then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 10, 0)
        end
    end
end

function shimen_0901:CheckAccept(selfId)
    if self:GetMissionCount(selfId) >= 20 then
        self:BeginEvent(self.script_id)
        self:AddText("Ghi chép nhiệm vụ của ngươi đã đầy.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã tiếp nhận nhiệm vụ này rồi.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    return 1
end

function shimen_0901:OnAccept(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        local saveteamid = self:GetMissionParam(selfId, misIndex, self.g_Param_teamid)
        local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
        if copysceneid then
            self:NewWorld(selfId, copysceneid,sn, self.g_Fuben_X, self.g_Fuben_Z,self.g_client_res)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Điều kiện không phù hợp!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    else
        if self:CheckAccept(selfId) <= 0 then
            return 0
        end
        self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_ok, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
        self:SetMissionByIndex(selfId, misIndex, 6, 10)
        self:MakeCopyScene(selfId)
    end
    self:CallScriptFunction(229000, "SetFubenMissionSucc", selfId, targetId)
end

function shimen_0901:OnAbandon(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    local sceneId = self:GetSceneID()
    local sn = self:LuaFnGetCopySceneData_Sn(copyscene)
    self:DelMission(selfId, self.g_MissionId)
    if sceneId == copyscene then
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId,sn, self.g_Back_X, self.g_Back_Z,592)
    end
end

function shimen_0901:MakeCopyScene(selfId)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local mylevel = self:GetLevel(selfId)
    local isMoreExpFuben = 0
    local iniLevel
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    for i, v in pairs(ScriptGlobal.MENPAI_SHIMEN_MISID) do
        if self:IsHaveMission(selfId, v) then
            local misIndex = self:GetMissionIndexByID(selfId, v)
            local missionType = self:GetMissionParam(selfId, misIndex, 1)
            if missionType == 8 and mylevel >= 40 then
                isMoreExpFuben = 1
            end
        end
    end
    local config = {}
    config.navmapname = "mantuofb.nav"
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = self.g_NoUserTime * 1000
	config.Timer = self.g_TickTime * 1000
    config.params = {}
	config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
	config.params[2] = 0
    config.params[3] = -1
    config.params[4] = 0
    config.params[5] = 0
	config.params[6] = self:GetTeamId(selfId)
	config.params[7] = 0
    for i = 8,31 do
        config.params[i] = 0
    end
    config.params[define.CopyScene_LevelGap] = iniLevel
    config.eventfile = "mantuofb_area.ini"
    if isMoreExpFuben == 0 then
        if mylevel < 10 then
            iniLevel = 10
        elseif mylevel < PlayerMaxLevel then
            iniLevel = math.floor(mylevel / 10) * 10
        else
            iniLevel = PlayerMaxLevel
        end
        config.monsterfile = "mantuofb_monster_" .. iniLevel .. ".ini"
    else
        if mylevel < 40 then
            iniLevel = 40
        elseif mylevel < PlayerMaxLevel then
            iniLevel = math.floor(mylevel / 10) * 10
        else
            iniLevel = PlayerMaxLevel
        end
        config.monsterfile = "mantuofb_20monster_" .. iniLevel .. ".ini"
    end
    config.sn = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    local text
    if bRetSceneID > 0 then
        text = "Tạo phó bản thành công!"
    else
        text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
    end
    self:notify_tips(selfId, text)
end

function shimen_0901:OnContinue(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid) then
        self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function shimen_0901:CheckSubmit(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Param_ok) then
        return 1
    else
        return 0
    end
end

function shimen_0901:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) > 0 then
        self:DelMission(selfId, self.g_MissionId)
        self:CallScriptFunction(229000, "SetFubenMissionSucc", selfId, targetId)
        self:BeginEvent(self.script_id)
        self:AddText("Nhiệm vụ hoàn thành!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function shimen_0901:OnKillObject(selfId, objdataId, objId)
    local sceneType = self:LuaFnGetSceneType()
    if sceneType ~= 1 then
        return
    end
    local fubentype = self:LuaFnGetCopySceneData_Param(0)
    if fubentype ~= self.g_CopySceneType then
        return
    end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        return
    end
    local num = self:LuaFnGetCopyScene_HumanCount()
    local killednumber = self:LuaFnGetCopySceneData_Param(7)
    killednumber = killednumber + 1
    self:LuaFnSetCopySceneData_Param(7, killednumber)
    if killednumber < self.g_TotalNeedKill then
        self:BeginEvent(self.script_id)
        local strText = self:format("Đã giết quái vật: %d/%d", killednumber, self.g_TotalNeedKill)
        self:AddText(strText)
        self:EndEvent()
        for i = 1, num do
            local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:DispatchMissionTips(humanObjId)
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            local killedcount = self:GetMissionParam(humanObjId, misIndex, self.g_Param_killcount)
            killedcount = killedcount + 1
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_killcount, killedcount)
        end
    elseif killednumber >= self.g_TotalNeedKill then
        self:LuaFnSetCopySceneData_Param(4, 1)
        TickCount = self:LuaFnGetCopySceneData_Param(2)
        for i = 1, num do
            local humanObjId = self:LuaFnGetCopyScene_HumanObjId(i)
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            local killedcount = self:GetMissionParam(humanObjId, misIndex, self.g_Param_killcount)
            killedcount = killedcount + 1
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_killcount, killedcount)
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_ok, 1)
            self:SetMissionByIndex(humanObjId, misIndex, self.g_Param_time, TickCount * self.g_TickTime)
            self:BeginEvent(self.script_id)
            self:AddText("Nhiệm vụ hoàn thành, ngươi sẽ được truyền tống đến vị trí lối vào")
            self:EndEvent()
            self:DispatchMissionTips(humanObjId)
            self:DelMission(humanObjId, self.g_MissionId)
        end
    end
end

function shimen_0901:OnEnterZone(selfId, zoneId)
end

function shimen_0901:OnItemChanged(selfId, itemdataId)
end

function shimen_0901:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    local misIndex = self:GetMissionIndexByID(leaderObjId, self.g_MissionId)
    self:SetMissionByIndex(leaderObjId, misIndex, self.g_Param_sceneid, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(leaderObjId, destsceneId,sn, self.g_Fuben_X, self.g_Fuben_Z,self.g_client_res)
end

function shimen_0901:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1,0, self.g_Fuben_X, self.g_Fuben_Z)
end

function shimen_0901:OnHumanDie(selfId, killerId)
    if self.g_DeadTrans == 1 then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local destsceneId = self:GetMissionParam(selfId, misIndex,self.g_Param_sceneid)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_ok, 1)
        local TickCount = self:LuaFnGetCopySceneData_Param(2)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_time, TickCount * self.g_TickTime)
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
        self:NewWorld(selfId, oldsceneId, sn,self.g_Back_X, self.g_Back_Z,592)
    end
end

function shimen_0901:OnCopySceneTimer(nowTime)
    TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        local leaveTickCount = self:LuaFnGetCopySceneData_Param(5)
        leaveTickCount = leaveTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, leaveTickCount)
        if leaveTickCount == self.g_CloseTick then
            local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 0, membercount - 1 do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
                local destsceneId = self:GetMissionParam(mems[i], misIndex, self.g_Param_sceneid)
                local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
                self:NewWorld(mems[i], oldsceneId,sn,self.g_Back_X, self.g_Back_Z,592)
            end
        elseif leaveTickCount < self.g_CloseTick then
            local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            for i = 0, membercount - 1 do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(mems[i]) == 1 and self:LuaFnIsCanDoScriptLogic(mems[i]) == 1 then
                    self:BeginEvent(self.script_id)
                    local strText = self:format("Ngươi sẽ rời khỏi cảnh sau %d giây!",
                        (self.g_CloseTick - leaveTickCount) * self.g_TickTime)
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(mems[i])
                end
            end
        end
    elseif TickCount == self.g_LimitTimeSuccess then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(mems[i]) == 1 and self:LuaFnIsCanDoScriptLogic(mems[i]) == 1 then
                self:BeginEvent(self.script_id)
                self:AddText("Hết thời gian nhiệm vụ, hoàn thành!")
                self:EndEvent()
                self:DispatchMissionTips(mems[i])
            end
            local misIndex = self:GetMissionIndexByID(mems[i], self.g_MissionId)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_ok, 1)
            self:SetMissionByIndex(mems[i], misIndex, self.g_Param_time, TickCount * self.g_TickTime)
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    elseif TickCount == self.g_LimitTotalHoldTime then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:DelMission(mems[i], self.g_MissionId)
            if self:LuaFnIsObjValid(mems[i]) == 1 and self:LuaFnIsCanDoScriptLogic(mems[i]) == 1 then
                self:BeginEvent(self.script_id)
                self:AddText("Nhiệm vụ thất bại, quá thời gian!")
                self:EndEvent()
                self:DispatchMissionTips(mems[i])
            end
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

return shimen_0901
