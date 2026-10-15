local class = require "class"
local script_base = require "script_base"
local edali_newquest_004 = class("edali_newquest_004", script_base)
local define = require "define"
edali_newquest_004.script_id  = 210257
edali_newquest_004.g_NextScriptId = 210258
edali_newquest_004.g_Position_X=238
edali_newquest_004.g_Position_Z=172
edali_newquest_004.g_SceneID=2
edali_newquest_004.g_AccomplishNPC_Name="黄公道"
edali_newquest_004.g_MissionIdPre = 1402
edali_newquest_004.g_MissionId = 1403
edali_newquest_004.g_Name	="黄公道"
edali_newquest_004.g_MissionKind = 13
edali_newquest_004.g_MissionLevel = 2
edali_newquest_004.g_MinMissionLevel = 2
edali_newquest_004.g_IfMissionElite = 0
edali_newquest_004.g_MissionName="Lần đầu giết quái"
edali_newquest_004.g_MissionTarget="#{XSRW_100111_65}"	--任务目标
edali_newquest_004.g_MissionInfo="#{XSRW_100111_8}" --任务描述
edali_newquest_004.g_ContinueInfo="#{XSRW_100111_83}"	--未完成任务的npc对话
edali_newquest_004.g_MissionComplete="#{XSRW_100111_9}"	--完成任务npc说话的话
edali_newquest_004.g_SignPost = {x = 238, z = 172, tip = "黄公道"}
edali_newquest_004.g_MoneyJZBonus=30
edali_newquest_004.g_ExpBonus=780
edali_newquest_004.g_ItemBonus={{id=10110000,num=1}}
edali_newquest_004.g_RadioItemBonus={}
edali_newquest_004.g_DemandTrueKill ={{name="高山白猿",num=4}}
edali_newquest_004.g_IsMissionOkFail = 0		--变量的第0位
edali_newquest_004.g_DemandKill ={{id=708,num=4}}		--变量第1位
function edali_newquest_004:OnDefaultEvent(selfId,targetId,arg,index)
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
		for i,item in pairs(self.g_ItemBonus) do
			self:AddRadioItemBonus(item["id"], item["num"])
		end
		self:EndEvent()
		self:DispatchMissionInfo(selfId,targetId,self.script_id,self.g_MissionId)
	end
end 
function edali_newquest_004:OnEnumerate(caller,selfId,targetId,arg,index)
	if self:IsMissionHaveDone(selfId,self.g_MissionId) or not self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return
	end
	if self:IsHaveMission(selfId,self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,2,1)
	else
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
end
function edali_newquest_004:OnAccept(selfId)
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
function edali_newquest_004:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then 
		return 0 
	end
	return 1
end
function edali_newquest_004:OnAbandon(selfId)
	self:DelMission(selfId,self.g_MissionId)
end
function edali_newquest_004:OnContinue(selfId,targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	for i,item in pairs(self.g_ItemBonus) do
    	self:AddRadioItemBonus(item["id"], item["num"])
	end
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId,targetId,self.script_id,self.g_MissionId)
end
function edali_newquest_004:OnSubmit(selfId,targetId)
	if not self:IsHaveMission(selfId,self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
    self:BeginAddItem()
	for i,item in pairs(self.g_ItemBonus) do
    	self:AddItem(item["id"], item["num"])
	end
    local ret = self:EndAddItem(selfId)
    if ret then
        if not self:AddItemListToHuman(selfId) then return end
		if (self.g_MoneyJZBonus > 0) then
			self:AddMoneyJZ(selfId,self.g_MoneyJZBonus)
		end
		if (self.g_ExpBonus > 0) then
			self:LuaFnAddExp(selfId,self.g_ExpBonus )
		end
		ret = self:DelMission(selfId, self.g_MissionId)
		if ret then
			self:MissionCom(selfId, self.g_MissionId)
			
			self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Lần đầu giết quái")
			self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId,targetId)
        end
	end
end
function edali_newquest_004:CheckAccept(selfId)
	if self:IsMissionHaveDone(selfId,self.g_MissionIdPre) then
		return 1
	else
		return 0
	end
end
function edali_newquest_004:OnKillObject(selfId,objdataId,objId)
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
							strText = string.format("Đã giết Bạch Viên Cao Sơn %d/4", self:GetMissionParam(humanObjId,misIndex,1))
							self:AddText(strText);
						self:EndEvent()
						self:DispatchMissionTips(humanObjId)
					end
				end
			end
		end
	end
end
function edali_newquest_004:OnEnterArea(selfId,zoneId)
end
function edali_newquest_004:OnItemChanged(selfId,itemdataId)
end

return edali_newquest_004