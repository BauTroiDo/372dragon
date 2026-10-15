local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_005 = class("edali_newquest_005", script_base)
edali_newquest_005.script_id = 210258
edali_newquest_005.g_NextScriptId = 210263
edali_newquest_005.g_Position_X = 160
edali_newquest_005.g_Position_Z = 156
edali_newquest_005.g_SceneID = 2
edali_newquest_005.g_AccomplishNPC_Name = "赵天师"
edali_newquest_005.g_MissionId = 1404
edali_newquest_005.g_MissionIdPre = 1403
edali_newquest_005.g_Name = "黄公道"
edali_newquest_005.g_MissionKind = 13
edali_newquest_005.g_MissionLevel = 3
edali_newquest_005.g_MinMissionLevel = 3
edali_newquest_005.g_IfMissionElite = 0
edali_newquest_005.g_MissionName = "Hồi thăm Thiên Sư"
edali_newquest_005.g_MissionTarget = "#{XSRW_100111_57}"
edali_newquest_005.g_MissionInfo = "#{XSRW_100111_10}"
edali_newquest_005.g_ContinueInfo = "#{XSRW_100111_69}"
edali_newquest_005.g_MissionComplete = "#{XSRW_100111_11}"
edali_newquest_005.g_MoneyJZBonus = 30
edali_newquest_005.g_ExpBonus = 1200
edali_newquest_005.g_SignPost = {x = 160, z = 156, tip = "赵天师"}
edali_newquest_005.g_RadioItemBonus = {}
edali_newquest_005.g_ItemBonus = {}
edali_newquest_005.g_Custom = {{ id = "已找到赵天师", num = 1 }}
edali_newquest_005.g_IsMissionOkFail = 0

function edali_newquest_005:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) or not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_AccomplishNPC_Name then
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

function edali_newquest_005:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) or not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) ~= self.g_AccomplishNPC_Name and not self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_005:OnAccept(selfId)
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
	self:SetMissionByIndex(selfId, misIndex, 0, 1)
	self:SetMissionByIndex(selfId, misIndex, 1, 1)
end

function edali_newquest_005:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_005:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_005:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_005:OnSubmit(selfId, targetId)
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
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Hồi phỏng Thiên Sư")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_005:CheckAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionIdPre) and self:GetLevel(selfId) >= self.g_MissionLevel then
		return 1
	else
		return 0
	end
end

function edali_newquest_005:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_005:OnEnterArea(selfId, zoneId)
end

function edali_newquest_005:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_005
