local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_010 = class("edali_newquest_010", script_base)
edali_newquest_010.script_id = 210280
edali_newquest_010.g_NextScriptId = 210275
edali_newquest_010.g_Position_X = 215
edali_newquest_010.g_Position_Z = 284
edali_newquest_010.g_SceneID = 2
edali_newquest_010.g_AccomplishNPC_Name = "段延庆"
edali_newquest_010.g_MissionId = 1423
edali_newquest_010.g_MissionIdPre = 1408
edali_newquest_010.g_Name = "段延庆"
edali_newquest_010.g_StuffName = "黄公道"
edali_newquest_010.g_QigaiName = "小乞丐"
edali_newquest_010.g_MissionKind = 13
edali_newquest_010.g_MissionLevel = 5
edali_newquest_010.g_IfMissionElite = 0
edali_newquest_010.g_IsMissionOkFail = 0 --变量的第0位
edali_newquest_010.g_MissionName = "Hà Vị Hành Thiện"
edali_newquest_010.g_MissionInfo = "#{XSRW_100111_109}"
edali_newquest_010.g_MissionTarget = "#{XSRW_100111_120}"
edali_newquest_010.g_ContinueInfo = "#{XSRW_100111_119}"
edali_newquest_010.g_MissionComplete = "#{XSRW_100111_121}"
edali_newquest_010.g_SignPost = { x = 199, z = 256, tip = "小乞丐" }
edali_newquest_010.g_Custom = { { id = "得到要赠与小乞丐的物品", num = 1 }, { id = "赠送馒头给小乞丐",
	num = 1 }, { id = "赠送衣服给小乞丐", num = 1 }, { id = "赠送锄头给小乞丐", num = 1 } }
edali_newquest_010.g_MoneyJZBonus = 300
edali_newquest_010.g_ExpBonus = 6000


function edali_newquest_010:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_Name then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_ContinueInfo)
		self:EndEvent()
		local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
	elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_StuffName then
		self:BeginAddItem()
		self:AddItem(40004514, 1)
		self:AddItem(40004515, 1)
		self:AddItem(40004516, 1)
		local ret = self:EndAddItem(selfId)
		if ret then
			self:AddItemListToHuman(selfId)
			self:notify_tips(selfId, "Nhận được vật phẩm muốn tặng cho Tiểu khất cái: 1/1")
			local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
			self:SetMissionByIndex(selfId, misIndex, 1, 1)
			self:BeginEvent(self.script_id)
			self:AddText("#{XSRW_100111_122}")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText("Túi đồ không đủ chỗ trống.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
	elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_QigaiName then
		local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
		if self:GetMissionParam(selfId, misIndex, 0) < 1 then
			if self:GetMissionParam(selfId, misIndex, 2) < 1 then
				self:DelItem(selfId, 40004514)
				self:SetMissionByIndex(selfId, misIndex, 2, 1)
				self:notify_tips(selfId, "Tặng màn thầu cho Tiểu khất cái: 1/1")
			end
			if self:GetMissionParam(selfId, misIndex, 2) > 0 and self:GetMissionParam(selfId, misIndex, 3) < 1 and self:GetMissionParam(selfId, misIndex, 4) < 1 then
				self:BeginEvent(self.script_id)
				self:AddText("#{XSRW_100111_114}")
				self:AddNumText("赠送衣服给小乞丐", 2, 5)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
			if self:GetMissionParam(selfId, misIndex, 2) > 0 and self:GetMissionParam(selfId, misIndex, 3) < 1 and self:GetMissionParam(selfId, misIndex, 4) < 1 then
				self:DelItem(selfId, 40004515)
				self:SetMissionByIndex(selfId, misIndex, 3, 1)
				self:notify_tips(selfId, "Tặng Y phục cho Tiểu khất cái: 1/1")
			end
			if self:GetMissionParam(selfId, misIndex, 2) > 0 and self:GetMissionParam(selfId, misIndex, 3) > 0 and self:GetMissionParam(selfId, misIndex, 4) < 1 then
				self:BeginEvent(self.script_id)
				self:AddText("#{XSRW_100111_116}")
				self:AddNumText("赠送锄头给小乞丐", 2, 6)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
			if self:GetMissionParam(selfId, misIndex, 2) > 0 and self:GetMissionParam(selfId, misIndex, 3) > 0 and self:GetMissionParam(selfId, misIndex, 4) < 1 then
				self:DelItem(selfId, 40004516)
				self:SetMissionByIndex(selfId, misIndex, 4, 1)
				self:notify_tips(selfId, "Tặng cuốc cho Tiểu khất cái: 1/1")
				self:SetMissionByIndex(selfId, misIndex, 0, 1)
			end
		end
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionTarget)
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_010:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	elseif self:GetName(targetId) == self.g_StuffName and self:IsHaveMission(selfId, self.g_MissionId) then
		local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
		if self:GetMissionParam(selfId, misIndex, 1) < 1 then
			caller:AddNumTextWithTarget(self.script_id, "Lĩnh Đoàn Diên Khánh để lại của đồ vật", 2, 3)
		end
	elseif self:GetName(targetId) == self.g_QigaiName and self:IsHaveMission(selfId, self.g_MissionId) then
		local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
		if self:GetMissionParam(selfId, misIndex, 2) < 1 then
			caller:AddNumTextWithTarget(self.script_id, "赠送馒头给小乞丐", 2, 4)
		end
	end
end

function edali_newquest_010:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
	if not ret then
		self:notify_tips(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
	self:notify_tips(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
end

function edali_newquest_010:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_010:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_010:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_010:OnSubmit(selfId, targetId)
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
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Thế nào là hành thiện")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_010:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	else
		return 1
	end
end

function edali_newquest_010:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_010:OnEnterArea(selfId, zoneId)
end

function edali_newquest_010:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_010
