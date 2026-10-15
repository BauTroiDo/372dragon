local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_003 = class("edali_newquest_003", script_base)
edali_newquest_003.script_id = 210256
edali_newquest_003.g_NextScriptId = 210257
edali_newquest_003.g_Position_X = 238
edali_newquest_003.g_Position_Z = 171
edali_newquest_003.g_SceneID = 2
edali_newquest_003.g_AccomplishNPC_Name = "黄公道"
edali_newquest_003.g_MissionId = 1402
edali_newquest_003.g_MissionIdPre = 1401
edali_newquest_003.g_Name = "蒲良"
edali_newquest_003.g_MissionKind = 13
edali_newquest_003.g_MissionLevel = 1
edali_newquest_003.g_MinMissionLevel = 1
edali_newquest_003.g_IfMissionElite = 0
edali_newquest_003.g_MissionName = "Trang bị phòng ngự đầu tiên"
edali_newquest_003.g_MissionTarget = "#{XSRW_100111_56}"
edali_newquest_003.g_MissionInfo = "#{XSRW_100111_6}"
edali_newquest_003.g_ContinueInfo = "#{XSRW_100111_68}"
edali_newquest_003.g_MissionComplete = "#{XSRW_100111_7}"
edali_newquest_003.g_MoneyJZBonus = 1
edali_newquest_003.g_ExpBonus = 200
edali_newquest_003.g_SignPost = { x = 238, z = 171, tip = "黄公道" }
edali_newquest_003.g_RadioItemBonus = {}
edali_newquest_003.g_ItemBonus = { { id = 10113000, num = 1 } }
edali_newquest_003.g_Custom = { { id = "已找到黄公道", num = 1 } }
edali_newquest_003.g_IsMissionOkFail = 0

function edali_newquest_003:OnDefaultEvent(selfId, targetId, arg, index)
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
		for i, item in pairs(self.g_ItemBonus) do
			self:AddRadioItemBonus(item["id"], item["num"])
		end
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_003:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) or not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) ~= self.g_AccomplishNPC_Name and not self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_003:OnAccept(selfId)
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

function edali_newquest_003:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_003:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_003:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i, item in pairs(self.g_ItemBonus) do
		self:AddRadioItemBonus(item["id"], item["num"])
	end
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_003:OnSubmit(selfId, targetId)
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
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Món phòng cụ đầu tiên")
			self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
		end
	end
end

function edali_newquest_003:CheckAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 1
	else
		return 0
	end
end

function edali_newquest_003:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_003:OnEnterArea(selfId, zoneId)
end

function edali_newquest_003:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_003
