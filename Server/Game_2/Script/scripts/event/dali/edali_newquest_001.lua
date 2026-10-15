local class = require "class"
local script_base = require "script_base"
local define = require "define"
local edali_newquest_001 = class("edali_newquest_001", script_base)
edali_newquest_001.script_id = 210262
edali_newquest_001.g_NextScriptId = 210200
edali_newquest_001.g_Position_X = 160
edali_newquest_001.g_Position_Z = 156
edali_newquest_001.g_SceneID = 2
edali_newquest_001.g_AccomplishNPC_Name = "赵天师"
edali_newquest_001.g_MissionId = 1400
edali_newquest_001.g_MissionIdPre = 0
edali_newquest_001.g_Name	="赵天师"
edali_newquest_001.g_MissionKind = 13
edali_newquest_001.g_MissionLevel = 1
edali_newquest_001.g_IfMissionElite = 0
edali_newquest_001.g_MissionName = "Sơ nhập giang hồ"
edali_newquest_001.g_MissionInfo = ""
edali_newquest_001.g_MissionTarget = "#{XSRW_100111_1}"
edali_newquest_001.g_ContinueInfo = ""
edali_newquest_001.g_MissionComplete = "#{XSRW_100111_2}"
edali_newquest_001.g_MoneyJZBonus = 1
edali_newquest_001.g_ExpBonus = 200
edali_newquest_001.g_SignPost = {x = 160, z = 156, tip = "赵天师"}
edali_newquest_001.g_Custom	= { {id="已找到赵天师",num=1} }
edali_newquest_001.g_IsMissionOkFail = 0

function edali_newquest_001:OnDefaultEvent(selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionComplete)
		self:EndEvent()
	    local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId,targetId,self.script_id,self.g_MissionId,bDone)
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionTarget)
		self:EndEvent()
		self:DispatchMissionInfo(selfId,targetId,self.script_id,self.g_MissionId)
	end
end
function edali_newquest_001:OnEnumerate(caller,selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,2,1)
	else
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
end
function edali_newquest_001:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId,self.g_MissionId,self.script_id,1,0,0)
	if not ret then
		self:notify_tips(selfId,"#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
    self:notify_tips(selfId,"Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
	local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
	self:SetMissionByIndex(selfId,misIndex,0,1)
	self:SetMissionByIndex(selfId,misIndex,1,1)
end
function edali_newquest_001:CheckSubmit(selfId)
    local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
    local param = self:GetMissionParam(selfId,misIndex,0)
    if param < 1 then
        return 0
    end
	return 1
end
function edali_newquest_001:OnAbandon(selfId)
	self:DelMission(selfId,self.g_MissionId)
end
function edali_newquest_001:OnContinue(selfId,targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId,targetId,self.script_id,self.g_MissionId)
end
function edali_newquest_001:OnSubmit(selfId,targetId)
	if not self:IsHaveMission(selfId,self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	if (self.g_ExpBonus > 0) then
		self:LuaFnAddExp(selfId,self.g_ExpBonus )
	end
    self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId,targetId)
	self:DelMission(selfId,self.g_MissionId)
	self:MissionCom(selfId,self.g_MissionId)
end
function edali_newquest_001:CheckAccept(selfId)
	if self:GetLevel(selfId) >= 1 then
		return 1
	else
		return 0
	end
end
function edali_newquest_001:OnKillObject(selfId,objdataId,objId)
end
function edali_newquest_001:OnEnterArea(selfId,zoneId)
end
function edali_newquest_001:OnItemChanged(selfId,itemdataId)
end

return edali_newquest_001