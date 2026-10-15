local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4924 = class("item_4924", script_base)
item_4924.script_id = 334924
item_4924.g_Impact = -1
function item_4924:OnDefaultEvent(selfId, bagIndex)
end

function item_4924:IsSkillLikeScript(selfId)
    return 1
end

function item_4924:CancelImpacts(selfId)
    return 0
end

function item_4924:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4924:OnDeplete(selfId)
    return 1
end

function item_4924:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact, 0)
    end
    self:CallScriptFunction(600042, "OnItemUse", selfId, self.script_id)
    return 1
end

function item_4924:OnActivateEachTick(selfId)
    return 1
end

return item_4924
