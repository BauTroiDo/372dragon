local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4121 = class("item_4121", script_base)
item_4121.script_id = 334121
item_4121.g_Impact1 = 34121
item_4121.g_Impact2 = -1
function item_4121:OnDefaultEvent(selfId, bagIndex)
end

function item_4121:IsSkillLikeScript(selfId)
    return 1
end

function item_4121:CancelImpacts(selfId)
    return 0
end

function item_4121:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4121:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4121:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4121:OnActivateEachTick(selfId)
    return 1
end

return item_4121
