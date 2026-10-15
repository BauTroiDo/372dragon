local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_30505075 = class("item_30505075", script_base)
item_30505075.script_id = 332000
item_30505075.g_Impact1 = 3004
item_30505075.g_Impact2 = -1
function item_30505075:OnDefaultEvent(selfId, bagIndex)
end

function item_30505075:IsSkillLikeScript(selfId)
    return 1
end

function item_30505075:CancelImpacts(selfId)
    return 0
end

function item_30505075:OnConditionCheck(selfId)
    local sceneId = self:get_scene_id()
    if sceneId ~= 5 then
        return 0
    end
    local targetX, targetZ
    targetX = 268
    targetZ = 241
    local nPlayerX, nPlayerZ = self:GetWorldPos(selfId)
    local fDis =
        math.floor(math.sqrt((targetX - nPlayerX) * (targetX - nPlayerX) + (targetZ - nPlayerZ) * (targetZ - nPlayerZ)))
    local msg
    if fDis > 5 then
        msg = "Chỉ có thể tiến hành luyện chế ở gần Kính Hồ (268,241)."
        self:NotifyTip(selfId, msg)
        return 0
    end
    local nItemBagIndex = self:GetBagPosByItemSn(selfId, 40004414)
    if nItemBagIndex >= 0 then
        local nStartTime = self:GetBagItemParam(selfId, nItemBagIndex, 4, 2)
        local nCurTime = self:LuaFnGetCurrentTime()
        local nDelta = nCurTime - nStartTime
        if nDelta >= 4 * 60 * 60 then
            self:DelItem(selfId, 40004414, 1)
            local msg = "Đã quá thời hạn hữu hiệu!"
            self:NotifyTip(selfId, msg)
            return 0
        end
    end
    local actId = 36
    local LianYaoStatus = self:GetActivityParam(actId, 0)
    if LianYaoStatus <= 0 then
        self:DelItem(selfId, 40004414, 1)
        local msg = "Đã quá 22:00 không thể trồng trọt, tiên thảo đã biến mất."
        self:NotifyTip(selfId, msg)
        return 0
    end
    local QianNianCaoGen = self:GetActivityParam(actId, 1)
    if QianNianCaoGen <= 0 then
        return 0
    end
    local YaoDing_LianYao_Status = self:GetActivityParam(actId, 2)
    if YaoDing_LianYao_Status > 0 then
        return 0
    end
    msg = "#{JingHu_LingYao_01}"
    self:BeginUICommand()
    self:UICommand_AddInt(self.g_scriptId)
    self:UICommand_AddInt(1)
    self:UICommand_AddStr("DoUseItemReal")
    self:UICommand_AddStr(msg)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 24)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 0
end

function item_30505075:DoUseItemReal(selfId, param1, param2)
    local sceneId = self:get_scene_id()
    if sceneId ~= 5 then
        return 0
    end
    local nItemBagIndex = self:GetBagPosByItemSn(selfId, 40004414)
    if nItemBagIndex >= 0 then
        local targetX, targetZ
        targetX = 268
        targetZ = 241
        local nPlayerX, nPlayerZ = self:GetWorldPos(selfId)
        local fDis =
            math.floor(
            math.sqrt((targetX - nPlayerX) * (targetX - nPlayerX) + (targetZ - nPlayerZ) * (targetZ - nPlayerZ))
        )
        if fDis > 5 then
            local msg
            msg = "Chỉ có thể tiến hành luyện chế ở gần Kính Hồ (268,241)."
            self:NotifyTip(selfId, msg)
            return 0
        end
        local nStartTime = self:GetBagItemParam(selfId, nItemBagIndex, 4, 2)
        local nCurTime = self:LuaFnGetCurrentTime()
        local nDelta = nCurTime - nStartTime
        if nDelta >= 4 * 60 * 60 then
            self:DelItem(selfId, 40004414, 1)
            local msg = "Đã quá thời hạn hữu hiệu!"
            self:NotifyTip(selfId, msg)
            return 0
        end
        local szTransfer = self:GetBagItemTransfer(selfId, nItemBagIndex)
        local message = string.format("#{JingHu_LingYao_02}#{_INFOMSG%s}#{JingHu_LingYao_03}", szTransfer)
        self:BroadMsgByChatPipe(selfId, message, 4)
        self:DelItem(selfId, 40004414, 1)
        local nPlayerX, nPlayerZ = self:GetWorldPos(selfId)
        nPlayerX = nPlayerX + 1
        nPlayerZ = nPlayerZ + 1
        local MonsterId = self:LuaFnCreateMonster(881, nPlayerX, nPlayerZ, 3, -1, 502000)
        self:SetCharacterDieTime(MonsterId, 1000 * 60 * 60)
        local nCurTime = self:LuaFnGetCurrentTime()
        local actId = 36
        self:SetActivityParam(actId, 4, nCurTime)
        self:SetActivityParam(actId, 2, 1)
        local selfGUID = self:LuaFnGetGUID(selfId)
        self:SetActivityParam(actId, 3, selfGUID)
        local szPlayerName = self:LuaFnGetName(selfId)
        local JINGHU_YAODING_CREATER_NAME = szPlayerName
        self:SetActivityParam(actId, 5, MonsterId)
        self:DelItem(selfId, 40004415, 1)
        if self:TryRecieveItem(selfId, 40004415, 1) then
            local nItemBagIndex = self:GetBagPosByItemSn(selfId, 40004415)
            self:SetBagItemParam(selfId, nItemBagIndex, 3, 2, nCurTime)
        end
    end
end

function item_30505075:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_30505075:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_30505075:OnActivateEachTick(selfId)
    return 1
end

function item_30505075:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_30505075
