local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_100019_38000958 = class("item_100019_38000958", script_base)
item_100019_38000958.script_id = 100019

-- 新手装备礼包装备列表
item_100019_38000958.Equip = 
{
	10415054, -- 无忧之肩 (请在EquipBase.txt中查找ID并替换)
	10414054, -- 无忧之腕 (请在EquipBase.txt中查找ID并替换)
	10422152, -- 无忧之戒 (请在EquipBase.txt中查找ID并替换)
	10423060, -- 无忧之饰 (请在EquipBase.txt中查找ID并替换)
	10423062, -- 天龙聚义护符 (请在EquipBase.txt中查找ID并替换)
	10110001, -- 布帽
	10113001, -- 布衣 (请在EquipBase.txt中查找ID并替换)
	10112001, -- 布手套 (请在EquipBase.txt中查找ID并替换)
	10111001, -- 布鞋 (请在EquipBase.txt中查找ID并替换)
	10121001, -- 柳色腰带 (请在EquipBase.txt中查找ID并替换)
	10122001, -- 青戒 (请在EquipBase.txt中查找ID并替换)
	10120001, -- 千花结 (请在EquipBase.txt中查找ID并替换)
}



-- 装备ID说明（请在EquipBase.txt中查找并替换上面的0）：
-- 无忧之肩：肩膀装备
-- 无忧之腕：护腕装备
-- 无忧之戒：戒指装备
-- 无忧之饰：护符装备
-- 天龙聚义护符：护符装备
-- 布帽：10110001 (已设置)
-- 布衣：衣服装备
-- 布手套：手套装备
-- 布鞋：鞋子装备
-- 柳色腰带：腰带装备
-- 青戒：戒指装备
-- 千花结：项链装备



function item_100019_38000958:OnDefaultEvent(selfId, bagIndex)
end

function item_100019_38000958:IsSkillLikeScript(selfId)
    return 1
end

function item_100019_38000958:CancelImpacts(selfId)
    return 0
end

function item_100019_38000958:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 38000958 then
		return 0
	end
	local havemenpai = self:GetMenPai(selfId)
	if not havemenpai or havemenpai < 0 or havemenpai > 15 or havemenpai == 9 then
		self:notify_tips(selfId, "Vào môn phái rồi mới mở được đạo cụ này.")
		return 0
	end
    return 1
end

function item_100019_38000958:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function item_100019_38000958:OnActivateOnce(selfId)
    local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return 1
	end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 38000958 then
		return 1
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 1
	end
	local havemenpai = self:GetMenPai(selfId)
	if not havemenpai or havemenpai < 0 or havemenpai > 15 or havemenpai == 9 then
		self:notify_tips(selfId, "Vào môn phái rồi mới mở được đạo cụ này.")
		return 1
	end
	self:BeginAddItem()
	for i,j in ipairs(self.Equip) do
		if j > 0 then
			self:AddItem(j,1,true);
		end
	end
	if not self:EndAddItem(selfId) then
		self:notify_tips(selfId,"Túi hành trang không đủ chỗ")
		return 1
	end
	self:BeginAddItem()
	local human_item_logic = require "human_item_logic"
    local logparam = {}
    local del = human_item_logic:dec_item_lay_count(logparam, obj, usepos, 1)
	if del then
		local logparam = { reason = "Hộp Quà Trang Bị Tân Thủ", user_name = obj:get_name(), user_guid = obj:get_guid(), func_name = "TryRecieveItem", script_id = self.script_id }
		for i,j in ipairs(self.Equip) do
			if j > 0 then
				human_item_logic:create_multi_item_to_bag(logparam, obj, j, 1, true)
			end
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId,"Bạn nhận một bộ trang bị tân thủ, chúc chơi vui.")
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
	end
	return 1
end

function item_100019_38000958:OnActivateEachTick(selfId)
    return 1
end

return item_100019_38000958
