local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4901 = class("item_4901", script_base)
item_4901.script_id = 334901
item_4901.g_levelRequire = 1
item_4901.g_radiusAE = 3.0
item_4901.g_standFlag = 1
item_4901.g_effectCount = 4
item_4901.g_Impact1 = 4901
item_4901.g_Impact2 = -1
function item_4901:OnDefaultEvent(selfId, bagIndex)
end

function item_4901:IsSkillLikeScript(selfId)
    return 1
end

function item_4901:CancelImpacts(selfId)
    return 0
end

function item_4901:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if not self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        if not self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function item_4901:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4901:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            if self:LuaFnIsFriend(targetId, selfId) then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
                self:BeginEvent(self.script_id)
                self:AddText("Độ hảo hữu giữa ngươi và đối phương tăng thêm 50")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    end
    return 1
end

function item_4901:OnActivateEachTick(selfId)
    return 1
end

return item_4901
