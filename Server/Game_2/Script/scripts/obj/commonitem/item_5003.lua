local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_5003 = class("item_5003", script_base)
item_5003.g_petCommonId = define.PETCOMMON
item_5003.script_id = 335003
item_5003.g_LifeValue = 20000
function item_5003:IsSkillLikeScript(selfId)
    return 1
end

function item_5003:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
    local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
    if (self:LuaFnGetPetLife(selfId, petGUID_H, petGUID_L) >= self:LuaFnGetPetMaxLife(selfId, petGUID_H, petGUID_L)) then
        self:BeginEvent(self.script_id)
        local strText = "Trân Thú này không Yêu cầu kéo dài tuổi thọ."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    return 1
end

function item_5003:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_5003:OnActivateOnce(selfId)
    if self.g_LifeValue > 0 then
        self:CallScriptFunction(self.g_petCommonId, "IncPetLife", selfId, self.g_LifeValue)
    end
    return 1
end

function item_5003:OnActivateEachTick(selfId)
    return 1
end

function item_5003:CancelImpacts(selfId)
    return 0
end

return item_5003
