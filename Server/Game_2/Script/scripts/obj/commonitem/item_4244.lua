local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4244 = class("item_4244", script_base)
item_4244.script_id = 334244
item_4244.g_Impact1 = 34244
item_4244.g_Impact2 = -1
function item_4244:OnDefaultEvent(selfId, bagIndex)
end

function item_4244:IsSkillLikeScript(selfId)
    return 1
end

function item_4244:CancelImpacts(selfId)
    return 0
end

function item_4244:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4244:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4244:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4244:OnActivateEachTick(selfId)
    return 1
end

return item_4244
