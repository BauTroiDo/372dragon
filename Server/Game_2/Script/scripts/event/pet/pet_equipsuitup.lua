--珍兽装备进阶
local class = require "class"
local script_base = require "script_base"
local pet_equipsuitup = class("pet_equipsuitup", script_base)
function pet_equipsuitup:OnPetEquipSuitUp(selfId, BagPos, Target, Num)
	local nMaterialItem = self:LuaFnGetItemTableIndexByIndex(selfId, BagPos)
	local product_equip, material, material_count, cost_money = self:PetEquipSuitUpInfo(nMaterialItem)
	if (-1 == product_equip) then
		self:notify_tips(selfId, "#{ZSZBSJ_090706_03}")
		return
	end
	if self:LuaFnIsItemLocked(selfId, BagPos) then
		self:notify_tips(selfId, "#{ZSZBSJ_090706_02}" )
		return
	end
	local nMoneySelf = self:GetMoneyJZ(selfId) + self:GetMoney(selfId)
	if nMoneySelf < cost_money then
        self:notify_tips(selfId,  "#{ZSZB_090421_24}" )
        return
	end
	local costtab = {}
	local itemcount
	local allnum = 0
	for i,j in ipairs({20301007,20301009}) do
		itemcount = self:LuaFnGetAvailableItemCount(selfId, j)
		if itemcount > 0 then
			allnum = allnum + itemcount
			table.insert(costtab,j)
		end
	end
	
	--20301007
	-- if self:LuaFnMtl_GetCostNum(selfId,{20301007,20301009}) < material_count then
		-- self:notify_tips(selfId,  "#{ZSZBSJ_090706_04}" )
		-- return
	-- end
	if allnum < material_count then
		self:notify_tips(selfId,  "#{ZSZBSJ_090706_04}" )
		return
	end
	self:LuaFnMtl_CostMaterial(selfId,material_count,costtab)
	self:LuaFnCostMoneyWithPriority(selfId, cost_money)
	local quality = self:GetBagItemQuality(selfId, BagPos)
	self:EraseItem(selfId, BagPos)
	local nNewPos = self:TryRecieveItem(selfId, product_equip, 1, quality + 1)
	self:LuaFnItemBind(selfId,nNewPos)
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0);
	self:notify_tips(selfId,  "#{ZSZBSJ_090706_05}" )
end

return pet_equipsuitup