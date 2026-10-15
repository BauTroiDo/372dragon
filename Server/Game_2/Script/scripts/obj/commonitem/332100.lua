local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_MaxValue = 500000
local g_IncPerAct = 2500

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    local hp = self:GetHp(selfId)
    local max_hp = self:GetMaxHp(selfId)
    if hp == max_hp then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    return 1
end

function common_item:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then
		return 1
	end
	return 0
end

function common_item:OnActivateOnce(selfId)
    local bag_index = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local use_value = self:GetBagItemParam(selfId, bag_index, 8)
    local vaild_value = g_MaxValue - use_value

    local hp = self:GetHp(selfId)
    local max_hp = self:GetMaxHp(selfId)
    local need_hp = max_hp - hp
    need_hp = need_hp > g_IncPerAct and g_IncPerAct or need_hp
    if hp == max_hp then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_HEALTH_IS_FULL)
        return 0
    end
    if need_hp >= vaild_value then
        self:IncreaseHp(selfId, vaild_value)
        self:SetBagItemParam(selfId, bag_index, 4, g_MaxValue)
        self:SetBagItemParam(selfId, bag_index, 8, g_MaxValue)
        self:EraseItem(selfId, bag_index)
    else
        self:IncreaseHp(selfId, need_hp)
        self:SetBagItemParam(selfId, bag_index, 4, g_MaxValue)
        self:SetBagItemParam(selfId, bag_index, 8, use_value + g_IncPerAct)
        if use_value + g_IncPerAct >= g_MaxValue then
            self:EraseItem(selfId, bag_index)
        end
    end
    self:LuaFnRefreshItemInfo(selfId, bag_index)
    return 1
end

return common_item