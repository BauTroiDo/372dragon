local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local need_id = 30505196
--预留空间  因有无道具的存在，不提前预留背包空间能固定开绑元
local need_space_count = 1

--给予道具 按概率给予  rate / 所有道具的rate总和
--id = "绑元"  给绑元时这个配置不要动   只改动num的数量即可
local give_item = {
	{id = "绑元",num = 10000,bind = true,rate = 40},
	{id = 38008161,num = 20,bind = true,rate = 30},
	{id = 38003055,num = 5,bind = true,rate = 30},
	{id = 20502003,num = 10,bind = true,rate = 40},
	{id = 20501003,num = 10,bind = true,rate = 40},
}



function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	-- 校验使用的物品
	if not self:LuaFnVerifyUsedItem(selfId )then
		self:notify_tips( selfId, "Đạo cụ chưa mở, không thể sử dụng.")
		return 0
	end
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	local itemid = self:LuaFnGetItemIndexOfUsedItem(selfId)
	if itemid ~= need_id then
		self:notify_tips( selfId, "Đạo cụ chưa mở, không thể sử dụng.")
		return 0
	end
	local BagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,BagIndex) ~= itemid then
		self:notify_tips( selfId, "Dùng sai, xin thử lại.")
		return 0
	end
	if self:LuaFnGetPropertyBagSpace(selfId) < need_space_count then
		local msg = string.format("Xin chừa %s chỗ trống ô đạo cụ.",need_space_count)
		self:notify_tips( selfId,msg )
		return 0
	elseif self:LuaFnGetMaterialBagSpace(selfId) < need_space_count then
		local msg = string.format("Xin chừa %s chỗ trống ô nguyên liệu.",need_space_count)
		self:notify_tips( selfId,msg )
		return 0
	end
	self:LuaFnDecItemLayCount(selfId,BagIndex,1)
	give_item.all_rate = 0
	for i,j in ipairs(give_item) do
		give_item.all_rate = give_item.all_rate + j.rate
		j.cur_rate = give_item.all_rate
	end
	if give_item.all_rate > 0 then
		local cur_rate = math.random(give_item.all_rate)
		local item
		for i,j in ipairs(give_item) do
			if cur_rate <= j.cur_rate then
				item = j
				break
			end
		end
		if item then
			if item.id == "绑元" then
				self:AddBindYuanBao(selfId, item.num, "Script 335139 cấp")
				local msg = string.format("Ngươi nhận %d nguyên bảo khóa.",item.num)
				self:notify_tips( selfId,msg )
				self:ShowObjBuffEffect(selfId,selfId,-1,18)
			else
				self:TryRecieveItemWithCount(selfId, item.id, item.num, item.bind)
				self:GiveItemTip(selfId,item.id,item.num,18)
			end
		end
	end
	return 1
end

return common_item