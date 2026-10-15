local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_husong = class("event_husong", script_base)
event_husong.script_id = 006671
event_husong.g_MissionTypeList =
{
    { ["StartIdx"] = 1000000, ["EndIdx"] = 1009999, ["ScriptId"] = 006666 },
    { ["StartIdx"] = 1010000, ["EndIdx"] = 1019999, ["ScriptId"] = 006668 },
    { ["StartIdx"] = 1020000, ["EndIdx"] = 1029999, ["ScriptId"] = 006669 },
    { ["StartIdx"] = 1030000, ["EndIdx"] = 1039999, ["ScriptId"] = 006667 },
    { ["StartIdx"] = 1050000, ["EndIdx"] = 1059999, ["ScriptId"] = 006671 }
}
function event_husong:DisplayBonus(missionIndex)
    local itemCt
    local a = { { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    , { ["id"] = -1, ["ct"] = 0 }
    }
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct = self:TGetAwardItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            self:AddItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct = self:TGetRadioItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            self:AddRadioItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    itemCt, a[1].id, a[1].ct,
    a[2].id, a[2].ct,
    a[3].id, a[3].ct,
    a[4].id, a[4].ct,
    a[5].id, a[5].ct = self:TGetHideItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            self:AddRandItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    local awardMoney = self:TGetAwardMoney(missionIndex)
    self:AddMoneyBonus(awardMoney)
end

function event_husong:OnDefaultEvent(selfId, targetId, missionIndex,index)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local missionTarget, missionInfo, missionContinue, missionComplete = self:TGetMissionDesc(missionIndex)
    if self:IsHaveMission(selfId, missionId) then
        if index == 3 then
            if self:GetMissionParam(selfId, misIndex, 0) ~= 0 then
                return
            end
            local x, z = self:GetWorldPos(targetId)
            local sceneId = self:get_scene_id()
            self:SetMissionByIndex(selfId, misIndex, 7, sceneId)
            self:SetMissionByIndex(selfId, misIndex, 1, 0)
            self:SetMissionByIndex(selfId, misIndex, 2, targetId)
            self:SetMissionByIndex(selfId, misIndex, 3, x)
            self:SetMissionByIndex(selfId, misIndex, 4, z)
            local targetNpcScene, targetNpcName = self:TGetTargetNpcInfo(missionIndex)
            local targetName = self:GetName(targetId)
            if targetNpcScene ~= self:get_scene_id() or targetNpcName ~= targetName then
                return 0
            end
            local oldAIType = self:GetNPCAIType(targetId)
            local oldUnitReputationId = self:GetUnitReputationID(selfId, targetId)
            local patrolPathIndex = self:TGetHusongPatrolPath(missionIndex)
            self:SetUnitReputationID(selfId, targetId, 0)
            self:SetMonsterFightWithNpcFlag(targetId, 1)
            self:SetNPCAIType(targetId, self:TGetHusongAIType(missionIndex))
            self:SetPatrolId(targetId, patrolPathIndex)
            self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetPatrolID", -1)
            self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetBaseAIType", 0, -1, oldAIType)
            self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetReputationID_CodingRefix", oldUnitReputationId)
            self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetMonsterFightWithNpcFlag", 0)
            self:StartMissionTimer(selfId, missionId)
            self:SetMissionEvent(selfId, missionId, 5)
            self:SetMissionEvent(selfId, missionId, 6)
        end
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(missionContinue)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId, missionIndex)
        self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
    elseif self:CheckAccept(selfId, missionIndex) > 0 then
        local targetscene, targetname = self:TGetTargetNpcInfo(missionIndex)
        local monsterId = self:GetMonsterIdByName(targetname)
        local targetx, targetz = self:GetWorldPos(monsterId)
        local respawnx, rewpawnz = self:GetMonsterRespawnPos(monsterId)
        local distSqr = (targetx - respawnx) * (targetx - respawnx) + (targetz - rewpawnz) * (targetz - rewpawnz)
        if distSqr > 2.0 then
            self:BeginEvent(self.script_id)
            self:AddText(missionName)
            self:AddText("Mục tiêu đã bị Khác nhân hộ tống đi rồi!")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText(missionName)
            self:AddText(missionInfo)
            self:DisplayBonus(missionIndex)
            self:EndEvent()
            self:DispatchMissionInfo(selfId, targetId, missionIndex, missionId)
        end
    end
end

function event_husong:OnEnumerate(caller, selfId, targetId,missionIndex, index)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local nLevel, nMis1, nMis2, nMis3 = self:TGetCheckInfo(missionIndex)
    if nLevel > self:GetLevel(selfId) then
        return
    end
    if nMis1 > 0 then
        if not self:IsMissionHaveDone(selfId, nMis1) then
            return
        end
    end
    if nMis2 > 0 then
        if not self:IsMissionHaveDone(selfId, nMis2)  then
            return
        end
    end
    if nMis3 > 0 then
        if not self:IsMissionHaveDone(selfId, nMis3)  then
            return
        end
    end
    if self:IsMissionHaveDone(selfId, missionId) then
        return
    elseif self:IsHaveMission(selfId, missionId) then
        local completeNpcScene, completeNpcName = self:TGetCompleteNpcInfo(missionIndex)
        local targetNpcScene, targetNpcName = self:TGetTargetNpcInfo(missionIndex)
        if self:GetName(targetId) == completeNpcName then
            caller:AddNumTextWithTarget(missionIndex, missionName, 1, -1)
        elseif self:GetName(targetId) == targetNpcName then
            if self:GetPatrolId(targetId) ~= define.INVAILD_ID then
                return
            end
            caller:AddNumTextWithTarget(missionIndex, missionName, 1, 3)
        end
    elseif self:CheckAccept(selfId, missionIndex) > 0 then
        local acceptNpcScene, acceptNpcName = self:TGetAcceptNpcInfo(missionIndex)
        if self:GetName(targetId) == acceptNpcName then
            caller:AddNumTextWithTarget(missionIndex, missionName, 1, -1)
        end
    end
end

function event_husong:OnLockedTarget(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local missionName = self:TGetMissionName(missionIndex)
    local nscene1, name1 = self:TGetCompleteNpcInfo(missionIndex)
    local nscene2, name2 = self:TGetTargetNpcInfo(missionIndex)
    local targetName = self:GetName(targetId)
    if targetName == name1 then
        self:TAddNumText(missionIndex, missionName, 1, -1)
    elseif targetName == name2 then
        if self:GetMissionParam(selfId, misIndex, 0)== 1  then
            return
        end
        if self:GetPatrolId(targetId) ~= -1 then
            return
        end
        --self:TAddNumText(missionIndex, missionName,1,3);
    end
end

function event_husong:CheckAccept(selfId, missionIndex)
    local nLevel = self:LuaFnGetLevel(selfId)
    local limitLevel, PreMisId1, PreMisId2, PreMisId3 = self:TGetCheckInfo(missionIndex)
    if nLevel < limitLevel then
        self:TAddText("Giang hồ lịch duyệt của ngươi còn thấp, e rằng không thể đảm đương nổi, đợi" .. tostring(limitLevel) .. "cấp sau hãy đến tìm ta!")
        self:TDispatchEventList(selfId)
        return 0
    else
        local a = {}
        local index = 1
        if PreMisId1 > 0 then
            a[index] = PreMisId1
            index    = index + 1
        end
        if PreMisId2 > 0 then
            a[index] = PreMisId2
            index    = index + 1
        end
        if PreMisId3 > 0 then
            a[index] = PreMisId3
            index    = index + 1
        end
        for i, v in pairs(a) do
            if not self:IsMissionHaveDone(selfId, v)  then
                return 0
            end
        end
        return 1
    end
end

function event_husong:OnAccept(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:IsMissionHaveDone(selfId, missionId) then
        return
    end
    local ret = self:AddMission(selfId, missionId, missionIndex, 0, 0, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, 0)
    local nscene1, name1 = self:TGetAcceptNpcInfo(missionIndex)
    local nscene2, name2 = self:TGetCompleteNpcInfo(missionIndex)
    local nscene3, name3 = self:TGetTargetNpcInfo(missionIndex)
    if name1 ~= name2 or name1 ~= name3 then
        self:SetMissionEvent(selfId, missionId, 4)
    end
    if name1 == name3 then
        local x, z = self:GetWorldPos(targetId)
        self:SetMissionByIndex(selfId, misIndex, 7)
        self:SetMissionByIndex(selfId, misIndex, 2, targetId)
        self:SetMissionByIndex(selfId, misIndex, 3, x)
        self:SetMissionByIndex(selfId, misIndex, 4, z)
        local targetNpcScene, targetNpcName = self:TGetTargetNpcInfo(missionIndex)
        local targetName = self:GetName(targetId)
        if targetNpcScene ~= self:get_scene_id() or targetNpcName ~= targetName then
            return 0
        end
        local oldAIType = self:GetNPCAIType(targetId)
        local oldUnitReputationId = self:GetUnitReputationID(selfId, targetId)
        local patrolPathIndex = self:TGetHusongPatrolPath(missionIndex)
        self:SetUnitReputationID(selfId, targetId, 0)
        self:SetMonsterFightWithNpcFlag(targetId, 1)
        self:SetNPCAIType(targetId, self:TGetHusongAIType(missionIndex))
        self:SetPatrolId(targetId, patrolPathIndex)
        self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetPatrolID", -1)
        self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetBaseAIType", 0, -1, oldAIType)
        self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetReputationID_CodingRefix", oldUnitReputationId)
        self:AddNpcPatrolEndPointOperator(targetId, "AIS_SetMonsterFightWithNpcFlag", 0)
        self:StartMissionTimer(selfId, missionId)
        self:SetMissionEvent(selfId, missionId, 5)
        self:SetMissionEvent(selfId, missionId, 6)
    end
    self:Msg2Player(selfId, "#Y Tiếp nhận nhiệm vụ" .. tostring(missionName), define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:BeginEvent(self.script_id)
    local strText = "#Y Tiếp nhận nhiệm vụ " .. tostring(missionName)
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_husong:OnAbandon(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local targetScene = self:GetMissionParam(selfId, misIndex, 7)
    local targetId = self:GetMissionParam(selfId, misIndex, 2)
    local x = self:GetMissionParam(selfId, misIndex, 3)
    local z = self:GetMissionParam(selfId, misIndex, 4)
    self:StopMissionTimer(selfId, missionId)
    self:DelMission(selfId, missionId)
    self:SetPos(targetId, x, z)
    self:SetPatrolId(targetId, define.INVAILD_ID)
end

function event_husong:OnContinue(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, missionInfo, missionContinue, missionComplete = self:TGetMissionDesc(missionIndex)
    self:BeginEvent(self.script_id)
    self:AddText(missionName)
    self:AddText(missionComplete)
    self:AddText("#{M_MUBIAO}#r")
    self:AddText(missionTarget)
    self:DisplayBonus(missionIndex)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, missionIndex, missionId)
end

function event_husong:CheckSubmit(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local bComplete = self:GetMissionParam(selfId, misIndex, 0)
    if bComplete > 0 then
        return 1
    else
        return 0
    end
end

function event_husong:OnSubmit(selfId, targetId, selectRadioId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:CheckSubmit(selfId, missionIndex) <= 0 then
        return
    end
    if self:IsHaveMission(selfId, missionId) then
        local nAddItemNum = 0
        self:BeginAddItem()
        local itemCt
        local a = { { ["id"] = -1, ["ct"] = 0 }
        , { ["id"] = -1, ["ct"] = 0 }
        , { ["id"] = -1, ["ct"] = 0 }
        , { ["id"] = -1, ["ct"] = 0 }
        , { ["id"] = -1, ["ct"] = 0 }
        }
        itemCt, a[1].id, a[1].ct,
        a[2].id, a[2].ct,
        a[3].id, a[3].ct,
        a[4].id, a[4].ct,
        a[5].id, a[5].ct  = self:TGetAwardItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
            end
        end
        itemCt, a[1].id, a[1].ct,
        a[2].id, a[2].ct,
        a[3].id, a[3].ct,
        a[4].id, a[4].ct,
        a[5].id, a[5].ct  = self:TGetRadioItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 and a[i]["id"] == selectRadioId then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
                break
            end
        end
        itemCt, a[1].id, a[1].ct,
        a[2].id, a[2].ct,
        a[3].id, a[3].ct,
        a[4].id, a[4].ct,
        a[5].id, a[5].ct  = self:TGetHideItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
            end
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            if nAddItemNum > 0 then
                self:AddItemListToHuman(selfId)
            end
            local awardMoney = self:TGetAwardMoney(missionIndex)
            self:AddMoneyJZ(selfId, awardMoney)
            local awardExp = self:TGetAwardExp(missionIndex)
            self:LuaFnAddExp(selfId, awardExp)
            self:DelMission(selfId, missionId)
            self:MissionCom(selfId, missionId)
            local strText = "#Y" .. missionName .. "Nhiệm vụ đã hoàn thành."
            self:BeginEvent(self.script_id)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            local NextMissIndex = self:GetNextMissionIndex(missionIndex)
            for i, MissType in pairs(self.g_MissionTypeList) do
                if MissType["ScriptId"] ~= nil and MissType["ScriptId"] ~= 0 then
                    if NextMissIndex and NextMissIndex >= MissType["StartIdx"] and NextMissIndex <= MissType["EndIdx"] then
                        local missionId = self:TGetMissionIdByIndex(NextMissIndex)
                        local szNpcName = self:GetName(targetId)
                        local AcceptNpcScene, AcceptNpcName = self:TGetAcceptNpcInfo(NextMissIndex)
                        if self:get_scene_id() == AcceptNpcScene and szNpcName == AcceptNpcName then
                            if MissType["ScriptId"] == 006671 then
                                if not self:IsHaveMission(selfId, missionId) then
                                    self:OnDefaultEvent(selfId, targetId, NextMissIndex)
                                end
                            else
                                if not self:IsHaveMission(selfId, missionId) then
                                    self:CallScriptFunction(MissType["ScriptId"], "OnDefaultEvent", selfId, targetId,
                                        NextMissIndex,selectRadioId)
                                end
                            end
                        end
                        break
                    end
                end
            end
        else
            self:BeginEvent(self.script_id)
            self:AddText("Túi đã đầy, không thể hoàn thành nhiệm vụ")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function event_husong:OnHumanDie(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local targetScene = self:GetMissionParam(selfId, misIndex, 7)
    local targetId = self:GetMissionParam(selfId, misIndex, 2)
    local x = self:GetMissionParam(selfId, misIndex, 3)
    local z = self:GetMissionParam(selfId, misIndex, 4)
    self:StopMissionTimer(selfId, missionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 2)
    self:ResetMissionEvent(selfId, missionId, 4)
    self:ResetMissionEvent(selfId, missionId, 5)
    self:ResetMissionEvent(selfId, missionId, 6)
    self:SetPos(targetId, x, z)
    self:SetPatrolId(targetId, define.INVAILD_ID)
    local targetscene, targetname = self:TGetTargetNpcInfo(missionIndex)
    self:BeginEvent(self.script_id)
    self:AddText("Hộ tống" .. targetname .. "Thất bại")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_husong:OnTimer(selfId, missionIndex)
    local playerX, playerZ = self:GetWorldPos(selfId)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local targetScene = self:GetMissionParam(selfId, misIndex, 7)
    local targetId = self:GetMissionParam(selfId, misIndex, 2)
    local targetX, targetZ = self:GetWorldPos(targetId)
    local old_x = self:GetMissionParam(selfId, misIndex, 3)
    local old_z = self:GetMissionParam(selfId, misIndex, 4)
    local distance = math.floor(math.sqrt((playerX - targetX) * (playerX - targetX) +
    (playerZ - targetZ) * (playerZ - targetZ)))
    local isTargetObjLive = self:LuaFnIsCharacterLiving(targetId)
    local patrolPathIndex = self:TGetHusongPatrolPath(missionIndex)
    local x, z = self:GetLastPatrolPoint(patrolPathIndex)
    local targetscene, targetname = self:TGetTargetNpcInfo(missionIndex)
    if self:get_scene_id() ~= targetscene then
        self:StopMissionTimer(selfId, missionId)
        self:ResetMissionEvent(selfId, missionId, 4)
        self:ResetMissionEvent(selfId, missionId, 5)
        self:ResetMissionEvent(selfId, missionId, 6)
        self:SetMissionByIndex(selfId, misIndex, 0, 2)
        self:SetPos(targetId, old_x, old_z)
        self:SetPatrolId(targetId, define.INVAILD_ID)
        self:BeginEvent(self.script_id)
        self:AddText("Hộ tống" .. targetname .. "Thất bại")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local distance2 = math.floor(math.sqrt((targetX - x) * (targetX - x) + (targetZ - z) * (targetZ - z)))
    if distance2 <= 2 then
        self:StopMissionTimer(selfId, missionId)
        self:ResetMissionEvent(selfId, missionId, 5)
        self:ResetMissionEvent(selfId, missionId, 6)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
        self:SetPos(targetId, old_x, old_z)
        self:SetPatrolId(targetId, define.INVAILD_ID)
        self:BeginEvent(self.script_id)
        self:AddText("Hộ tống" .. targetname .. "Thành công")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local bfailed = 0
    if not isTargetObjLive then
        bfailed = 1
    elseif self:get_scene_id() ~= targetScene or distance > 20 then
        bfailed = 1
    end
    if bfailed == 1 then
        self:StopMissionTimer(selfId, missionId)
        self:ResetMissionEvent(selfId, missionId, 4)
        self:ResetMissionEvent(selfId, missionId, 5)
        self:ResetMissionEvent(selfId, missionId, 6)
        self:SetMissionByIndex(selfId, misIndex, 0, 2)
        self:SetPos(targetId, old_x, old_z)
        self:SetPatrolId(targetId, define.INVAILD_ID)
        self:BeginEvent(self.script_id)
        self:AddText("Hộ tống" .. targetname .. "Thất bại")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

return event_husong
