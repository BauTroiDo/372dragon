local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_3851 = class("item_3851", script_base)
item_3851.script_id = 333851
item_3851.g_Impact1 = 33851
item_3851.g_Impact2 = -1
function item_3851:OnDefaultEvent(selfId, bagIndex)
end

function item_3851:IsSkillLikeScript(selfId)
    return 1
end

function item_3851:CancelImpacts(selfId)
    return 0
end

function item_3851:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_3851:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_3851:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_3851:OnActivateEachTick(selfId)
    return 1
end

return item_3851
