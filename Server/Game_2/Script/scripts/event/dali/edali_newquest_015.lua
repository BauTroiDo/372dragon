local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_015 = class("edali_newquest_015", script_base)
edali_newquest_015.g_ScriptId = 210264
edali_newquest_015.g_NextScriptId = 210265
edali_newquest_015.g_Position_X = 265
edali_newquest_015.g_Position_Z = 129
edali_newquest_015.g_SceneID = 2
edali_newquest_015.g_AccomplishNPC_Name = "云飘飘"
edali_newquest_015.g_MissionIdPre = 1413
edali_newquest_015.g_MissionId = 1414
edali_newquest_015.g_Name = "云飘飘"
edali_newquest_015.g_MissionKind = 13
edali_newquest_015.g_MissionLevel = 7
edali_newquest_015.g_IfMissionElite = 0
edali_newquest_015.g_MissionName = "Trân thú Đầu Tiên"
edali_newquest_015.g_MissionInfo = "#{XSRW_100111_32}"     --任务描述
edali_newquest_015.g_MissionTarget = "#{XSRW_100111_90}"   --任务目标
edali_newquest_015.g_ContinueInfo = "#{XSRW_100111_80}"    --未完成任务的npc对话
edali_newquest_015.g_MissionComplete = "#{XSRW_100111_34}" --完成任务npc说话的话
edali_newquest_015.g_SignPost = { x = 263, z = 129, tip = "云飘飘" }
edali_newquest_015.g_IsMissionOkFail = 0                   --变量的第0位
edali_newquest_015.g_Custom = { { id = "小兔子升到2级", num = 1 } }
edali_newquest_015.g_MoneyJZBonus = 100
edali_newquest_015.g_ExpBonus = 4000
edali_newquest_015.g_ItemBonus = { { id = 30603001, num = 20 } }
edali_newquest_015.g_PetID = 559 --给的珍兽ID

function edali_newquest_015:OnDefaultEvent(selfId, targetId, arg, index)
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

function edali_newquest_015:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_015:OnAccept(selfId)
    if self:IsMissionHaveDone(selfId,self.g_MissionId) or self:IsHaveMission(selfId,self.g_MissionId)
        or self:CheckAccept(selfId) <= 0 then return end
    if not self:AddMission(selfId,self.g_MissionId,self.script_id,0,0,0) then
        self:notify_tips(selfId,"Nhật ký nhiệm vụ đã đầy.")
        return
    end
    local ret = self:LuaFnCreatePetToHuman(selfId,self.g_PetID,true)
    if not ret then
        self:DelMission(selfId,self.g_MissionId)
        return
    end
    self:notify_tips(selfId,"Ngươi nhận được Phiêu Phiêu Thỏ.")
    self:notify_tips(selfId,"Tiếp nhận nhiệm vụ: "..self.g_MissionName)
end

function edali_newquest_015:CheckSubmit(selfId)
	local petcount = self:LuaFnGetPetCount(selfId)
	for i = 1, petcount do
		local petdataid = self:LuaFnGetPet_DataID(selfId, i)
		local nPetLevel = self:LuaFnGetPet_Level(selfId, i)
		if petdataid == self.g_PetID and nPetLevel >= 2 then
			return 1
		end
	end
	return 0
end

function edali_newquest_015:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
	local petcount = self:LuaFnGetPetCount(selfId)
	for i = 1, petcount do
		local petdataid = self:LuaFnGetPet_DataID(selfId, i)
		if petdataid == self.g_PetID then
			self:LuaFnDeletePet(selfId, i)
		end
	end
end

function edali_newquest_015:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i, item in pairs(self.g_ItemBonus) do
		self:AddRadioItemBonus(item["id"], item["num"])
	end
	self:AddMoneyBonus(self.g_MoneyJZBonus)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_015:OnSubmit(selfId, targetId)
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
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Trân thú đầu tiên")
			self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
		end
	end
end

function edali_newquest_015:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	else
		return 1
	end
end

function edali_newquest_015:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_015:OnEnterArea(selfId, zoneId)
end

function edali_newquest_015:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_015
