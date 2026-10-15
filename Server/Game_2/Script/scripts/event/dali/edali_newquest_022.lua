local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_022 = class("edali_newquest_022", script_base)
edali_newquest_022.g_ScriptId = 210268
edali_newquest_022.g_NextScriptId = 210279
edali_newquest_022.g_Position_X=160
edali_newquest_022.g_Position_Z=157
edali_newquest_022.g_SceneID=2
edali_newquest_022.g_AccomplishNPC_Name="赵天师"
edali_newquest_022.g_MissionId = 1421
edali_newquest_022.g_MissionIdPer = 0
edali_newquest_022.g_Name	="赵天师"
edali_newquest_022.g_MissionKind = 13
edali_newquest_022.g_MissionLevel = 10
edali_newquest_022.g_IfMissionElite = 0
edali_newquest_022.g_MissionName="Thập Đại Môn phái"
edali_newquest_022.g_MissionInfo="#{XSRW_100111_48}" --任务描述
edali_newquest_022.g_MissionTarget="#{XSRW_100111_97}"
edali_newquest_022.g_ContinueInfo="#{XSRW_100111_98}"
edali_newquest_022.g_MissionComplete="#{XSRW_100111_49}"
edali_newquest_022.g_ItemBonus={}
edali_newquest_022.g_IsMissionOkFail = 0		--变量的第0位
edali_newquest_022.g_Custom	= { {id="加入门派",num=1} }--变量的第1位

function edali_newquest_022:OnDefaultEvent(selfId, targetId, arg, index)
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

function edali_newquest_022:CheckMenPai(selfId)
	if self:IsHaveMission(selfId,self.g_MissionId) then
		if self:GetMenPai(selfId) ~= 9 then
			local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
			self:SetMissionByIndex(selfId,misIndex,0,1)
			self:SetMissionByIndex(selfId,misIndex,1,1)
			self:notify_tips(selfId,"已加入门派")
		end
	end
end

function edali_newquest_022:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId, self.g_MissionId) and self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_022:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
	if not ret then
		self:notify_tips(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
	self:notify_tips(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
	if self:GetMenPai(selfId) ~= 9 then
		local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
		self:SetMissionByIndex(selfId,misIndex,0,1)
		self:SetMissionByIndex(selfId,misIndex,1,1)
	end
end

function edali_newquest_022:CheckSubmit(selfId)
	local nMenPai = self:GetMenPai(selfId)
	if nMenPai == 9 then
		return 0
	end
	return 1
end

function edali_newquest_022:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_022:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_022:OnSubmit(selfId, targetId)
	if not self:IsHaveMission(selfId, self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	local ret = self:DelMission(selfId, self.g_MissionId)
	if ret then
		self:MissionCom(selfId, self.g_MissionId)
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Gia nhập môn phái")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_022:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionId) and self:GetLevel(selfId) >= 10 then
		return 1
	else
		return 0
	end
end

function edali_newquest_022:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_022:OnEnterArea(selfId, zoneId)
end

function edali_newquest_022:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_022
