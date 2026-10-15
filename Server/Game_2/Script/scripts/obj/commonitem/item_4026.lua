local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4026 = class("item_4026", script_base)
item_4026.script_id = 334026
item_4026.g_Impact1 = 34026
item_4026.g_Impact2 = -1
function item_4026:OnDefaultEvent(selfId, bagIndex)
end

function item_4026:IsSkillLikeScript(selfId)
    return 1
end

function item_4026:CancelImpacts(selfId)
    return 0
end

function item_4026:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4026:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4026:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4026:OnActivateEachTick(selfId)
    return 1
end

return item_4026
