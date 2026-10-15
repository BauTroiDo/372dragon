local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4822 = class("item_4822", script_base)
item_4822.script_id = 334822
item_4822.g_Impact1 = 34822
item_4822.g_Impact2 = -1
function item_4822:OnDefaultEvent(selfId, bagIndex)
end

function item_4822:IsSkillLikeScript(selfId)
    return 1
end

function item_4822:CancelImpacts(selfId)
    return 0
end

function item_4822:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4822:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4822:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4822:OnActivateEachTick(selfId)
    return 1
end

return item_4822
