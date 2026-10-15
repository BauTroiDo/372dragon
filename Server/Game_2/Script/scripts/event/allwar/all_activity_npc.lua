local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local all_activity_npc = class("all_activity_npc", script_base)
all_activity_npc.script_id = 999980
--快捷传送是否开启  false = 不开启  true = 开启
all_activity_npc.transfer_is_open = true
--万能传送
--scenename 目标场景名称
--sceneid 	目标场景ID
--posx		位置X
--posz		位置Z
--needlevel 需求等级   不需要的话可写0 也可以删掉此项

all_activity_npc.universal_transfer = 
{
	{
		msgtitle = "Truyền tống chủ thành",
		sceneinfo =
		{
			{scenename = "Tô Châu ",sceneid = 1,posx = 114,posz = 162,needlevel = 10},
			{scenename = "Tô Châu - Tiệm Thợ rèn ",sceneid = 1,posx = 235,posz = 132,needlevel = 10},
			{scenename = "Đại Lý ",sceneid = 2,posx = 241,posz = 141,needlevel = 10},
			{scenename = "Lâu Lan ",sceneid = 186,posx = 288,posz = 136,needlevel = 10},
			{scenename = "束河古镇 ",sceneid = 420,posx = 200,posz = 211,needlevel = 10},
			{scenename = "Lạc Dương - Nam Hải Thiên Châu ",sceneid = 0,posx = 199,posz = 199,needlevel = 10},
		},
	},
	{
		msgtitle = "Truyền tống thăng cấp",
		sceneinfo =
		{
			--{scenename = "敦煌 ",sceneid = 8,posx = 240,posz = 170,needlevel = 10},
			{scenename = "Ma Nhai Động ",sceneid = 170,posx = 38,posz = 220,needlevel = 20},
			{scenename = "Cổ Mộ Tầng Một ",sceneid = 159,posx = 107,posz = 94,needlevel = 30},
			{scenename = "Cổ Mộ tầng 3 ",sceneid = 161,posx = 13,posz = 25,needlevel = 40},
			{scenename = "Cổ Mộ tầng 7 ",sceneid = 165,posx = 25,posz = 108,needlevel = 50},
			{scenename = "Địa Cung tầng một ",sceneid = 400,posx = 60,posz = 90,needlevel = 60},
			{scenename = "Địa Cung tầng ba ",sceneid = 402,posx = 131,posz = 128,needlevel = 60},
			{scenename = "Cửa giữa Địa Tứ ",sceneid = 1303,posx = 90,posz = 128,needlevel = 60},
			{scenename = "Cửa Đông Bắc Địa Tứ ",sceneid = 1303,posx = 215,posz = 85,needlevel = 60},
			{scenename = "Cửa Đông Nam Địa Tứ ",sceneid = 1303,posx = 208,posz = 168,needlevel = 60},
			{scenename = "Cửa Tây Nam Địa Tứ ",sceneid = 1303,posx = 80,posz = 205,needlevel = 60},
		},
	},
	{
		msgtitle = "Chuyển Tống Phó Bản",
		sceneinfo =
		{
			{scenename = "水牢 ",sceneid = 4,posx = 65,posz = 75,needlevel = 10},
			{scenename = "Lão Tam Khuyên ",sceneid = 1,posx = 62,posz = 162,needlevel = 10},
			{scenename = "燕子坞 ",sceneid = 4,posx = 70,posz = 120,needlevel = 10},
			{scenename = "Tân Tam Khuyên ",sceneid = 186,posx = 295,posz = 67,needlevel = 10},
			{scenename = "Sát Tinh ",sceneid = 2,posx = 131,posz = 76,needlevel = 10},
			{scenename = "Phiêu Miễu Phong ",sceneid = 186,posx = 189,posz = 218,needlevel = 10},
			{scenename = "Thủy Nguyệt Sơn Trang ",sceneid = 1,posx = 130,posz = 108,needlevel = 10},
			{scenename = "Thanh Khâu Thí Luyện ",sceneid = 1,posx = 135,posz = 80,needlevel = 10},
			{scenename = "Vãng Nhật Mộng Cảnh ",sceneid = 2,posx = 248,posz = 59,needlevel = 10},
		},
	},
	{
		msgtitle = "Truyền tống dã ngoại",
		sceneinfo =
		{
			{scenename = "Kính Hồ ",sceneid = 5,posx = 277,posz = 46,needlevel = 10},
			{scenename = "Thảo Nguyên ",sceneid = 20,posx = 278,posz = 255,needlevel = 10},
			{scenename = "Thương Sơn ",sceneid = 25,posx = 164,posz = 57,needlevel = 10},
			{scenename = "Võ Di ",sceneid = 32,posx = 45,posz = 44,needlevel = 10},
			{scenename = "Huyền Võ Đảo ",sceneid = 39,posx = 92,posz = 31,needlevel = 10},
			{scenename = "Huyền Vũ Đảo Kính ",sceneid = 41,posx = 71,posz = 42,needlevel = 10},
			{scenename = "Đỉnh Thánh Thú Sơn ",sceneid = 158,posx = 86,posz = 68,needlevel = 10},

		},
	},
}




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


all_activity_npc.war_config = 
{
	{
		sceneId = 713,
		name = "#GĐại chiến Ngưu Ma Vương",
		script_id = 999983,
		posx_min = 159,
		posx_max = 178,
		posz_min = 82,
		posz_max = 100,
	},
	{
		sceneId = 714,
		name = "#GĐại chiến Tôn Ngộ Không",
		script_id = 999983,
		posx_min = 46,
		posx_max = 60,
		posz_min = 99,
		posz_max = 128,
	},
	{
		sceneId = 715,
		name = "#GĐại chiến Nhị Lang Thần",
		script_id = 999983,
		posx_min = 112,
		posx_max = 149,
		posz_min = 60,
		posz_max = 92,
	},
	{
		sceneId = 490,
		name = "#GBăng Tuyết Bất Dạ Thành",
		script_id = 999992,
		 posx_min = 130,
		 posx_max = 180,
		 posz_min = 140,
		 posz_max = 191,
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
		sceneId = 315,
		name = "#GTranh đoạt Thi Vương",
		posx_min = 15,
		posx_max = 44,
		posz_min = 17,
		posz_max = 46,
	},

}
--内测道具领取配置
all_activity_npc.neice_info =
{
	{listname = "#GNhóm loại khác",
	 item = {
			 {30900057,1},			--一次1个  
			 {20600003,20},			--一次20个 
			 {38008177,5},	 
			 
			 {10155002,1},			--一次1个 
			 {38008160,250},			--一次1个 
			 {38002499,250},			--一次20个 
			 {38002397,500},			--一次20个 
			 {30008117,10},			--一次20个 
			 {20310219,50},			--一次20个 
			 
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
	{listname = "#GLoại khắc điêu văn",
	 item = {
			 {38003158,10},			--一次50个
			 {30900200,1},			-- 一次1个 
			 {30900201,1},			-- 一次1个 
			 {30900202,1},			-- 一次1个 
			 {30900203,1},			-- 一次1个 
			 {30900204,1},			--一次1个 
			 {30900205,1},			--一次1个 
			 {30900206,1},			--一次1个 
			 {30900207,1},			--一次1个 
			 {30900208,1},			-- 一次1个 
			 {30900209,1},			--一次1个 
			 {30900210,1},			-- 一次1个 
			 {30900211,1},			--一次1个 
			 {30900212,1},			--一次1个 
			 {30900213,1},			--一次1个 			 
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
	{listname = "#GLoại Thất Tình",
	 item = {
			 {20900001,250},			--  一次250个
			 {38002900,250},			--  一次250个
			 {38002901,250},			--  一次250个 
			 {38002969,250},			--  一次250个 
			 {38002970,250},			--  一次250个 
			 {38002971,250},			--  一次250个 
			 {38002902,1},			-- 一次250个
			 {38002903,1},			--一次250个
			 {38002904,1},			-- 一次250个
			 {38002905,1},			-- 一次250个
			 {38002906,1},			--一次250个
			 {38002907,1},			-- 一次250个
			 {38002908,1},			-- 一次250个
			 {38002909,1},			--一次250个
			 {38002910,1},			-- 一次250个
			 {38002911,1},			-- 一次250个
			 {38002912,1},			--一次250个
			 {38002913,1},			-- 一次250个		
			 {38002914,1},			-- 一次250个
			 {38002915,1},			--一次250个
			 {38002916,1},			-- 一次250个	
			 {38002917,1},			-- 一次250个
			 {38002918,1},			--一次250个
			 {38002919,1},			-- 一次250个				 
			},
	},
	
	
}


function all_activity_npc:call_back_neice_info(selfId)
	return self.neice_info
end
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
	for i,war in ipairs(self.war_config) do
		if self:CallDestSceneFunction(war.sceneId,war.script_id,"CheckActiviyIsOpen") then
			self:AddNumText(war.name.."#BĐang diễn ra...",6,i)
		end
	end
	if ScriptGlobal.is_internal_test then
		self:AddNumText("#b#GNhận đạo cụ trải nghiệm test",6,-3)
		 self:AddNumText("#b#GNhận cấp 102",6,-4)
	end
	if self.transfer_is_open then
		self:AddNumText("#b#GTruyền tống thế giới",6,-1000)
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
	elseif index == -4 then
		if ScriptGlobal.is_internal_test then
			local obj = self:get_scene():get_obj_by_id(selfId)
			obj:set_level(102)
			obj:wash_points()
			obj:notify_tips("Nhận thành công.")
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
    --[[elseif index == 301 then
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(1)
		self:EndUICommand()
		self:DispatchUICommand(selfId,20100118)
		return
    elseif index == 302 then
		local cururl = "http://ste.sanqnet.com:8181/ch/a.html?sid=76093"
		if ScriptGlobal.is_internal_test then
			cururl = "http://ste.sanqnet.com:8181/ch/a.html?sid=34076"
		end
        self:BeginUICommand()
        self:UICommand_AddStr(cururl)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2023120201)
        return--]]
	end
	if self.transfer_is_open then
		if index == -1000 then
			self:BeginEvent(self.script_id)
			self:AddText("    Xin chọn loại truyền tống:")
			for i,cs in ipairs(self.universal_transfer) do
				self:AddNumText("#G"..tostring(cs.msgtitle),6,-1000 - i)
			end
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
			return
		end
		local startid = -1000 - #self.universal_transfer
		local endid = -1001
		if index >= startid and index <= endid then
			local idx = -1 * index - 1000
			local universal_transfer = self.universal_transfer[idx]
			if universal_transfer then
				self:BeginEvent(self.script_id)
				self:AddText("    #B"..universal_transfer.msgtitle..":")
				local ii = -1000 - idx * 20 + 20 - 10
				for i,cs in ipairs(universal_transfer.sceneinfo) do
					self:AddNumText("#GTiến về"..tostring(cs.scenename),6,ii - i)
				end
				self:AddNumText("Quay lại trang trước",11,-1000)
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			else
				self:BeginEvent(self.script_id)
				self:AddText("    #B"..tostring(idx)..":")
				self:EndEvent()
				self:DispatchEventList(selfId, targetId)
			end
			return
		end
		local startid = -1000 - #self.universal_transfer * 20 - 10
		local endid = -1011
		if index >= startid and index <= endid then
			local idx = -1 * index - 1010
			local m_idx = math.ceil(idx / 20)
			local n_idx = idx % 20
			if self.universal_transfer[m_idx] then
				local sceneinfo = self.universal_transfer[m_idx].sceneinfo[n_idx]
				if sceneinfo then
					local goto_scene = sceneinfo.sceneid
					if goto_scene == 1303 then
						local curHour = self:GetHour() * 100 + self:GetMinute()
						if curHour >= 100 and curHour <= 2130 then
							self:notify_tips(selfId,"Vào được lúc 21:30 - 1:00 hôm sau.")
							return
						end
						--local serverid = self:LuaFnGetServerID(selfId)
						--if serverid == 10 or serverid == 11 or serverid == 14 then
							--local cer_week = self:GetWeek()
							--if cer_week == 2 or cer_week == 4 or cer_week == 6 or cer_week == 7 then
								--goto_scene = 1299
							--end
						--end
					end
					-- local str_index
					-- self:BeginEvent(self.script_id)
					-- str_index = tostring(index)
					-- self:AddText(str_index)
					-- str_index = tostring(m_idx)
					-- self:AddText(str_index)
					-- str_index = tostring(n_idx)
					-- self:AddText(str_index)
					-- self:AddText(sceneinfo.scenename)
					-- str_index = tostring(sceneinfo.sceneid)
					-- self:AddText(str_index)
					-- self:AddText(sceneinfo.posx)
					-- self:AddText(sceneinfo.posz)
					-- self:EndEvent()
					-- self:DispatchEventList(selfId, targetId)
					self:CallScriptFunction((400900), "TransferFunc", selfId, goto_scene, sceneinfo.posx, sceneinfo.posz, sceneinfo.needlevel)
				end
			end
			return
		end
	end
	--<=100
	local startid = 1
	local endid = #self.war_config
	if index >= startid and index <= endid then
		local war_config = self.war_config[index]
		if not war_config then
			return
		end
		local ret = self:CallScriptFunction(war_config.script_id,"CheckActiviyParticipation",selfId)
		if ret == 0 then
			self:BeginEvent(self.script_id)
			self:AddText("    Ngươi sắp tới"..war_config.name.."#Wchiến trường, xin xác nhận.")
			self:AddNumText(war_config.name.."gogogo, lên đường...",6,index + 100)
			self:AddNumText(war_config.name.."Nguy hiểm quá, để ta nghĩ đã",11,0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText(ret)
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
		local war_config = self.war_config[idx]
		if not war_config then
			return
		end
		local ret = self:CallScriptFunction(war_config.script_id,"CheckActiviyParticipation",selfId)
		if ret == 0 then
			local posx = math.random(war_config.posx_min,war_config.posx_max)
			local posz = math.random(war_config.posz_min,war_config.posz_max)
			self:NewWorld(selfId,war_config.sceneId,nil,posx,posz)
		else
			self:BeginEvent(self.script_id)
			self:AddText(ret)
			self:AddNumText("wow~, cảm ơn đã báo.",11,0)
			self:AddNumText("Được, biết rồi.",11,0)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
			-- if warinfo.sceneId == 314 then
				-- local maxcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,15)
				-- local curcount = self:LuaFnGetCopySceneData_Param(warinfo.sceneId,14)
				-- if curcount >= maxcount then
					-- local msgtab = {
					-- "    ",
					-- warinfo.name,
					-- "#W参数人数为:#G",
					-- curcount,
					-- "#W / #G",
					-- maxcount,
					-- "#cff0000\n已满员，暂时不可前往，请留意人员变动再择机进场。",
					-- }
					-- local msg = table.concat(msgtab)
					-- self:BeginEvent(self.script_id)
					-- self:AddText(msg)
					-- self:AddNumText("wow~，谢谢告知。",11,0)
					-- self:AddNumText("好的，知道了。",11,0)
					-- self:EndEvent()
					-- self:DispatchEventList(selfId, targetId)
					-- return
				-- end
			-- end
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
					local id,num = itemaward[item_index][1],itemaward[item_index][2]
					if id == 30900058 or id == 30900059 then
						self:BeginAddItem()
						self:AddItem(id,num,true)
						if not self:EndAddItem(selfId,true) then
							return
						end
						for i = 1,num do
							local newpos = self:TryRecieveItem(selfId,id,true)
							if newpos ~= -1 then
								self:SetBagItemParam(selfId, newpos, 4, 30000000, "int", true)
							end
						end
					else
						self:BeginAddItem()
						self:AddItem(id,num,true)
						if not self:EndAddItem(selfId) then
							return
						end
						self:AddItemListToHuman(selfId)
					end
					self:notify_tips(selfId,"Nhận thành công"..self:GetItemName(id)..tostring(num).."cái.")
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
