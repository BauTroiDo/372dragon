local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_MaxValue = 50000
local g_IncPerAct = 2000

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
    local mp = self:GetMp(selfId)
    local max_mp = self:GetMaxMp(selfId)
    if mp == max_mp then
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

    local mp = self:GetMp(selfId)
    local max_mp = self:GetMaxMp(selfId)
    local need_mp = max_mp - mp
    need_mp = need_mp > g_IncPerAct and g_IncPerAct or need_mp
    if mp == need_mp then
        self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_MANA_IS_FULL)
        return 0
    end
    if need_mp >= vaild_value then
        self:IncreaseMp(selfId, vaild_value)
        self:SetBagItemParam(selfId, bag_index, 4, g_MaxValue)
        self:SetBagItemParam(selfId, bag_index, 8, g_MaxValue)
        self:EraseItem(selfId, bag_index)
    else
        self:IncreaseMp(selfId, need_mp)
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