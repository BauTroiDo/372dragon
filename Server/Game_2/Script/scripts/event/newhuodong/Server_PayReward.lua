local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
-- local gbk = require "wire_charset"
-- local skynet = require "skynet"
local packet_def = require "game.packet"
local Server_PayReward = class("Server_PayReward", script_base)
Server_PayReward.script_id = 888817
--每日充值豪礼，暂设 最少 1 个档次 最多 8 个档次
Server_PayReward.OptionalItem = {
	[1] = {
			--需求日充点数
			needpoint = 18,
			--道具池中选择 4 种奖励，道具池配置 至少 4 种道具，至多 30 种
			iteminfo = {
				{20501004,20 },
				{20502004,20 },
				{38008160,50 },
				{30505835,10 },
				{30008117,1 },
				{30900016,10 },
			},
	},
	[2] = {
			--需求日充点数
			needpoint = 38,
			--道具池中选择 4 种奖励，道具池配置 至少 4 种道具，至多 30 种
			iteminfo = {
				{20501004,30 },
				{20502004,30 },
				{38008160,100 },
				{30505835,15 },
				{30008117,2 },
				{30900016,20 },
			},
	},
	[3] = {
			--需求日充点数
			needpoint = 68,
			--道具池中选择 4 种奖励，道具池配置 至少 4 种道具，至多 30 种
			iteminfo = {
				{20501004,40 },
				{20502004,40 },
				{38008160,150 },
				{30505835,25 },
				{30008117,3 },
				{30900016,34 },
			},
	},
}
--开启每日豪礼
--密钥 区服ID 结束时间
function Server_PayReward:SetDailyRechargeReward(selfId, ... )
	local params = { ... }
	local curdate = self:GetTime2Day()
	local overdate = tonumber(params[1].overdate) or 0
	if overdate < curdate then
		self:notify_tips( selfId,"Ngày sai." )
		return
	end
	self:LuaFnSetWorldGlobalDataEx(ScriptGlobal.WORLD_CHONGZHI_DAY,overdate)
	self:notify_tips( selfId,"Mở hào lễ hằng ngày thành công." )
	local msg = "@*;SrvMsg;SCA:#GTừ giờ#Ptới#G"..tostring(overdate).."ngày 23:59:59#P, nạp mỗi ngày nhận#Ghào lễ#P."
	self:AddGlobalCountNews(msg)
end
--重置功力值
function Server_PayReward:ResetGongLiCount(selfId, ... )
	local params = { ... }
	local key = tonumber(params[1].key) or 0
	local count = tonumber(params[1].count) or 0
	if key ~= 3399 then
		return
	end
	self:SetGongLi(selfId, count)
	self:notify_tips( selfId,"Bạn nhận công lực bồi thường"..tostring(count).."Chấm." )
end
--开启ui  其它脚本跳转过来
-- self:CallScriptFunction(888817,"OpenUI",selfId,0)
--增加日充值点数
-- self:CallScriptFunction(888817,"ResetPayReward",selfId,增加的点数,666666,888888)		--666666,888888 此两值不要改动
function Server_PayReward:ResetPayReward(selfId,addpoint,param1,param2)
	if param1 ~= 666666 or param2 ~= 888888 then
		return
	elseif not addpoint or addpoint < 0 then
		return
	end
	local today = self:GetTime2Day()
	local mypoint = 0
	if self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_DAY) ~= today then
		-- mypoint = mypoint + addpoint
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG,0)
		for i = 441,448 do
			self:SetMissionDataEx(selfId,i,0)
		end
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_DAY,today)
	else
		mypoint = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_POINT)
	end
	local newpoint = mypoint + addpoint
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_POINT,newpoint)
	if addpoint > 0 then
		local actname = "Biến động điểm nạp ngày"
		local info1 = "Điểm gốc:"..tostring(mypoint)
		local info2 = "Điểm thêm:"..tostring(addpoint)
		local info3 = "Điểm hiện tại:"..tostring(newpoint)
		self:SetLog(selfId,actname,info1,info2,info3)
	end
end
function Server_PayReward:ReceiveAward(selfId,index)
	self:ResetPayReward(selfId,0,666666,888888)
	local opendate = self:LuaFnGetWorldGlobalDataEx(ScriptGlobal.WORLD_CHONGZHI_DAY)
	local curdate = self:GetTime2Day()
	if curdate > opendate then
		self:notify_tips(selfId,"Thưởng nạp ngày hiện chưa mở.")
		return
	end
	if not index or index < 1 or index > 8 then
		self:notify_tips(selfId,"not index")
		return
	end
	local awardinfo = self.OptionalItem[index]
	if not awardinfo then
		self:notify_tips(selfId,"Không có thưởng mốc này, xin đừng thao tác trái phép")
		return
	elseif not awardinfo.iteminfo or #awardinfo.iteminfo == 0 then
		self:notify_tips(selfId,"Mốc này chưa cấu hình thưởng, xin báo GM")
		return
	end
	local receive_ex = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG)
	if receive_ex > 0 then
		local istrue = self:BitIsTrue(receive_ex,index)
		if istrue then
			self:notify_tips(selfId,"Thưởng mốc này ngươi đã nhận")
			return
		end
	end
	local exid = index + 440
	local exdata = self:GetMissionDataEx(selfId,exid)
	local exdatalog = exdata
	if exdata == 0 then
		self:notify_tips(selfId,"Xin chọn thưởng trước")
		return
	end
	local idx
	local selectinfo = {0,0,0,0}
	selectinfo[1] = math.floor(exdata / 1000000)
	exdata = exdata % 1000000
	selectinfo[2] = math.floor(exdata / 10000)
	exdata = exdata % 10000
	selectinfo[3] = math.floor(exdata / 100)
	selectinfo[4] = exdata % 100
	for i = 1,4 do
		idx = selectinfo[i]
		if idx == 0 then
			self:notify_tips(selfId,"第"..tostring(i).."phần thưởng chưa chọn")
			return
		elseif not awardinfo.iteminfo[idx] then
			self:notify_tips(selfId,"第"..tostring(i).."chọn thưởng bất thường, xin chọn lại")
			return
		end
	end
	self:BeginAddItem()
	for i = 1,4 do
		idx = selectinfo[i]
		self:AddItem(awardinfo.iteminfo[idx][1],awardinfo.iteminfo[idx][2],true);
	end
	if not self:EndAddItem(selfId) then
		self:notify_tips(selfId,"Túi hành trang không đủ chỗ")
		return
	end
	receive_ex = self:MarkBitTrue(receive_ex, index)
	local istrue = self:BitIsTrue(receive_ex,index)
	if istrue then
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG,receive_ex)
		if receive_ex == self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG) then
			self:AddItemListToHuman(selfId)
			
			local actname = "Nhận thưởng nạp ngày"
			local info1 = "Nhận thành công thứ"..tostring(index).."mốc thưởng"
			local info2 = "Chọn dữ liệu:"..tostring(exdatalog)
			local info3 = "Dự phòng:"
			self:SetLog(selfId,actname,info1,info2,info3)
			
			self:notify_tips(selfId,"phần thưởng lĩnh nhận thành công")
			self:OpenUI(selfId,index)
		else
			self:BeginAddItem()
			self:notify_tips(selfId,"Lưu thất bại, xin thử lại")
		end
	else
		self:BeginAddItem()
		self:notify_tips(selfId,"Lưu thất bại, xin thử lại")
	end
end
function Server_PayReward:ClientSubmit(selfId,index,param1,param2,param3,param4)
	self:ResetPayReward(selfId,0,666666,888888)
	local opendate = self:LuaFnGetWorldGlobalDataEx(ScriptGlobal.WORLD_CHONGZHI_DAY)
	local curdate = self:GetTime2Day()
	if curdate > opendate then
		self:notify_tips(selfId,"Thưởng nạp ngày hiện chưa mở.")
		return
	end
	if not index or index < 1 or index > 8 then
		self:notify_tips(selfId,"not index")
		return
	elseif not param1 or param1 < 0 then
		self:notify_tips(selfId,"not param1")
		return
	elseif not param2 or param2 < 0 then
		self:notify_tips(selfId,"not param2")
		return
	elseif not param3 or param3 < 0 then
		self:notify_tips(selfId,"not param3")
		return
	elseif not param4 or param4 < 0 then
		self:notify_tips(selfId,"not param4")
		return
	end
	local awardinfo = self.OptionalItem[index]
	if not awardinfo then
		self:notify_tips(selfId,"Không có thưởng mốc này, xin đừng thao tác trái phép")
		return
	elseif not awardinfo.iteminfo or #awardinfo.iteminfo == 0 then
		self:notify_tips(selfId,"Mốc này chưa cấu hình thưởng, xin báo GM")
		return
	end
	local receive_ex = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG)
	if receive_ex > 0 then
		local istrue = self:BitIsTrue(receive_ex,index)
		if istrue then
			self:notify_tips(selfId,"Thưởng mốc này đã nhận, không đặt lại được")
			return
		end
	end
	if param1 > 0 and not awardinfo.iteminfo[param1] then
		self:notify_tips(selfId,"Chọn vị trí 1 bất thường, xin thao tác lại")
		return
	elseif param2 > 0 and not awardinfo.iteminfo[param2] then
		self:notify_tips(selfId,"Chọn vị trí 2 bất thường, xin thao tác lại")
		return
	elseif param3 > 0 and not awardinfo.iteminfo[param3] then
		self:notify_tips(selfId,"Chọn vị trí 3 bất thường, xin thao tác lại")
		return
	elseif param4 > 0 and not awardinfo.iteminfo[param4] then
		self:notify_tips(selfId,"Chọn vị trí 4 bất thường, xin thao tác lại")
		return
	end
	local exid = index + 440
	local exdata = param1 * 1000000 + param2 * 10000 + param3 * 100 + param4
	self:SetMissionDataEx(selfId,exid,exdata)
	self:OpenUI(selfId,index)
end
function Server_PayReward:OpenUI(selfId,paramx)
	if paramx == 0 then
		self:ResetPayReward(selfId,0,666666,888888)
		local opendate = self:LuaFnGetWorldGlobalDataEx(ScriptGlobal.WORLD_CHONGZHI_DAY)
		local curdate = self:GetTime2Day()
		if not opendate or opendate < curdate then
			self:LuaFnSetWorldGlobalDataEx(ScriptGlobal.WORLD_CHONGZHI_DAY, 99999999)
		end
	end
	if #self.OptionalItem == 0 then
		self:notify_tips(selfId,"Xin báo GM cấu hình thưởng")
		return
	elseif #self.OptionalItem > 8 then
		self:notify_tips(selfId,"Tạm chưa mở thứ"..tostring(#self.OptionalItem).."Nội dung mốc")
		return
	end
	local todaypoint = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_POINT)
	local receive_ex = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_PAYREWARD_FLAG)
	local idx,maxidx
	local itemidx,countidx,istrue
	local intx,intz,index
	local backdata = {}
	for i,j in ipairs(self.OptionalItem) do
		idx = i * 20 - 20
		for k = 1,20 do
			backdata[k + idx] = {
								name = "",
								rank_value_1 = 0,
								level = 0,
								menpai = 0,
								total = 999,
								win = 0,
								rank_value_2 = 0,
								rank_value_3 = 0,
								server_id = 0,
							}
		end
		maxidx = idx + 20
		backdata[maxidx].rank_value_1 = j.needpoint
		backdata[maxidx].rank_value_2 = todaypoint
		
		idx = idx + 1
		backdata[idx].menpai = i
		intx = self:GetMissionDataEx(selfId,i + 440)
		if intx > 0 then
			backdata[idx].rank_value_1 = math.floor(intx / 1000000)
			intx = intx % 1000000
			backdata[idx].rank_value_2 = math.floor(intx / 10000)
			intx = intx % 10000
			backdata[idx].rank_value_3 = math.floor(intx / 100)
			backdata[idx].win = intx % 100
		end
		if todaypoint < j.needpoint then
			backdata[idx].name = "XinShouNew_WDC"
			backdata[maxidx].name = "#cff0000"
		else
			istrue = self:BitIsTrue(receive_ex,i)
			if istrue then
				backdata[idx].name = "XinShouNew_YLQ"
				backdata[maxidx].name = "#cFFCC99"
			else
				backdata[idx].level = 1
				backdata[idx].name = "XinShouNew_LQDIS"
				backdata[maxidx].name = "#G"
			end
		end
		if j.iteminfo and #j.iteminfo > 0 then
			for m,n in ipairs(j.iteminfo) do
				if m <= 30 then
					intx,intz = n[1],n[2]
					itemidx = math.ceil(m / 4) + idx
					countidx = itemidx + 8
					index = m % 4
					if index == 0 then
						backdata[itemidx].win = intx
						backdata[countidx].win = intz
					elseif index == 1 then
						backdata[itemidx].rank_value_1 = intx
						backdata[countidx].rank_value_1 = intz
					elseif index == 2 then
						backdata[itemidx].rank_value_2 = intx
						backdata[countidx].rank_value_2 = intz
					elseif index == 3 then
						backdata[itemidx].rank_value_3 = intx
						backdata[countidx].rank_value_3 = intz
					-- elseif index == 4 then
						-- backdata[itemidx].win = intx
						-- backdata[countidx].win = intz
					end
				end
			end
		end
	end
	index = #self.OptionalItem + 1
	for i = index,10 do
		idx = i * 20 - 20
		for k = 1,20 do
			backdata[k + idx] = {
								name = "",
								rank_value_1 = 0,
								level = 0,
								menpai = 0,
								total = 999,
								win = 0,
								rank_value_2 = 0,
								rank_value_3 = 0,
								server_id = 0,
							}
		end
	end
	local human = self:get_scene():get_obj_by_id(selfId)
	local guid = human:get_guid()
	local msg = packet_def.WGCRetQueryXBWRankCharts.new()
    msg.status = 2
    msg.type = 1
    msg.guid = guid
    msg.rank_count = 200
    msg.top_list = backdata
	self:get_scene():send2client(human, msg)
	self:BeginUICommand()
    -- self:UICommand_AddInt(1)
    -- self:UICommand_AddInt(1)
    -- self:UICommand_AddInt(1)
    -- self:UICommand_AddInt(0)
    -- self:UICommand_AddStr("#{QRZM_211119_206*\1\6*\0012}")
    self:EndUICommand()
    self:DispatchUICommand(selfId,418042021)
end
return Server_PayReward
