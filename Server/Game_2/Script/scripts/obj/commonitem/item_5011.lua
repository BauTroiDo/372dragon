local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5011 = class("item_5011", script_base)
item_5011.g_petCommonId = define.PETCOMMON
item_5011.script_id = 335011
item_5011.g_HappinessValue = 40
function item_5011:IsSkillLikeScript(selfId)
    return 1
end

function item_5011:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5011:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5011:OnActivateOnce(selfId)
    if self.g_HappinessValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHappiness", selfId, self.g_HappinessValue)
    end
    return 1
end

function item_5011:OnActivateEachTick(selfId)
    return 1
end

function item_5011:CancelImpacts(selfId)
    return 0
end

return item_5011
