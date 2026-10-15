local class = require "class"
local define = require "define"
local script_base = require "script_base"
local commonitem = class("commonitem", script_base)
commonitem.script_id = 890011
commonitem.g_levelRequire = 1
commonitem.g_radiusAE = 3.0
commonitem.g_standFlag = 1
commonitem.g_effectCount = 4
commonitem.g_Impact1 = 34916
commonitem.g_Impact2 = -1
function commonitem:OnDefaultEvent(selfId, bagIndex)
end

function commonitem:IsSkillLikeScript(selfId)
    return 1
end

function commonitem:CancelImpacts(selfId)
    return 0
end

function commonitem:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if not self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        if not self:LuaFnIsFriend(selfId, targetId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        local SelfSex = self:LuaFnGetSex(selfId)
        local TargetSex = self:LuaFnGetSex(targetId)
        if (SelfSex ~= TargetSex) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function commonitem:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function commonitem:OnActivateOnce(selfId)
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

function commonitem:OnActivateEachTick(selfId)
    return 1
end

return commonitem
