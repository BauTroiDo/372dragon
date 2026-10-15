local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_013 = class("edali_newquest_013", script_base)
edali_newquest_013.script_id = 210275
edali_newquest_013.g_NextScriptId = 210276
edali_newquest_013.g_Position_X=160
edali_newquest_013.g_Position_Z=156
edali_newquest_013.g_SceneID=2
edali_newquest_013.g_AccomplishNPC_Name="赵天师"
edali_newquest_013.g_MissionId = 1412
edali_newquest_013.g_MissionIdPre = 1423
edali_newquest_013.g_Name	="段延庆"
edali_newquest_013.g_MissionKind = 13
edali_newquest_013.g_MissionLevel = 6
edali_newquest_013.g_MinMissionLevel = 6
edali_newquest_013.g_IfMissionElite = 0
edali_newquest_013.g_MissionName="Tái Phỏng Thiên Sư"
edali_newquest_013.g_MissionTarget="#{XSRW_100111_60}"
edali_newquest_013.g_MissionInfo="#{XSRW_100111_28}"
edali_newquest_013.g_ContinueInfo ="#{XSRW_100111_72}"
edali_newquest_013.g_MissionComplete="#{XSRW_100111_29}"
edali_newquest_013.g_SignPost = {x = 160, z = 156, tip = "赵天师"}
edali_newquest_013.g_MoneyJZBonus=30
edali_newquest_013.g_ExpBonus = 3200
edali_newquest_013.g_RadioItemBonus={}
edali_newquest_013.g_ItemBonus={}
edali_newquest_013.g_Custom = { {id="已找到赵天师",num=1} }
edali_newquest_013.g_IsMissionOkFail = 0		--变量的第0位


function edali_newquest_013:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_ContinueInfo)
		self:EndEvent()
		local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionTarget)
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_013:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId,self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId,self.g_MissionId) and self:CheckAccept(selfId) > 0 and self:GetLevel(selfId) >= self.g_MissionLevel then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_013:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
	if not ret then
		self:notify_tips(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
	self:notify_tips(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
	local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
	self:SetMissionByIndex(selfId,misIndex,0,1)
	self:SetMissionByIndex(selfId,misIndex,1,1)
end

function edali_newquest_013:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_013:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_013:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_013:OnSubmit(selfId, targetId)
	if not self:IsHaveMission(selfId, self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	if (self.g_MoneyJZBonus > 0) then
		self:AddMoneyJZ(selfId, self.g_MoneyJZBonus)
	end
	if (self.g_ExpBonus > 0) then
		self:LuaFnAddExp(selfId, self.g_ExpBonus)
	end
	local ret = self:DelMission(selfId, self.g_MissionId)
	if ret then
		self:MissionCom(selfId, self.g_MissionId)	
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Tái phỏng Thiên Sư")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_013:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return 0
	else
		return 1
	end
end

function edali_newquest_013:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_013:OnEnterArea(selfId, zoneId)
end

function edali_newquest_013:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_013
