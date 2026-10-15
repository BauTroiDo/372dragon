local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_332104 = class("item_332104", script_base)
item_332104.script_id = 332104
item_332104.g_MaxValue = 100000
item_332104.g_IncPerAct = 1500
function item_332104:OnDefaultEvent(selfId, bagIndex)
end

function item_332104:IsSkillLikeScript(selfId)
    return 1
end

function item_332104:CancelImpacts(selfId)
    return 0
end

function item_332104:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local PlayerHP = self:GetHp(selfId)
    local PlayerMaxHP = self:GetMaxHp(selfId)
    if PlayerHP == PlayerMaxHP then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_332104:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_332104:OnActivateOnce(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local UseValue = self:GetBagItemParam(selfId, bagId, 8, 2)
    local ValidValue = self.g_MaxValue - UseValue
    local PlayerHP = self:GetHp(selfId)
    local PlayerMaxHP = self:GetMaxHp(selfId)
    local NeedHP = PlayerMaxHP - PlayerHP
    if self.g_IncPerAct < NeedHP then
        NeedHP = self.g_IncPerAct
    end
    if PlayerHP == PlayerMaxHP then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
    else
        local nCB = ValidValue
        local nHPB = PlayerHP
        local bErased = -1
        if NeedHP >= ValidValue then
            self:IncreaseHp(selfId, ValidValue)
            self:SetBagItemParam(selfId, bagId, 4, 2, self.g_MaxValue)
            self:SetBagItemParam(selfId, bagId, 8, 2, self.g_MaxValue)
            bErased = self:EraseItem(selfId, bagId)
        else
            self:IncreaseHp(selfId, NeedHP)
            self:SetBagItemParam(selfId, bagId, 4, 2, self.g_MaxValue)
            self:SetBagItemParam(selfId, bagId, 8, 2, UseValue + self.g_IncPerAct)
            if (self.g_MaxValue == (UseValue + self.g_IncPerAct)) then
                bErased = self:EraseItem(selfId, bagId)
            end
        end
        local szName = self:GetName(selfId)
        local nGuid = self:LuaFnGetGUID(selfId)
        local nHPA = self:GetHp(selfId)
        if bErased < 0 then
            local szLog = "Use31000006, Tên=%s, Guid=%d, Lượng thuốc trước khi dùng=%d, Lượng thuốc sau khi dùng=%d, HP trước khi dùng=%d, HP sau khi dùng=%d, Vị trí trong túi=%d"
            local UseValue_log = self:GetBagItemParam(selfId, bagId, 8, 2)
            local nCA = self.g_MaxValue - UseValue_log
            local szDebugLog = string.format(szLog, szName, nGuid, nCB, nCA, nHPB, nHPA, bagId)
            self:WriteDebugLog(selfId, szDebugLog)
        else
            local szLog = "Use31000006, Tên=%s, Guid=%d, Lượng thuốc trước khi dùng=%d, Đã bị xóa, HP trước khi dùng=%d, HP sau khi dùng=%d, Vị trí trong túi=%d"
            local szDebugLog = string.format(szLog, szName, nGuid, nCB, nHPB, nHPA, bagId)
            self:WriteDebugLog(selfId, szDebugLog)
        end
    end
    self:LuaFnRefreshItemInfo(selfId, bagId)
    return 1
end

function item_332104:OnActivateEachTick(selfId)
    return 1
end

function item_332104:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_332104
