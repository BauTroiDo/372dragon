local class = require "class"
local script_base = require "script_base"
local define = require "define"
local packet_def = require "game.packet"

local PetSoulQiongQi = class("PetSoulQiongQi", script_base)
PetSoulQiongQi.script_id = 998522
PetSoulQiongQi.g_CostMoney = 500000

local SOUL_TYPES = {
	[70600000] = true,
	[70600001] = true,
	[70600002] = true,
	[70600003] = true,
	[70600004] = true,
}

function PetSoulQiongQi:IsPetSoul(selfId, BagPos)
	return self:GetPetEquipType(selfId, BagPos) == define.PET_EQUIP_TYPE.SOUL
end

function PetSoulQiongQi:GetPetSoulBloodData(selfId, BagPos)
	local obj = self:get_scene():get_obj_by_id(selfId)
	local item = obj:get_prop_bag_container():get_item(BagPos)
	if item == nil or item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
		return 0, 0
	end
	local data = item:get_pet_equip_data()
	return data:get_pet_soul_level(), data:get_pet_soul_exp()
end

function PetSoulQiongQi:SendItemRefresh(obj, bagIndex, item)
	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = bagIndex
	msg.item = item:copy_raw_data()
	obj:get_scene():send2client(obj, msg)
end

function PetSoulQiongQi:Restore(selfId, targetId, nBagIndex)
	local sceneId = self:GetSceneID()
	if sceneId ~= define.SCENE_ENUM.SCENE_SUZHOU then
		self:ShowTips(selfId, "#{QQJG_20230815_17}")
		return
	end
	if self:GetLevel(selfId) < 85 then
		self:ShowTips(selfId, "#{QQJG_20230815_15}")
		return
	end
	if not self:IsInDist(selfId, targetId, 6) then
		self:ShowTips(selfId, "#{QQJG_20230815_18}")
		return
	end
	if not self:IsPetSoul(selfId, nBagIndex) then
		self:ShowTips(selfId, "#{QQJG_20230815_25}")
		return
	end
	local nPetSoulQual = self:GetPetSoulQuanlity(selfId, nBagIndex)
	if nPetSoulQual ~= 3 then
		self:ShowTips(selfId, "#{QQJG_20230815_25}")
		return
	end
	local obj = self:get_scene():get_obj_by_id(selfId)
	local container = obj:get_prop_bag_container()
	local item = container:get_item(nBagIndex)
	item:set_index(70600015)
	self:SendItemRefresh(obj, nBagIndex, item)
	self:ShowTips(selfId, "#{QQJG_20230815_33}")
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function PetSoulQiongQi:Swallow(selfId, targetId, nQBagIndex, nSBagIndex, nSelectButton)
	local sceneId = self:GetSceneID()
	if sceneId ~= define.SCENE_ENUM.SCENE_SUZHOU then
		self:ShowTips(selfId, "#{QQJG_20230815_17}")
		return
	end
	if self:GetLevel(selfId) < 85 then
		self:ShowTips(selfId, "#{QQJG_20230815_15}")
		return
	end
	if not self:IsInDist(selfId, targetId, 6) then
		self:ShowTips(selfId, "#{QQJG_20230815_18}")
		return
	end
	if nSelectButton <= 0 then
		self:ShowTips(selfId, "#{QQJG_20230815_35}")
		return
	end
	if not self:IsPetSoul(selfId, nQBagIndex) then
		self:ShowTips(selfId, "#{QQJG_20230815_10}")
		return
	end
	if not self:IsPetSoul(selfId, nSBagIndex) then
		self:ShowTips(selfId, "#{QQJG_20230815_20}")
		return
	end
	if self:LuaFnIsPasswordSetup(selfId, 0) == 1 then
		if self:LuaFnIsPasswordUnlocked(selfId, 1) == 0 then
			self:ShowTips(selfId, "#{QQJG_20230815_16}")
			return
		end
	end
	local nPetSoulQual = self:GetPetSoulQuanlity(selfId, nQBagIndex)
	if nPetSoulQual ~= 3 then
		self:ShowTips(selfId, "#{QQJG_20230815_13}")
		return
	end
	if not self:LuaFnIsItemAvailable(selfId, nQBagIndex) or self:LuaFnIsItemLocked(selfId, nQBagIndex) then
		self:ShowTips(selfId, "#{QQJG_20230815_12}")
		return
	end
	local nMoneySelf = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
	if nMoneySelf < self.g_CostMoney then
		self:ShowTips(selfId, "#{QQJG_20230815_32}")
		return
	end
	local nBloodRank, nBloodConcentrate = self:GetPetSoulBloodData(selfId, nSBagIndex)
	if nBloodRank > 0 or nBloodConcentrate > 0 then
		self:ShowTips(selfId, "#{QQJG_20230815_14}")
		return
	end
	local sub_index = self:GetBagItemIndex(selfId, nSBagIndex)
	if not SOUL_TYPES[sub_index] then
		self:ShowTips(selfId, "Chỉ nuốt được thú hồn Thanh Long, Huyền Vũ, Bạch Hổ, Chu Tước, Cửu Vĩ")
		return
	end
	self:LuaFnCostMoneyWithPriority(selfId, self.g_CostMoney)
	local obj = self:get_scene():get_obj_by_id(selfId)
	local container = obj:get_prop_bag_container()
	local main_item = container:get_item(nQBagIndex)
	local keep_a = (nSelectButton ~= 1)
	if keep_a then
		main_item:set_index(sub_index + 21)
	else
		main_item:set_index(sub_index + 16)
	end
	self:SendItemRefresh(obj, nQBagIndex, main_item)
	self:LuaFnEraseItem(selfId, nSBagIndex)
	self:ShowTips(selfId, "#{QQJG_20230815_24}")
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
end

function PetSoulQiongQi:ShowTips(selfId, tipMsg)
	self:BeginEvent(self.script_id)
	self:AddText(tipMsg)
	self:EndEvent()
	self:DispatchMissionTips(selfId)
end

return PetSoulQiongQi
