local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3172 = class("item_3172", script_base)
item_3172.script_id = 333172
item_3172.g_Impact1 = 3172
item_3172.g_Impact2 = -1
item_3172.g_DepletedMp = 80
function item_3172:OnDefaultEvent(selfId, bagIndex)
end

function item_3172:IsSkillLikeScript(selfId)
    return 1
end

function item_3172:CancelImpacts(selfId)
    return 0
end

function item_3172:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if (self.g_DepletedMp > self:GetMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_LACK_MANA)
        return 0
    end
    return 1
end

function item_3172:OnDeplete(selfId)
    if (self.g_DepletedMp > self:GetMp(selfId)) then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_LACK_MANA)
        return 0
    end
    self:IncreaseMp(selfId, -self.g_DepletedMp)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3172:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3172:OnActivateEachTick(selfId)
    return 1
end

return item_3172
