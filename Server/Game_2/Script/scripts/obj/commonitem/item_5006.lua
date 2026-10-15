local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5006 = class("item_5006", script_base)
item_5006.g_petCommonId = define.PETCOMMON
item_5006.script_id = 335006
item_5006.g_HappinessValue = 10
function item_5006:IsSkillLikeScript(selfId)
    return 1
end

function item_5006:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_5006:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5006:OnActivateOnce(selfId)
    if self.g_HappinessValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHappiness", selfId, self.g_HappinessValue)
    end
    return 1
end

function item_5006:OnActivateEachTick(selfId)
    return 1
end

function item_5006:CancelImpacts(selfId)
    return 0
end

return item_5006
