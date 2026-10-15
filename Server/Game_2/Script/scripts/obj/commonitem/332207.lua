local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local DarkItem_AdjustSkillItem = {30503118, 30503123, 30503130}
local DarkItem_ResetQuality = {type1 = { 30503119, 30503124, 30503132}, type2 = { 30503120, 30503125, 30503133}}
local DarkItem_Resetdark = {30503121, 30503126, 30503131}

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
end
function common_item:LuaFnMtl_GetCostNum_Ex(selfId,itemtab)
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs(itemtab) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
	return allnum,costtab
end



function common_item:DarkSkillAdjustForBagItem(selfId, pos)
    local ok=require('cy_equipment_skills').paid_roll(self,selfId,pos,17,DarkItem_AdjustSkillItem,50000)
    self:DarkOperateResult(selfId,1,ok and 1 or -1)
    if ok then self:SendImpact(selfId) end
    return ok
end

function common_item:DoRefreshDarkSkill(selfId, BagPos)
    local nSucc = self:RefreshDarkSkills(selfId, BagPos)
    if not nSucc then
		--失败了，通知客户端
		self:DarkOperateResult(selfId, 1, -1)
	else
		--成功了，通知客户端
		self:DarkOperateResult(selfId, 1, 1)
        self:notify_tips(selfId, "#{CXYH_140813_27}")
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 8000341)
	end
end

local Adjust_materials = {
	30503115, 30503122, 30503129
}
function common_item:DarkAttrAdjustForBagItem(selfId, bagpos, attrfrom)
	local nCleanTimes = self:GetDarkCleanTimes(selfId, bagpos)
	local nTotalCleanTimes = self:GetDarkTotalCleanTimes(selfId, bagpos)
	if (nCleanTimes >= nTotalCleanTimes) then
		self:DarkOperateResult(selfId, 0, -3, attrfrom)
		return
	end
	local nAttrValue = self:GetDarkAttrForBagItem(selfId, bagpos, attrfrom)
	if (nAttrValue <= 1) then
		self:DarkOperateResult( selfId, 0, -1, attrfrom)
		return
	end
	local allnum,costtab = self:LuaFnMtl_GetCostNum_Ex(selfId, Adjust_materials)
	--有这个物品吗
	if allnum < 1 then
		self:DarkOperateResult(selfId, 0, -2, attrfrom)
		return
	end

	
	--有这个物品吗
	-- if self:LuaFnMtl_GetCostNum(selfId, Adjust_materials) < 1 then
		-- self:DarkOperateResult(selfId, 0, -2, attrfrom)
		-- return
	-- end
	local bMoneyEnough = self:HaveEnoughMoney(selfId, 0, 10000);
	if not bMoneyEnough then
	    return
	end
	local bCostMoney = self:CostMoney(selfId, 0, 10000)
	if not bCostMoney then
	    return
	end
	--扣除成功
	self:LuaFnMtl_CostMaterial(selfId, 1, costtab)
	self:SetDarkCleanTimes(selfId, bagpos, nCleanTimes + 1)
	local nAttrTo = self:AdjustDarkAttrForBagItem(selfId, bagpos, attrfrom )
	if nAttrTo == -1 then
		--失败了，通知客户端
		self:DarkOperateResult(selfId, 0, -1, attrfrom)
	else
		--成功了，通知客户端
		self:DarkOperateResult(selfId, 0, attrfrom, nAttrTo)
		self:SendImpact(selfId)
	end
end

function common_item:DarkResetQualityForBagItem(selfId, bagpos, resettype)
	--有这个物品吗
	local nNeedItem = DarkItem_ResetQuality.type1
	if(resettype == 2) then
		nNeedItem = DarkItem_ResetQuality.type2
	end
	local allnum,costtab = self:LuaFnMtl_GetCostNum_Ex(selfId, nNeedItem)
	--有这个物品吗
	if allnum < 1 then
		if(resettype == 2) then
			self:DarkOperateResult(selfId, 2, -3)
		else
			self:DarkOperateResult(selfId, 2, -2)
		end
		return
	end
	local bMoneyEnough = self:HaveEnoughMoney(selfId, 2, 10000)
	if not bMoneyEnough then
		return
	end
	local bCostMoney = self:CostMoney(selfId, 2, 10000)
	if not bCostMoney then
		return
	end
	--扣除成功
	self:LuaFnMtl_CostMaterial(selfId, 1, costtab)
	local nSucc = self:ResetDarkQualityForBagItem(selfId, bagpos, resettype)
	if not nSucc then
			--失败了，通知客户端
		self:DarkOperateResult(selfId, 2, -1)
	else
		--成功了，通知客户端
		self:DarkOperateResult(selfId, 2, 1)
		self:SendImpact(selfId)
	end
end


function common_item:DarkResetForBagItem(selfId, bagpos )
	local allnum,costtab = self:LuaFnMtl_GetCostNum_Ex(selfId, DarkItem_Resetdark)
	--有这个物品吗
	if allnum < 1 then
		self:DarkOperateResult(selfId, 6, -2)
		return
	end

	--有这个物品吗
	-- local nNeedItem = DarkItem_Resetdark
	-- if self:LuaFnMtl_GetCostNum(selfId, nNeedItem) < 1 then
		-- self:DarkOperateResult(selfId, 6, -2)
		-- return
	-- end
	local bMoneyEnough = self:HaveEnoughMoney(selfId, 6, 10000)
	if not bMoneyEnough then
	    return
	end
	local bCostMoney = self:CostMoney(selfId, 6, 10000)
	if not bCostMoney then
	    return
	end
	--扣除成功
	self:LuaFnMtl_CostMaterial(selfId, 1, costtab)
	local nSucc = self:ResetDarkForBagItem(selfId, bagpos)
	if not nSucc then
		--失败了，通知客户端
		self:DarkOperateResult(selfId, 6, -1)
	else
		--成功了，通知客户端
		self:DarkOperateResult(selfId, 6, 1)
		self:SendImpact(selfId)
	end
end

function common_item:HaveEnoughMoney(selfId, nType, nMoney)
    --判断玩家身上是否有足够的钱
    local nHaveMoney = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if (nHaveMoney >= nMoney) then
        return true
    else
        self:DarkOperateResult(selfId, nType, -4)
        return false
    end
end

function common_item:CostMoney(selfId, nType, nMoney)
    --扣钱
    local nRet = self:LuaFnCostMoneyWithPriority(selfId,nMoney)
    if not nRet then
        self:DarkOperateResult(selfId, nType, -4)
        return false
    else
        return true
    end
end

function common_item:SendImpact(playerId)
	self:LuaFnSendSpecificImpactToUnit(playerId, playerId, playerId, 18, 0 )
end


return common_item