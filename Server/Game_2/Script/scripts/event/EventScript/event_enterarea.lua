local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_enterarea = class("event_enterarea", script_base)
event_enterarea.script_id = 006669
event_enterarea.g_MissionTypeList = {
    {["StartIdx"] = 1000000, ["EndIdx"] = 1009999, ["ScriptId"] = 006666},
    {["StartIdx"] = 1010000, ["EndIdx"] = 1019999, ["ScriptId"] = 006668},
    {["StartIdx"] = 1020000, ["EndIdx"] = 1029999, ["ScriptId"] = 006669},
    {["StartIdx"] = 1030000, ["EndIdx"] = 1039999, ["ScriptId"] = 006667},
    {["StartIdx"] = 1050000, ["EndIdx"] = 1059999, ["ScriptId"] = 006671}
}
function event_enterarea:DisplayBonus(missionIndex)
    local itemCt
    local a = {
        {["id"] = -1, ["ct"] = 0}, {["id"] = -1, ["ct"] = 0},
        {["id"] = -1, ["ct"] = 0}, {["id"] = -1, ["ct"] = 0},
        {["id"] = -1, ["ct"] = 0}
    }
    itemCt = self:TGetAwardItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then self:AddItemBonus(a[i]["id"], a[i]["ct"]) end
    end
    itemCt = self:TGetRadioItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            self:AddRadioItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    itemCt = self:TGetHideItem(missionIndex)
    for i = 1, itemCt do
        if a[i]["id"] > 0 then
            self:AddRandItemBonus(a[i]["id"], a[i]["ct"])
        end
    end
    local awardMoney = self:TGetAwardMoney(missionIndex)
    self:AddMoneyBonus(awardMoney)
end

function event_enterarea:OnDefaultEvent(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local _, missionInfo, missionContinue = self:TGetMissionDesc(missionIndex)
    if self:IsHaveMission(selfId, missionId) then
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(missionContinue)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId, missionIndex)
        self:DispatchMissionDemandInfo(selfId, targetId, missionIndex, missionId, bDone)
    elseif self:CheckAccept(selfId, missionIndex) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(missionName)
        self:AddText(missionInfo)
        self:DisplayBonus(missionIndex)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, missionIndex, missionId)
    end
end

function event_enterarea:OnEnumerate(selfId, targetId, missionIndex, index)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local nLevel, nMis1, nMis2, nMis3 = self:TGetCheckInfo(missionIndex)
    if nLevel > self:GetLevel(selfId) then return end
    if nMis1 >= 0 then
        if not self:IsMissionHaveDone(selfId, nMis1) then return end
    end
    if nMis2 >= 0 then
        if not self:IsMissionHaveDone(selfId, nMis2) then return end
    end
    if nMis3 >= 0 then
        if not self:IsMissionHaveDone(selfId, nMis3) then return end
    end
    if self:IsMissionHaveDone(selfId, missionId) then
        return
    elseif self:IsHaveMission(selfId, missionId) then
        local _, completeNpcName = self:TGetCompleteNpcInfo(missionIndex)
        if self:GetName(targetId) == completeNpcName then
            self:TAddNumText(missionIndex, missionName, 2, -1)
            self:TEndEvent()
            self:TDispatchEventList(selfId, targetId)
        end
    elseif self:CheckAccept(selfId, missionIndex) > 0 then
        local _, acceptNpcName = self:TGetAcceptNpcInfo(missionIndex)
        if self:GetName(targetId) == acceptNpcName then
            self:TAddNumText(missionIndex, missionName, 1, -1)
            self:TEndEvent()
            self:TDispatchEventList(selfId, targetId)
        end
    end
end

function event_enterarea:CheckAccept(selfId, missionIndex)
    local nLevel = self:GetLevel(selfId)
    local limitLevel, PreMisId1, PreMisId2, PreMisId3 = self:TGetCheckInfo(missionIndex)
    if nLevel < limitLevel then
        self:TAddText("Giang hồ lịch duyệt của ngươi còn thấp, e rằng không thể đảm đương nổi, đợi" .. tostring(limitLevel) .. "cấp sau đó hãy đến tìm ta")
        self:TEndEvent()
        self:TDispatchEventList(selfId)
        return 0
    else
        local a = {}
        local index = 1
        if PreMisId1 > 0 then
            a[index] = PreMisId1
            index = index + 1
        end
        if PreMisId2 > 0 then
            a[index] = PreMisId2
            index = index + 1
        end
        if PreMisId3 > 0 then
            a[index] = PreMisId3
            index = index + 1
        end
        for i, v in pairs(a) do
            if not self:IsMissionHaveDone(selfId, v) then return 0 end
        end
        return 1
    end
end

function event_enterarea:OnAccept(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    if self:IsMissionHaveDone(selfId, missionId) then return end
    if self:CheckAccept(selfId, missionIndex) <= 0 then return end
    local ret = self:AddMission(selfId, missionId, missionIndex, 0, 1, 0)
    if not ret then
        self:Msg2Player(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy",
                        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        return
    end
    self:Msg2Player(selfId, "#Y Tiếp nhận nhiệm vụ" .. tostring(missionName),
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:BeginEvent(self.script_id)
    local strText = "#Y Tiếp nhận nhiệm vụ " .. tostring(missionName)
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_enterarea:OnAbandon(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    self:DelMission(selfId, missionId)
end

function event_enterarea:OnContinue(selfId, targetId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local missionTarget, _, _, missionComplete = self:TGetMissionDesc(missionIndex)
    self:BeginEvent(self.script_id)
    self:AddText(missionName)
    self:AddText(missionComplete)
    self:AddText("#{M_MUBIAO}#r")
    self:AddText(missionTarget)
    self:DisplayBonus(missionIndex)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, missionIndex, missionId)
end

function event_enterarea:CheckSubmit(selfId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local enterAreaCount = self:TGetEnterAreaInfo(missionIndex)
    for i = 1, enterAreaCount do
        local misIndex = self:GetMissionIndexByID(selfId, missionId)
        local num0 = self:GetMissionParam(selfId, misIndex, i - 1)
        if num0 < 1 then return 0 end
    end
    return 1
end

function event_enterarea:OnSubmit(selfId, targetId, selectRadioId, missionIndex)
    if self:CheckSubmit(selfId, missionIndex) > 0 then
        local missionId = self:TGetMissionIdByIndex(missionIndex)
        local missionName = self:TGetMissionName(missionIndex)
        if not self:IsHaveMission(selfId, missionId) then return end
        local nAddItemNum = 0
        self:BeginAddItem()
        local itemCt
        local a = {
            {["id"] = -1, ["ct"] = 0}, {["id"] = -1, ["ct"] = 0},
            {["id"] = -1, ["ct"] = 0}, {["id"] = -1, ["ct"] = 0},
            {["id"] = -1, ["ct"] = 0}
        }
        itemCt = self:TGetAwardItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
            end
        end
        itemCt = self:TGetRadioItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 and a[i]["id"] == selectRadioId then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
                break
            end
        end
        itemCt = self:TGetHideItem(missionIndex)
        for i = 1, itemCt do
            if a[i]["id"] > 0 then
                self:AddItem(a[i]["id"], a[i]["ct"])
                nAddItemNum = nAddItemNum + 1
            end
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            if nAddItemNum > 0 then self:AddItemListToHuman(selfId) end
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
            self:Msg2Player(selfId, strText,
                            define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
            local NextMissIndex = self:GetNextMissionIndex(missionIndex)
            for i, MissType in pairs(self.g_MissionTypeList) do
                if MissType["ScriptId"] ~= nil and MissType["ScriptId"] ~= 0 then
                    if NextMissIndex and NextMissIndex >= MissType["StartIdx"] and
                        NextMissIndex <= MissType["EndIdx"] then
                        local missionId =
                            self:TGetMissionIdByIndex(NextMissIndex)
                        local szNpcName = self:GetName(targetId)
                        local AcceptNpcScene, AcceptNpcName =
                            self:TGetAcceptNpcInfo(NextMissIndex)
                        if self:get_scene_id() == AcceptNpcScene and szNpcName ==
                            AcceptNpcName then
                            if MissType["ScriptId"] == 006669 then
                                if not self:IsHaveMission(selfId, missionId) then
                                    self:OnDefaultEvent(selfId, targetId,
                                                        NextMissIndex)
                                end
                            else
                                if not self:IsHaveMission(selfId, missionId) then
                                    self:CallScriptFunction(
                                        MissType["ScriptId"], "OnDefaultEvent",
                                        selfId, targetId, NextMissIndex,
                                        selectRadioId)
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

function event_enterarea:OnKillObject(selfId, objdataId, objId, missionIndex) end

function event_enterarea:OnItemChanged(selfId, targetId, itemdataId) end

function event_enterarea:OnEnterArea(selfId, areaId, missionIndex)
    local missionId = self:TGetMissionIdByIndex(missionIndex)
    local missionName = self:TGetMissionName(missionIndex)
    local enterAreaCount = 0
    local a = {
        {["scene"] = 0, ["ea"] = 0}, {["scene"] = 0, ["ea"] = 0},
        {["scene"] = 0, ["ea"] = 0}
    }
    enterAreaCount = self:TGetEnterAreaInfo(missionIndex)
    for i = 1, enterAreaCount do
        if self:get_scene_id() == a[i]["scene"] and areaId == a[i]["ea"] then
            local bHave = 0
            local szDesc = ""
            local szTip = ""
            bHave = self:TGetEnterAreaDesc(missionIndex)
            if bHave > 0 then
                self:BeginEvent(self.script_id)
                self:AddText(szDesc)
                self:EndEvent()
                self:DispatchEventList(selfId, selfId)
            end
            local misIndex = self:GetMissionIndexByID(selfId, missionId)
            local num0 = self:GetMissionParam(selfId, misIndex, 0)
            if num0 < 1 then
                self:SetMissionByIndex(selfId, misIndex, 0, 1)
                self:SetMissionByIndex(selfId, misIndex, 1, 1)
                self:BeginEvent(self.script_id)
                self:AddText(szTip)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    end
end

return event_enterarea
