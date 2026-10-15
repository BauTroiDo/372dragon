local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
-- local gbk = require "wire_charset"
-- local skynet = require "skynet"
local packet_def = require "game.packet"
local MingDong = class("MingDong", script_base)
MingDong.script_id = 888816

--缺省配置
MingDong.max_top = 50				--前50名  至少1  至大 200
MingDong.end_hour = 23				--结束小时
MingDong.end_minute = 0				--结束分钟

--此配置只在开启时生效   进行中设置见 MingDong:MingDongCondition
MingDong.need_yb = 0				--限制元宝上榜

--此配置只在开启时生效   进行中设置见 MingDong:MingDongCondition
MingDong.need_point = 0				--限制兑换点数上榜

--限制不上榜的角色  此配置只在开启时生效   进行中设置见 MingDong:MingDongLimitPlayer
--配置示例:
-- MingDong.limit_info = {
	-- {guid = 12345678,name = "角色名"}
-- }
MingDong.limit_info = {


}



--奖励配置   适配UI   固定7档  每档至少1种至多10种奖励  档次配置 name = "第一名", top_min = 1,top_max = 1,
--IsPreview = 0 不可预览  
--IsPreview = 1 title 2 pet
--IsPreview = 3 时装、脸型、发型
MingDong.award_info = {
	--名次奖励，不需要的奖励把键位内容删掉即可
	[1] = {
		name = "Đệ nhất danh",
		top_min = 1,top_max = 1,
		--消费元宝 达标方有奖励  不需要条件则删掉此键
		need_yuanbao = 10000,
		--兑换点数 达标方有奖励  不需要条件则删掉此键
		need_point = 50,
		Titleid = 1368,
		Item = {
			{ID = 10126195,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142900,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 28011,						--珍兽ID
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
		name = "Hạng nhì",
		top_min = 2,top_max = 2,
		--消费元宝 达标方有奖励  不需要条件则删掉此键
		need_yuanbao = 10000,
		--兑换点数 达标方有奖励  不需要条件则删掉此键
		need_point = 50,
		Titleid = 1285,
		Item = {
			{ID = 10126195,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142900,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 28011,						--珍兽ID
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
		name = "Hạng ba",
		top_min = 3,top_max = 3,
		--消费元宝 达标方有奖励  不需要条件则删掉此键
		need_yuanbao = 10000,
		--兑换点数 达标方有奖励  不需要条件则删掉此键
		need_point = 50,
		Titleid = 1083,
		Item = {
			{ID = 10126195,Count = 1,Isbind = true,IsPreview = 3},
			{ID = 10142900,Count = 1,Isbind = true,IsPreview = 0},
		},
		 Pet = {
			 Dataid = 28011,						--珍兽ID
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
	[4] = {
		name = "Hạng 4-5",
		top_min = 4,top_max = 5,
		Titleid = 1084,Item = {{ID = 10126179,Count = 1,Isbind = true,IsPreview = 3}}
	},
	[5] = {
		name = "Hạng 6-10",
		top_min = 6,top_max = 10,
		Titleid = 1084,Item = {{ID = 10126179,Count = 1,Isbind = true,IsPreview = 3}}
	},
	[6] = {
		name = "Hạng 11-20",
		top_min = 11,top_max = 20,
		Titleid = 1084,Item = {{ID = 10126179,Count = 1,Isbind = true,IsPreview = 3}}
	},
	[7] = {
		name = "Đồng khánh phần thưởng",
		top_min = 21,top_max = 200,
		Titleid = 1084,Item = {{ID = 10126179,Count = 1,Isbind = true,IsPreview = 3}}
	},
}

--开启名动
--字段:max_top,over_date,end_hour,end_minute,need_yb,need_point
function MingDong:StartMingDongTop(selfId, ... )
	local params = { ... }
	params[1] = params[1] or {}
	local max_top = tonumber(params[1].max_top) or self.max_top
	if max_top < 1 or max_top > 200 then
		self:notify_tips( selfId,"Phạm vi hạng Danh Động: 1-200, cấu hình dữ liệu bất thường." )
		return
	end
	local over_date = tonumber(params[1].over_date) or tonumber(os.date("%Y%m%d"))
	local end_hour = tonumber(params[1].end_hour) or self.end_hour
	local end_minute = tonumber(params[1].end_minute) or self.end_minute
	local end_time = end_hour * 60 + end_minute
	local need_yb = tonumber(params[1].need_yb) or self.need_yb
	local need_point = tonumber(params[1].need_point) or self.need_point
	local isok = self:ResetMingDong(selfId,max_top,over_date,end_time,need_yb,need_point,self.limit_info)
	if isok == 0 then
		local msg = "#BDanh Động Giang Hồ#P mở ngay."
		self:AddGlobalCountNews_Fun(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",msg)
		self:notify_tips( selfId,msg )
	elseif isok == -1 then
		self:notify_tips( selfId,"Danh Động đang chạy, có thể đóng rồi mở lại." )
	elseif isok == -2 then
		self:notify_tips( selfId,"Giờ mở Danh Động bất thường, kiểm xem có phải giờ quá khứ." )
	elseif isok == -3 then
	else
		self:notify_tips( selfId,"Lỗi không xác định." )
	end
end
--关闭名动
function MingDong:CloseMingDongTop(selfId, ... )
	local params = { ... }
	if self:MingDongClose(selfId) then
		self:notify_tips( selfId,"Danh Động đóng." )
	else
		self:notify_tips( selfId,"Danh Động chưa mở, nếu không ẩn icon xin để ý thông báo có ra chưa." )
	end
end
--设置名动条件
--字段:need_yb,need_point
function MingDong:MingDongCondition(selfId, ... )
	local params = { ... }
	params[1] = params[1] or {}
	local need_yb = tonumber(params[1].need_yb) or self.need_yb
	local need_point = tonumber(params[1].need_point) or self.need_point
	if self:SetMingDongCondition(selfId,need_yb,need_point) then
		self:notify_tips( selfId,"Cài đặt thành công." )
	else
		self:notify_tips( selfId,"Đặt thất bại, Danh Động chưa mở hoặc đang ở cảnh liên server." )
	end
end
--设置名动  上榜角色
--字段:guid,name,is_add    is_add = 1 添加不上榜角色并刷新排行   is_add = 0 剔除不上榜角色并刷新排行
function MingDong:MingDongLimitPlayer(selfId, ... )
	local params = { ... }
	params[1] = params[1] or {}
	local guid = tonumber(params[1].guid)
	local name = params[1].name
	local is_add = params[1].is_add == 1
	if not guid then
		self:notify_tips( selfId,"Tham số GUID nhân vật hạn chế sai." )
	elseif not name then
		self:notify_tips( selfId,"Tham số tên nhân vật hạn chế sai." )
	else
		if self:SetMingDongLimitPlayer(selfId,guid,name,is_add) then
			self:notify_tips( selfId,"Cài đặt thành công." )
		else
			self:notify_tips( selfId,"Đặt thất bại, Danh Động chưa mở/đã kết thúc/ở cảnh liên server/đã đặt rồi." )
			self:notify_tips( selfId,"Nếu đã đặt danh sách thì thao tác ngược lại được, ví dụ trong danh sách hạn chế, xóa hạn chế nhân vật trước, rồi đặt để xóa bảng tương ứng." )
		end
	end
end
function MingDong:OpenMingDong(selfId,iscd)
	if iscd == 1 and not self:CheckTopOpenUiCD(selfId,3) then
		return
	end
	local mingdong = self:GetMingDongTop(selfId)
	if not mingdong[0] then
		self:BeginUICommand()
		self:UICommand_AddInt(0)
		self:EndUICommand()
		self:DispatchUICommand(selfId,415052022)
		self:notify_tips( selfId,"Danh Động Giang Hồ đã kết thúc hoặc chưa mở." )
		return
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
	local is_over = mingdong[0].claim_award == 3
	local show_award = 0
	local back_data = {}
	local index = 0
	for i,top in pairs(mingdong) do
		if i > 0 then
			index = index + 1
			back_data[index] = {
				name = top.char_name,
				rank_value_1 = top.money_yb,
				level = 1,
				menpai = top.men_pai,
				total = 117,
				win = 0,
				rank_value_2 = top.need_point,
				rank_value_3 = top.char_guid,
				server_id = 0,
			}
			if top.char_guid == guid then
				if is_over and top.claim_award == 0 then
					show_award = i
					back_data[index].level = 101
				else
					back_data[index].level = 100
				end
			end
		end
	end
	local maxtop = index
	index = index + 1
	for i = index,200 do
		back_data[i] = {
			name = "",
			rank_value_1 = 0,
			level = 1,
			menpai = 0,
			total = 117,
			win = 0,
			rank_value_2 = 0,
			rank_value_3 = 0,
			server_id = 0,
		}
	end
	local over_date = mingdong[0].over_date
	local end_time = mingdong[0].end_time
	local mingdong_yb,money_point = 0,0
	local mingdong_date = human:get_game_flag_key("mingdong_date")
	local mingdong_time = human:get_game_flag_key("mingdong_time")
	if over_date == mingdong_date and end_time == mingdong_time then
		mingdong_yb = human:get_game_flag_key("mingdong_yb")
		money_point = human:get_game_flag_key("mingdong_point")
	else
		human:set_game_flag_key("mingdong_yb",0)
		human:set_game_flag_key("mingdong_point",0)
		human:set_game_flag_key("mingdong_date",over_date)
		human:set_game_flag_key("mingdong_time",end_time)
	end
	back_data[200].name = "MingDong_TopList"
	back_data[200].rank_value_1 = maxtop
	back_data[200].rank_value_2 = mingdong_yb
	back_data[200].rank_value_3 = money_point
	
	local msg = packet_def.WGCRetQueryXBWRankCharts.new()
	msg.status = 2
	msg.type = 1
	msg.guid = guid
	msg.rank_count = 200
	msg.top_list = back_data
	self:get_scene():send2client(human, msg)
	
	local params = {
		{
			date = over_date,
			minute_time = end_time,
			sec = 0,
		},
		{
			date = over_date,
			hour = 0,
			min = 0,
			sec = 0,
			add_time = 86400,
		},
	}
	local back_time,cur_year,cur_mon,cur_day = self:GetDateToTime(params)
	local text1 = string.format("Năm %d tháng %d ngày %d",cur_year,cur_mon,cur_day)
	local text2 = string.format("Tháng %d ngày %d %d giờ %d phút",back_time[1].month,back_time[1].day,back_time[1].hour,back_time[1].min)
	
	self:BeginUICommand()
	self:UICommand_AddInt(back_time[1].n_day)
	self:UICommand_AddInt(back_time[1].n_hour)
	self:UICommand_AddInt(back_time[1].n_sec)
	self:UICommand_AddInt(back_time[2].n_day)
	self:UICommand_AddInt(back_time[2].n_hour)
	self:UICommand_AddInt(back_time[2].n_sec)
	self:UICommand_AddInt(back_time[1].month)
	self:UICommand_AddInt(back_time[1].day)
	self:UICommand_AddInt(mingdong[0].money_yb)
	self:UICommand_AddInt(mingdong[0].need_point)
	self:UICommand_AddStr("MingDong_TopList")
	self:UICommand_AddStr(text1)
	self:UICommand_AddStr(text2)
	self:EndUICommand()
	self:DispatchUICommand(selfId,415052021)
		-- local n_year = maxalldate // 10000
		-- maxalldate = maxalldate % 10000
		-- local n_month = maxalldate // 100
		-- local n_day = maxalldate % 100
		-- local n_hour = alltime // 60
		-- local n_minute = alltime - n_hour * 60
		-- local dateinfo = string.format("%d年%02d月%02d日%02d:%02d",n_year,n_month,n_day,n_hour,n_minute)
		-- n_year = specialdate // 10000
		-- specialdate = specialdate % 10000
		-- n_month = specialdate // 100
		-- n_day = specialdate % 100
		-- local specialdateinfo = string.format("%d年%02d月%02d日",n_year,n_month,n_day)
		-- self:BeginUICommand()
		-- self:UICommand_AddInt(806042021)
		-- self:UICommand_AddInt(curSection - 1)
		-- self:UICommand_AddInt(migration - 1)
		-- self:UICommand_AddInt(1)
		-- self:UICommand_AddInt(ui_show)
		-- self:UICommand_AddInt(sortflag)
		-- self:UICommand_AddStr(dateinfo)
		-- self:UICommand_AddStr(specialdateinfo)
		-- self:EndUICommand()
		-- self:DispatchUICommand(selfId,806042021)
end
--奖励预览
function MingDong:AwardPreview(selfId)
	if not self:CheckTopPreviewCD(selfId,2) then
		return
	end
	local selfindex,value = self:CheckMingdongTopClaimAward(selfId)
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
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
	local index = 0
	local zzx,zzz
	local awardname
	local needmsg1,needmsg2
	local self_index = 0
	for i,j in ipairs(self.award_info) do
		if selfindex >= j.top_min and selfindex <= j.top_max then
			self_index = i
		end
		awardname = j.name
		needmsg1 = ""
		needmsg2 = ""
		if j.need_yuanbao then
			needmsg1 = "Nguyên bảo >="..tostring(j.need_yuanbao)
		end
		if j.need_point then
			needmsg2 = "Điểm >="..tostring(j.need_point)
		end
		if needmsg1 == "" then
			needmsg1 = "(Không yêu cầu)"
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
			elseif needmsg1 then
				datax[index].name = needmsg1
				needmsg1 = nil
			elseif needmsg2 then
				datax[index].name = needmsg2
				needmsg2 = nil
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
				elseif needmsg1 then
					datax[index].name = needmsg1
					needmsg1 = nil
				elseif needmsg2 then
					datax[index].name = needmsg2
					needmsg2 = nil
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
				elseif needmsg1 then
					datax[index].name = needmsg1
					needmsg1 = nil
				elseif needmsg2 then
					datax[index].name = needmsg2
					needmsg2 = nil
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
	
	datax[200].name = "MingDong_TopListAward"
    local msg = packet_def.WGCRetQueryXBWRankCharts.new()
	msg.status = 2
    msg.type = 1
    msg.guid = guid
    msg.rank_count = 200
    msg.top_list = datax
	self:get_scene():send2client(human, msg)
	
	self:BeginUICommand()
	self:UICommand_AddInt(self_index)
	self:UICommand_AddInt(value)
	self:UICommand_AddStr("MingDong_TopListAward")
	self:EndUICommand()
	self:DispatchUICommand(selfId,415052023)
end
--领奖
function MingDong:GetHuaBangAward(selfId,topid)
	if not topid or topid < 1 then
		self:notify_tips( selfId,"Thao tác không hợp lệ." )
		return
	end
	local mingdong_yb,money_point = self:GetPlayerMingDongPoint(selfId)
	local award_info
	for i,j in ipairs(self.award_info) do
		if topid >= j.top_min and topid <= j.top_max then
			award_info = j
			break
		end
	end
	if not award_info then
		self:notify_tips( selfId,"Không có thưởng cho hạng này." )
		return
	elseif award_info.need_yuanbao then
		if award_info.need_yuanbao > mingdong_yb then
			local msg = string.format("Hạng [%d] Danh Động Giang Hồ cần nguyên bảo tiêu: %d, của ngươi: %d, không nhận thưởng được.",topid,award_info.need_yuanbao,mingdong_yb)
			self:notify_tips( selfId,msg )
			return
		end
	elseif award_info.need_point then
		if award_info.need_point > money_point then
			local msg = string.format("Hạng [%d] Danh Động Giang Hồ cần điểm đổi: %d, của ngươi: %d, không nhận thưởng được.",topid,award_info.need_point,money_point)
			self:notify_tips( selfId,msg )
			return
		end
	end
	local haveitem = false
	if award_info.Item then
		self:BeginAddItem()
		for i,j in ipairs(award_info.Item) do
			self:AddItem(j.ID,j.Count,j.Isbind)
			haveitem = true
		end
		if not self:EndAddItem(selfId) then
			return
		end
	end
	if award_info.Pet then
		local checkCreatePet = self:TryCreatePet(selfId, 1)
		if not checkCreatePet then
			self:notify_tips(selfId, "Ngươi không thể mang thêm Trân thú.")
			return
		end
	end
	local isok = self:MingdongTopClaimAward(selfId,topid)
	if isok == 0 then
		if haveitem then
			local isspecial
			self:BeginAddItem()
			for i,j in ipairs(award_info.Item) do
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
		if award_info.Titleid then
			self:LuaFnAddNewAgname(selfId, award_info.Titleid)
		end
		if award_info.Pet then
			local ret,petGUID_H,petGUID_L = self:CallScriptFunction(800105, "CreateRMBPetToHuman34534", selfId, award_info.Pet.Dataid, 1)
			if ret then
				for key,value in pairs(award_info.Pet.Arrt) do
					if value > 0 then
						self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, key,value)
					end
				end
				local petname = self:GetPetName(award_info.Pet.Dataid)
				self:notify_tips(selfId,"Bạn nhận được"..petname.."một con.")
			else
				self:notify_tips(selfId,"Túi trân thú đầy, nhận trân thú thất bại.")
			end
		end
		msg = string.format("Nhận thưởng hạng [%d] Danh Động Giang Hồ thành công.",topid)
		self:notify_tips(selfId,msg)
		self:OpenMingDong(selfId,0)
	elseif isok == 1 then
		self:notify_tips(selfId, "Không có hạng này hoặc bảng Danh Động không tồn tại.")
	elseif isok == 2 then
		self:notify_tips(selfId, "Phần thưởng đã nhận.")
	elseif isok == 3 then
		self:notify_tips(selfId, "Hạng này không thuộc về ngươi.")
	elseif isok == 4 then
		self:notify_tips(selfId, "Bảng Danh Động đang diễn ra hoặc chưa kết toán.")
	elseif isok == -1 then
	else
		self:notify_tips(selfId, "Lỗi không xác định.")
	end
end

return MingDong
