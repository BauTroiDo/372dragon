local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5005 = class("item_5005", script_base)
item_5005.g_petCommonId = define.PETCOMMON
item_5005.script_id = 335005
item_5005.g_HappinessValue = 5
function item_5005:IsSkillLikeScript(selfId)
    return 1
end

function item_5005:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5005:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5005:OnActivateOnce(selfId)
    if self.g_HappinessValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHappiness", selfId, self.g_HappinessValue)
    end
    return 1
end

function item_5005:OnActivateEachTick(selfId)
    return 1
end

function item_5005:CancelImpacts(selfId)
    return 0
end

return item_5005
