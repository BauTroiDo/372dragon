local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_018 = class("edali_newquest_018", script_base)
edali_newquest_018.script_id = 210266
edali_newquest_018.g_NextScriptId = 210278
edali_newquest_018.g_Position_X = 160
edali_newquest_018.g_Position_Z = 158
edali_newquest_018.g_SceneID = 2
edali_newquest_018.g_AccomplishNPC_Name = "赵天师"
edali_newquest_018.g_MissionIdPre = 0
edali_newquest_018.g_MissionId = 1417
edali_newquest_018.g_Name = "赵天师"
edali_newquest_018.g_ItemId = 30505273
edali_newquest_018.g_MissionKind = 13
edali_newquest_018.g_MissionLevel = 8
edali_newquest_018.g_IfMissionElite = 0
edali_newquest_018.g_IsMissionOkFail = 0                 --变量的第0位
edali_newquest_018.g_MissionName = "Pháo hoa mừng lễ"
edali_newquest_018.g_MissionInfo = "#{XSRW_100111_39}"   --任务描述至于什么地方合适，你只要打开#Y背包#W里的任务道具栏，右键点一下这个#Y传讯焰火#W，它就能给你相关的提示。
edali_newquest_018.g_MissionTarget = "#{XSRW_100111_95}" --任务目标
edali_newquest_018.g_ContinueInfo = "#{XSRW_100111_96}"  --未完成任务的npc对话
edali_newquest_018.g_MissionComplete = "#{XSRW_100111_40}" --完成任务npc说话的话
edali_newquest_018.g_SignPost = { x = 160, z = 157, tip = "赵天师" }
edali_newquest_018.g_MoneyJZBonus = 100
edali_newquest_018.g_ExpBonus = 2400
edali_newquest_018.g_SignPost_1 = { x = 139, z = 169, tip = "Điểm đốt pháo hoa" }
edali_newquest_018.g_Custom = { { id = "已燃放焰火", num = 1 } }

function edali_newquest_018:OnDefaultEvent(selfId, targetId, arg, index)
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
		self:AddMoneyBonus(self.g_MoneyJZBonus)
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	end
end

function edali_newquest_018:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_018:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	end
	self:BeginAddItem()
	self:AddItem(self.g_ItemId, 1)
	local ret = self:EndAddItem(selfId)
	if ret then
		ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
		if not ret then
			self:notify_tips(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy")
			return
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, "Ngươi nhận pháo hoa hỷ khánh")
	end
end

function edali_newquest_018:CheckSubmit(selfId)
	local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
	local param = self:GetMissionParam(selfId, misIndex, 0)
	if param < 1 then
		return 0
	else
		return 1
	end
end

function edali_newquest_018:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
	if self:HaveItemInBag(selfId, 30505273) then
		self:DelItem(selfId,30505273)
	end
end

function edali_newquest_018:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:AddMoneyBonus(self.g_MoneyJZBonus)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_018:OnSubmit(selfId, targetId)
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
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Pháo hoa hỷ khánh")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_018:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionId) and self:GetLevel(selfId) >= self.g_MissionLevel and not self:IsHaveMission(selfId, self.g_MissionId) then
		return 1
	else
		return 0
	end
end

function edali_newquest_018:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_018:OnEnterArea(selfId, zoneId)
end

function edali_newquest_018:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_018
