local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_shaguai = class("event_shaguai", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
event_shaguai.script_id = 006666
event_shaguai.g_duanyanqiId = 002016
event_shaguai.g_IsMissionOkFail = 0
event_shaguai.g_MissionTypeList = { { ["StartIdx"] = 1000000, ["EndIdx"] = 1009999, ["ScriptId"] = 006666 }
, { ["StartIdx"] = 1010000, ["EndIdx"] = 1019999, ["ScriptId"] = 006668 }
, { ["StartIdx"] = 1020000, ["EndIdx"] = 1029999, ["ScriptId"] = 006669 }
, { ["StartIdx"] = 1030000, ["EndIdx"] = 1039999, ["ScriptId"] = 006667 }
, { ["StartIdx"] = 1050000, ["EndIdx"] = 1059999, ["ScriptId"] = 006671 }
}
function event_shaguai:OnDefaultEvent(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, missionInfo, missionContinue = self:TGetMissionDesc(missionIndex)
    if self:IsHaveMission(selfId, missionId) then
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(missionContinue)
        self:AddText("#{M_MUBIAO}#r")
        self:AddText("  " .. missionTarget)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId, missionIndex)
        self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
    elseif self:CallScriptFunction(006672, "CheckAccept", selfId, missionIndex) > 0 then
        local _, acceptNpcName = self:TGetAcceptNpcInfo(missionIndex)
        if acceptNpcName == "" then
            if self:OnAccept(selfId, targetId, missionIndex) ~= 1 then
                return
            end
        end
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(missionInfo)
        self:AddText("#{M_MUBIAO}#r")
        self:AddText("  " .. missionTarget)
        self:CallScriptFunction(006672, "DisplayBonus", self, missionIndex)
        self:EndEvent()
        if acceptNpcName == "" then
            self:DispatchEventList(selfId, targetId)
        else
            self:DispatchMissionInfo(selfId, targetId, missionIndex, missionId)
        end
    end
end

function event_shaguai:OnEnumerate(caller, selfId, targetId, arg, index)
    self:CallScriptFunction(006672, "DoEnumerate", caller, selfId, targetId, arg)
end

function event_shaguai:OnAccept(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:IsMissionHaveDone(selfId, missionId) and not self:TIsMissionRoundable(missionIndex) then
        return 0
    end
    if self:CallScriptFunction(006672, "CheckAccept", selfId, missionIndex) <= 0 then
        return 0
    end
    local ret = self:AddMission(selfId, missionId, missionIndex, 1, 0, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
    local nscene1, name1 = self:TGetAcceptNpcInfo(missionIndex)
    local nscene2, name2 = self:TGetCompleteNpcInfo(missionIndex)
    if name1 ~= name2 then
        self:SetMissionEvent(selfId, missionId, 4)
    end
    local killDataCt = 0
    local a = { { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    }
    killDataCt, a[1].name, a[1].ct,
    a[2].name, a[2].ct,
    a[3].name, a[3].ct,
    a[4].name, a[4].ct,
    a[5].name, a[5].ct
    = self:TGetKillInfo(missionIndex)
    print(killDataCt, a[1]["name"], a[1]["ct"], a[2]["name"], a[2]["ct"], a[3]["name"], a[3]["ct"], a[4]["name"],
        a[4]["ct"], a[5]["name"], a[5]["ct"])
    for i = 1, killDataCt do
        if a[i]["name"] ~= "" then
            self:SetMissionByIndex(selfId, misIndex, i, 0)
        end
    end
    self:Msg2Player(selfId, "#Y Tiếp nhận nhiệm vụ" .. missionName, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    return 1
end

function event_shaguai:OnAbandon(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    self:CallScriptFunction(006672, "PunishRelationShip", selfId, missionIndex)
    self:CallScriptFunction(006672, "AcceptTimeLimit", selfId, missionIndex)
    self:DelMission(selfId, missionId)
end

function event_shaguai:OnContinue(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, _, _, missionComplete = self:TGetMissionDesc(missionIndex)
    self:BeginEvent(self.script_id)
    self:AddText(missionName)
    self:AddText(missionComplete)
    self:AddText("#{M_MUBIAO}#r")
    self:AddText(missionTarget)
    self:CallScriptFunction(006672, "DisplayBonus", self, missionIndex, selfId)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, missionIndex, missionId)
end

function event_shaguai:CheckSubmit(selfId, missionIndex)
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

function event_shaguai:OnSubmit(selfId, targetId, selectRadioId, missionIndex)
    if self:CheckSubmit(selfId, missionIndex) > 0 then
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        local missionName = self:TGetMissionName(missionIndex)
        if not self:IsHaveMission(selfId, missionId) then
            return
        end
        local ItemCount, nAddItemNum = 0, 0
        local item, count = 1, 2
        local mi = { { -1, 0 }
        , { -1, 0 }
        , { -1, 0 }
        , { -1, 0 }
        , { -1, 0 }
        }
        self:BeginAddItem()
        ItemCount, mi[1][1], mi[1][2],
        mi[2][1], mi[2][2],
        mi[3][1], mi[3][2],
        mi[4][1], mi[4][2],
        mi[5][1], mi[5][2]
        = self:TGetAwardItem(missionIndex)
        if ItemCount > 0 then
            for i = 1, ItemCount do
                if mi[i][item] > 0 then
                    self:AddItem(mi[i][item], mi[i][count])
                    nAddItemNum = nAddItemNum + 1
                end
            end
        end
        ItemCount, mi[1][1], mi[1][2],
        mi[2][1], mi[2][2],
        mi[3][1], mi[3][2],
        mi[4][1], mi[4][2],
        mi[5][1], mi[5][2] = self:TGetRadioItem(missionIndex)
        if ItemCount > 0 then
            for i = 1, ItemCount do
                if mi[i][item] > 0 and mi[i][item] == selectRadioId then
                    self:AddItem(mi[i][item], mi[i][count])
                    nAddItemNum = nAddItemNum + 1
                    break
                end
            end
        end
        ItemCount, mi[1][1], mi[1][2],
        mi[2][1], mi[2][2],
        mi[3][1], mi[3][2],
        mi[4][1], mi[4][2],
        mi[5][1], mi[5][2] = self:TGetHideItem(missionIndex)
        if ItemCount > 0 then
            for i = 1, ItemCount do
                if mi[i][item] > 0 then
                    self:AddItem(mi[i][item], mi[i][count])
                    nAddItemNum = nAddItemNum + 1
                end
            end
        end
        if self:CallScriptFunction(self.g_duanyanqiId, "OnAddRewards", selfId, missionIndex) == 1 then
            nAddItemNum = nAddItemNum + 1
        end
        local ret = self:EndAddItem(selfId)
        if not ret then
            self:NotifyFailTips(selfId, "Túi đã đầy, không thể hoàn thành nhiệm vụ")
            return
        end
        if nAddItemNum > 0 then
            self:AddItemListToHuman(selfId)
        end
        local awardMoney = self:TGetAwardMoney(missionIndex)
        if awardMoney then
            self:AddMoneyJZ(selfId, awardMoney, missionId, missionIndex)
        end
        local awardExp = self:TGetAwardExp(missionIndex)
        if awardExp then
            self:LuaFnAddExp(selfId, awardExp)
        end
        self:CallScriptFunction(006672, "RewardRelationShip", selfId, missionIndex)
        local mdLocation, _, _ = self:TGetRelationShipAwardInfo(missionIndex)
        if mdLocation == ScriptGlobal.MD_RELATION_AZHU then
            self:CallScriptFunction(005001, "OnModEvent_Submit", selfId, targetId, missionIndex)
        elseif mdLocation == ScriptGlobal.MD_RELATION_DUANYANQING then
            self:CallScriptFunction(self.g_duanyanqiId, "OnMissionSubmitionSuccess", selfId, targetId, missionIndex)
        elseif mdLocation == ScriptGlobal.MD_RELATION_MUWANQING then
            self:CallScriptFunction(002010, "OnModEvent_Submit", selfId, targetId, missionIndex)
        end
        self:DelMission(selfId, missionId)
        self:MissionCom(selfId, missionId)
        local strText = "#Y" .. missionName .. "Nhiệm vụ đã hoàn thành."
        self:NotifyFailTips(selfId, strText)
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        self:CallScriptFunction(888888, "PlaySoundEffect", selfId, 66)
        local NextMissIndex = self:GetNextMissionIndex(missionIndex)
        for i, MissType in pairs(self.g_MissionTypeList) do
            if MissType["ScriptId"] ~= nil and MissType["ScriptId"] ~= 0 then
                if NextMissIndex and NextMissIndex >= MissType["StartIdx"] and NextMissIndex <= MissType["EndIdx"] then
                    local missionId = self:TGetMissionIdByIndex(NextMissIndex)
                    local szNpcName = self:GetName(targetId)
                    local AcceptNpcScene, AcceptNpcName = self:TGetAcceptNpcInfo(NextMissIndex)
                    if self:get_scene_id() == AcceptNpcScene and szNpcName == AcceptNpcName then
                        if MissType["ScriptId"] == 006666 then
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
    end
end

function event_shaguai:OnKillObject(selfId, objdataId, objId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local killDataCount
    local a = { { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    , { ["name"] = "", ["ct"] = 0 }
    }
    killDataCount, a[1].name, a[1].ct,
    a[2].name, a[2].ct,
    a[3].name, a[3].ct,
    a[4].name, a[4].ct,
    a[5].name, a[5].ct = self:TGetKillInfo(missionIndex)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    for i = 1, killDataCount do
        if monsterName == a[i]["name"] then
            local num = self:GetNearHumanCount(objId)
            for j = 1, num do
                local humanObjId = self:GetNearHuman(objId, j)
                if self:IsHaveMission(humanObjId, missionId) then
                    local misIndex = self:GetMissionIndexByID(humanObjId, missionId)
                    if  self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then
                        local ct = self:GetMissionParam(humanObjId, misIndex, i)
                        if ct < a[i]["ct"] then
                            self:SetMissionByIndex(humanObjId, misIndex, i, ct + 1)
                            self:BeginEvent(self.script_id)
                            local strText = string.format("Đã tiêu diệt %s%d/%d", a[i]["name"], ct + 1, a[i]["ct"])
                            self:AddText(strText)
                            self:EndEvent()
                            self:DispatchMissionTips(humanObjId)
                        end
                        local IsOk = 1
                        if ct + 1 == a[i]["ct"] then
                            for j = 1, killDataCount do
                                local ct1 = self:GetMissionParam(humanObjId, misIndex, j)
                                if ct1 < a[j]["ct"] then
                                    IsOk = 0
                                end
                            end
                            if IsOk == 1 then
                                self:SetMissionByIndex(humanObjId, misIndex, self.g_IsMissionOkFail, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end

function event_shaguai:OnLockedTarget(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local szNpcName = self:GetName(targetId)
    local nScene, szName = self:TGetCompleteNpcInfo(missionIndex)
    if szNpcName == szName then
        if self:TIsMissionRoundable(missionIndex) then
            self:TAddNumText(missionIndex, missionName, 4, -1)
        else
            self:TAddNumText(missionIndex, missionName, 2, -1)
        end
        self:TDispatchEventList(selfId, targetId)
        return 1
    end
    return 0
end

function event_shaguai:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return event_shaguai
