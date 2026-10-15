local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local all_activity_npc = class("all_activity_npc", script_base)
all_activity_npc.script_id = 999980
--万能传送
--scenename 目标场景名称
--sceneid 	目标场景ID
--posx		位置X
--posz		位置Z
--needlevel 需求等级   不需要的话可写0 也可以删掉此项
--[[
all_activity_npc.universal_transfer = 
{
	{
		msgtitle = "主城传送",
		sceneinfo =
		{
			{scenename = "苏州 ",sceneid = 1,posx = 114,posz = 162,needlevel = 10},
			{scenename = "苏州 - 铁匠铺 ",sceneid = 1,posx = 235,posz = 132,needlevel = 10},
			{scenename = "大理 ",sceneid = 2,posx = 241,posz = 141,needlevel = 10},
			{scenename = "楼兰 ",sceneid = 186,posx = 288,posz = 136,needlevel = 10},
			{scenename = "束河古镇 ",sceneid = 420,posx = 200,posz = 211,needlevel = 10},
			{scenename = "洛阳 - 南海千洲 ",sceneid = 0,posx = 199,posz = 199,needlevel = 10},
		},
	},
	{
		msgtitle = "升级传送",
		sceneinfo =
		{
			--{scenename = "敦煌 ",sceneid = 8,posx = 240,posz = 170,needlevel = 10},
			{scenename = "摩崖洞 ",sceneid = 170,posx = 38,posz = 220,needlevel = 20},
			{scenename = "古墓一层 ",sceneid = 159,posx = 107,posz = 94,needlevel = 30},
			{scenename = "古墓三层 ",sceneid = 161,posx = 13,posz = 25,needlevel = 40},
			{scenename = "古墓七层 ",sceneid = 165,posx = 25,posz = 108,needlevel = 50},
			{scenename = "地宫一层 ",sceneid = 400,posx = 60,posz = 90,needlevel = 60},
			{scenename = "地宫三层 ",sceneid = 402,posx = 131,posz = 128,needlevel = 60},
			{scenename = "地四中部入口 ",sceneid = 1299,posx = 90,posz = 128,needlevel = 60},
			{scenename = "地四东北入口 ",sceneid = 1299,posx = 215,posz = 85,needlevel = 60},
			{scenename = "地四东南入口 ",sceneid = 1299,posx = 208,posz = 168,needlevel = 60},
			{scenename = "地四西南入口 ",sceneid = 1299,posx = 80,posz = 205,needlevel = 60},
		},
	},
	{
		msgtitle = "副本传送",
		sceneinfo =
		{
			{scenename = "水牢 ",sceneid = 4,posx = 65,posz = 75,needlevel = 10},
			{scenename = "老三环 ",sceneid = 1,posx = 62,posz = 162,needlevel = 10},
			{scenename = "燕子坞 ",sceneid = 4,posx = 70,posz = 120,needlevel = 10},
			{scenename = "新三环 ",sceneid = 186,posx = 295,posz = 67,needlevel = 10},
			{scenename = "杀星 ",sceneid = 2,posx = 131,posz = 76,needlevel = 10},
			{scenename = "缥缈峰 ",sceneid = 186,posx = 189,posz = 218,needlevel = 10},
			{scenename = "水月山庄 ",sceneid = 1,posx = 130,posz = 108,needlevel = 10},
			{scenename = "青丘试炼 ",sceneid = 1,posx = 135,posz = 80,needlevel = 10},
			{scenename = "往日梦境 ",sceneid = 2,posx = 248,posz = 59,needlevel = 10},
		},
	},
	{
		msgtitle = "野外传送",
		sceneinfo =
		{
			{scenename = "镜湖 ",sceneid = 5,posx = 277,posz = 46,needlevel = 10},
			{scenename = "草原 ",sceneid = 20,posx = 278,posz = 255,needlevel = 10},
			{scenename = "苍山 ",sceneid = 25,posx = 164,posz = 57,needlevel = 10},
			{scenename = "武夷 ",sceneid = 32,posx = 45,posz = 44,needlevel = 10},
			{scenename = "玄武岛 ",sceneid = 39,posx = 92,posz = 31,needlevel = 10},
			{scenename = "玄武岛镜 ",sceneid = 41,posx = 71,posz = 42,needlevel = 10},
			{scenename = "圣兽山顶 ",sceneid = 158,posx = 86,posz = 68,needlevel = 10},

		},
	},
}

--]]


--尸王争夺 带着BUFF坚持到最后玩家奖励
all_activity_npc.shiwangzengduo_award = 
{
  {itemid = 38008173,count = 1,isbind = true},
}


--帮会首领 伤害前十奖励配置
all_activity_npc.banghuishouling_award = 
{
  [1] = {
   {itemid = 38008168,count = 10,isbind = true},
  },
  [2] = {
     {itemid = 38008168,count = 9,isbind = true},
  },
  [3] = {
    {itemid = 38008168,count = 8,isbind = true},
  },
  [4] = {
    {itemid = 38008168,count = 7,isbind = true},
  },
  [5] = {
    {itemid = 38008168,count = 6,isbind = true},
  },
  [6] = {
    {itemid = 38008168,count = 5,isbind = true},
  },
  [7] = {
    {itemid = 38008168,count = 4,isbind = true},
  },
  [8] = {
    {itemid = 38008168,count = 3,isbind = true},
  },
  [9] = {
    {itemid = 38008168,count = 2,isbind = true},
  },
  [10] = {
    {itemid = 38008168,count = 1,isbind = true},
  },
}



all_activity_npc.warinfo = 
{
	{
		sceneId = 313,
		name = "#GThủ lĩnh bang hội",
		posx_min = 17,
		posx_max = 45,
		posz_min = 30,
		posz_max = 49,
	},
	{
		sceneId = 314,
		name = "#GQuà heo vàng",
		posx_min = 12,
		posx_max = 44,
		posz_min = 16,
		posz_max = 47,
	},
	{
		sceneId = 315,
		name = "#GTranh đoạt Thi Vương",
		posx_min = 15,
		posx_max = 44,
		posz_min = 17,
		posz_max = 46,
	},
	{
		sceneId = 713,
		name = "#GĐại chiến Ngưu Ma Vương",
		posx_min = 159,
		posx_max = 178,
		posz_min = 82,
		posz_max = 100,
	},
	{
		sceneId = 714,
		name = "#GĐại chiến Tôn Ngộ Không",
		posx_min = 46,
		posx_max = 60,
		posz_min = 99,
		posz_max = 128,
	},
	{
		sceneId = 715,
		name = "#GĐại chiến Nhị Lang Thần",
		posx_min = 112,
		posx_max = 149,
		posz_min = 60,
		posz_max = 92,
	},

}
--内测道具领取配置
all_activity_npc.neice_info =
{
	{listname = "#GNhóm loại khác",
	 item = {
			 {30900057,1},			--一次1个 
			 {20600003,20},			--一次20个 
			 
			 {10155002,1},			--一次1个 
			 {38002397,250},			--一次20个 
			 {38008160,250},			--一次1个 
			 {38002499,250},			--一次20个 
			 
			},
	},
	{listname = "#GLoại chế trang bị",
	 item = {
			 {20501004,100},			--一次100个
			 {20502004,100},			--一次100个
			 {38003055,100},			--一次100个
			 
			},
	},
	
	{listname = "#GLoại Điêu văn",
	 item = {
			 {20502009,50},			--一次50个
			 {30700232,50},			--一个50个
			 {30503118,50},			-- 一次50个
	 
			 {30120145,1},			-- 一次1个 
			 {30120066,1},			-- 一次1个 
			 {30120067,1},			--一次1个 
			 {30120068,1},			--一次1个 
			 {30120069,1},			--一次1个 
			 {30120050,1},			--一次1个 
			 {30120042,1},			-- 一次1个 
			 {30120041,1},			--一次1个 
			 {30120035,1},			-- 一次1个 
			 {30120036,1},			--一次1个 
			 {30120037,1},			--一次1个 
			 {30120038,1},			--一次1个 
			 {30120028,1},			--一次1个 
			 {30120014,1},			--一次1个 
			 {30120015,1},			--一次1个 
			 {30120016,1},			--一次1个 
			 {30120017,1},			--一次1个 
			 {30120010,1},			--一次1个 
			 {30120008,1},			--一次1个 
			 
			},
	},
	{listname = "#GLoại Võ Hồn",
	 item = {
			 {10156001,1},			--     一次1个
			 {10156002,1},			--     一次1个
			 {30700226,1},			--     一次1个
			 {30700227,1},			--     一次1个
			 {30700228,1},			--    一个1个
			 {30700229,1},			--   一次1个
			 {30700222,1},			--   一次1个
			 {30700223,1},			--  一次1个
			 {30700224,1},			-- 一次1个
			 {30700225,1},			-- 一次1个
			 {30700218,1},			-- 一次1个
			 {30700219,1},			-- 一次1个
			 {30700220,1},			-- 一次1个
			 {30700221,1},			-- 一次1个
	 
			 {20800010,250},			--  一次250个
			 {20800008,250},			--  一次250个
			 {20800004,250},			--  一次250个
			 {20800006,250},			-- 一次250个
			 {20800002,250},			--一次250个
			 {20800000,250},			-- 一次250个
	 
			},
	},
	
	
	
}




function all_activity_npc:OnDefaultEvent(selfId, targetId)
	if not targetId or targetId < 0 then return end
	local monster = self.scene:get_obj_by_id(targetId)
	if not monster then return end
	if monster:get_obj_type() ~= "monster" then return end
	self:MonsterAI_SetIntParamByIndex(targetId, 5, self.script_id)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then return end
	local guid = obj:get_guid()
	local shiwang_true = self:GetActivityWar("shiwangzhengduo","playerguid",guid,"findOne")
	local shouling_true = self:GetActivityWar("banghuishouling","playerguid",guid,"findOne")
    self:BeginEvent(self.script_id)
    self:AddText("    Giang hồ Bách Hiểu Sinh: hoạt động chiến trường và thưởng cứ tìm lão phu.\\nNgoài ra lão phu còn nhiều dịch vụ tiện lợi cho khách quan!")
	if shiwang_true then
		self:AddNumText("#b#HNhận thưởng tranh đoạt Thi Vương",6,-1)
	end
	if shouling_true then
		local awardtime = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_AWARDTIME)
		if awardtime < shouling_true.opentime then
			self:AddNumText("#b#HNhận thủ lĩnh bang hội thứ ["..shouling_true.topid.."]thưởng",6,-2)
		end
	end
	for i,j in ipairs(self.warinfo) do
		if self:LuaFnGetCopySceneData_Param(j.sceneId,1) > 0 then
			self:AddNumText(j.name.."#BĐang diễn ra...",6,i)
		end
	end
	if ScriptGlobal.is_internal_test then
		self:AddNumText("#b#GNhận đạo cụ trải nghiệm test",6,-3)
	end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function all_activity_npc:OnEventRequest(selfId, targetId, arg, index)
	if not targetId or targetId < 0 then return end
	local monster = self.scene:get_obj_by_id(targetId)
	if not monster then return end
	if monster:get_obj_type() ~= "monster" then return end
	if self:MonsterAI_GetIntParamByIndex(targetId,5) ~= self.script_id then
		return
	end
	if index == 0 then
		self:OnDefaultEvent(selfId, targetId)
		return
	elseif index == -3 then
		if ScriptGlobal.is_internal_test then
			local maxlist = #self.neice_info
			if maxlist == 0 then
				self:BeginEvent(self.script_id)
				self:AddText("    Giang hồ Bách Hiểu Sinh: chưa có cấu hình thưởng.")
				self:AddNumText("Làm phiền rồi..",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
				return
			elseif maxlist > 9 then
				maxlist = 9
			end
			self:BeginEvent(self.script_id)
			self:AddText("    Giang hồ Bách Hiểu Sinh: xin chọn thưởng phân loại dưới.")
			for i = 1,maxlist do
				self:AddNumText(self.neice_info[i].listname,6,2000 + i * 100 + 10)
			end
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
	elseif index == -2 then
		self:BangHuiShouLing_Damage(selfId,0)
		return
	elseif index == -1 then
		local obj = self.scene:get_obj_by_id(selfId)
		if not obj then return end
		local guid = obj:get_guid()
		local shiwang_true = self:GetActivityWar("shiwangzhengduo","playerguid",guid,"findOne")
		if shiwang_true then
			local msgtab = {"    Chi tiết thưởng Thi Vương mới:",}
			self:BeginAddItem()
			for i,j in ipairs(self.shiwangzengduo_award) do
				table.insert(msgtab,self:GetItemName(j.itemid).." * "..tostring(j.count).."\n")
				self:AddItem(j.itemid,j.count,j.isbind)
			end
			if not self:EndAddItem(selfId) then
				return
			end
			shiwang_true.playerguid = 0
			shiwang_true.warini = "Thưởng: đã nhận"
			self:UpdateActivityWar("shiwangzhengduo",false,false,shiwang_true)
			local shiwang_true = self:GetActivityWar("shiwangzhengduo","playerguid",guid,"findOne")
			if not shiwang_true then
				self:AddItemListToHuman(selfId)
				local msg = table.concat(msgtab)
				self:BeginEvent(self.script_id)
				self:AddText(msg)
				self:EndEvent()
				self:DispatchEventList(selfId,selfId)
			end
		end
		return
	end
	--<=100
	local startid = 1
	local endid = #self.warinfo
	if index >= startid and index <= endid then
		local warinfo = self.warinfo[index]
		if not warinfo then
			return
		end
		if self:LuaFnGetCopySceneData_Param(warinfo.sceneId,1) > 0 then
			if self:LuaFnHasTeam(selfId) then
				self:BeginEvent(self.script_id)
				self:AddText("    Chiến trường không cho vào theo đội, lập đội bên trong cũng bị đưa ra đấy.")
				self:AddNumText("wow~, cảm ơn đã báo.",11,0)
				self:AddNumText("Được, biết rồi.",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
				return
			end
			if warinfo.sceneId == 314 then
				local maxcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,15)
				local curcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,14)
				if curcount >= maxcount then
					local msgtab = {
					"    ",
					warinfo.name,
					"#WSố người tham số:#G",
					curcount,
					"#W / #G",
					maxcount,
					"#cff0000\\nĐã đủ người, tạm không tới được, xin chờ biến động rồi chọn lúc vào.",
					}
					local msg = table.concat(msgtab)
					self:BeginEvent(self.script_id)
					self:AddText(msg)
					self:AddNumText("wow~, cảm ơn đã báo.",11,0)
					self:AddNumText("Được, biết rồi.",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				end
			end
			self:BeginEvent(self.script_id)
			self:AddText("    Ngươi sắp tới"..warinfo.name.."#Wchiến trường, xin xác nhận.")
			self:AddNumText(warinfo.name.."gogogo, lên đường...",6,index + 100)
			self:AddNumText(warinfo.name.."Nguy hiểm quá, để ta nghĩ đã",11,0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText("    Theo lão phu biết,"..warinfo.name.."#WChưa mở, vào cũng bị đá ra đấy, chắc ăn thì chờ thời cơ.")
			self:AddNumText("wow~, cảm ơn đã báo.",11,0)
			self:AddNumText("Được, biết rồi.",11,0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
		return
	end
	-- >=101 and <=200
	startid = startid + 100
	endid = endid + 100
	if index >= startid and index <= endid then
		local idx = index - 100
		local warinfo = self.warinfo[idx]
		if not warinfo then
			return
		end
		if self:LuaFnGetCopySceneData_Param(warinfo.sceneId,1) > 0 then
			if self:LuaFnHasTeam(selfId) then
				self:BeginEvent(self.script_id)
				self:AddText("    Chiến trường không cho vào theo đội, lập đội bên trong cũng bị đưa ra đấy.")
				self:AddNumText("wow~, cảm ơn đã báo.",11,0)
				self:AddNumText("Được, biết rồi.",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
				return
			end
			if warinfo.sceneId == 314 then
				local maxcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,15)
				local curcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,14)
				if curcount >= maxcount then
					local msgtab = {
					"    ",
					warinfo.name,
					"#WSố người tham số:#G",
					curcount,
					"#W / #G",
					maxcount,
					"#cff0000\\nĐã đủ người, tạm không tới được, xin chờ biến động rồi chọn lúc vào.",
					}
					local msg = table.concat(msgtab)
					self:BeginEvent(self.script_id)
					self:AddText(msg)
					self:AddNumText("wow~, cảm ơn đã báo.",11,0)
					self:AddNumText("Được, biết rồi.",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				end
			end
			local posx = math.random(warinfo.posx_min,warinfo.posx_max)
			local posz = math.random(warinfo.posz_min,warinfo.posz_max)
			self:NewWorld(selfId,warinfo.sceneId,nil,posx,posz)
		end
		return
	end
	startid = 2000
	endid = 2999
	if index >= startid and index <= endid then
		-- self:notify_tips(selfId,"选中"..(index))
		if ScriptGlobal.is_internal_test then
			local newindex = index % 1000
			local lx_index = newindex // 100
			newindex = newindex % 100
			local page_index = newindex // 10
			local item_index = newindex % 10
		-- self:notify_tips(selfId,"lx_index"..(lx_index))
		-- self:notify_tips(selfId,"page_index"..(page_index))
		-- self:notify_tips(selfId,"item_index"..(item_index))
			local haveaward = self.neice_info[lx_index]
			if not haveaward then
				self:BeginEvent(self.script_id)
				self:AddText("    Giang hồ Bách Hiểu Sinh: không có phân loại này >> "..tostring(lx_index))
				self:AddNumText("Về phân loại",11,-3)
				self:AddNumText("Về trang đạo cụ",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
				return
			end
			local itemaward = haveaward.item
			if not itemaward or #itemaward < 1 then
				self:BeginEvent(self.script_id)
				self:AddText("    Giang hồ Bách Hiểu Sinh:["..tostring(haveaward.listname).."]chưa cấu hình thưởng.")
				self:AddNumText("Về phân loại",11,-3)
				self:AddNumText("Về trang đạo cụ",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
				return
			end
			if item_index == 0 then
				local itemname
				local headindex = 2000
				local uppage_index = page_index - 1
				local downpage_index = page_index + 1
				local item_over = page_index * 9
				local item_statr = item_over - 8
				local maxpage = math.ceil(#itemaward / 9)
				if maxpage > 9 then
					maxpage = 9
				end
				newindex = headindex + lx_index * 100 + page_index * 10
				local idx = 0
				self:BeginEvent(self.script_id)
				self:AddText("    Giang hồ Bách Hiểu Sinh: xin chọn ["..haveaward.listname.."]#WThưởng:")
				if uppage_index > 0 then
					self:AddNumText("#b#PTrang trước",6,headindex + lx_index * 100 + uppage_index * 10)
				end
				for i = item_statr,item_over do
					idx = idx + 1
					if i <= #itemaward then
						if itemaward[i] then
							itemname = self:GetItemName(itemaward[i][1])
							if itemname ~= -1 then
								self:AddNumText("#B"..itemname.."#W * #B"..tostring(itemaward[i][2]),6,newindex + idx)
							end
						end
					end
				end
				if downpage_index > 1 and downpage_index <= maxpage then
					self:AddNumText("#b#PTrang sau",6,headindex + lx_index * 100 + downpage_index * 10)
				end
				self:AddNumText("Về phân loại",11,-3)
				self:AddNumText("Về trang đạo cụ",11,0)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			else
				item_index = item_index + page_index * 9 - 9
				if not itemaward[item_index] then
					self:BeginEvent(self.script_id)
					self:AddText("    Giang hồ Bách Hiểu Sinh:["..tostring(haveaward.listname).."] >> "..tostring(item_index))
					self:AddNumText("Về phân loại",11,-3)
					self:AddNumText("Về trang đạo cụ",11,0)
					self:EndEvent()
					self:DispatchEventList(selfId, targetId)
					return
				end
				if ScriptGlobal.is_internal_test then
					self:BeginAddItem()
					self:AddItem(itemaward[item_index][1],itemaward[item_index][2],true);
					if not self:EndAddItem(selfId) then
						return
					end
					self:AddItemListToHuman(selfId)
					self:notify_tips(selfId,"Nhận thành công"..self:GetItemName(itemaward[item_index][1])..tostring(itemaward[item_index][2]).."cái.")
				end
			end
		end
	end
end
function all_activity_npc:BangHuiShouLing_Damage(selfId,index)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then return end
	
	if not index or index < 0 or index > #self.banghuishouling_award then
		return
	elseif index == 0 then
		local obj = self.scene:get_obj_by_id(selfId)
		if not obj then return end
		local guid = obj:get_guid()
		local shouling_true = self:GetActivityWar("banghuishouling","playerguid",guid,"findOne")
		if shouling_true then
			local topid = shouling_true.topid
			local msgtab = {"    Chi tiết thưởng Thi Vương mới:",}
			self:BeginAddItem()
			for i,j in ipairs(self.banghuishouling_award[topid]) do
				table.insert(msgtab,self:GetItemName(j.itemid).." * "..tostring(j.count).."\n")
				self:AddItem(j.itemid,j.count,j.isbind)
			end
			if not self:EndAddItem(selfId) then
				return
			end
			shouling_true.playerguid = 0
			shouling_true.warini = "Thưởng: đã nhận"
			self:UpdateActivityWar("banghuishouling","topid",topid,shouling_true)
			local shouling_true = self:GetActivityWar("shiwangzhengduo","playerguid",guid,"findOne")
			if not shouling_true then
				self:AddItemListToHuman(selfId)
				local msg = table.concat(msgtab)
				self:BeginEvent(self.script_id)
				self:AddText(msg)
				self:EndEvent()
				self:DispatchEventList(selfId,selfId)
			end
		end
	else
		local awardinfo = self.banghuishouling_award[index]
		if not awardinfo then
			obj:notify_tips("Thứ ["..tostring(index).."]hạng chưa cấu hình thưởng, xin báo GM.")
			return
		end
		local awardmsgtab = {"    Bảng sát thương thứ [",index,"]chi tiết thưởng hạng:",}
		for i,j in ipairs(awardinfo) do
			table.insert(awardmsgtab,self:GetItemName(j.itemid))
			table.insert(awardmsgtab," * ")
			table.insert(awardmsgtab,j.count)
			if j.isbind then
				table.insert(awardmsgtab,"(Khóa)\\n")
			else
				table.insert(awardmsgtab,"\n")
			end
		end
		local awardmsg = table.concat(awardmsgtab)
		self:BeginEvent(self.script_id)
		self:AddText(awardmsg)
		self:EndEvent()
		self:DispatchEventList(selfId, selfId)
	end
end
return all_activity_npc
