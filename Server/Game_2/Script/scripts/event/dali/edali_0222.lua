local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local edali_0222 = class("edali_0222", script_base)
edali_0222.script_id = 210222
edali_0222.g_CopySceneName = "后花园"
edali_0222.g_CopySceneMap = "newbie_2.nav"
edali_0222.g_CopySceneMonster = "newbie_2_monster.ini"
edali_0222.g_MissionId = 702
edali_0222.g_MissionIdPre = 701
edali_0222.g_Name = "劫匪"
edali_0222.g_IfMissionElite = 1
edali_0222.g_MissionKind = 13
edali_0222.g_MissionLevel = 7
edali_0222.g_MissionName = "后花园"
edali_0222.g_MissionInfo = "#{event_dali_0032}"
edali_0222.g_MissionTarget = "Tiến vào hậu hoa viên."
edali_0222.g_ContinueInfo = "Tiến vào hậu hoa viên"
edali_0222.g_MissionComplete = "  Nhiệm vụ hoàn thành"
edali_0222.g_SignPost = {["x"] = 275, ["z"] = 50, ["tip"] = "黄眉僧"}
edali_0222.g_PetDataID = 558
edali_0222.g_Param_huan = 0
edali_0222.g_IsMissionOkFail = 1
edali_0222.g_Param_sceneid = 2
edali_0222.g_Param_guid = 3
edali_0222.g_Param_killcount = 4
edali_0222.g_Param_time = 5
edali_0222.g_MoneyBonus = 2
edali_0222.g_CopySceneType = ScriptGlobal.FUBEN_MURENXIANG_7
edali_0222.g_LimitMembers = 1
edali_0222.g_TickTime = 5
edali_0222.g_LimitTotalHoldTime = 360
edali_0222.g_LimitTimeSuccess = 500
edali_0222.g_CloseTick = 6
edali_0222.g_NoUserTime = 300
edali_0222.g_DeadTrans = 0
edali_0222.g_Fuben_X = 44
edali_0222.g_Fuben_Z = 54
edali_0222.g_Back_X = 275
edali_0222.g_Back_Z = 50
edali_0222.g_TotalNeedKill = 0
edali_0222.g_MissionIdPre = 701
function edali_0222:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local bDone = self:CheckSubmit(selfId)
        if bDone == 0 then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText("Ngươi đã chuẩn bị xong chưa!")
            self:AddMoneyBonus(self.g_MoneyBonus)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
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
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function edali_0222:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, -1)
    elseif self:CheckAccept(selfId) > 0 then
        caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, -1)
    end
end

function edali_0222:CheckAccept(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionIdPre) then return 0 end
    local petcount = self:LuaFnGetPetCount(selfId)
    for i = 1, petcount do
        local petdataid = self:LuaFnGetPet_DataID(selfId, i)
        if petdataid == self.g_PetDataID then return 0 end
    end
    return 1
end

function edali_0222:OnAccept(selfId)
    local selfguid = self:LuaFnGetGUID(selfId)
    if (self:IsHaveMission(selfId, self.g_MissionId)) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local copysceneid = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
        local saveguid = self:GetMissionParam(selfId, misIndex, self.g_Param_guid)
        if copysceneid >= 0 and selfguid == saveguid then
            local sn = self:LuaFnGetCopySceneData_Sn(copysceneid)
            if self:IsCanEnterCopyScene(copysceneid, self:GetHumanGUID(selfId)) then
                self:NewWorld(selfId, copysceneid, sn, self.g_Fuben_X, self.g_Fuben_Z)
            else
                self:NotifyFailTips(selfId,"Phó bản đã đóng, xin hãy từ bỏ nhiệm vụ này rồi nhận lại")
            end
        else
            self:NotifyFailTips(selfId, "Xin hãy nhận lại nhiệm vụ này.")
        end
    else
        if self:CheckAccept(selfId) <= 0 then return 0 end
        self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_sceneid, -1)
        self:SetMissionByIndex(selfId, misIndex, self.g_Param_guid, selfguid)
        self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Hậu Hoa Viên", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, 2,
                                self.g_SignPost["x"], self.g_SignPost["z"],
                                self.g_SignPost["tip"])
        self:MakeCopyScene(selfId, 0)
    end
end

function edali_0222:OnAbandon(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local copyscene = self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid)
    self:DelMission(selfId, self.g_MissionId)
    local sceneId = self:get_scene_id()
    if sceneId == copyscene then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã kết thúc cuộc thám hiểm Hậu Hoa Viên của mình, hãy trở về Đại Lý thành!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
    end
end

function edali_0222:MakeCopyScene(selfId, nearmembercount)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = self.g_CopySceneMap
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = self.g_NoUserTime*1000
	config.Timer = self.g_TickTime * 1000
	config.params = {}
    config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
    config.params[2] = 0
    config.params[2] = -1
    config.params[4] = 0
    config.params[5] = 0
    config.params[6] = leaderguid
    config.params[7] = 0
    config.eventfile = "newbie_2_area.ini"
    config.monsterfile = self.g_CopySceneMonster
	config.sn 		 = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        self:DelMission(selfId, self.g_MissionId)
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function edali_0222:OnContinue(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Param_sceneid) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionComplete)
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function edali_0222:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) >= 1 then
        return 1
    else
        return 0
    end
end

function edali_0222:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) > 0 then
        local money = self.g_MoneyBonus
        self:AddMoneyJZ(selfId, money)
        self:BeginEvent(self.script_id)
        self:AddText("Nhiệm vụ hoàn thành")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:DelMission(selfId, self.g_MissionId)
    end
end

function edali_0222:OnKillObject(selfId, objdataId, objId) end

function edali_0222:OnEnterZone(selfId, zoneId) end

function edali_0222:OnItemChanged(selfId, itemdataId) end

function edali_0222:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if self:LuaFnIsCanDoScriptLogic(leaderObjId) then
        if self:IsHaveMission(leaderObjId, self.g_MissionId) then
            local misIndex = self:GetMissionIndexByID(leaderObjId, self.g_MissionId)
            local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
            self:SetMissionByIndex(leaderObjId, misIndex, self.g_Param_sceneid, destsceneId)
            self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X,  self.g_Fuben_Z)
        else
            self:NotifyFailTips(leaderObjId, "Ngươi hiện tại chưa tiếp nhiệm vụ này")
        end
    end
end

function edali_0222:OnPlayerEnter(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        self:NotifyFailTips(selfId, "Ngươi hiện tại chưa tiếp nhiệm vụ này, hãy trở về Đại Lý thành")
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        self:NewWorld(selfId, oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
        return
    end
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, self.g_Fuben_X,self.g_Fuben_Z)
end

function edali_0222:OnHumanDie(selfId, killerId) end

function edali_0222:OnCopySceneTimer(nowTime)
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
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
            for i = 1, membercount do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                self:NewWorld(mems[i], oldsceneId, nil, self.g_Back_X, self.g_Back_Z)
            end
        elseif leaveTickCount < self.g_CloseTick then
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            local mems = {}
            local strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!",(self.g_CloseTick - leaveTickCount) * self.g_TickTime)
            for i = 1, membercount do
                mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
                self:BeginEvent(self.script_id)
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(mems[i])
            end
        end
    elseif TickCount == self.g_LimitTotalHoldTime then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local mems = {}
        for i = 1, membercount do
            mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
            self:DelMission(mems[i], self.g_MissionId)
            self:BeginEvent(self.script_id)
            self:AddText("Nhiệm vụ thất bại, quá thời gian!")
            self:EndEvent()
            self:DispatchMissionTips(mems[i])
        end
        self:LuaFnSetCopySceneData_Param(4, 1)
    end
end

function edali_0222:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return edali_0222
