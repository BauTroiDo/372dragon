local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4943 = class("item_4943", script_base)
item_4943.script_id = 334943
item_4943.g_Impact1 = 4943
item_4943.g_Impact2 = -1
function item_4943:OnDefaultEvent(selfId, bagIndex)
end

function item_4943:IsSkillLikeScript(selfId)
    return 1
end

function item_4943:CancelImpacts(selfId)
    return 0
end

function item_4943:OnConditionCheck(selfId)
    if self:CallScriptFunction(050009, "IsItemValid", selfId) == 0 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4943:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4943:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4943:OnActivateEachTick(selfId)
    return 1
end

return item_4943
