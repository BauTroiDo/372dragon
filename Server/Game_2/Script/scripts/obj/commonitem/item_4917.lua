local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4917 = class("item_4917", script_base)
item_4917.script_id = 334917
item_4917.g_levelRequire = 1
item_4917.g_radiusAE = 3.0
item_4917.g_standFlag = 1
item_4917.g_effectCount = 4
item_4917.g_Impact1 = 34917
item_4917.g_Impact2 = -1
function item_4917:OnDefaultEvent(selfId, bagIndex)
end

function item_4917:IsSkillLikeScript(selfId)
    return 1
end

function item_4917:CancelImpacts(selfId)
    return 0
end

function item_4917:OnConditionCheck(selfId)
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

function item_4917:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4917:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            if self:LuaFnIsFriend(targetId, selfId) then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi và đối phương của hảo hữu độ tăng thêm 500")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                local namSelf = self:GetName(selfId)
                local namTarget = self:GetName(targetId)
                local str =
                    string.format(
                    "#B#{_INFOUSR" ..
                        namSelf ..
                            "}#g7ffff0tận tay đem#g000000#W[99 đóa hoa hồng]#g7ffff0đưa đến#g000000#B#{_INFOUSR" ..
                                namTarget .. "}#g7ffff0trong tay, thâm tình nhìn#g000000#B#{_INFOUSR" .. namTarget .. "}#g7ffff0。"
                )
                self:AddGlobalCountNews(str)
            end
        end
    end
    return 1
end

function item_4917:OnActivateEachTick(selfId)
    return 1
end

return item_4917
