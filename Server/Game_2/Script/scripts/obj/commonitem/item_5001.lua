local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5001 = class("item_5001", script_base)
item_5001.g_petCommonId = define.PETCOMMON
item_5001.script_id = 335001
item_5001.g_HappinessValue = 2
function item_5001:IsSkillLikeScript(selfId)
    return 1
end

function item_5001:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5001:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5001:OnActivateOnce(selfId)
    if self.g_HappinessValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHappiness", selfId, self.g_HappinessValue)
    end
    return 1
end

function item_5001:OnActivateEachTick(selfId)
    return 1
end

function item_5001:CancelImpacts(selfId)
    return 0
end

return item_5001
