local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4618 = class("item_4618", script_base)
item_4618.g_petCommonId = define.PETCOMMON
item_4618.script_id = 334618
item_4618.g_HPValue = 10964
item_4618.g_MaxHPValue = 0
item_4618.g_LifeValue = 0
item_4618.g_HappinessValue = 0
function item_4618:IsSkillLikeScript(selfId)
    return 1
end

function item_4618:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local nIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local ret = self:CallScriptFunction(self.g_petCommonId, "IsPetCanUseFood", selfId, nIndex)
    return ret
end

function item_4618:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4618:OnActivateOnce(selfId)
    if self.g_HPValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHP", selfId, self.g_HPValue)
    end
    if self.g_MaxHPValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetMaxHP", selfId, self.g_MaxHPValue)
    end
    if self.g_LifeValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetLife", selfId, self.g_LifeValue)
    end
    if self.g_HappinessValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetHappiness", selfId, self.g_HappinessValue)
    end
    return 1
end

function item_4618:OnActivateEachTick(selfId)
    return 1
end

function item_4618:CancelImpacts(selfId)
    return 0
end

return item_4618
