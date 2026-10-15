local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_007 = class("edali_newquest_007", script_base)
edali_newquest_007.script_id = 210259
edali_newquest_007.g_NextScriptId = 210273
edali_newquest_007.g_Position_X = 103
edali_newquest_007.g_Position_Z = 133
edali_newquest_007.g_SceneID = 2
edali_newquest_007.g_AccomplishNPC_Name = "卢三七"
edali_newquest_007.g_MissionId = 1406
edali_newquest_007.g_MissionIdPre = 1405
edali_newquest_007.g_Name = "钱龙"
edali_newquest_007.g_MissionKind = 13
edali_newquest_007.g_MissionLevel = 4
edali_newquest_007.g_MinMissionLevel = 4
edali_newquest_007.g_IfMissionElite = 0
edali_newquest_007.g_MissionName = "Linh Đan Diệu Dược"
edali_newquest_007.g_MissionTarget = "#{XSRW_100111_58}"
edali_newquest_007.g_MissionInfo = "#{XSRW_100111_16}"
edali_newquest_007.g_ContinueInfo = "#{XSRW_100111_70}"
edali_newquest_007.g_MissionComplete = "#{XSRW_100111_17}"
edali_newquest_007.g_MoneyJZBonus = 30
edali_newquest_007.g_ExpBonus = 1600
edali_newquest_007.g_SignPost = { x = 103, z = 133, tip = "卢三七" }
edali_newquest_007.g_RadioItemBonus = {}
edali_newquest_007.g_ItemBonus = { { id = 30001001, num = 5 } }
edali_newquest_007.g_Custom = { { id = "已找到卢三七", num = 1 } }
edali_newquest_007.g_IsMissionOkFail = 0

function edali_newquest_007:OnDefaultEvent(selfId, targetId, arg, index)
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
		for i, item in pairs(self.g_ItemBonus) do
			self:AddRadioItemBonus(item["id"], item["num"])
		end
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_007:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_007:OnAccept(selfId)
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

function edali_newquest_007:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_007:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_007:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i, item in pairs(self.g_ItemBonus) do
		self:AddRadioItemBonus(item["id"], item["num"])
	end
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_007:OnSubmit(selfId, targetId)
	if not self:IsHaveMission(selfId, self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	self:BeginAddItem()
	for i, item in pairs(self.g_ItemBonus) do
		self:AddItem(item["id"], item["num"])
	end
	local ret = self:EndAddItem(selfId)
	if ret then
        if not self:AddItemListToHuman(selfId) then return end
		if (self.g_MoneyJZBonus > 0) then
			self:AddMoneyJZ(selfId, self.g_MoneyJZBonus)
		end
		if (self.g_ExpBonus > 0) then
			self:LuaFnAddExp(selfId, self.g_ExpBonus)
		end
		ret = self:DelMission(selfId, self.g_MissionId)
		if ret then
			self:MissionCom(selfId, self.g_MissionId)
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Linh đan diệu dược")
			self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
		end
	end
end

function edali_newquest_007:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	else
		return 1
	end
end

function edali_newquest_007:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_007:OnEnterArea(selfId, zoneId)
end

function edali_newquest_007:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_007
