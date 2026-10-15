local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4053 = class("item_4053", script_base)
item_4053.script_id = 334053
item_4053.g_Impact1 = 34053
item_4053.g_Impact2 = -1
function item_4053:OnDefaultEvent(selfId, bagIndex)
end

function item_4053:IsSkillLikeScript(selfId)
    return 1
end

function item_4053:CancelImpacts(selfId)
    return 0
end

function item_4053:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4053:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4053:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4053:OnActivateEachTick(selfId)
    return 1
end

return item_4053
