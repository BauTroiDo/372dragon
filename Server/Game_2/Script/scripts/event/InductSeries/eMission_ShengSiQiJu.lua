local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eMission_ShengSiQiJu = class("eMission_ShengSiQiJu", script_base)
eMission_ShengSiQiJu.script_id = 500601
eMission_ShengSiQiJu.g_Position_X = 160.2399
eMission_ShengSiQiJu.g_Position_Z = 134.1486
eMission_ShengSiQiJu.g_SceneID = 0
eMission_ShengSiQiJu.g_AccomplishNPC_Name = "周天师"
eMission_ShengSiQiJu.g_PreMissionId = 407
eMission_ShengSiQiJu.g_MissionId = 408
eMission_ShengSiQiJu.g_MissionIdNext = 409
eMission_ShengSiQiJu.g_NextScriptId = 500602
eMission_ShengSiQiJu.g_AcceptNPC_SceneID = 0
eMission_ShengSiQiJu.g_Name = "卜悔琪"
eMission_ShengSiQiJu.g_MissionKind = 11
eMission_ShengSiQiJu.g_MissionLevel = 28
eMission_ShengSiQiJu.g_IfMissionElite = 0
eMission_ShengSiQiJu.g_IsMissionOkFail = 0
eMission_ShengSiQiJu.g_MissionName = "Sinh Tử Kỳ Cục"
eMission_ShengSiQiJu.g_MissionInfo = "#{YD_20080421_32}"
eMission_ShengSiQiJu.g_MissionTarget = "#{YD_20080421_31}"
eMission_ShengSiQiJu.g_ContinueInfo = "#{YD_20080421_33}"
eMission_ShengSiQiJu.g_MissionComplete = "#{YD_20080421_34}"
eMission_ShengSiQiJu.g_MaxRound = 1
eMission_ShengSiQiJu.g_ControlScript = 001066
eMission_ShengSiQiJu.g_Custom = { { ["id"] = "已杀死远古棋魂", ["num"] = 1 }}
eMission_ShengSiQiJu.g_Mission_IsComplete = 0
eMission_ShengSiQiJu.g_RecordIdx = 1
eMission_ShengSiQiJu.g_MissScriptID_Idx = 2
eMission_ShengSiQiJu.g_AcceptNPC_Idx = 3
eMission_ShengSiQiJu.g_AcceptMission_IDX = 745
eMission_ShengSiQiJu.g_CompleteMission_IDX = 746
eMission_ShengSiQiJu.g_EventList = {}
eMission_ShengSiQiJu.g_PlayerSlow_LVL = 28
eMission_ShengSiQiJu.g_MoneyBonus = 7969
eMission_ShengSiQiJu.g_ExpBonus = 31877
eMission_ShengSiQiJu.g_TargetSceneId = 44
eMission_ShengSiQiJu.g_MonsterName = "远古棋魂"
eMission_ShengSiQiJu.g_KillMonsterCnt = 1
function eMission_ShengSiQiJu:OnDefaultEvent(selfId, targetId,arg,index)
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
function eMission_ShengSiQiJu:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:GetName(targetId) == self.g_Name and self:GetSceneID() == self.g_AcceptNPC_SceneID then
        if not self:IsHaveMission(selfId, self.g_MissionId) then
            print("self:IsMissionHaveDone(selfId, self.g_PreMissionId) = ",self:IsMissionHaveDone(selfId, self.g_PreMissionId))
            if self:IsMissionHaveDone(selfId, self.g_PreMissionId) and not self:IsMissionHaveDone(selfId, self.g_MissionId) then
                caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 1, self.g_AcceptMission_IDX)
            end
        end
    elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:get_scene_id() == self.g_SceneID then
        if self:IsHaveMission(selfId, self.g_MissionId) then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 2, self.g_CompleteMission_IDX)
        end
    else
        return 0
    end
end
function eMission_ShengSiQiJu:CheckAccept(selfId, targetId)
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
function eMission_ShengSiQiJu:OnAccept(selfId, targetId, scriptId)
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
function eMission_ShengSiQiJu:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    end
    return 0
end
function eMission_ShengSiQiJu:OnContinue(selfId, targetId)
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
function eMission_ShengSiQiJu:CheckSubmit(selfId, targetId)
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
function eMission_ShengSiQiJu:OnSubmit(selfId, targetId, selectRadioId)
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
end
function eMission_ShengSiQiJu:OnKillObject(selfId, objdataId, objId)
    local sceneType = self:LuaFnGetSceneType()
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
            if self:GetMissionParam(humanObjId, misIndex, self.g_Mission_IsComplete) < 1 then
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
function eMission_ShengSiQiJu:OnEnterArea(selfId, zoneId)
end
function eMission_ShengSiQiJu:OnItemChanged(selfId, itemdataId)
end
function eMission_ShengSiQiJu:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_ShengSiQiJu:SubmitDialog(selfId, rand)
end
function eMission_ShengSiQiJu:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
function eMission_ShengSiQiJu:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function eMission_ShengSiQiJu:GetEventMissionId(selfId)
    return self.g_MissionId
end
function eMission_ShengSiQiJu:AcceptMission(selfId, targetId)
    if self:GetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{YD_20080421_31}")
    self:AddText("#{M_SHOUHUO}")
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eMission_ShengSiQiJu:GetItemDetailInfo(itemId)
    return 0
end
function eMission_ShengSiQiJu:OnUseItem(selfId, bagIndex)
end
function eMission_ShengSiQiJu:OnDie(selfId, killerId)
end
return eMission_ShengSiQiJu