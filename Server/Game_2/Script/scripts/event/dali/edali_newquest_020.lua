local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_020 = class("edali_newquest_020", script_base)
edali_newquest_020.script_id = 210267
edali_newquest_020.g_NextScriptId = 210269
edali_newquest_020.g_Position_X = 160
edali_newquest_020.g_Position_Z = 158
edali_newquest_020.g_SceneID = 2
edali_newquest_020.g_AccomplishNPC_Name = "赵天师"
edali_newquest_020.g_MissionId = 1419
edali_newquest_020.g_MissionIdPre = 1418
edali_newquest_020.g_Name = "钱龙"
edali_newquest_020.g_MissionKind = 13
edali_newquest_020.g_MissionLevel = 9
edali_newquest_020.g_IfMissionElite = 0
edali_newquest_020.g_IsMissionOkFail = 0 --变量的第0位
edali_newquest_020.g_Custom = { { id = "已连续答对钱龙的五个问题", num = 1 } }
edali_newquest_020.g_MissionName = "Giang Hồ Vấn Đáp"
edali_newquest_020.g_MissionInfo = "#{XSRW_100111_43}"
edali_newquest_020.g_MissionTarget = "#{XSRW_100111_92}"
edali_newquest_020.g_ContinueInfo = "#{XSRW_100111_44}" --未完成任务的npc对话
edali_newquest_020.g_MissionComplete = "#{XSRW_100111_45}"
edali_newquest_020.g_MoneyJZBonus = 100
edali_newquest_020.g_ExpBonus = 2400
edali_newquest_020.g_SignPost = { x = 145, z = 138, tip = "钱龙" }
edali_newquest_020.g_ItemBonus = { { id = 10111000, num = 1 } }

function edali_newquest_020:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
		local Param = self:GetMissionParam(selfId, misIndex, 1)
		if Param < 1 and self:GetName(targetId) == self.g_Name then
			self:CallScriptFunction(311100, "OnDefaultEvent", selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText(self.g_MissionName)
			self:AddText(self.g_ContinueInfo)
			self:EndEvent()
			local bDone = self:CheckSubmit(selfId)
			self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
		end
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionTarget)
		for i, item in pairs(self.g_ItemBonus) do
			self:AddItemBonus(item["id"], item["num"])
		end
		self:AddMoneyBonus(self.g_MoneyJZBonus)
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_020:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId, self.g_MissionId) and self:GetLevel(selfId) >= self.g_MissionLevel and self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	elseif self:GetName(targetId) == self.g_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
		local Param = self:GetMissionParam(selfId, misIndex, 1)
		if Param < 1 then
			caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
		end
	end
end

function edali_newquest_020:OnAccept(selfId)
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

function edali_newquest_020:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_020:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_020:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i, item in pairs(self.g_ItemBonus) do
		self:AddItemBonus(item["id"], item["num"])
	end
	self:AddMoneyBonus(self.g_MoneyJZBonus)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_020:OnSubmit(selfId, targetId)
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
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Vấn đáp giang hồ")
			--self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
		end
	end
end

function edali_newquest_020:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	else
		return 1
	end
end

function edali_newquest_020:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_020:OnEnterArea(selfId, zoneId)
end

function edali_newquest_020:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_020
