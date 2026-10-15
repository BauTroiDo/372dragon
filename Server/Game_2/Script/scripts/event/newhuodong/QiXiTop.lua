local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local packet_def = require "game.packet"
-- local gbk = require "wire_charset"
-- local skynet = require "skynet"
local QiXiTop = class("QiXiTop", script_base)
QiXiTop.script_id = 888819
local TopOverHour = 23					--当期花榜结束小时 1-23
local TopOverMinue = 0					--当期花榜结束分钟 0-59
--奖励预览标题  废弃，无需定义此项，自适应识别
-- QiXiTop.PreviewTitle = "#{QRZM_211119_132}"
-- QiXiTop.PreviewTitle = "#{QRZM_211119_164}"
-- QiXiTop.PreviewTitle = "#{QRZM_211119_148}"
--奖励预览送花底图
QiXiTop.PreviewBackgroundImage_Song = "set:LoverTime11 image:LoverTime3_songzuoqi"
-- QiXiTop.PreviewBackgroundImage_Song = "set:LoverTime09 image:LoverTime2_songzhenshou"
-- QiXiTop.PreviewBackgroundImage_Song = "set:LoverTime07 image:LoverTime2_songshizhuang"
--奖励预览收花底图
QiXiTop.PreviewBackgroundImage_Show = "set:LoverTime10 image:LoverTime3_shouzuoqi"
-- QiXiTop.PreviewBackgroundImage_Song = "set:LoverTime08 image:LoverTime2_shouzhenshou"
-- QiXiTop.PreviewBackgroundImage_Song = "set:LoverTime07 image:LoverTime2_shoushizhuang"
--1title 2pet
--收花奖励配置  
--IsPreview = 0 不可预览  
--IsPreview = 3 时装、脸型、发型
local TopShouHuaAward = {
	--名次奖励，不需要的奖励把键位内容删掉即可
	[1] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 700000,
		Titleid = 1285,
		Item = {
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142994,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 3888,			--标准力量资质
				 spr_perception = 3888,			--标准灵气资质
				 con_perception = 3888,			--标准体质资质
				 dex_perception = 3888,			--标准身法资质
				 int_perception = 3888,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[2] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 300000,
		Titleid = 1214,
		Item = {
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142994,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 3288,			--标准力量资质
				 spr_perception = 3288,			--标准灵气资质
				 con_perception = 3288,			--标准体质资质
				 dex_perception = 3288,			--标准身法资质
				 int_perception = 3288,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[3] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 150000,
		Titleid = 1083,
		Item = {
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142994,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 3088,			--标准力量资质
				 spr_perception = 3088,			--标准灵气资质
				 con_perception = 3088,			--标准体质资质
				 dex_perception = 3088,			--标准身法资质
				 int_perception = 3088,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[4] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[5] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[6] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[7] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[8] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[9] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[10] = {Titleid = 1084,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[11] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[12] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[13] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[14] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[15] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[16] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[17] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[18] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[19] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
	[20] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3}}},
}
--送花奖励配置
--IsPreview = 0 不可预览  
--IsPreview = 3 时装、脸型、发型
local TopSongHuaAward = {
	--名次奖励，不需要的奖励把键位内容删掉即可
	[1] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 700000,
		Titleid = 1284,
		Item = {
			{ID = 38008161,Count = 5000,Isbind = false,IsPreview = 0},
			{ID = 38002397,Count = 5000,Isbind = true,IsPreview = 0},
			{ID = 38003055,Count = 300,Isbind = true,IsPreview = 0},
			{ID = 20900001,Count = 2000,Isbind = true,IsPreview = 0},
			{ID = 10126507,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 0},
			--{ID = 70600015,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 4288,			--标准力量资质
				 spr_perception = 4288,			--标准灵气资质
				 con_perception = 4288,			--标准体质资质
				 dex_perception = 4288,			--标准身法资质
				 int_perception = 4288,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[2] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 300000,
		Titleid = 1213,
		Item = {
			{ID = 38008161,Count = 3000,Isbind = false,IsPreview = 0},
			{ID = 38002397,Count = 3000,Isbind = true,IsPreview = 0},
			{ID = 38003055,Count = 200,Isbind = true,IsPreview = 0},
			{ID = 20900001,Count = 1500,Isbind = true,IsPreview = 0},
			{ID = 10126507,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 3688,			--标准力量资质
				 spr_perception = 3688,			--标准灵气资质
				 con_perception = 3688,			--标准体质资质
				 dex_perception = 3688,			--标准身法资质
				 int_perception = 3688,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[3] = {
		--收花最低 该朵数以上方有奖励  不需要条件则删掉此键
		Needcount = 150000,
		Titleid = 1082,
		Item = {
			{ID = 38008161,Count = 2000,Isbind = false,IsPreview = 0},
			{ID = 38002397,Count = 2000,Isbind = true,IsPreview = 0},
			{ID = 38003055,Count = 100,Isbind = true,IsPreview = 0},
			{ID = 20900001,Count = 1000,Isbind = true,IsPreview = 0},
			{ID = 10126507,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10143014,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 25991,						--珍兽ID
			 Arrt = {
				 str_perception = 3488,			--标准力量资质
				 spr_perception = 3488,			--标准灵气资质
				 con_perception = 3488,			--标准体质资质
				 dex_perception = 3488,			--标准身法资质
				 int_perception = 3488,			--标准定力资质
				 growth_rate = 2.188,			--成长率
			 }
		 },
	},
	[4] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 600,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 1500,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 50,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 1500,Isbind = false,IsPreview = 0}}},
	[5] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 500,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 1000,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 30,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 1000,Isbind = false,IsPreview = 0}}},
	[6] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 400,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 800,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 20,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 800,Isbind = false,IsPreview = 0}}},
	[7] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 300,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 600,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 10,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 600,Isbind = false,IsPreview = 0}}},
	[8] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 200,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 500,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 10,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 500,Isbind = false,IsPreview = 0}}},
	[9] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 200,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 400,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 10,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 400,Isbind = false,IsPreview = 0}}},
	[10] = {Titleid = 1250,Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 20900001,Count = 200,Isbind = true,IsPreview = 0},{ID = 38002397,Count = 300,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 10,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 300,Isbind = false,IsPreview = 0}}},
	[11] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[12] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[13] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[14] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[15] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[16] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[17] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[18] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[19] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
	[20] = {Item = {{ID = 10126499,Count = 1,Isbind = true,IsPreview = 3},{ID = 30310156,Count = 1,Isbind = true,IsPreview = 2},{ID = 38002397,Count = 200,Isbind = true,IsPreview = 0},{ID = 20900001,Count = 100,Isbind = true,IsPreview = 0},{ID = 38003055,Count = 5,Isbind = true,IsPreview = 0},{ID = 38008161,Count = 200,Isbind = false,IsPreview = 0}}},
}
--开启花榜
--密钥 区服ID 结束时间 UI显示标记   is_new 
function QiXiTop:StartHuaBangTop(selfId, ... )
	local params = { ... }
	local uiflag = tonumber(params[1].uiflag) == 2 and tonumber(params[1].uiflag) or 1
	local curdate = tonumber(os.date("%Y%m%d"))
	local overdate = tonumber(params[1].overdate) or curdate
	local is_new = tonumber(params[1].is_new) == 1
	
	if overdate < curdate then
		self:notify_tips( selfId,"Ngày sai." )
		return
	elseif overdate == curdate then
		local timex = os.date("*t")
		local curtime = timex.hour * 60 + timex.min
		local overtime = TopOverHour * 60 + TopOverMinue
		if curtime >= overtime then
			self:notify_tips( selfId,"Thời gian kết thúc sai." )
			return
		end
	end
	local endtime = TopOverHour * 60 + TopOverMinue
	local migration = self:ResetHuaBang(selfId,overdate,endtime,uiflag,is_new)
	if migration >= 1 and migration <= 3 then
		local topname = define.FLOWER_TOP_NAME[uiflag][migration] or "Bảng hoa"
		local msg = "#B"..topname.."#PBảng hoa mở ngay."
		self:AddGlobalCountNews_Fun(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",msg)
		self:notify_tips( selfId,msg )
	else
		self:notify_tips( selfId,"Mở bảng hoa thất bại, xin kiểm có bảng hoa đang chạy hoặc đang ở cảnh liên server." )
	end
end
--关闭花榜
--密钥 区服ID
function QiXiTop:CloseHuaBangTop(selfId, ... )
	local params = { ... }
	if self:CloseHuaBangEx(selfId) then
		self:notify_tips( selfId,"Bảng hoa đóng." )
	else
		self:notify_tips( selfId,"Bảng hoa chưa mở, nếu không ẩn icon xin để ý thông báo có ra chưa." )
	end
end
--奖励预览
function QiXiTop:AwardPreview(selfId,migration)
	if not migration or migration < 1 or migration > 3 then
		return
	end
	if not self:CheckTopPreviewCD(selfId,2) then
		return
	end
	local migration_2 = migration + 3
	local world_id = self:LuaFnGetServerID(selfId)
	local curhb_shou = self:GetHuaBangData(world_id,migration,migration_2)
	if #curhb_shou ~= 20 then
		self:notify_tips( selfId,"Tra dữ liệu bảng hoa bất thường, xin đóng hoặc chuyển rồi thao tác lại." )
		return
	end
	local uiflag = curhb_shou[1].uiflag == 2 and curhb_shou[1].uiflag or 1
	local topname = define.FLOWER_TOP_NAME[uiflag][migration] or "Bảng hoa"
	local ui_title = string.format("#gFF0FA0Xem trước thưởng %s",topname)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
    local guid = human:get_guid()
    local msg = packet_def.WGCRetQueryXBWRankCharts.new()
	local datax = {};
	for i = 1,200 do
		datax[i] = {
			-- name = string.rep("",30),
			name = "",
			rank_value_1 = 0,
			level = 0,
			menpai = 0,
			total = 117,
			win = 0,
			rank_value_2 = 0,
			rank_value_3 = 0,
			server_id = 0,
		}
	end
	-- local topneed_song = {"送花奖励需求(无显示的则无需求):"}
	-- local haveneed_song = false
	local index = 0
	local zzx,zzz
	local awardname
	local needmsg
	for i,j in ipairs(TopSongHuaAward) do
		awardname = "Tặng hoa thứ"..tostring(i).."hạng thưởng"
		needmsg = "(Không yêu cầu)"
		if j.Needcount then
			needmsg = "(Cần >="..tostring(j.Needcount).."đóa)"
		end
		-- if j.Needcount then
			-- table.insert(topneed_song,"\n第[")
			-- table.insert(topneed_song,i)
			-- table.insert(topneed_song,"]名 >= ")
			-- table.insert(topneed_song,j.Needcount)
			-- table.insert(topneed_song,"朵")
			-- haveneed_song = true
		-- end
		if j.Titleid then
			index = index + 1
			if awardname then
				datax[index].name = awardname
				awardname = nil
			elseif needmsg then
				datax[index].name = needmsg
				needmsg = nil
			end
			datax[index].level = i
			datax[index].menpai = 1
			datax[index].server_id = 1
			datax[index].win = j.Titleid
		end
		
		if j.Pet then
			-- for k,l in ipairs(j.Pet) do
				index = index + 1
				if awardname then
					datax[index].name = awardname
					awardname = nil
				elseif needmsg then
					datax[index].name = needmsg
					needmsg = nil
				end
				datax[index].level = i
				datax[index].menpai = 2
				datax[index].server_id = 1
				datax[index].win = j.Pet.Dataid
				if j.Pet.Arrt then
					zzx = j.Pet.Arrt.str_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.spr_perception or 0
					if zzz > 21000 then
						zzz = 21000
					end
					datax[index].rank_value_1 = zzx * 100000 + zzz
					zzx = j.Pet.Arrt.con_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.dex_perception or 0
					if zzz > 21000 then
						zzz = 21000
					end
					datax[index].rank_value_2 = zzx * 100000 + zzz
					zzx = j.Pet.Arrt.int_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.growth_rate or 0
					zzz = zzz * 1000
					if zzz > 99999 then
						zzz = 99999
					end
					datax[index].rank_value_3 = zzx * 100000 + zzz
				end
			-- end
		end
		if j.Item then
			for k,l in ipairs(j.Item) do
				index = index + 1
				if awardname then
					datax[index].name = awardname
					awardname = nil
				elseif needmsg then
					datax[index].name = needmsg
					needmsg = nil
				end
				datax[index].level = i
				datax[index].menpai = l.IsPreview
				datax[index].server_id = 1
				datax[index].win = l.ID
				datax[index].rank_value_1 = l.Count
				if l.Isbind then
					datax[index].rank_value_2 = 1
				end
			end
		end
	end
	-- local topneed_shou = {"收花奖励需求(无显示的则无需求):"}
	-- local haveneed_shou = false
	for i,j in ipairs(TopShouHuaAward) do
		awardname = "Nhận hoa thứ"..tostring(i).."hạng thưởng"
		needmsg = "(Không yêu cầu)"
		if j.Needcount then
			needmsg = "(Cần >="..tostring(j.Needcount).."đóa)"
		end
		-- if j.Needcount then
			-- table.insert(topneed_shou,"\n第[")
			-- table.insert(topneed_shou,i)
			-- table.insert(topneed_shou,"]名 >= ")
			-- table.insert(topneed_shou,j.Needcount)
			-- table.insert(topneed_shou,"朵")
			-- haveneed_shou = true
		-- end
		if j.Titleid then
			index = index + 1
			if awardname then
				datax[index].name = awardname
				awardname = nil
			elseif needmsg then
				datax[index].name = needmsg
				needmsg = nil
			end
			datax[index].level = i
			datax[index].menpai = 1
			datax[index].server_id = 2
			datax[index].win = j.Titleid
		end
		if j.Pet then
			-- for k,l in ipairs(j.Pet) do
				index = index + 1
				if awardname then
					datax[index].name = awardname
					awardname = nil
				elseif needmsg then
					datax[index].name = needmsg
					needmsg = nil
				end
				datax[index].level = i
				datax[index].menpai = 2
				datax[index].server_id = 2
				datax[index].win = j.Pet.Dataid
				if j.Pet.Arrt then
					zzx = j.Pet.Arrt.str_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.spr_perception or 0
					if zzz > 21000 then
						zzz = 21000
					end
					datax[index].rank_value_1 = zzx * 100000 + zzz
					zzx = j.Pet.Arrt.con_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.dex_perception or 0
					if zzz > 21000 then
						zzz = 21000
					end
					datax[index].rank_value_2 = zzx * 100000 + zzz
					zzx = j.Pet.Arrt.int_perception or 0
					if zzx > 21000 then
						zzx = 21000
					end
					zzz = j.Pet.Arrt.growth_rate or 0
					zzz = zzz * 1000
					if zzz > 99999 then
						zzz = 99999
					end
					datax[index].rank_value_3 = zzx * 100000 + zzz
				end
			-- end
		end
		if j.Item then
			for k,l in ipairs(j.Item) do
				index = index + 1
				if awardname then
					datax[index].name = awardname
					awardname = nil
				elseif needmsg then
					datax[index].name = needmsg
					needmsg = nil
				end
				datax[index].level = i
				datax[index].menpai = l.IsPreview
				datax[index].server_id = 2
				datax[index].win = l.ID
				datax[index].rank_value_1 = l.Count
				if l.Isbind then
					datax[index].rank_value_2 = 1
				end
			end
		end
	end
	
	
	
	msg.status = 2
    msg.type = 1
    msg.guid = guid
    msg.rank_count = 200
    msg.top_list = datax
	self:get_scene():send2client(human, msg)
	self:BeginUICommand()
	self:UICommand_AddInt(31142021)
	self:UICommand_AddStr(ui_title)
	self:UICommand_AddStr(self.PreviewBackgroundImage_Song)
	self:UICommand_AddStr(self.PreviewBackgroundImage_Show)
	self:EndUICommand()
	self:DispatchUICommand(selfId,31142021)
	
	-- local text_song = ""
	-- local text_shou = ""
	-- if haveneed_song then
		-- text_song = table.concat(topneed_song)
	-- end
	-- if haveneed_shou then
		-- text_shou = table.concat(topneed_shou)
	-- end
	-- local text = text_song ~= "" and text_song.."\n"..text_shou or text_shou
	-- if text ~= "" then
		-- self:BeginEvent(self.script_id)
		-- self:AddText(text)
		-- self:EndEvent()
		-- self:DispatchEventList(selfId,selfId)
	-- end
	
end
--定义描述
function QiXiTop:GetHuaBangMsg(selfId)
	local backtitle = "Thưởng bảng hoa"			--不要标题就写  ""
	local backmsg = "Chi tiết bấm nút xem trước thưởng"
	self:BeginUICommand()
	-- self:UICommand_AddInt(0)
	self:UICommand_AddStr(backtitle)
	self:UICommand_AddStr(backmsg)
	self:EndUICommand()
	self:DispatchUICommand(selfId,137042021)
end

function QiXiTop:OpenHuaBangTop(selfId,openflag)
	if not self:CheckTopOpenUiCD(selfId,3) then
		return
	end
	if not openflag or openflag < 0 or openflag > 3 then
		return
	end
	local migration,overdate,uiflag,old_migration,_,_,back_flag = self:HuaBangCheck(selfId,true)
	local cur_date = self:GetTime2Day()
	if migration == -1 then
		self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID, "OnPlayerUpdateIconDisplay", selfId)
		self:notify_tips(selfId,"Liên server không thao tác được.")
		return
	elseif migration == -2 or cur_date > overdate then
		self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID, "OnPlayerUpdateIconDisplay", selfId)
		self:notify_tips(selfId,"Bảng hoa chưa mở.")
		return
	end
	local cur_openflag = openflag
	if openflag == 0 then
		if migration >= 1 and migration <= 3 then
			cur_openflag = migration
		else
			cur_openflag = old_migration
		end
	end
	if cur_openflag == 0 then
		self:notify_tips(selfId,"Bảng hoa chưa mở..")
		return
	end
	uiflag = uiflag == 2 and uiflag or 1
	if openflag == 0 and cur_openflag == migration then
		local daibi_md = uiflag == 1 and ScriptGlobal.MD_QINGRENJIEDAIBI or ScriptGlobal.MD_QIXIHUOBI
		self:UpdateHuaBang(selfId,selfId,0,daibi_md,0)
	end
	local topname = define.FLOWER_TOP_NAME[uiflag][cur_openflag] or "Bảng hoa"
	local world_id = self:LuaFnGetServerID(selfId)
	local curhb_shou,curhb_song = self:GetHuaBangData(world_id,cur_openflag,cur_openflag + 3)
	if not curhb_shou or  #curhb_shou < 1 then
		local msg = topname.."Chưa mở, không có dữ liệu nhận hoa."
		self:notify_tips(selfId,msg)
		return
	end
	if not curhb_song or #curhb_song < 1 then
		local msg = topname.."Chưa mở, không có dữ liệu tặng hoa."
		self:notify_tips(selfId,msg)
		return
	end
	-- table.sort(curhb_shou,function(t1, t2) return t1.flower > t2.flower end)
	-- table.sort(curhb_song,function(t1, t2) return t1.flower > t2.flower end)
	local datax,dataz = {},{}
	local topinfo_shou,topinfo_song
	for i = 1,20 do
		topinfo_song = curhb_song[i]
		if topinfo_song then
			datax[i] = {
			count = topinfo_song.flower,
			guid = topinfo_song.charguid,
			guild_name = topinfo_song.guildname,
			name = topinfo_song.charname,
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
			}
		else
			datax[i] = {
			count = 0,
			guid = 0,
			guild_name = " ",
			name = " ",
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
			}
		end
		topinfo_shou = curhb_shou[i]
		if topinfo_shou then
			dataz[i] = {
			count = topinfo_shou.flower,
			guid = topinfo_shou.charguid,
			guild_name = topinfo_shou.guildname,
			name = topinfo_shou.charname,
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
			}
		else
			dataz[i] = {
			count = 0,
			guid = 0,
			guild_name = " ",
			name = " ",
			unknow_1 = 0,
			unknow_2 = -1,
			unknow_3 = -1
			}
		end
	end
	
	-- local subtime = 0
	-- local backinfo = "#GXXXX(当前未开放)"
	-- if curflag ~= 0 then
	local overdate = curhb_shou[1].overdate
	local endtime = curhb_shou[1].endtime
	local nyear = math.floor(overdate / 10000)
	overdate = overdate % 10000
	local nmonth = math.floor(overdate / 100)
	overdate = overdate % 100
	local nhour = math.floor(endtime / 60)
	local nminue = endtime - nhour * 60
	local subtime = self:LuaFnGetSubTime(nyear,nmonth,overdate,nhour,nminue)
	local backinfo = string.format("#GTrước ngày %d %02d:%02d",curhb_shou[1].overdate,nhour,nminue)
	-- end
	-- curflag = curflag == 0 and 6 or curflag
	local uiid
	if curhb_shou[1].uiflag == 2 then
		uiflag = 2
		uiid = 891396
	else
		uiflag = 1
		uiid = 892974
	end
	back_flag = back_flag or {0,0,0}
	self:BeginUICommand()
	self:UICommand_AddInt(cur_openflag)
	-- self:UICommand_AddInt(curflag)
	self:UICommand_AddInt(1)--state
	self:UICommand_AddInt(1)
	self:UICommand_AddInt(0)--DaiBi
	self:UICommand_AddInt(back_flag[1])
	self:UICommand_AddInt(back_flag[2])
	self:UICommand_AddInt(back_flag[3])
	self:UICommand_AddStr(subtime)
	self:UICommand_AddStr(backinfo)
	self:EndUICommand()
	self:DispatchUICommand(selfId,uiid)
	
	local msg = packet_def.WGCRetQueryQingRenJieTopList.new()
	msg.rank_list_1 = dataz
	msg.rank_list_2 = datax
	msg.unknow_1 = 270213680
	msg.unknow_2 = 0
	msg.unknow_3 = 16
	msg.unknow_4 = 0
	msg.unknow_5 = uiflag
	self:get_scene():send2client(selfId, msg)
end
function QiXiTop:GetHuaBangAward(selfId,openflag,addnum)
	if not self:CheckTopClaimAwardCD(selfId,2) then
		return
	end
	if not openflag or openflag < 1 or openflag > 3 then
		return
	end
	local msg
	local toptype = ""
	if addnum == 0 then
		toptype = "Bảng Nhận Hoa"
	elseif addnum == 3 then
		toptype = "Bảng Tặng Hoa"
	else
		return
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	if not human then return end
	local guid = human:get_guid()
	local select_migration = openflag + addnum
	local world_id = self:LuaFnGetServerID(selfId)
	local ret,etime,top,flower,uiflag = self:HaveHuaBangAward(world_id,select_migration,guid)
	if ret > 0 then
		uiflag = uiflag == 2 and uiflag or 1
		local topname = define.FLOWER_TOP_NAME[uiflag][openflag] or ""
		topname = topname..toptype
		local cur_date = self:GetTime2Day()
		if cur_date < ret then
				msg = string.format("%s chưa kết thúc.",topname)
			self:notify_tips(selfId,msg)
			return
		elseif cur_date == ret then
			local times = os.date("*t")
			local nowtime = times.hour * 60 + times.min
			if nowtime < etime then
				msg = string.format("%s chưa kết thúc..",topname)
				self:notify_tips(selfId,msg)
				return
			end
		end
		local award
		if addnum == 3 then
			award = TopSongHuaAward[top]
		else
			award = TopShouHuaAward[top]
		end
		if not award then
			msg = string.format("Cấu hình thưởng hạng [%d] của %s bất thường, xin báo GM.",topname,top)
			self:notify_tips(selfId,msg)
			return
		end
		if award.Needcount and award.Needcount > flower then
			msg = string.format("Thưởng hạng [%d] của %s cần số hoa từ %d trở lên, số hoa của bạn trong bảng: %d, không nhận được.",topname,top,award.Needcount,flower)
			self:notify_tips(selfId,msg)
			return
		end
		local haveitem = false
		if award.Item then
			self:BeginAddItem()
			for i,j in ipairs(award.Item) do
				self:AddItem(j.ID,j.Count,j.Isbind)
				haveitem = true
			end
			if not self:EndAddItem(selfId) then
				return
			end
		end
		if award.Pet then
			local checkCreatePet = self:TryCreatePet(selfId, 1)
			if not checkCreatePet then
				self:notify_tips(selfId, "Ngươi không thể mang thêm Trân thú.")
				return
			end
		end
		if self:ClaimHuaBangAward(world_id,select_migration,top,guid) then
			if haveitem then
				local isspecial
				self:BeginAddItem()
				for i,j in ipairs(award.Item) do
					if j.ID ~= 70600015 then
						self:AddItem(j.ID,j.Count,j.Isbind)
					else
						isspecial = j
					end
				end
				if not self:EndAddItem(selfId) then
					return
				end
				self:AddItemListToHuman(selfId)
				if isspecial then
					local prop_bag_container = human:get_prop_bag_container()
					for i = 1,isspecial.Count do
						local newpos = self:TryRecieveItem(selfId, isspecial.ID, isspecial.Isbind)
						if newpos ~= -1 then
							local item = prop_bag_container:get_item(newpos)
							if item then
								item:get_pet_equip_data():set_pet_soul_level(5)
								self:LuaFnRefreshItemInfo(selfId, newpos)
							end
						end
					end
				end
			end
			if award.Titleid then
				self:LuaFnAddNewAgname(selfId, award.Titleid)
			end
			if award.Pet then
				local ret,petGUID_H,petGUID_L = self:CallScriptFunction(800105, "CreateRMBPetToHuman34534", selfId, award.Pet.Dataid, 1)
				if ret then
					for key,value in pairs(award.Pet.Arrt) do
						if value > 0 then
							self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, key,value)
						end
					end
					local petname = self:GetPetName(award.Pet.Dataid)
					self:notify_tips(selfId,"Bạn nhận được"..petname.."một con.")
				else
					self:notify_tips(selfId,"Túi trân thú đầy, nhận trân thú thất bại.")
				end
			end
			msg = string.format("Nhận thưởng hạng [%d] của %s thành công.",topname,top)
			self:notify_tips(selfId,msg)
		else
			msg = string.format("Nhận thưởng hạng [%d] của %s thất bại.",topname,top)
			self:notify_tips(selfId,msg)
		end
	elseif ret == 0 then
		self:notify_tips(selfId,"Liên server không thao tác được.")
	elseif ret == -1 then
		msg = string.format("Thưởng %s đã nhận.",toptype)
		self:notify_tips(selfId,msg)
	elseif ret == -2 then
		msg = string.format("Trong %s không có hạng của các hạ.",toptype)
		self:notify_tips(selfId,msg)
	elseif ret == -3 then
		msg = string.format("%s không có thưởng cho hạng này.",toptype)
		self:notify_tips(selfId,msg)
	elseif ret == -4 then
		msg = string.format("%s chưa kết thúc.",toptype)
		self:notify_tips(selfId,msg)
	else
		self:notify_tips(selfId,"error。")
	end
end
function QiXiTop:Qingrenjie_Exchange(selfId,index,paramx)
	self:notify_tips(selfId,"Sắp mở")
end

return QiXiTop
