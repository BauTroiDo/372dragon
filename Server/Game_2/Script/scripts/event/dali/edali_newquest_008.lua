local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_008 = class("edali_newquest_008", script_base)
edali_newquest_008.script_id  = 210273
edali_newquest_008.g_NextScriptId = 210274
edali_newquest_008.g_Position_X=58
edali_newquest_008.g_Position_Z=133
edali_newquest_008.g_SceneID=2
edali_newquest_008.g_AccomplishNPC_Name="高升祥"
edali_newquest_008.g_MissionIdPre = 1406
edali_newquest_008.g_MissionId = 1407
edali_newquest_008.g_Name	="卢三七"
edali_newquest_008.g_MissionKind = 13
edali_newquest_008.g_MissionLevel = 4
edali_newquest_008.g_MinMissionLevel = 4
edali_newquest_008.g_IfMissionElite = 0
edali_newquest_008.g_MissionName="Kiếm Các Hầu Hoạn"
edali_newquest_008.g_MissionTarget="#{XSRW_100111_66}"	--任务目标
edali_newquest_008.g_MissionInfo="#{XSRW_100111_18}" --任务描述
edali_newquest_008.g_ContinueInfo="#{XSRW_100111_84}"	--未完成任务的npc对话
edali_newquest_008.g_MissionComplete="#{XSRW_100111_19}"	--完成任务npc说话的话
edali_newquest_008.g_SignPost = {x = 58, z = 133, tip = "高升祥"}
edali_newquest_008.g_MoneyJZBonus=30
edali_newquest_008.g_ExpBonus=4560
edali_newquest_008.g_ItemBonus={}
edali_newquest_008.g_RadioItemBonus={{id=10401072,num=1},{id=10402082,num=1},{id=10403072,num=1},{id=10404077,num=1},{id=10406010,num=1}}
edali_newquest_008.g_DemandTrueKill ={{name="蜀道白猿",num=4}}
edali_newquest_008.g_IsMissionOkFail = 0		--变量的第0位
edali_newquest_008.g_DemandKill ={{id=719,num=4}}		--变量第1位

function edali_newquest_008:OnDefaultEvent(selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) or not self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) and self:GetName(targetId) == self.g_AccomplishNPC_Name then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_ContinueInfo)
		self:EndEvent()
	    local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId,targetId,self.script_id,self.g_MissionId,bDone)
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionTarget)
		for i,item in pairs(self.g_RadioItemBonus) do
			self:AddRadioItemBonus(item["id"], item["num"])
		end
		self:EndEvent()
		self:DispatchMissionInfo(selfId,targetId,self.script_id,self.g_MissionId)
	end
end 
function edali_newquest_008:OnEnumerate(caller,selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) or not self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return
	end
	if self:IsHaveMission(selfId,self.g_MissionId) and self:GetName(targetId) == self.g_AccomplishNPC_Name then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,2,1)
	else
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
end
function edali_newquest_008:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId,self.g_MissionId,self.script_id,1,0,0)
	if not ret then
		self:notify_tips(selfId,"#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
    self:notify_tips(selfId,"Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
end
function edali_newquest_008:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then 
		return 0 
	end
	return 1
end
function edali_newquest_008:OnAbandon(selfId)
	self:DelMission(selfId,self.g_MissionId)
end
function edali_newquest_008:OnContinue(selfId,targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i,item in pairs(self.g_RadioItemBonus) do
    	self:AddRadioItemBonus(item["id"], item["num"])
	end
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId,targetId,self.script_id,self.g_MissionId)
end
function edali_newquest_008:OnSubmit(selfId,targetId,selectRadioId)
    local reward
    for _,item in ipairs(self.g_RadioItemBonus) do
        if item.id == selectRadioId then reward = item; break end
    end
    if not reward then return end
	if not self:IsHaveMission(selfId,self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
    self:BeginAddItem()
	self:AddItem(reward.id, reward.num)
    local ret = self:EndAddItem(selfId)
    if ret then
        if not self:AddItemListToHuman(selfId) then return end
		if (self.g_MoneyJZBonus > 0) then
			-- [quest-live 17/09] truoc day ghi nham g_ExpBonus -> tra 4560 giao tu thay vi 30
			self:AddMoneyJZ(selfId,self.g_MoneyJZBonus)
		end
		if (self.g_ExpBonus > 0) then
			self:LuaFnAddExp(selfId,self.g_ExpBonus )
		end
		ret = self:DelMission(selfId, self.g_MissionId)
		if ret then
			self:MissionCom(selfId, self.g_MissionId)
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Nạn khỉ Kiếm Các")
			self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId,targetId)
        end
	end
end
function edali_newquest_008:CheckAccept(selfId)
	if self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return 1
	else
		return 0
	end
end
function edali_newquest_008:OnKillObject(selfId,objdataId,objId)
	local strText = ""
	for i,data in pairs(self.g_DemandTrueKill) do
		if self:GetName(objId) == data["name"] then
			local num = self:GetNearHumanCount(objId)
			for j = 1,num  do
				local humanObjId = self:GetNearHuman(objId,j)
				if self:IsHaveMission(humanObjId, self.g_MissionId) then
					local misIndex = self:GetMissionIndexByID(humanObjId,self.g_MissionId)
					local nNum = self:GetMissionParam(humanObjId,misIndex,1)
					if nNum < data["num"] then
						if nNum == data["num"] - 1 then
							self:SetMissionByIndex(humanObjId,misIndex,0,1)
						end
						self:SetMissionByIndex(humanObjId,misIndex,1,nNum+1)
						self:BeginEvent(self.script_id)
							strText = string.format("Đã giết Bạch Viên Thục Đạo %d/4", self:GetMissionParam(humanObjId,misIndex,1))
							self:AddText(strText);
						self:EndEvent()
						self:DispatchMissionTips(humanObjId)
					end
				end
			end
		end
	end
end
function edali_newquest_008:OnEnterArea(selfId,zoneId)
end
function edali_newquest_008:OnItemChanged(selfId,itemdataId)
end

return edali_newquest_008