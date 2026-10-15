local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4905 = class("item_4905", script_base)
item_4905.script_id = 334905
item_4905.g_levelRequire = 1
item_4905.g_radiusAE = 3.0
item_4905.g_standFlag = 1
item_4905.g_effectCount = 4
item_4905.g_Impact1 = 4905
item_4905.g_Impact2 = -1
function item_4905:OnDefaultEvent(selfId, bagIndex)
end

function item_4905:IsSkillLikeScript(selfId)
    return 1
end

function item_4905:CancelImpacts(selfId)
    return 0
end

function item_4905:OnConditionCheck(selfId)
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
        if (SelfSex == TargetSex) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function item_4905:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4905:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            if self:LuaFnIsFriend(targetId, selfId) then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
                self:BeginEvent(self.script_id)
                self:AddText("Độ hữu hảo giữa ngươi và đối phương tăng 90")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    end
    return 1
end

function item_4905:OnActivateEachTick(selfId)
    return 1
end

return item_4905
