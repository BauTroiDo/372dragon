local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eMission_KillFanZei = class("eMission_KillFanZei", script_base)
eMission_KillFanZei.script_id = 500604
eMission_KillFanZei.g_Position_X = 160.2399
eMission_KillFanZei.g_Position_Z = 134.1486
eMission_KillFanZei.g_SceneID = 0
eMission_KillFanZei.g_AccomplishNPC_Name = "周天师"
eMission_KillFanZei.g_PreMissionId = 413
eMission_KillFanZei.g_MissionId = 414
eMission_KillFanZei.g_MissionIdNext = 415
eMission_KillFanZei.g_NextScriptId = 500605
eMission_KillFanZei.g_AcceptNPC_SceneID = 0
eMission_KillFanZei.g_Name = "立繁"
eMission_KillFanZei.g_MissionKind = 11
eMission_KillFanZei.g_MissionLevel = 32
eMission_KillFanZei.g_IfMissionElite = 0
eMission_KillFanZei.g_IsMissionOkFail = 0
eMission_KillFanZei.g_MissionName = "造反恶贼"
eMission_KillFanZei.g_MissionInfo = "#{YD_20080421_49}"
eMission_KillFanZei.g_MissionTarget = "#{YD_20080421_48}"
eMission_KillFanZei.g_ContinueInfo = "#{YD_20080421_185}"
eMission_KillFanZei.g_MissionComplete = "#{YD_20080421_50}"
eMission_KillFanZei.g_MaxRound = 1
eMission_KillFanZei.g_ControlScript = 001066
eMission_KillFanZei.g_Custom = { { ["id"] = "已杀死贼兵头目", ["num"] = 1 }
}
eMission_KillFanZei.g_Mission_IsComplete = 0
eMission_KillFanZei.g_RecordIdx = 1
eMission_KillFanZei.g_MissScriptID_Idx = 2
eMission_KillFanZei.g_AcceptNPC_Idx = 3
eMission_KillFanZei.g_AcceptMission_IDX = 751
eMission_KillFanZei.g_CompleteMission_IDX = 752
eMission_KillFanZei.g_EventList = {}
eMission_KillFanZei.g_PlayerSlow_LVL = 32
eMission_KillFanZei.g_MoneyBonus = 8121
eMission_KillFanZei.g_ExpBonus = 32487
eMission_KillFanZei.g_ItemBonus_List = { ["id"] = 40004449, ["num"] = 1 }
eMission_KillFanZei.g_TargetSceneId = 127
eMission_KillFanZei.g_MonsterName = "贼兵头目"
eMission_KillFanZei.g_KillMonsterCnt = 1
function eMission_KillFanZei:OnDefaultEvent(selfId, targetId,arg,index)
    local key = index
    if key == self.g_AcceptMission_IDX then
        if self:GetName(targetId) ~= self.g_Name then
            self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
            return 0
        end
        if self:IsMissionFull(selfId) == 1 then
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
function eMission_KillFanZei:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == self.g_Name and self:get_scene_id() == self.g_AcceptNPC_SceneID then
        if not self:IsHaveMission(selfId, self.g_MissionId) then
            if self:IsMissionHaveDone(selfId, self.g_PreMissionId) and not self:IsMissionHaveDone(selfId, self.g_MissionId) then
                caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, self.g_AcceptMission_IDX)
            end
        end
    elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:get_scene_id() == self.g_SceneID then
        if self:IsHaveMission(selfId, self.g_MissionId)then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, self.g_CompleteMission_IDX)
        end
    else
        return 0
    end
end
function eMission_KillFanZei:CheckAccept(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:GetLevel(selfId) < self.g_PlayerSlow_LVL then
        local nStr = string.format("#{YD_20080421_175}%d#{YD_20080421_176}", self.g_PlayerSlow_LVL)
        self:TalkInfo(selfId, targetId, nStr)
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{XSHCD_20080418_067}")
        return 0
    end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return 0
    end
    if not self:IsMissionHaveDone(selfId, self.g_PreMissionId) then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_177}")
        return 0
    end
    return 1
end
function eMission_KillFanZei:OnAccept(selfId, targetId, scriptId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:CheckAccept(selfId, targetId) <= 0 then
        return 0
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
    if bAdd then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_RecordIdx, 0)
        self:SetMissionByIndex(selfId, misIndex, self.g_MissScriptID_Idx, scriptId)
        self:SetMissionByIndex(selfId, misIndex, self.g_AcceptNPC_Idx, 1)
        local strText = "#{YD_20080421_229}" .. self.g_MissionName
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    return 1
end
function eMission_KillFanZei:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    end
    return 0
end
function eMission_KillFanZei:OnContinue(selfId, targetId)
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
function eMission_KillFanZei:CheckSubmit(selfId, targetId)
    if self:GetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_178}")
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Mission_IsComplete) then
        return 1
    end
    return 0
end
function eMission_KillFanZei:OnSubmit(selfId, targetId, selectRadioId)
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
        if self:CallScriptFunction(self.g_NextScriptId, "CheckAccept", selfId, targetId) > 0 then
            self:CallScriptFunction(self.g_NextScriptId, "AcceptMission", selfId, targetId)
        end
    end
    local nItemId = 0
    self:BeginAddItem()
    self:AddItem(self.g_ItemBonus_List["id"], self.g_ItemBonus_List["num"])
    local canAdd = self:EndAddItem(selfId)
    if canAdd then
        nItemId = self.g_ItemBonus_List["id"]
        self:AddItemListToHuman(selfId)
    end
end
function eMission_KillFanZei:OnKillObject(selfId, objdataId, objId)
    local sceneType = self:GetSceneType()
    if sceneType ~= 1 then
        return
    end
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    if monsterName ~= self.g_MonsterName then
        return 0
    end
    local num = self:GetMonsterOwnerCount(objId)
    for i = 1, num do
        local humanObjId = self:GetMonsterOwnerID(objId, i)
        if self:IsHaveMission(humanObjId, self.g_MissionId) then
            local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
            if not self:GetMissionParam(humanObjId, misIndex, self.g_Mission_IsComplete) then
                local killedCount = self:GetMissionParam(humanObjId, misIndex, self.g_RecordIdx)
                killedCount = killedCount + 1
                self:SetMissionByIndex(humanObjId, misIndex, self.g_RecordIdx, killedCount)
                self:BeginEvent(self.script_id)
                local str = string.format("Đã tiêu diệt %s%d/%d", self.g_MonsterName, killedCount, self.g_KillMonsterCnt)
                self:AddText(str)
                self:EndEvent()
                self:DispatchMissionTips(humanObjId)
                if killedCount >= self.g_KillMonsterCnt then
                    self:SetMissionByIndex(humanObjId, misIndex, self.g_Mission_IsComplete, 1)
                end
            end
        end
    end
end
function eMission_KillFanZei:OnEnterArea(selfId, zoneId)
end
function eMission_KillFanZei:OnItemChanged(selfId, itemdataId)
end
function eMission_KillFanZei:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_KillFanZei:SubmitDialog(selfId, rand)
end
function eMission_KillFanZei:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
function eMission_KillFanZei:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_KillFanZei:GetEventMissionId(selfId)
    return self.g_MissionId
end
function eMission_KillFanZei:AcceptMission(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{YD_20080421_48}")
    self:AddText("#{M_SHOUHUO}")
    self:AddItemBonus(self.g_ItemBonus_List["id"], self.g_ItemBonus_List["num"])
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eMission_KillFanZei:GetItemDetailInfo(itemId)
    return 0
end
function eMission_KillFanZei:OnUseItem(selfId, bagIndex)
end
function eMission_KillFanZei:OnDie(selfId, killerId)
end
return eMission_KillFanZei