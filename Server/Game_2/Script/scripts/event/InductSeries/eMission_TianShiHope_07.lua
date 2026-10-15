local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eMission_TianShiHope_07 = class("eMission_TianShiHope_07", script_base)
eMission_TianShiHope_07.script_id = 500613
eMission_TianShiHope_07.g_Position_X = 160.2399
eMission_TianShiHope_07.g_Position_Z = 134.1486
eMission_TianShiHope_07.g_SceneID = 0
eMission_TianShiHope_07.g_AccomplishNPC_Name = "周天师"
eMission_TianShiHope_07.g_PreMissionId = 432
eMission_TianShiHope_07.g_MissionId = 433
eMission_TianShiHope_07.g_MissionIdNext = 434
eMission_TianShiHope_07.g_MissionIndexNext = 1018716
eMission_TianShiHope_07.g_NextScriptId = 006668
eMission_TianShiHope_07.g_AcceptNPC_SceneID = 0
eMission_TianShiHope_07.g_Name = "周天师"
eMission_TianShiHope_07.g_MissionKind = 11
eMission_TianShiHope_07.g_MissionLevel = 40
eMission_TianShiHope_07.g_IfMissionElite = 0
eMission_TianShiHope_07.g_IsMissionOkFail = 0
eMission_TianShiHope_07.g_MissionName = "Thiên Sư của kỳ vọng (7)"
eMission_TianShiHope_07.g_MissionInfo = "#{YD_20080421_14}"
eMission_TianShiHope_07.g_MissionTarget = "#{YD_20080421_95}"
eMission_TianShiHope_07.g_ContinueInfo = "#{YD_20080421_15}"
eMission_TianShiHope_07.g_MissionComplete = "#{YD_20080421_16}"
eMission_TianShiHope_07.g_MaxRound = 1
eMission_TianShiHope_07.g_ControlScript = 001066
eMission_TianShiHope_07.g_Custom = { { ["id"] = "已升到42级", ["num"] = 1 }
}
eMission_TianShiHope_07.g_Mission_IsComplete = 0
eMission_TianShiHope_07.g_RecordIdx = 1
eMission_TianShiHope_07.g_MissScriptID_Idx = 2
eMission_TianShiHope_07.g_AcceptNPC_Idx = 3
eMission_TianShiHope_07.g_AcceptMission_IDX = 781
eMission_TianShiHope_07.g_CompleteMission_IDX = 782
eMission_TianShiHope_07.g_EventList = {}
eMission_TianShiHope_07.g_PlayerSlow_LVL = 40
eMission_TianShiHope_07.g_MoneyBonus = 1397
eMission_TianShiHope_07.g_ExpBonus = 5589
function eMission_TianShiHope_07:OnDefaultEvent(selfId, targetId,arg,index)
    local key = index
    if key == self.g_AcceptMission_IDX then
        if self:GetName(targetId) ~= self.g_Name then
            self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
            return 0
        end
        if self:IsMissionFull(selfId) then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_23}")
            return 0
        end
        if self:CheckAccept(selfId, targetId) <= 0 then
            return 0
        end
        self:AcceptMission(selfId, targetId)
    elseif key == self.g_CompleteMission_IDX then
        if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
            self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
            return 0
        end
        if self:IsHaveMission(selfId, self.g_MissionId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_ContinueInfo)
            self:EndEvent()
            local bDone = self:CheckSubmit(selfId, targetId)
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
        else
            self:TalkInfo(selfId, targetId, "#{YD_20080421_178}")
            return 0
        end
    else
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
end
function eMission_TianShiHope_07:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) ~= self.g_Name or self:get_scene_id() ~= self.g_SceneID then
        return 0
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if not self:IsMissionHaveDone(selfId, self.g_MissionId) and self:GetLevel(selfId) >= self.g_PlayerSlow_LVL then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, self.g_AcceptMission_IDX)
        end
    else
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, self.g_CompleteMission_IDX)
    end
end
function eMission_TianShiHope_07:CheckAccept(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:GetLevel(selfId) < self.g_PlayerSlow_LVL then
        local nStr = string.format("#{YD_20080421_175}%d#{YD_20080421_176}", self.g_PlayerSlow_LVL)
        self:TalkInfo(selfId,targetId,nStr)
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    return 1
end
function eMission_TianShiHope_07:OnAccept(selfId, targetId, scriptId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:CheckAccept(selfId, targetId) <= 0 then
        return 0
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if bAdd then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_RecordIdx, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_MissScriptID_Idx, scriptId)
        self:SetMissionByIndex(selfId, misIndex, self.g_AcceptNPC_Idx, 1)
        local strText = "#{YD_20080421_229}" .. self.g_MissionName
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        local Playerlvl = self:GetLevel(selfId)
        if Playerlvl >= 42 then
            self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 1)
            self:SetMissionByIndex(selfId, misIndex, self.g_RecordIdx, 1)
            self:NotifyTip(selfId, "#{YD_20080421_198}")
        end
    end
    return 1
end
function eMission_TianShiHope_07:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    end
    return 0
end
function eMission_TianShiHope_07:OnContinue(selfId, targetId)
    if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId, targetId) ~= 1 then
        return 0
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eMission_TianShiHope_07:CheckSubmit(selfId, targetId)
    if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_178}")
        return 0
    end
    local Playerlvl = self:GetLevel(selfId)
    if Playerlvl < 42 then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_199}")
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Mission_IsComplete) then
        return 1
    end
    return 0
end
function eMission_TianShiHope_07:OnSubmit(selfId, targetId, selectRadioId)
    if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId, targetId) ~= 1 then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    self:AddMoney(selfId, self.g_MoneyBonus)
    self:AddExp(selfId, self.g_ExpBonus)
    self:NotifyTip(selfId, "#{YD_20080421_180}")
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
        self:MissionCom(selfId, self.g_MissionId)
        local strText = "#Y" .. self.g_MissionName .. "#{YD_20080421_230}"
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        if not self:IsHaveMission(selfId, self.g_MissionIdNext) and not self:IsMissionHaveDone(selfId, self.g_MissionIdNext) then
            self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId, self.g_MissionIndexNext)
        end
    end
end
function eMission_TianShiHope_07:OnKillObject(selfId, objdataId, objId)
end
function eMission_TianShiHope_07:OnEnterArea(selfId, zoneId)
end
function eMission_TianShiHope_07:OnItemChanged(selfId, itemdataId)
end
function eMission_TianShiHope_07:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_TianShiHope_07:SubmitDialog(selfId, rand)
end
function eMission_TianShiHope_07:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
function eMission_TianShiHope_07:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_TianShiHope_07:GetEventMissionId(selfId)
    return self.g_MissionId
end
function eMission_TianShiHope_07:AcceptMission(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{YD_20080421_95}")
    self:AddText("#{M_SHOUHUO}")
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eMission_TianShiHope_07:GetItemDetailInfo(itemId)
    return 0
end
function eMission_TianShiHope_07:OnUseItem(selfId, bagIndex)
end
function eMission_TianShiHope_07:OnDie(selfId, killerId)
end
return eMission_TianShiHope_07