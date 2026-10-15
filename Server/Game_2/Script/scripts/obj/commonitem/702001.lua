local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_petCommonId = define.PETCOMMON
local g_HPValue = 10000			-- 生命值增加值
local g_MaxHPValue = 0			-- 最大生命值增加值
local g_LifeValue = 0				-- 寿命增加值
local g_HappinessValue = 1	-- 快乐度增加值
local g_MaxUseCount = 100		-- 最大使用次数100次

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
	-- 得到当前正在使用的物品的背包位置
	local nIndex = self:LuaFnGetBagIndexOfUsedItem(selfId )	
	local ret = self:CallScriptFunction( g_petCommonId, "IsPetCanUseFood", selfId, nIndex )
	return ret
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
	local bagId	 = self:LuaFnGetBagIndexOfUsedItem(selfId )
	local UseValue = self:GetBagItemParam(selfId, bagId, 8)
    local ValidValue = g_MaxUseCount - UseValue
	
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId )
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId )	
	
	local valueHP = self:LuaFnGetPetHP(selfId, petGUID_H, petGUID_L )
	local MaxHP = self:LuaFnGetPetMaxHP(selfId, petGUID_H, petGUID_L )
	
	local valueHappy = self:LuaFnGetPetHappiness(selfId, petGUID_H, petGUID_L )
	local MaxHappiness = 100
	
	if valueHP == MaxHP and valueHappy == MaxHappiness then
		self:notify_tips (selfId, "Trân thú này không Yêu cầu sử dụng Thức Ăn Trân Thú.")
		return 0
	end
	--消耗一次珍兽滋补丹
	if bagId >= 0 then		
		if UseValue >= g_MaxUseCount then   --记录的使用次数大于等于最大可用次数,理论上不可能出现.
		    return 0
		end
		local CurValue = UseValue + 1
		self:SetBagItemParam(selfId, bagId, 4, g_MaxUseCount ) --设置最大次数
		self:SetBagItemParam(selfId, bagId, 8, CurValue ) --设置已用次数
				
		--------------参数设置安全性检测,虽然理论上参数设置不会失败
		local CheckParam1 = self:GetBagItemParam(selfId, bagId, 4)
		local CheckParam2 = self:GetBagItemParam(selfId, bagId, 8)
		
		if CheckParam1 ~= g_MaxUseCount then
		    return 0
		end
		if CheckParam2 ~= CurValue then
		    return 0
		end
		self:LuaFnRefreshItemInfo(selfId, bagId )	--刷新背包信息
		if CurValue >= g_MaxUseCount then  --当使用次数达到最大次数时,将删除此物品
			local EraseRet = self:EraseItem(selfId, bagId )
			if not EraseRet then      --如果删除失败,将不会产生任何效果
			    local strMsg = "Yêu cầu Trân Thú Tư Bổ Đan."
                self:notify_tips( selfId, strMsg)
				return 0
			end
		end
	else
		local strMsg = "Yêu cầu Trân Thú Tư Bổ Đan."
		self:notify_tips(selfId, strMsg)
		return 0
	end
	-- 消耗珍兽滋补丹完毕
	if g_HPValue > 0 then
		self:CallScriptFunction(g_petCommonId, "IncPetHP", selfId, g_HPValue )
	end

	if g_MaxHPValue > 0 then
		self:CallScriptFunction( g_petCommonId, "IncPetMaxHP", selfId, g_MaxHPValue )
	end

	if g_LifeValue > 0 then
		self:CallScriptFunction( g_petCommonId, "IncPetLife", selfId, g_LifeValue )
	end

	if g_HappinessValue > 0 then
		if valueHappy < 60 then
			local happyes = 61 - valueHappy
			self:CallScriptFunction(g_petCommonId, "IncPetHappiness", selfId, happyes )
		else
			self:CallScriptFunction(g_petCommonId, "IncPetHappiness", selfId, g_HappinessValue )
		end
	end
	return 1
end

return common_item