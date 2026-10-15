local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_songxin = class("event_songxin", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
event_songxin.script_id = 006668
event_songxin.g_duanyanqiId = 002016
event_songxin.g_IsMissionOkFail = 0
event_songxin.g_SongXinFlag = 1
event_songxin.g_StrForePart = 5
event_songxin.g_MissionTypeList = { { ["StartIdx"] = 1000000, ["EndIdx"] = 1009999, ["ScriptId"] = 006666 }
, { ["StartIdx"] = 1010000, ["EndIdx"] = 1019999, ["ScriptId"] = 006668 }
, { ["StartIdx"] = 1020000, ["EndIdx"] = 1029999, ["ScriptId"] = 006669 }
, { ["StartIdx"] = 1030000, ["EndIdx"] = 1039999, ["ScriptId"] = 006667 }
, { ["StartIdx"] = 1050000, ["EndIdx"] = 1059999, ["ScriptId"] = 006671 }
}
function event_songxin:GetTNpcStoreLoc(selfId, targetId, missionIndex)
    local _, _, isTargetDynamic = self:TGetTargetNpcInfo(missionIndex)
    if not isTargetDynamic then
        return -1
    end
    return self.g_StrForePart
end

function event_songxin:GetTargetNpcId(selfId, targetId, missionIndex)
    local loc = self:GetTNpcStoreLoc(selfId, targetId, missionIndex)
    if loc == -1 then
        return -1
    end
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    return self:GetMissionParam(selfId, misIndex, loc)
end

function event_songxin:GetTItemStoreLoc(selfId, targetId, missionIndex)
    local ItemCount, _, _, _, _, _, _, _, _, _, _, _, _, Item, Count, bGiveFlag = self:TGetSongXinInfo(missionIndex)
    if not Item then
        return -1
    end
    local nOffset = 0
    if self:GetTNpcStoreLoc(selfId, targetId, missionIndex) ~= -1 then
        nOffset = nOffset + 1
    end
    return self.g_StrForePart + nOffset
end

function event_songxin:GetTargetItemIndex(selfId, targetId, missionIndex)
    local loc = self:GetTItemStoreLoc(selfId, targetId, missionIndex)
    if loc == -1 then
        return -1
    end
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    return self:GetMissionParam(selfId, misIndex, loc)
end

function event_songxin:TakeOutMissionItem(selfId, missionIndex)
    local ItemCount = 0
    local item, count, bGiveFlag = 1, 2, 3
    local mi = { { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    }
    local itemList = {}
    ItemCount, mi[1][1], mi[1][2], mi[1][3],
    mi[2][1], mi[2][2], mi[2][3],
    mi[3][1], mi[3][2], mi[3][3],
    mi[4][1], mi[4][2], mi[4][3],
    mi[5][1], mi[5][2], mi[5][3] = self:TGetSongXinInfo(missionIndex)
    if ItemCount > 0 then
        if mi[5][item] > 0 then
            mi[5][item] = self:GetOneMissionItem(mi[5][item])
            table.insert(itemList, { mi[5][item], mi[5][count] }
            )
            ItemCount = ItemCount - 1
        end
        for i = 1, ItemCount do
            table.insert(itemList, { mi[i][item], mi[i][count] }
            )
        end
        for i = 1, #(itemList) do
            if itemList[i][item] > 0 then
                if self:LuaFnGetAvailableItemCount(selfId, itemList[i][item]) < itemList[i][count] then
                    return 0
                end
            end
        end
        for i = 1, #(itemList) do
            if itemList[i][item] > 0 then
                self:LuaFnDelAvailableItem(selfId, itemList[i][item], itemList[i][count])
            end
        end
    end
    return 1
end
 
function event_songxin:OnDefaultEvent(selfId, targetId, missionIndex)
    print("shimen_missionIndex = ",missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local _, missionInfo, missionContinue = self:TGetMissionDesc(missionIndex)
    local npcId = -1
    local itemIndex = -1
    if self:IsHaveMission(selfId, missionId) then
        local _, targetNPCName, isTargetDynamic, targetDuologue = self:TGetTargetNpcInfo(missionIndex)
        local _, completeNpcName = self:TGetCompleteNpcInfo(missionIndex)
        local szNpcName = self:GetName(targetId)
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        if targetNPCName ~= completeNpcName then
            local bAchieveMission = 0
            if not isTargetDynamic or isTargetDynamic ~= 1 then
                if szNpcName == targetNPCName then
                    bAchieveMission = 1
                end
            else
                npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
                local _, strNpcName = self:GetNpcInfoByNpcId(npcId)
                if strNpcName == szNpcName then
                    bAchieveMission = 1
                end
            end
            if bAchieveMission == 1 then
                if self:TakeOutMissionItem(selfId, missionIndex) == 1 then
                    local strText = self:CallScriptFunction(006672, "GetRandomDuologue", missionIndex, targetDuologue)
                    if strText ~= "" then
                        itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
                        strText = self:CallScriptFunction(006672, "FormatDuologue", selfId, strText, npcId, itemIndex, "")
                        self:NotifyFailBox(selfId, targetId, strText)
                    end
                    if (missionIndex >= 1010243 and missionIndex <= 1010250) or (missionIndex >= 1010402 and missionIndex <= 1010409) or (missionIndex >= 1018000 and missionIndex <= 1018033) or (missionIndex >= 1018050 and missionIndex <= 1018084) or (missionIndex >= 1018100 and missionIndex <= 1018155) or (missionIndex >= 1018200 and missionIndex <= 1018235) or (missionIndex >= 1018300 and missionIndex <= 1018311) or (missionIndex >= 1018350 and missionIndex <= 1018352) or (missionIndex >= 1018360 and missionIndex <= 1018367) or (missionIndex >= 1018400 and missionIndex <= 1018455) or (missionIndex >= 1018500 and missionIndex <= 1018504) or (missionIndex >= 1018530 and missionIndex <= 1018541) or (missionIndex >= 1018560 and missionIndex <= 1018566) then
                        self:BeginEvent(self.script_id)
                        self:AddText("Mục tiêu nhiệm vụ đã đạt được!")
                        self:EndEvent()
                        self:DispatchMissionTips(selfId)
                    end
                    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 1)
                    return
                end
            end
        elseif self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) ~= 1 then
            if self:TakeOutMissionItem(selfId, missionIndex) == 1 then
                self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 1)
            end
        end
        if completeNpcName == szNpcName then
            local bHaveContinue = self:TIsHaveContinue(missionIndex)
            if bHaveContinue <= 0 then
                self:OnContinue(selfId, targetId, missionIndex)
            else
                local bDone = self:CheckSubmit(selfId, missionIndex)
                npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
                itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
                self:BeginEvent(self.script_id)
                self:AddText(missionName)
                self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionContinue, npcId, itemIndex,
                    ""))
                self:EndEvent()
                self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
            end
        end
    elseif self:CallScriptFunction(006672, "CheckAccept", selfId, missionIndex) > 0 then
        local _, acceptNpcName = self:TGetAcceptNpcInfo(missionIndex)
        if acceptNpcName == "" then
            if self:OnAccept(selfId, targetId, missionIndex) ~= 1 then
                return
            end
            npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
            itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
        end
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionInfo, npcId, itemIndex, ""))
        self:CallScriptFunction(006672, "DisplayBonus", self, missionIndex, selfId)
        self:EndEvent()
        if acceptNpcName == "" then
            self:DispatchEventList(selfId, targetId)
        else
            self:DispatchMissionInfo(selfId, targetId, missionIndex, missionId)
        end
    end
end

function event_songxin:OnEnumerate(caller, selfId, targetId, arg, index)
    self:CallScriptFunction(006672, "DoEnumerate", caller, selfId, targetId, arg)
end

function event_songxin:OnLockedTarget(selfId, targetId, missionIndex)
    local targetNpcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
    local targetNPCName
    if targetNpcId ~= -1 then
        _, targetNPCName = self:GetNpcInfoByNpcId(targetNpcId)
    else
        _, targetNPCName = self:TGetTargetNpcInfo(missionIndex)
    end
    local szNpcName = self:GetName(targetId)
    local _, completeNpcName = self:TGetCompleteNpcInfo(missionIndex)
    if szNpcName == targetNPCName then
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        if completeNpcName ~= targetNPCName and self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail) == 1 then
            return
        end
        self:SetMissionByIndex(selfId, misIndex, self.g_SongXinFlag, 1)
    end
    if szNpcName == targetNPCName or szNpcName == completeNpcName then
        local missionName = self:TGetMissionName(missionIndex)
        self:BeginEvent(missionIndex)
        if self:TIsMissionRoundable(missionIndex) then
            self:TAddNumText(missionIndex, missionName, 4, -1)
        else
            self:TAddNumText(missionIndex, missionName, 2, -1)
        end
        self:TDispatchEventList(selfId, targetId)
    end
end

function event_songxin:OnAccept(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local ItemCount = 0
    if self:IsMissionHaveDone(selfId, missionId) and not self:TIsMissionRoundable(missionIndex) then
        return 0
    end
    if self:CallScriptFunction(006672, "CheckAccept", selfId, missionIndex) <= 0 then
        return 0
    end
    local strText
    if self:GetMissionCount(selfId) >= 20 then
        strText = "#YNhật ký nhiệm vụ của ngươi đã đầy."
        self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return 0
    end
    local item, count, bGiveFlag = 1, 2, 3
    local mi = { { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    }
    ItemCount, mi[1][1], mi[1][2], mi[1][3],
    mi[2][1], mi[2][2], mi[2][3],
    mi[3][1], mi[3][2], mi[3][3],
    mi[4][1], mi[4][2], mi[4][3],
    mi[5][1], mi[5][2], mi[5][3] = self:TGetSongXinInfo(missionIndex)
    local give_item
    local bAddItem = 0
    if ItemCount > 0 then
        self:BeginAddItem()
        if mi[5][item] > 0 then
            mi[5][item] = self:GetOneMissionItem(mi[5][item])
            if mi[5][bGiveFlag] > 0 then
                self:AddItem(mi[5][item], mi[5][count])
                bAddItem = 1
                give_item = mi[5][item]
            end
            ItemCount = ItemCount - 1
        end
        for i = 1, ItemCount do
            if mi[i][bGiveFlag] > 0 then
                self:AddItem(mi[i][item], mi[i][count])
                bAddItem = 1
                give_item = mi[i][item]
            end
        end
        if bAddItem > 0 then
            local ret = self:EndAddItem(selfId)
            if not ret then
                strText = "#YTúi nhiệm vụ của ngươi đã đầy."
                self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                return 0
            end
        end
    end
    local ret = self:AddMission(selfId, missionId, missionIndex, 0, 0, 0)
    if not ret then
        return 0
    end
    self:SetMissionEvent(selfId, missionId, 4)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local targetNpcStoreLocation, itemStoreLocation
    local _, targetNPCName, isTargetDynamic = self:TGetTargetNpcInfo(missionIndex)
    targetNpcStoreLocation = self:GetTNpcStoreLoc(selfId, targetId, missionIndex)
    if targetNpcStoreLocation ~= -1 then
        local nNpcId, _, _, nScene, nPosX, nPosZ = self:GetOneMissionNpc(tonumber(targetNPCName))
        nNpcId = nNpcId or define.INVAILD_ID
        self:SetMissionByIndex(selfId, misIndex, targetNpcStoreLocation, nNpcId)
    end
    itemStoreLocation = self:GetTItemStoreLoc(selfId, targetId, missionIndex)
    if itemStoreLocation ~= -1 then
        give_item = give_item or define.INVAILD_ID
        self:SetMissionByIndex(selfId, misIndex, itemStoreLocation, give_item)
    end
    if bAddItem > 0 then
        self:AddItemListToHuman(selfId)
    end
    strText = "#Y Tiếp nhận nhiệm vụ" .. missionName
    self:Msg2Player(selfId, strText, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    return 1
end

function event_songxin:OnAbandon(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local ItemCount = 0
    local item, count, bGiveFlag = 1, 2, 3
    local mi = { { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    , { -1, 0, 0 }
    }
    ItemCount, mi[1][1], mi[1][2], mi[1][3],
    mi[2][1], mi[2][2], mi[2][3],
    mi[3][1], mi[3][2], mi[3][3],
    mi[4][1], mi[4][2], mi[4][3],
    mi[5][1], mi[5][2], mi[5][3] = self:TGetSongXinInfo(missionIndex)
    if ItemCount > 0 then
        if mi[5][item] > 0 then
            mi[5][item] = self:GetOneMissionItem(mi[5][item])
            self:LuaFnDelAvailableItem(selfId, mi[5][item], mi[5][count])
            ItemCount = ItemCount - 1
        end
        for i = 1, ItemCount do
            if mi[i][item] > 0 then
                self:LuaFnDelAvailableItem(selfId, mi[i][item], mi[i][count])
            end
        end
    end
    self:CallScriptFunction(006672, "PunishRelationShip", selfId, missionIndex)
    self:CallScriptFunction(006672, "AcceptTimeLimit", selfId, missionIndex)
    self:DelMission(selfId, missionId)
end

function event_songxin:OnContinue(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, _, _, missionComplete = self:TGetMissionDesc(missionIndex)
    local npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
    local itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
    self:BeginEvent(self.script_id)
    self:AddText(missionName)
    local ret = self:CallScriptFunction(self.g_duanyanqiId, "NPCTalkOnFirstSubmission", selfId, missionIndex, 0)
    if ret == 0 then
        self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionComplete, npcId, itemIndex, ""))
        self:AddText("#{M_MUBIAO}#r")
        self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionTarget, npcId, itemIndex, ""))
        self:CallScriptFunction(006672, "DisplayBonus", self, missionIndex, selfId)
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, missionIndex, missionId)
end

function event_songxin:CheckSubmit(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local bComplete = self:GetMissionParam(selfId, misIndex, self.g_IsMissionOkFail)
    if bComplete == 1 then
        return 1
    else
        return 0
    end
end

function event_songxin:OnSubmit(selfId, targetId, selectRadioId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:IsHaveMission(selfId, missionId) then
        if self:CheckSubmit(selfId, missionIndex) ~= 1 then
            return 0
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
        mi[5][1], mi[5][2] = self:TGetAwardItem(missionIndex)
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
        if awardMoney > 0 then
            self:AddMoneyJZ(selfId, awardMoney)
        end
        local awardExp = self:TGetAwardExp(missionIndex)
        if awardExp > 0 then
            self:LuaFnAddExp(selfId, awardExp)
        end
        self:CallScriptFunction(006672, "RewardRelationShip", selfId, missionIndex, targetId)
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
                        if MissType["ScriptId"] == 006668 then
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

function event_songxin:OnKillObject(selfId, objdataId, objId, missionIndex)
end

function event_songxin:OnItemChanged(selfId, itemdataId)
end

function event_songxin:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function event_songxin:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return event_songxin
