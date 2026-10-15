local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
common_item.MD_DrawCount = 570      -- 累计抽奖次数
	--rate  必级是概率10000   机率给则是 rate / 100
	--bind  true >> 给予绑定   false >> 给予不绑定
	--num_max  存在该键时  则随机数量给予 num - num_max中随机
local ItemInfo = 
{
	[38002949] = {
		random_one = false,
		{id = 30505079,num = 1,bind = true,rate = 100},
		{id = 30509012,num = 1,bind = true,rate = 100},
		{id = 38002283,num = 1,bind = true,rate = 100},
	  },
	[38002967] = {
		random_one = false,
		{id = 30008034,num = 1,bind = true,rate = 100},
		{id = 20310168,num = 10,bind = true,rate = 100},
		{id = 10141247,num = 1,bind = true,rate = 10},
	},
	[38002968] = {
		random_one = false,
		{id = 10125250,num = 1,bind = true,rate = 100},
		{id = 30008217,num = 1,bind = true,rate = 100},
		{id = 20307231,num = 1,bind = true,rate = 100},
	},
   
	[38008179] = {
		random_one = false,
		{id = 38008161,num = 30,num_max = 50,bind = false,rate = 100},
	},	
	[38008207] = {
		random_one = false,
		{id = 30700226,num = 1,bind = false,rate = 5},	--暴·穿冰属性书
		{id = 30700227,num = 1,bind = false,rate = 5},	--暴·暗火属性书
		{id = 30700228,num = 1,bind = false,rate = 5},	--暴·冲玄属性书
		{id = 30700229,num = 1,bind = false,rate = 5},	--暴·拔毒属性书

		{id = 10340102,num = 1,bind = false,rate = 5},	--大夏龙雀
		{id = 10341102,num = 1,bind = false,rate = 5},	--大秦锋镝
		{id = 10341202,num = 1,bind = false,rate = 5},	--大唐昆岳
		{id = 10342102,num = 1,bind = false,rate = 5},	--大商尘影
		{id = 10343102,num = 1,bind = false,rate = 5},	--大周岚夜
		{id = 10343202,num = 1,bind = false,rate = 5},	--大晋星痕
		{id = 10344102,num = 1,bind = false,rate = 5},	--大宋君岑
		{id = 10345102,num = 1,bind = false,rate = 5},	--大汉弘纲
		{id = 10345202,num = 1,bind = false,rate = 5},	--大隋凝霜
		{id = 10346102,num = 1,bind = false,rate = 5},	--大楚秋声
		{id = 10347102,num = 1,bind = false,rate = 5},	--大齐鸣风



		
		{id = 10126850,num = 1,bind = false,rate = 1},	--蚩尤血袍·天魔
		{id = 30900016,num = 1,bind = false,rate = 500},	--高级宝石合成符
		
		{id = 38008161,num = 1,bind = false,rate = 500},	--至尊强化精华
		{id = 30008117,num = 1,bind = false,rate = 500},	--玄灵丹
		{id = 38008301,num = 1,bind = false,rate = 2000},	--兽灵宝盒
		{id = 38008201,num = 1,bind = false,rate = 800},	--经验丹1000万
		{id = 20600004,num = 1,bind = false,rate = 1000},	--灵级长春玉

		{id = 30310168,num = 1,bind = false,rate = 1},	--典藏珍兽蛋：黑山姥姥
		{id = 30310188,num = 1,bind = false,rate = 1},	--典藏珍兽蛋：烈兔甜心
		{id = 30310189,num = 1,bind = false,rate = 1},	--典藏珍兽蛋：六耳猕猴
		{id = 30310187,num = 1,bind = false,rate = 1},	--典藏珍兽蛋：覆海龙君
		

		{id = 26000001,num = 1,bind = false,rate = 1000},	--灵玑瑶盘·残篇
		{id = 26000001,num = 1,bind = false,rate = 1000},
		{id = 26000001,num = 1,bind = false,rate = 1000},
		{id = 26000001,num = 1,bind = false,rate = 1000},
		{id = 26000001,num = 1,bind = false,rate = 1000},
		{id = 26000001,num = 1,bind = false,rate = 1000},	--九幽鸩鼎·残篇
		
		{id = 20301007,num = 1,bind = false,rate = 2000},	--圣兽鳞


		
		--{id = 20502004,num = 1,bind = false,rate = 10000},	--4级秘银
		--{id = 20501004,num = 1,bind = false,rate = 10000},	--4级棉布
	},
	[38008301] = {
		random_one = true,
		{id = 70700000,num = 1,bind = true,rate = 100},
		{id = 70700001,num = 1,bind = true,rate = 100},
		{id = 70700002,num = 1,bind = true,rate = 100},
		{id = 70700003,num = 1,bind = true,rate = 100},
		{id = 70700004,num = 1,bind = true,rate = 100},
		{id = 70700005,num = 1,bind = true,rate = 100},
		{id = 70700006,num = 1,bind = true,rate = 100},
		{id = 70700007,num = 1,bind = true,rate = 100},
		{id = 70700008,num = 1,bind = true,rate = 100},
		{id = 70700012,num = 1,bind = true,rate = 100},
		{id = 70700013,num = 1,bind = true,rate = 100},
		{id = 70700014,num = 1,bind = true,rate = 100},
		{id = 70700015,num = 1,bind = true,rate = 100},
		{id = 70700016,num = 1,bind = true,rate = 100},
		{id = 70700017,num = 1,bind = true,rate = 100},
		{id = 70700021,num = 1,bind = true,rate = 100},
		{id = 70700022,num = 1,bind = true,rate = 100},
		{id = 70700023,num = 1,bind = true,rate = 100},
		{id = 70700024,num = 1,bind = true,rate = 100},
		{id = 70700025,num = 1,bind = true,rate = 100},
		{id = 70700026,num = 1,bind = true,rate = 100},
		{id = 70700030,num = 1,bind = true,rate = 100},
		{id = 70700031,num = 1,bind = true,rate = 100},
		{id = 70700032,num = 1,bind = true,rate = 100},
		{id = 70700033,num = 1,bind = true,rate = 100},
		{id = 70700034,num = 1,bind = true,rate = 100},
		{id = 70700035,num = 1,bind = true,rate = 100},
		{id = 70700039,num = 1,bind = true,rate = 100},
		{id = 70700040,num = 1,bind = true,rate = 100},
		{id = 70700041,num = 1,bind = true,rate = 100},
		{id = 70700042,num = 1,bind = true,rate = 100},
		{id = 70700043,num = 1,bind = true,rate = 100},
		{id = 70700044,num = 1,bind = true,rate = 100},
		{id = 70700048,num = 1,bind = true,rate = 100},
		{id = 70700049,num = 1,bind = true,rate = 100},
		{id = 70700050,num = 1,bind = true,rate = 100},
		{id = 70700051,num = 1,bind = true,rate = 100},
		{id = 70700052,num = 1,bind = true,rate = 100},
		{id = 70700053,num = 1,bind = true,rate = 100},
		{id = 70700057,num = 1,bind = true,rate = 100},
		{id = 70700058,num = 1,bind = true,rate = 100},
		{id = 70700059,num = 1,bind = true,rate = 100},
		{id = 70700060,num = 1,bind = true,rate = 100},
		{id = 70700061,num = 1,bind = true,rate = 100},
		{id = 70700062,num = 1,bind = true,rate = 100},
		{id = 70700066,num = 1,bind = true,rate = 100},
		{id = 70700067,num = 1,bind = true,rate = 100},
		{id = 70700068,num = 1,bind = true,rate = 100},
		{id = 70700069,num = 1,bind = true,rate = 100},
		{id = 70700070,num = 1,bind = true,rate = 100},
		{id = 70700071,num = 1,bind = true,rate = 100},
		{id = 70700075,num = 1,bind = true,rate = 100},
		{id = 70700076,num = 1,bind = true,rate = 100},
		{id = 70700077,num = 1,bind = true,rate = 100},
		{id = 70700078,num = 1,bind = true,rate = 100},
		{id = 70700079,num = 1,bind = true,rate = 100},
		{id = 70700080,num = 1,bind = true,rate = 100},
		{id = 70700084,num = 1,bind = true,rate = 100},
		{id = 70700085,num = 1,bind = true,rate = 100},
		{id = 70700086,num = 1,bind = true,rate = 100},
		{id = 70700087,num = 1,bind = true,rate = 100},
		{id = 70700088,num = 1,bind = true,rate = 100},
		{id = 70700089,num = 1,bind = true,rate = 100},
		{id = 70700093,num = 1,bind = true,rate = 100},
		{id = 70700094,num = 1,bind = true,rate = 100},
		{id = 70700095,num = 1,bind = true,rate = 100},
		{id = 70700096,num = 1,bind = true,rate = 100},
		{id = 70700097,num = 1,bind = true,rate = 100},
		{id = 70700098,num = 1,bind = true,rate = 100},
		{id = 70700102,num = 1,bind = true,rate = 100},
		{id = 70700103,num = 1,bind = true,rate = 100},
		{id = 70700104,num = 1,bind = true,rate = 100},
		{id = 70700105,num = 1,bind = true,rate = 100},
		{id = 70700106,num = 1,bind = true,rate = 100},
		{id = 70700107,num = 1,bind = true,rate = 100},
		{id = 70700111,num = 1,bind = true,rate = 100},
		{id = 70700112,num = 1,bind = true,rate = 100},
		{id = 70700113,num = 1,bind = true,rate = 100},
		{id = 70700114,num = 1,bind = true,rate = 100},
		{id = 70700115,num = 1,bind = true,rate = 100},
		{id = 70700116,num = 1,bind = true,rate = 100},
		{id = 70700120,num = 1,bind = true,rate = 100},
		{id = 70700121,num = 1,bind = true,rate = 100},
		{id = 70700122,num = 1,bind = true,rate = 100},
		{id = 70700123,num = 1,bind = true,rate = 100},
		{id = 70700124,num = 1,bind = true,rate = 100},
		{id = 70700125,num = 1,bind = true,rate = 100},
		{id = 70700129,num = 1,bind = true,rate = 100},
		{id = 70700130,num = 1,bind = true,rate = 100},
		{id = 70700131,num = 1,bind = true,rate = 100},
		{id = 70700132,num = 1,bind = true,rate = 100},
		{id = 70700133,num = 1,bind = true,rate = 100},
		{id = 70700134,num = 1,bind = true,rate = 100},
	},



}
function common_item:OnDefaultEvent(selfId, bagIndex)

end

function common_item:IsSkillLikeScript(selfId)
    return 1
end

function common_item:CancelImpacts(selfId)
    return 0
end

function common_item:OnConditionCheck(selfId)
	if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
	local ItemTable = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local CurItem = ItemInfo[ItemTable]
	if not CurItem then
		self:notify_tips(selfId,"Đạo cụ chưa mở")
		return 0
	end
    return 1
end

function common_item:OnDeplete(selfId)
    return 1
end
-- 计算总权重
function common_item:CalcTotalWeight(ItemTable)
	
	local CurItem = ItemInfo[ItemTable]
    local total = 0
	for _,item in ipairs(CurItem) do
		if type(item) == "table" and item.id then
			total = total + item.rate
		end
	end
    return total
end

-- 根据权重抽取奖品索引
function common_item:DrawPrizeIndex(ItemTable)
	
	local CurItem = ItemInfo[ItemTable]
    local totalWeight = self:CalcTotalWeight(ItemTable)
    local randValue = math.random(1, totalWeight)
    local accumulated = 0
	local total = 1

	for _,item in ipairs(CurItem) do
		if type(item) == "table" and item.id then
			accumulated = accumulated + item.rate
			
        	if randValue <= accumulated then
         	   return total
       	 	end
				total=total+1
		end
	end
    return 1
end

function common_item:OnActivateOnce(selfId)
	local ItemTable = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local CurItem = ItemInfo[ItemTable]
	if not CurItem then
		self:notify_tips(selfId,"Đạo cụ chưa mở")
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= ItemTable then
		return 0
	end
	local give = {}
	self:BeginAddItem()

	-- 检查是否随机给一个
	if CurItem.random_one then
		-- 随机选择一个物品给予
		local available_items = {}
		for _,item in ipairs(CurItem) do
			if type(item) == "table" and item.id then
				available_items[#available_items + 1] = item
			end
		end

		if #available_items > 0 then
			local selected_item = available_items[math.random(1, #available_items)]
			if not selected_item.num_max then
				self:AddItem(selected_item.id, selected_item.num, selected_item.bind)
				table.insert(give, {selected_item.id, selected_item.num})
			else
				local num = math.random(selected_item.num, selected_item.num_max)
				self:AddItem(selected_item.id, num, selected_item.bind)
				table.insert(give, {selected_item.id, num})
			end
		end
	else
		-- 原来的逻辑：按概率给予多个物品
		local prizeIndex = self:DrawPrizeIndex(ItemTable)
		--self:notify_tips(selfId,prizeIndex)
		self:AddItem(CurItem[prizeIndex].id,CurItem[prizeIndex].num,CurItem[prizeIndex].bind)
		table.insert(give,{CurItem[prizeIndex].id,CurItem[prizeIndex].num})
		self:AddItem(20502004,1,false)
		table.insert(give,{20502004,1})
		self:AddItem(20501004,1,false)
		table.insert(give,{20501004,1})

	end
	if not self:EndAddItem(selfId) then
		return 0
	end
	self:LuaFnDecItemLayCount(selfId,usepos,1)
	self:AddItemListToHuman(selfId)

	-- 检查是否为幸运盲盒道具，进行世界广播
	if ItemTable == 38008207 and #give > 0  then
		--增加盲盒积分
		local curDrawCount = self:GetMissionData(selfId, self.MD_DrawCount)
		self:SetMissionData(selfId, self.MD_DrawCount, curDrawCount + 1)

		local player_name = self:GetName(selfId)
		for _,item in ipairs(give) do
			if item[1] ~= 20502004 and item[1] ~= 20501004  
			and item[1] ~= 20800000 and item[1] ~= 20800002 
			and item[1] ~= 20800004 and item[1] ~= 20800006 
			and item[1] ~= 20800008 and item[1] ~= 20800010 
			  then
				local item_name = self:GetItemName(item[1])
				local broadcast_msg = string.format("[%s]#Wmở#YHộp mù may mắn#W, nhận được#G[%s]", player_name, item_name)
				self:AddGlobalCountNews(broadcast_msg)
			end

		end
	end

	for _,item in ipairs(give) do
		self:GiveItemTip(selfId,item[1],item[2])
	end
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
    return 1
end

function common_item:OnActivateEachTick(selfId)
    return 1
end

return common_item
