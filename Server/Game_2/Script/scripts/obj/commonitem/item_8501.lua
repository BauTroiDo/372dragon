local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_8501 = class("item_8501", script_base)
item_8501.script_id = 338501
item_8501.g_levelRequire = 1
item_8501.g_radiusAE = 3.0
item_8501.g_standFlag = 1
item_8501.g_effectCount = 4
item_8501.g_Impact1 = 8501
item_8501.g_Impact2 = 8502
function item_8501:OnDefaultEvent(selfId, bagIndex)
end

function item_8501:IsSkillLikeScript(selfId)
    return 1
end

function item_8501:CancelImpacts(selfId)
    return 0
end

function item_8501:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if targetId ~= define.INVAILD_ID then
        if not self:LuaFnUnitIsFriend(selfId, targetId) then
            self:SendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function item_8501:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then
        return 1
    end
    return 0
end

function item_8501:OnActivateOnce(selfId)
    if self.g_Impact1 ~ define.INVAILD_ID then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if targetId ~= define.INVAILD_ID then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact2, 0)
        end
    end
    return 1
end

function item_8501:OnActivateEachTick(selfId)
    return 1
end

return item_8501
