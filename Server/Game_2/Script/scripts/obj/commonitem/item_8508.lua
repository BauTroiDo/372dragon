local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8508 = class("item_8508", script_base)
item_8508.script_id = 338508
item_8508.g_levelRequire = 1
item_8508.g_radiusAE = 3.0
item_8508.g_standFlag = 1
item_8508.g_effectCount = 4
item_8508.g_Impact1 = 8508
item_8508.g_Impact2 = -1
function item_8508:OnDefaultEvent(selfId, bagIndex)
end

function item_8508:IsSkillLikeScript(selfId)
    return 1
end

function item_8508:CancelImpacts(selfId)
    return 0
end

function item_8508:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
    end
    return 1
end

function item_8508:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_8508:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
        end
    end
    return 1
end

function item_8508:OnActivateEachTick(selfId)
    return 1
end

return item_8508
