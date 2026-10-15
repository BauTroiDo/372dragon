local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8507 = class("item_8507", script_base)
item_8507.script_id = 338507
item_8507.g_levelRequire = 1
item_8507.g_radiusAE = 3.0
item_8507.g_standFlag = 1
item_8507.g_effectCount = 4
item_8507.g_Impact1 = 8507
item_8507.g_Impact2 = -1
function item_8507:OnDefaultEvent(selfId, bagIndex)
end

function item_8507:IsSkillLikeScript(selfId)
    return 1
end

function item_8507:CancelImpacts(selfId)
    return 0
end

function item_8507:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
    end
    return 1
end

function item_8507:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_8507:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
        end
    end
    return 1
end

function item_8507:OnActivateEachTick(selfId)
    return 1
end

return item_8507
