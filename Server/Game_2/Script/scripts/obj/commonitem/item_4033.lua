local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4033 = class("item_4033", script_base)
item_4033.script_id = 334033
item_4033.g_Impact1 = 34033
item_4033.g_Impact2 = -1
function item_4033:OnDefaultEvent(selfId, bagIndex)
end

function item_4033:IsSkillLikeScript(selfId)
    return 1
end

function item_4033:CancelImpacts(selfId)
    return 0
end

function item_4033:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4033:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4033:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4033:OnActivateEachTick(selfId)
    return 1
end

return item_4033
