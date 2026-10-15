local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4920 = class("item_4920", script_base)
item_4920.script_id = 334920
item_4920.g_Impact1 = 4920
item_4920.g_Impact2 = -1
function item_4920:OnDefaultEvent(selfId, bagIndex)
end

function item_4920:IsSkillLikeScript(selfId)
    return 1
end

function item_4920:CancelImpacts(selfId)
    return 0
end

function item_4920:OnConditionCheck(selfId)
    if self:CallScriptFunction(050009, "IsItemValid", selfId) == 0 then
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4920:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4920:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4920:OnActivateEachTick(selfId)
    return 1
end

return item_4920
