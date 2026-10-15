local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eMission_TianShiHope_06 = class("eMission_TianShiHope_06", script_base)
eMission_TianShiHope_06.script_id = 500612
eMission_TianShiHope_06.g_Position_X = 160.2399
eMission_TianShiHope_06.g_Position_Z = 134.1486
eMission_TianShiHope_06.g_SceneID = 0
eMission_TianShiHope_06.g_AccomplishNPC_Name = "周天师"
eMission_TianShiHope_06.g_PreMissionId = 427
eMission_TianShiHope_06.g_MissionId = 428
eMission_TianShiHope_06.g_MissionIdNext = 429
eMission_TianShiHope_06.g_MissionIndexNext = 1018713
eMission_TianShiHope_06.g_NextScriptId = 006668
eMission_TianShiHope_06.g_AcceptNPC_SceneID = 0
eMission_TianShiHope_06.g_Name = "周天师"
eMission_TianShiHope_06.g_MissionKind = 11
eMission_TianShiHope_06.g_MissionLevel = 38
eMission_TianShiHope_06.g_IfMissionElite = 0
eMission_TianShiHope_06.g_IsMissionOkFail = 0
eMission_TianShiHope_06.g_MissionName = "Thiên SưcủaKỳ Vọng (6)"
eMission_TianShiHope_06.g_MissionInfo = "#{YD_20080421_14}"
eMission_TianShiHope_06.g_MissionTarget = "#{YD_20080421_80}"
eMission_TianShiHope_06.g_ContinueInfo = "#{YD_20080421_15}"
eMission_TianShiHope_06.g_MissionComplete = "#{YD_20080421_16}"
eMission_TianShiHope_06.g_MaxRound = 1
eMission_TianShiHope_06.g_ControlScript = 001066
eMission_TianShiHope_06.g_Custom = { { ["id"] = "已升到40级", ["num"] = 1 }
}
eMission_TianShiHope_06.g_Mission_IsComplete = 0
eMission_TianShiHope_06.g_RecordIdx = 1
eMission_TianShiHope_06.g_MissScriptID_Idx = 2
eMission_TianShiHope_06.g_AcceptNPC_Idx = 3
eMission_TianShiHope_06.g_AcceptMission_IDX = 767
eMission_TianShiHope_06.g_CompleteMission_IDX = 768
eMission_TianShiHope_06.g_EventList = {}
eMission_TianShiHope_06.g_PlayerSlow_LVL = 38
eMission_TianShiHope_06.g_MoneyBonus = 1336
eMission_TianShiHope_06.g_ExpBonus = 5346
function eMission_TianShiHope_06:OnDefaultEvent(selfId, targetId,arg,index)
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
function eMission_TianShiHope_06:OnEnumerate(caller, selfId, targetId, arg, index)
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
function eMission_TianShiHope_06:CheckAccept(selfId, targetId)
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
function eMission_TianShiHope_06:OnAccept(selfId, targetId, scriptId)
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
        if Playerlvl >= 40 then
            self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 1)
            self:SetMissionByIndex(selfId, misIndex, self.g_RecordIdx, 1)
            self:NotifyTip(selfId, "#{YD_20080421_196}")
        end
    end
    return 1
end
function eMission_TianShiHope_06:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    end
    return 0
end
function eMission_TianShiHope_06:OnContinue(selfId, targetId)
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
function eMission_TianShiHope_06:CheckSubmit(selfId, targetId)
    if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_178}")
        return 0
    end
    local Playerlvl = self:GetLevel(selfId)
    if Playerlvl < 40 then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_197}")
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Mission_IsComplete) then
        return 1
    end
    return 0
end
function eMission_TianShiHope_06:OnSubmit(selfId, targetId, selectRadioId)
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
function eMission_TianShiHope_06:OnKillObject(selfId, objdataId, objId)
end
function eMission_TianShiHope_06:OnEnterArea(selfId, zoneId)
end
function eMission_TianShiHope_06:OnItemChanged(selfId, itemdataId)
end
function eMission_TianShiHope_06:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_TianShiHope_06:SubmitDialog(selfId, rand)
end
function eMission_TianShiHope_06:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
function eMission_TianShiHope_06:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_TianShiHope_06:GetEventMissionId(selfId)
    return self.g_MissionId
end
function eMission_TianShiHope_06:AcceptMission(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{YD_20080421_80}")
    self:AddText("#{M_SHOUHUO}")
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eMission_TianShiHope_06:GetItemDetailInfo(itemId)
    return 0
end
function eMission_TianShiHope_06:OnUseItem(selfId, bagIndex)
end
function eMission_TianShiHope_06:OnDie(selfId, killerId)
end
return eMission_TianShiHope_06