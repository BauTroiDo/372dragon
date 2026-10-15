local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4231 = class("item_4231", script_base)
item_4231.script_id = 334231
item_4231.g_Impact1 = 34231
item_4231.g_Impact2 = -1
function item_4231:OnDefaultEvent(selfId, bagIndex)
end

function item_4231:IsSkillLikeScript(selfId)
    return 1
end

function item_4231:CancelImpacts(selfId)
    return 0
end

function item_4231:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4231:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4231:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4231:OnActivateEachTick(selfId)
    return 1
end

return item_4231
