local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_021 = class("edali_newquest_021", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
edali_newquest_021.script_id  = 210269
edali_newquest_021.g_NextScriptId = 210268
edali_newquest_021.g_Position_X=160
edali_newquest_021.g_Position_Z=158
edali_newquest_021.g_SceneID=2
edali_newquest_021.g_AccomplishNPC_Name="赵天师"
edali_newquest_021.g_MissionIdPre = 1419
edali_newquest_021.g_MissionId = 1420
edali_newquest_021.g_Name	="赵天师"
edali_newquest_021.g_MissionKind = 13
edali_newquest_021.g_MissionLevel = 9
edali_newquest_021.g_MinMissionLevel = 9
edali_newquest_021.g_IfMissionElite = 0
edali_newquest_021.g_MissionName="Thử thách cuối của"
edali_newquest_021.g_MissionTarget="#{XSRW_100111_93}"	--任务目标
edali_newquest_021.g_MissionInfo="#{XSRW_100111_46}" --任务描述
edali_newquest_021.g_ContinueInfo="#{XSRW_100111_85}"	--未完成任务的npc对话
edali_newquest_021.g_MissionComplete="#{XSRW_100111_47}"	--完成任务npc说话的话
edali_newquest_021.g_SignPost = {x = 160, z = 157, tip = "赵天师"}
edali_newquest_021.g_MoneyJZBonus=100
edali_newquest_021.g_ExpBonus=12860
edali_newquest_021.g_ItemBonus={}
edali_newquest_021.g_RadioItemBonus={}
edali_newquest_021.g_DemandTrueKill ={{name="木头人",num=5}}
edali_newquest_021.g_IsMissionOkFail = 0		--变量的第0位
edali_newquest_021.g_DemandKill ={{id=703,num=5}}		--变量第1位
edali_newquest_021.g_client_res = 47
edali_newquest_021.g_CopySceneType = ScriptGlobal.FUBEN_MURENXIANG --副本类型，定义在ScriptGlobal.lua里面
edali_newquest_021.g_LimitMembers = 1                                --可以进副本的最小队伍人数
edali_newquest_021.g_TickTime = 5                                    --回调脚本的时钟时间（单位：秒/次）
edali_newquest_021.g_LimitTotalHoldTime = 360                        --副本可以存活的时间（单位：次数）,如果此时间到了，则任务将会失败
edali_newquest_021.g_LimitTimeSuccess = 500                          --副本时间限制（单位：次数），如果此时间到了，任务完成
edali_newquest_021.g_CloseTick = 6                                   --副本关闭前倒计时（单位：次数）
edali_newquest_021.g_NoUserTime = 300                                --副本中没有人后可以继续保存的时间（单位：秒）
edali_newquest_021.g_DeadTrans = 0                                   --死亡转移模式，0：死亡后还可以继续在副本，1：死亡后被强制移出副本
edali_newquest_021.g_Fuben_X = 82                                    --进入副本的位置X
edali_newquest_021.g_Fuben_Z = 76                                    --进入副本的位置Z
edali_newquest_021.g_Back_X = 160                                    --源场景位置X
edali_newquest_021.g_Back_Z = 158                                     --源场景位置Z

function edali_newquest_021:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) then
		if index == 9 then
			self:CallScriptFunction((400900), "TransferFunc", selfId, 61, 82, 76)
			return
		end
		local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
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

function edali_newquest_021:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId,self.g_MissionId) then
	caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	caller:AddNumTextWithTarget(self.script_id, "Đến Mộc Nhân Hạng", 10, 9)
	elseif self:CheckAccept(selfId) > 0 then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName,1,1)
	end
end

function edali_newquest_021:OnAccept(selfId)
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

function edali_newquest_021:CheckSubmit(selfId)
    local bRet = self:CallScriptFunction(define.SCENE_SCRIPT_ID, "CheckSubmit", selfId, self.g_MissionId)
    if bRet ~= 1 then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local num = self:GetMissionParam(selfId, misIndex, 1)
    if num == self.g_DemandTrueKill[1]["num"] then
        return 1
    end
	return 0
end

function edali_newquest_021:OnAbandon(selfId)
	self:DelMission(selfId, self.g_MissionId)
end

function edali_newquest_021:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:AddMoneyBonus(self.g_MoneyJZBonus)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_021:OnSubmit(selfId, targetId)
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
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Thí luyện cuối cùng")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_021:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	end
	if self:IsHaveMission(selfId, self.g_MissionId) then
		return 0
	end
	if self:GetLevel(selfId) < self.g_MinMissionLevel then
		return 0
	end
	return 1
end

function edali_newquest_021:OnHumanDie(selfId, killerId)

end

function edali_newquest_021:OnKillObject(selfId, objdataId, objId)
    if self:GetName(objId) == self.g_DemandTrueKill[1]["name"] then
        local num = self:GetNearHumanCount(objId)
        for j = 1, num do
            local humanObjId = self:GetNearHuman(objId,j)
            if self:IsHaveMission(humanObjId, self.g_MissionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
                local nNum = self:GetMissionParam(humanObjId, misIndex, 1)
                if nNum < self.g_DemandTrueKill[1]["num"] then
                    if nNum == self.g_DemandTrueKill[1]["num"] - 1 then
                        self:SetMissionByIndex(humanObjId,misIndex,0,1)
                    end
                    self:SetMissionByIndex(humanObjId, misIndex, 1, nNum + 1)
                    local strText = string.format("Đã tiêu diệt Mộc Đầu Nhân %d/5", self:GetMissionParam(humanObjId,misIndex,1))
					self:notify_tips(humanObjId,strText)
                end
            end
        end
    end
end

function edali_newquest_021:OnEnterArea(selfId, zoneId)
end

function edali_newquest_021:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_021
