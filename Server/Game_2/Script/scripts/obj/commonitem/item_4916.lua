local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4916 = class("item_4916", script_base)
item_4916.script_id = 334916
item_4916.g_levelRequire = 1
item_4916.g_radiusAE = 3.0
item_4916.g_standFlag = 1
item_4916.g_effectCount = 4
item_4916.g_Impact1 = 34916
item_4916.g_Impact2 = -1
function item_4916:OnDefaultEvent(selfId, bagIndex)
end

function item_4916:IsSkillLikeScript(selfId)
    return 1
end

function item_4916:CancelImpacts(selfId)
    return 0
end

function item_4916:OnConditionCheck(selfId)
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

function item_4916:OnDeplete(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local itmId = self:GetItemTableIndexByIndex(selfId, bagId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        local namSelf = self:GetName(selfId)
        local namTarget = self:GetName(targetId)
        if itmId > 0 then
            local namItem = self:GetItemName(itmId)
            local str =
                string.format(
                "#B#{_INFOUSR" ..
                    namSelf ..
                        "}#cff0000 đích thân đem#W[" ..
                            namItem ..
                                "]#cff0000 đưa đến#B#{_INFOUSR" ..
                                    namTarget .. "}#cff0000 trong tay, thâm tình nhìn#B#{_INFOUSR" .. namTarget .. "}#cff0000。"
            )
            self:AddGlobalCountNews(str)
        end
        return 1
    end
    return 0
end

function item_4916:OnActivateOnce(selfId)
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

function item_4916:OnActivateEachTick(selfId)
    return 1
end

return item_4916
