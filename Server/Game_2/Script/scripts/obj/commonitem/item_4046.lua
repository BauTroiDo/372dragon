local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4046 = class("item_4046", script_base)
item_4046.script_id = 334046
item_4046.g_Impact1 = 34046
item_4046.g_Impact2 = -1
function item_4046:OnDefaultEvent(selfId, bagIndex)
end

function item_4046:IsSkillLikeScript(selfId)
    return 1
end

function item_4046:CancelImpacts(selfId)
    return 0
end

function item_4046:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4046:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4046:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4046:OnActivateEachTick(selfId)
    return 1
end

return item_4046
