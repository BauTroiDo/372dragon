local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eMission_KillBearKing = class("eMission_KillBearKing", script_base)
eMission_KillBearKing.script_id = 500610
eMission_KillBearKing.g_Position_X = 251.1648
eMission_KillBearKing.g_Position_Z = 108.9732
eMission_KillBearKing.g_SceneID = 1
eMission_KillBearKing.g_AccomplishNPC_Name = "花剑雨"
eMission_KillBearKing.g_PreMissionId = 423
eMission_KillBearKing.g_MissionId = 424
eMission_KillBearKing.g_MissionIdNext = 425
eMission_KillBearKing.g_MissionIndexNext = 1018711
eMission_KillBearKing.g_NextScriptId = 006668
eMission_KillBearKing.g_AcceptNPC_SceneID = 1
eMission_KillBearKing.g_Name = "花剑雨"
eMission_KillBearKing.g_MissionKind = 12
eMission_KillBearKing.g_MissionLevel = 38
eMission_KillBearKing.g_IfMissionElite = 0
eMission_KillBearKing.g_IsMissionOkFail = 0
eMission_KillBearKing.g_MissionName = "Tiêu diệt Hồng Hùng Vương"
eMission_KillBearKing.g_MissionInfo = "#{YD_20080421_70}"
eMission_KillBearKing.g_MissionTarget = "#{YD_20080421_69}"
eMission_KillBearKing.g_ContinueInfo = "#{YD_20080421_194}"
eMission_KillBearKing.g_MissionComplete = "#{YD_20080421_71}"
eMission_KillBearKing.g_MaxRound = 1
eMission_KillBearKing.g_ControlScript = 001066
eMission_KillBearKing.g_Custom = {{["id"] = "已杀死红熊王", ["num"] = 1}}

eMission_KillBearKing.g_Mission_IsComplete = 0
eMission_KillBearKing.g_RecordIdx = 1
eMission_KillBearKing.g_MissScriptID_Idx = 2
eMission_KillBearKing.g_AcceptNPC_Idx = 3
eMission_KillBearKing.g_AcceptMission_IDX = 763
eMission_KillBearKing.g_CompleteMission_IDX = 764
eMission_KillBearKing.g_EventList = {}

eMission_KillBearKing.g_PlayerSlow_LVL = 38
eMission_KillBearKing.g_MoneyBonus = 9475
eMission_KillBearKing.g_ExpBonus = 37902
eMission_KillBearKing.g_ItemBonus_List = {["id"] = 30505701, ["num"] = 1}

eMission_KillBearKing.g_TargetSceneId = 49
eMission_KillBearKing.g_MonsterName = "红熊王"
eMission_KillBearKing.g_KillMonsterCnt = 1
function eMission_KillBearKing:OnDefaultEvent(selfId, targetId, arg, index)
    local key = index
    if key == self.g_AcceptMission_IDX then
        if self:LuaFnGetName(targetId) ~= self.g_Name then
            self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
            return 0
        end
        if self:IsMissionFull(selfId) then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_23}")
            return 0
        end
        if self:CheckAccept(selfId, targetId) <= 0 then
        end
        self:AcceptMission(selfId, targetId)
    elseif key == self.g_CompleteMission_IDX then
        if self:LuaFnGetName(targetId) ~= self.g_AccomplishNPC_Name then
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

function eMission_KillBearKing:OnEnumerate(caller, selfId, targetId, arg, index)
    local sceneId = self:get_scene_id()
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        if self:LuaFnGetName(targetId) == self.g_Name and sceneId == self.g_AcceptNPC_SceneID then
            if self:IsMissionHaveDone(selfId, self.g_PreMissionId) and not self:IsMissionHaveDone(selfId, self.g_MissionId) then
                caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, self.g_AcceptMission_IDX)
            end
        end
    else
        if self:LuaFnGetName(targetId) == self.g_AccomplishNPC_Name and sceneId == self.g_SceneID then
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, self.g_CompleteMission_IDX)
        end
    end
end

function eMission_KillBearKing:CheckAccept(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_PlayerSlow_LVL then
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

function eMission_KillBearKing:OnAccept(selfId, targetId, scriptId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
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
        self:SetMissionByIndex(selfId, misIndex, self.g_AcceptNPC_Idx, 2)
        local strText = "#{YD_20080421_229}" .. self.g_MissionName
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
    return 1
end

function eMission_KillBearKing:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:DelMission(selfId, self.g_MissionId)
    end
    return 0
end

function eMission_KillBearKing:OnContinue(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_AccomplishNPC_Name then
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

function eMission_KillBearKing:CheckSubmit(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{YD_20080421_178}")
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, self.g_Mission_IsComplete) > 0 then
        return 1
    end
    return 0
end

function eMission_KillBearKing:OnSubmit(selfId, targetId, selectRadioId)
    if self:LuaFnGetName(targetId) ~= self.g_AccomplishNPC_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId, targetId) ~= 1 then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    self:AddMoney(selfId, self.g_MoneyBonus)
    self:LuaFnAddExp(selfId, self.g_ExpBonus)
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

function eMission_KillBearKing:OnKillObject(selfId, objdataId, objId)
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
            if self:GetMissionParam(humanObjId, misIndex, self.g_Mission_IsComplete) <= 0 then
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

function eMission_KillBearKing:OnEnterArea(selfId, zoneId)
end

function eMission_KillBearKing:OnItemChanged(selfId, itemdataId)
end

function eMission_KillBearKing:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function eMission_KillBearKing:SubmitDialog(selfId, rand)
end

function eMission_KillBearKing:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function eMission_KillBearKing:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function eMission_KillBearKing:GetEventMissionId(selfId)
    return self.g_MissionId
end

function eMission_KillBearKing:AcceptMission(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{YD_20080421_69}")
    self:AddText("#{M_SHOUHUO}")
    self:AddMoneyBonus(self.g_MoneyBonus)
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function eMission_KillBearKing:GetItemDetailInfo(itemId)
    return 0
end

function eMission_KillBearKing:OnUseItem(selfId, bagIndex)
end

function eMission_KillBearKing:OnDie(selfId, killerId)
end

return eMission_KillBearKing
