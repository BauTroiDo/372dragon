local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3207 = class("item_3207", script_base)
item_3207.script_id = 333207
item_3207.g_levelRequire = 1
item_3207.g_radiusAE = 3.0
item_3207.g_standFlag = 1
item_3207.g_effectCount = 4
item_3207.g_Impact1 = 3207
item_3207.g_Impact2 = -1
function item_3207:OnDefaultEvent(selfId, bagIndex)
end

function item_3207:IsSkillLikeScript(selfId)
    return 1
end

function item_3207:CancelImpacts(selfId)
    return 0
end

function item_3207:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if (not self:LuaFnUnitIsFriend(selfId, targetId)) then
            self:SendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function item_3207:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3207:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
        end
    end
    return 1
end

function item_3207:OnActivateEachTick(selfId)
    return 1
end

return item_3207
