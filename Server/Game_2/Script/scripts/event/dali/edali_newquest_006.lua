local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_006 = class("edali_newquest_006", script_base)
edali_newquest_006.script_id = 210263
edali_newquest_006.g_NextScriptId = 210259
edali_newquest_006.g_Position_X = 144
edali_newquest_006.g_Position_Z = 138
edali_newquest_006.g_SceneID = 2
edali_newquest_006.g_AccomplishNPC_Name = "钱龙"
edali_newquest_006.g_MissionId = 1405
edali_newquest_006.g_MissionIdPre = 0
edali_newquest_006.g_Name	="钱龙"
edali_newquest_006.g_AcceptNPC_Name="赵天师"
edali_newquest_006.g_MissionKind = 13
edali_newquest_006.g_MissionLevel = 3
edali_newquest_006.g_IfMissionElite = 0
edali_newquest_006.g_MissionName="Kỹ năng Sơ Cấp"
edali_newquest_006.g_MissionInfo="#{XSRW_100111_12}"
edali_newquest_006.g_MissionTarget="#{XSRW_100111_86}"
edali_newquest_006.g_MissionContinue="#{XSRW_100111_94}"
edali_newquest_006.g_MissionComplete="#{XSRW_100111_13}"
edali_newquest_006.g_MoneyJZBonus=30
edali_newquest_006.g_ExpBonus=1600
edali_newquest_006.g_SignPost = {x = 144, z = 138, tip = "钱龙"}
edali_newquest_006.g_IsMissionOkFail = 0
edali_newquest_006.g_Custom	= { {id="学习内劲攻击",num=1}, {id="学习初级隐遁",num=1} }

function edali_newquest_006:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionContinue)
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

function edali_newquest_006:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_Name and self:IsHaveMission(selfId,self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_AcceptNPC_Name and self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	end
end

function edali_newquest_006:OnAccept(selfId)
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
	if self:HaveSkill(selfId,244) then
		self:SetMissionByIndex(selfId,misIndex,1,1)
		self:notify_tips(selfId,"Đã học Nội Kình Công Kích")
	end
	if self:HaveSkill(selfId,248) then
		self:SetMissionByIndex(selfId,misIndex,2,1)
		self:notify_tips(selfId,"Đã học Ẩn Độn sơ cấp")
	end
	if self:GetMissionParam(selfId,misIndex,1) == 1 and self:GetMissionParam(selfId,misIndex,2) == 1 then
		self:SetMissionByIndex(selfId,misIndex,0,1) --设置完成任务
	end
end

function edali_newquest_006:CheckSubmit(selfId)
	local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
	if bRet ~= 1 then
		return 0
	end
	return 1
end

function edali_newquest_006:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_006:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_006:OnSubmit(selfId, targetId)
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
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Kỹ năng sơ cấp")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_006:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionId) and self:GetLevel(selfId) >= self.g_MissionLevel and not self:IsHaveMission(selfId,self.g_MissionId) then
		return 1
	else
		return 0
	end
end

function edali_newquest_006:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_006:OnEnterArea(selfId, zoneId)
end

function edali_newquest_006:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_006
