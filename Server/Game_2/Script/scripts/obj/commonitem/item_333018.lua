local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_333018 = class("item_333018", script_base)
item_333018.script_id = 333018
item_333018.g_MinValue = 1000
item_333018.g_MaxHPValue = 0
item_333018.g_MaxUseCount = 20
item_333018.g_HPValuePer = 0.1
function item_333018:OnDefaultEvent(selfId, bagIndex)
end

function item_333018:IsSkillLikeScript(selfId)
    return 1
end

function item_333018:CancelImpacts(selfId)
    return 0
end

function item_333018:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local PlayerHP = self:GetHp(selfId)
    local PlayerMaxHP = self:GetMaxHp(selfId)
    if PlayerHP >= PlayerMaxHP then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function item_333018:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_333018:OnActivateOnce(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local UseValue = self:GetBagItemParam(selfId, bagId, 8, 2)
    local ValidValue = self.g_MaxUseCount - UseValue
    local PlayerHP = self:GetHp(selfId)
    local PlayerMaxHP = self:GetMaxHp(selfId)
    local NeedHP = math.floor(PlayerMaxHP * self.g_HPValuePer)
    local IsDelete = 0
    if NeedHP < self.g_MinValue then
        NeedHP = self.g_MinValue
    end
    if PlayerHP >= PlayerMaxHP then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    if bagId >= 0 then
        if UseValue >= self.g_MaxUseCount then
            return 0
        end
        local CurValue = UseValue + 1
        self:IncreaseHp(selfId, NeedHP)
        self:SetBagItemParam(selfId, bagId, 4, 2, self.g_MaxUseCount)
        self:SetBagItemParam(selfId, bagId, 8, 2, CurValue)
        local CheckParam1 = self:GetBagItemParam(selfId, bagId, 4, 2)
        local CheckParam2 = self:GetBagItemParam(selfId, bagId, 8, 2)
        if CheckParam1 ~= self.g_MaxUseCount then
            return 0
        end
        if CheckParam2 ~= CurValue then
            return 0
        end
        self:LuaFnRefreshItemInfo(selfId, bagId)
        if CurValue >= self.g_MaxUseCount then
            local bErased = self:EraseItem(selfId, bagId)
            IsDelete = 1
            if bErased < 0 then
                local strMsg = "Yêu cầu Tiên Thiên Quy Tâm Đan"
                self:ShowNotice(selfId, strMsg)
                return 0
            end
        end
        local szName = self:GetName(selfId)
        local nGuid = self:LuaFnGetGUID(selfId)
        local szLog = "Use31000004, tên=%s, Guid=%0X, Dược lượng trước khi dùng=%d, Dược lượng còn lại=%d, HP trước khi dùng=%d, HP sau khi dùng=%d, Vị trí túi=%d, Đã bị xóa hay chưa=%d"
        local UseValue_log = self.g_MaxUseCount - CurValue
        local PlayerNowHP = self:GetHp(selfId)
        local szDebugLog =
            string.format(szLog, szName, nGuid, ValidValue, UseValue_log, PlayerHP, PlayerNowHP, bagId, IsDelete)
        self:WriteDebugLog(selfId, szDebugLog)
    else
        local strMsg = "Yêu cầu Tiên Thiên Quy Tâm Đan"
        self:ShowNotice(selfId, strMsg)
        return 0
    end
    return 1
end

function item_333018:OnActivateEachTick(selfId)
    return 1
end

function item_333018:ShowNotice(selfId, strNotice)
    self:BeginEvent(self.script_id)
    self:AddText(strNotice)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_333018
