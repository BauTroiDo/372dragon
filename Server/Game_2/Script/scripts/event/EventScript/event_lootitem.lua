local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_lootitem = class("event_lootitem", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
event_lootitem.script_id = 006667
event_lootitem.g_duanyanqiId = 002016
event_lootitem.g_StrForePart = 5
event_lootitem.g_IsMissionOkFail = 0
event_lootitem.g_MissionTypeList = { { ["StartIdx"] = 1000000, ["EndIdx"] = 1009999, ["ScriptId"] = 006666 }
, { ["StartIdx"] = 1010000, ["EndIdx"] = 1019999, ["ScriptId"] = 006668 }
, { ["StartIdx"] = 1020000, ["EndIdx"] = 1029999, ["ScriptId"] = 006669 }
, { ["StartIdx"] = 1030000, ["EndIdx"] = 1039999, ["ScriptId"] = 006667 }
, { ["StartIdx"] = 1050000, ["EndIdx"] = 1059999, ["ScriptId"] = 006671 }
}
function event_lootitem:GetTNpcStoreLoc(selfId, targetId, missionIndex)
    return -1
end

function event_lootitem:GetTargetNpcId(selfId, targetId, missionIndex)
    return -1
end

function event_lootitem:GetTItemStoreLoc(selfId, targetId, missionIndex)
    local _, _, dynamicFlag = self:TGetLootItemInfo(missionIndex)
    if dynamicFlag == 0 then
        return -1
    end
    local nOffset = 0
    if self:GetTNpcStoreLoc(selfId, targetId, missionIndex) ~= -1 then
        nOffset = nOffset + 1
    end
    return self.g_StrForePart + nOffset
end

function event_lootitem:GetTargetItemIndex(selfId, targetId, missionIndex)
    local loc = self:GetTItemStoreLoc(selfId, targetId, missionIndex)
    if loc == -1 then
        return -1
    end
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    return self:GetMissionParam(selfId, misIndex, loc)
end

function event_lootitem:OnDefaultEvent(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
     local missionName = self:TGetMissionName(missionIndex)
    local npcId = -1
    local itemIndex = -1
    local _, missionInfo, missionContinue = self:TGetMissionDesc(missionIndex)
    if self:IsHaveMission(selfId, missionId) then
        npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
        itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionContinue, npcId, itemIndex, ""))
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId, missionIndex)
        self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
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
            local _, _, dynamicFlag = self:TGetLootItemInfo(missionIndex)
            if dynamicFlag ~= 2 then
                self:DispatchEventList(selfId, targetId)
                local LogInfo = string.format("[XunWu]Old..Accept:( sceneId=%d, GUID=%0X ), missionIndex=%d",
                    self:LuaFnObjId2Guid(selfId), missionIndex)
                self:MissionLog(LogInfo)
            else
                local a, b, c, rowidx = self:TGetLootItemInfo(missionIndex)
                if rowidx < 1 then
                    return 0
                end
                local groupcnt = self:GetMissionGroupCount(rowidx)
                if groupcnt < 1 then
                    return 0
                end
                local groupid = math.random(groupcnt)
                if groupid < 1 then
                    return 0
                end
                local groupitemcnt = self:GetMissionItemCount(rowidx, groupid)
                if groupitemcnt < 1 then
                    return 0
                end
                local nitemid = 0
                local nitemname = 0
                local ItemNameList = ""
                for i = 1, groupitemcnt do
                    nitemid = self:GetMissionGroupItemID(rowidx, groupid, i - 1)
                    nitemname = self:GetItemName(nitemid)
                    ItemNameList = ItemNameList .. nitemname
                    if i ~= groupitemcnt then
                        ItemNameList = ItemNameList .. "、"
                    end
                end
                self:BeginEvent(self.script_id)
                self:AddText(missionName)
                self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionInfo, npcId, itemIndex,
                    ItemNameList))
                self:CallScriptFunction(006672, "DisplayBonus", missionIndex, selfId)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                local LogInfo = string.format(
                "[XunWu]New..Accept:( sceneId=%d, GUID=%0X ), missionIndex=%d, groupitemcnt=%d, groupid=%d, rowidx=%d",
                    self:LuaFnObjId2Guid(selfId), missionIndex, groupitemcnt, groupid, rowidx)
                self:MissionLog(LogInfo)
                local misIndex = self:GetMissionIndexByID(selfId, missionId)
                self:SetMissionByIndex(selfId, misIndex, 4, groupitemcnt)
                self:SetMissionByIndex(selfId, misIndex, 6, groupid)
                self:SetMissionByIndex(selfId, misIndex, 7, rowidx)
            end
        else
            self:DispatchMissionInfo(selfId, targetId, missionIndex, missionId)
        end
    end
end

function event_lootitem:OnEnumerate(caller, selfId, targetId, arg)
    self:CallScriptFunction(006672, "DoEnumerate", caller, selfId, targetId, arg)
end

function event_lootitem:OnAccept(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:IsMissionHaveDone(selfId, missionId) and not self:TIsMissionRoundable(missionIndex) then
        return 0
    end
    if self:CallScriptFunction(006672, "CheckAccept", selfId, missionIndex) <= 0 then
        return 0
    end
    local ret = self:AddMission(selfId, missionId, missionIndex, 1, 0, 1)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy.", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 0)
    local nscene1, name1 = self:TGetAcceptNpcInfo(missionIndex)
    local nscene2, name2 = self:TGetCompleteNpcInfo(missionIndex)
    if name1 ~= name2 then
        self:SetMissionEvent(selfId, missionId, 4)
    end
    local itemStoreLocation = self:GetTItemStoreLoc(selfId, targetId, missionIndex)
    if itemStoreLocation ~= -1 then
        local _, _, _, item = self:TGetLootItemInfo(missionIndex)
        item = self:GetOneMissionItem(item)
        self:SetMissionByIndex(selfId, misIndex, itemStoreLocation, item)
    end
    self:Msg2Player(selfId, "#Y Tiếp nhận nhiệm vụ" .. missionName, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    return 1
end

function event_lootitem:OnAbandon(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local a = { { ["name"] = "", ["flag"] = 0, ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    }
    local killDataCount
    killDataCount, a[1].name, a[1].flag, a[1].item, a[1].pro, a[1].ct,
    a[2].name, a[2].item, a[2].pro, a[2].ct,
    a[3].name, a[3].item, a[3].pro, a[3].ct,
    a[4].name, a[4].item, a[4].pro, a[4].ct,
    a[5].name, a[5].item, a[5].pro, a[5].ct = self:TGetLootItemInfo(missionIndex)
    local newItemIndex = self:GetTargetItemIndex(selfId, -1, missionIndex)
    if newItemIndex ~= -1 then
        a[1]["item"] = newItemIndex
    end
    for i = 1, killDataCount do
        self:DelItem(selfId, a[i]["item"], a[i]["ct"])
    end
    self:CallScriptFunction(006672, "PunishRelationShip", selfId, missionIndex)
    self:CallScriptFunction(006672, "AcceptTimeLimit", selfId, missionIndex)
    self:DelMission(selfId, missionId)
end

function event_lootitem:OnContinue(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, _, _, missionComplete = self:TGetMissionDesc(missionIndex)
    local npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
    local itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
    local _, _, dynamicFlag = self:TGetLootItemInfo(missionIndex)
    if dynamicFlag ~= 2 then
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        local ret = self:CallScriptFunction(self.g_duanyanqiId, "NPCTalkOnFirstSubmission", selfId, missionIndex, 0)
        if ret == 0 then
            self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionComplete, npcId, itemIndex, ""))
            self:AddText("#{M_MUBIAO}#r")
            self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionTarget, npcId, itemIndex, ""))
        end
        self:CallScriptFunction(006672, "DisplayBonus", self, missionIndex, selfId)
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId, targetId, missionIndex, missionId)
    else
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        if not self:IsHaveMission(selfId, missionId) then
            return 0
        end
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        local nitemcnt = self:GetMissionParam(selfId, misIndex, 4)
        local ngroupid = self:GetMissionParam(selfId, misIndex, 6)
        local nrowidx = self:GetMissionParam(selfId, misIndex, 7)
        if not nitemcnt or not ngroupid or not nrowidx then
            return 0
        end
        local nitemid = 0
        local nitemname = ""
        local ItemNameList = ""
        for i = 1, nitemcnt do
            nitemid = self:GetMissionGroupItemID(nrowidx, ngroupid, i - 1)
            nitemname = self:GetItemName(nitemid)
            ItemNameList = ItemNameList .. nitemname
            if i ~= nitemcnt then
                ItemNameList = ItemNameList .. "、"
            end
        end
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText("#{M_MUBIAO}#r")
        self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionTarget, npcId, itemIndex,
            ItemNameList))
        self:EndEvent()
        local bDone = 2
        self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
    end
end

function event_lootitem:CheckSubmit(selfId, missionIndex)
    local _, _, dynamicFlag = self:TGetLootItemInfo(missionIndex)
    if dynamicFlag ~= 2 then
        local a = { { ["name"] = "", ["flag"] = 0, ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
        , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
        , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
        , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
        , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
        }
        local killDataCount
        killDataCount, a[1].name, a[1].flag, a[1].item, a[1].pro, a[1].ct,
        a[2].name, a[2].item, a[2].pro, a[2].ct,
        a[3].name, a[3].item, a[3].pro, a[3].ct,
        a[4].name, a[4].item, a[4].pro, a[4].ct,
        a[5].name, a[5].item, a[5].pro, a[5].ct
        = self:TGetLootItemInfo(missionIndex)
        local newItemIndex = self:GetTargetItemIndex(selfId, -1, missionIndex)
        if newItemIndex ~= -1 then
            a[1]["item"] = newItemIndex
        end
        local bGetAllFlag = 1
        local nItemNum
        for i = 1, killDataCount do
            nItemNum = self:LuaFnGetAvailableItemCount(selfId, a[i]["item"])
            if a[i]["ct"] > nItemNum then
                bGetAllFlag = 0
            end
        end
        return bGetAllFlag
    else
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        if not self:IsHaveMission(selfId, missionId) then
            return 0
        end
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        local nitemcnt = self:GetMissionParam(selfId, misIndex, 4)
        local ngroupid = self:GetMissionParam(selfId, misIndex, 6)
        local nrowidx = self:GetMissionParam(selfId, misIndex, 7)
        if not nitemcnt or not ngroupid or not nrowidx then
            return 0
        end
        for i = 1, nitemcnt do
            local itemid = self:GetMissionGroupItemID(nrowidx, ngroupid, i - 1)
            local itemcnt = self:LuaFnGetAvailableItemCount(selfId, itemid)
            if itemcnt > 0 then
                return 1
            end
        end
        return 0
    end
end

function event_lootitem:OnSubmit(selfId, targetId, selectRadioId, missionIndex)
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
        mi[5][1], mi[5][2]
        = self:TGetRadioItem(missionIndex)
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
        local _, _, dynamicFlag = self:TGetLootItemInfo(missionIndex)
        if dynamicFlag ~= 2 then
            local a = { { ["name"] = "", ["flag"] = 0, ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
            , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
            , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
            , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
            , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
            }
            local killDataCount
            killDataCount, a[1].name, a[1].flag, a[1].item, a[1].pro, a[1].ct,
            a[2].name, a[2].item, a[2].pro, a[2].ct,
            a[3].name, a[3].item, a[3].pro, a[3].ct,
            a[4].name, a[4].item, a[4].pro, a[4].ct,
            a[5].name, a[5].item, a[5].pro, a[5].ct = self:TGetLootItemInfo(missionIndex)
            local newItemIndex = self:GetTargetItemIndex(selfId, -1, missionIndex)
            if newItemIndex ~= -1 then
                a[1]["item"] = newItemIndex
            end
            local sceneId = self:get_scene_id()
            local LogInfo = string.format("[XunWu]Old..Submit:( sceneId=%d, GUID=%0X ), missionIndex=%d", sceneId,
                self:LuaFnObjId2Guid(selfId), missionIndex)
            self:MissionLog(LogInfo)
            for i = 1, killDataCount do
                self:LuaFnDelAvailableItem(selfId, a[i]["item"], a[i]["ct"])
            end
        else
            local sceneId = self:get_scene_id()
            local LogInfo = string.format("[XunWu]New..Submit:( sceneId=%d, GUID=%0X ), missionIndex=%d, selectRadioId=%d", sceneId,
                self:LuaFnObjId2Guid(selfId), missionIndex, selectRadioId)
            self:MissionLog(LogInfo)
            local ItemType = self:GetItemClass(selectRadioId)
            local ItemPos = 0
            local startpos = 0
            while (ItemPos ~= -1) do
                ItemPos = self:LuaFnGetItemPosByItemDataID(selfId, selectRadioId, startpos)
                if not ItemPos then
                    break
                end
                startpos = ItemPos + 1
                if self:LuaFnIsItemAvailable(selfId, ItemPos) then
                    if ItemType then
                        if self:LuaFnIsJudgeApt(selfId, ItemPos) then
                            break
                        end
                    else
                        break
                    end
                end
            end
            if not ItemPos then
                self:NotifyFailTips(selfId, "Nhiệm vụ vật phẩm xóa thất bại, xin hãy nhận lại!")
                return 0
            end
            local isdelitem = 0
            if ItemType then
                isdelitem = self:EraseItem(selfId, ItemPos)
            else
                isdelitem = self:LuaFnDelAvailableItem(selfId, selectRadioId, 1)
            end
            if not isdelitem then
                self:NotifyFailTips(selfId, "Nhiệm vụ vật phẩm xóa thất bại, xin hãy nhận lại!")
                return 0
            end
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
                        if MissType["ScriptId"] == self.g_scriptId then
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

function event_lootitem:OnKillObject(selfId, objdataId, objId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    local a = { { ["name"] = "", ["flag"] = 0, ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    }
    local killDataCount = 0
    killDataCount, a[1].name, a[1].flag, a[1].item, a[1].pro, a[1].ct,
    a[2].name, a[2].item, a[2].pro, a[2].ct,
    a[3].name, a[3].item, a[3].pro, a[3].ct,
    a[4].name, a[4].item, a[4].pro, a[4].ct,
    a[5].name, a[5].item, a[5].pro, a[5].ct = self:TGetLootItemInfo(missionIndex)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    for i = 1, killDataCount do
        if monsterName == a[i]["name"] then
            local num = self:GetNearHumanCount(objId)
            for j = 1, num do
                local humanObjId = self:GetNearHuman(objId, j)
                if self:IsHaveMission(humanObjId, missionId) then
                    if self:GetItemCount(humanObjId, a[i]["item"]) < a[i]["ct"] then
                        local nPro = math.random(100)
                        if nPro <= a[i]["pro"] then
                            self:AddMonsterDropItem(objId, humanObjId, a[i]["item"])
                        end
                    end
                end
            end
        end
    end
end

function event_lootitem:OnItemChanged(selfId, itemdataId, missionIndex)
    local a = { { ["name"] = "", ["flag"] = 0, ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    , { ["name"] = "", ["item"] = 0, ["pro"] = 0, ["ct"] = 0 }
    }
    local killDataCount = 0
    killDataCount, a[1].name, a[1].flag, a[1].item, a[1].pro, a[1].ct,
    a[2].name, a[2].item, a[2].pro, a[2].ct,
    a[3].name, a[3].item, a[3].pro, a[3].ct,
    a[4].name, a[4].item, a[4].pro, a[4].ct,
    a[5].name, a[5].item, a[5].pro, a[5].ct = self:TGetLootItemInfo(missionIndex)
    local newItemIndex = self:GetTargetItemIndex(selfId, -1, missionIndex)
    if newItemIndex ~= -1 then
        a[1]["item"] = newItemIndex
    end
    local bGetAllFlag = 1
    local nItemNum, strText
    for i = 1, killDataCount do
        nItemNum = self:GetItemCount(selfId, a[i]["item"])
        if a[i]["ct"] > nItemNum then
            bGetAllFlag = 0
        end
        if itemdataId == a[i]["item"] then
            if a[i]["ct"] >= nItemNum then
                strText = string.format("Đã nhận #{_ITEM%s} %d/%d", a[i]["item"], nItemNum, a[i]["ct"])
                self:NotifyFailTips(selfId, strText)
            end
        end
    end
    if bGetAllFlag == 1 then
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        self:SetMissionByIndex(selfId, misIndex, self.g_IsMissionOkFail, 1)
    end
end

function event_lootitem:OnLockedTarget(selfId, targetId, missionIndex)
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

function event_lootitem:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_lootitem:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, petindex, missionIndex)
    if scriptId ~= self.g_scriptId then
        self:NotifyFailTips(selfId, "Nộp vật phẩm thất bại")
        return 0
    end
    local index = 0
    local ItemID = 0
    for i = 1, 3 do
        if i == 1 then
            index = index1
        elseif i == 2 then
            index = index2
        elseif i == 3 then
            index = index3
        else
            index = index1
        end
        if index < 100 then
            ItemID = self:LuaFnGetItemTableIndexByIndex(selfId, index)
            if not self:LuaFnIsItemAvailable(selfId, index) then
                break
            end
            local missionId = self:TGetMissionIdByIndex(missionIndex)
            if not self:IsHaveMission(selfId, missionId) then
                return 0
            end
            local misIndex = self:GetMissionIndexByID(selfId, missionId)
            local nitemcnt = self:GetMissionParam(selfId, misIndex, 4)
            local ngroupid = self:GetMissionParam(selfId, misIndex, 6)
            local nrowidx = self:GetMissionParam(selfId, misIndex, 7)
            if not nitemcnt or not ngroupid or not nrowidx then
                return 0
            end
            local submitcnt = 0
            local ItemNameList = ""
            for i = 1, nitemcnt do
                local nitemid = self:GetMissionGroupItemID(nrowidx, ngroupid, i - 1)
                local itemcnt = self:LuaFnGetAvailableItemCount(selfId, nitemid)
                local nitemname = self:GetItemName(nitemid)
                ItemNameList = ItemNameList .. nitemname
                if i ~= nitemcnt then
                    ItemNameList = ItemNameList .. "、"
                end
                if itemcnt > 0 and ItemID == nitemid then
                    submitcnt = submitcnt + 1
                end
            end
            if submitcnt > 0 then
                local ItemType = self:GetItemClass(ItemID)
                if ItemType == 1 then
                    if self:LuaFnIsJudgeApt(selfId, index) ~= 1 then
                        self:BeginEvent(self.script_id)
                        self:AddText("Trang bị này thuộc tính và tư chất còn chưa giám định a, có lẽ nó là một kiện #Gcực phẩm#W trên đời đó! Ta nào dám nhận trang bị quý trọng đến vậy a!")
                        self:EndEvent()
                        self:DispatchEventList(selfId, targetId)
                        return 0
                    end
                end
                local res = self:OnSubmit(selfId, targetId, ItemID, missionIndex)
                if res == 0 then
                    self:NotifyFailTips(selfId, "Nộp nhiệm vụ thất bại")
                    return 0
                end
                local missionName = self:TGetMissionName(missionIndex)
                local npcId = self:GetTargetNpcId(selfId, targetId, missionIndex)
                local missionTarget, _, _, missionComplete = self:TGetMissionDesc(missionIndex)
                local itemIndex = self:GetTargetItemIndex(selfId, targetId, missionIndex)
                self:BeginEvent(self.script_id)
                self:AddText(missionName)
                local ret = self:CallScriptFunction(self.g_duanyanqiId, "NPCTalkOnFirstSubmission", selfId, missionIndex,
                    1)
                if ret == 0 then
                    self:AddText(self:CallScriptFunction(006672, "FormatDuologue", selfId, missionComplete, npcId,
                        itemIndex, ""))
                end
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return 1
            else
                self:NotifyFailTips(selfId, "Nộp nhiệm vụ thất bại")
                self:BeginEvent(self.script_id)
                self:AddText("Vật phẩm này dường như không phải là thứ ta yêu cầu.")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return 0
            end
        end
    end
    self:NotifyFailTips(selfId, "Nộp vật phẩm thất bại")
    return 0
end

return event_lootitem
