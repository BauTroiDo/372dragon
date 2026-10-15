local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
-- local gbk = require "wire_charset"
-- local skynet = require "skynet"
local packet_def = require "game.packet"
local JingPai = class("JingPai", script_base)
JingPai.script_id = 888818

local JingPaiUpdateTime = 3				--刷新CD （单位：秒）
local JingPaiAddTime = 5				--竞拍接近结束时有人争夺追加时间 （单位：分钟）当追加时间达到23:59则该时间结束.
local JingPaiMaxHour = 23				--延长时间上限 小时
local JingPaiMaxMinute = 40				--延长时间上限 分钟

--留  ""  空符则竞拍界面不显示属性
-- JingPai.dress_msg = "\n#B血上限+15%"
-- JingPai.ride_msg = "\n#B伤害+15%"
JingPai.dress_msg = ""
JingPai.ride_msg = ""


function JingPai:JingPaiIsitenabled(selfId)
	-- self:NotifyTips(selfId,"xxxxxx")
	self:GetJingPaiSection(selfId)
end
function JingPai:NotifyTips(selfId,msg)
	self:BeginEvent()
        self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
function JingPai:Follow(selfId,index,Section)
	if not Section or Section < 0 or Section > 4 then
		return
	elseif not index or index < 1 or index > 99 then
		return
	end
	local migration = Section + 1
	local ex_pos = math.ceil(index / 32)
	local ex_id
	if ScriptGlobal.MDEX_JINGPAI_FOLLOW[migration] then
		ex_id = ScriptGlobal.MDEX_JINGPAI_FOLLOW[migration].follows[ex_pos]
	end
	if not ex_id then
		return
	end
	local ex_value = self:GetMissionDataEx(selfId,ex_id)
	local bit = index % 32
	bit = bit == 0 and 32 or bit
	local bFollowed = 0
	if self:BitIsTrue(ex_value,bit) then
		ex_value = (ex_value & ~(0x1 << (bit - 1)))
	else
		ex_value = self:MarkBitTrue(ex_value,bit)
		bFollowed = 1
	end
	self:SetMissionDataEx(selfId,ex_id,ex_value)
	self:TryOpenFashionAuction(selfId,1,Section,0,0)
end
function JingPai:BackJingPaiData(selfId,curSection,sortFlag)
	local jpData = self:GetJingPaiData(selfId,curSection);
	if #jpData > 0 then
		self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,0)
		local human = self:get_scene():get_obj_by_id(selfId)
		local guid = human:get_guid()
		local jpYuanbao = self:GetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO)
		local idx = 0;
		local isFollowed = 0
		local isTop = 0
		local haveBid = 0
		local isOver = 0
		local isShow = 1
		local subTime = -1
		local posFlag = 0
		local backData = {}
		local curDate = self:GetTime2Day()
		local times = os.date("*t")
		local curTime = times.hour * 60 + times.min
		local second = times.sec
		local Spcial = jpData[100]
		if not Spcial or not jpData[1] then
			return -1,0,0,0
		end
		jpData[100] = nil
		local maxalldate = jpData[1].end_date
		local follows_bit = {}
		if ScriptGlobal.MDEX_JINGPAI_FOLLOW[curSection] then
			local ndate = ScriptGlobal.MDEX_JINGPAI_FOLLOW[curSection].ndate
			local follows = ScriptGlobal.MDEX_JINGPAI_FOLLOW[curSection].follows
			if self:GetMissionDataEx(selfId,ndate) ~= maxalldate then
				for _,exid in ipairs(follows) do
					self:SetMissionDataEx(selfId,exid,0)
				end
				self:SetMissionDataEx(selfId,ndate,maxalldate)
				for i = 1,99 do
					follows_bit[i] = 0
				end
			else
				local idx,ex_value
				for i,exid in ipairs(follows) do
					idx = i * 32 - 32
					ex_value = self:GetMissionDataEx(selfId,exid)
					for bit = 0,31 do
						idx = idx + 1
						follows_bit[idx] = (ex_value >> bit) & 1
					end
				end
			end
		end
		-- local ui_show,maxalldate,alltime,specialdate = -1,0,0,0
		local ui_show,alltime,specialdate = -1,0,0
		local award_value,index
		ui_show = Spcial.claim_award
		local itemcount
		local have_mail
		for i,j in pairs(jpData) do
			index = j.index
			j.follow = follows_bit[index]
			-- skynet.logi("i = ",i,"index = ",index,"j.follow = ",j.follow)
			j.max_money = math.max(j.best_moeny,j.startmoney)
		end
		if sortFlag == 1 then
			local tab_sort = function(t1,t2)
				if t1.follow ~= t2.follow then
					return t1.follow > t2.follow
				end
				return t1.max_money > t2.max_money
			end
			table.sort(jpData,tab_sort)
		elseif sortFlag == 2 then
			local tab_sort = function(t1,t2)
				if t1.follow ~= t2.follow then
					return t1.follow > t2.follow
				end
				return t1.max_money < t2.max_money
			end
			table.sort(jpData,tab_sort)
		else
			local tab_sort = function(t1,t2)
				if t1.follow ~= t2.follow then
					return t1.follow > t2.follow
				end
				if t1.max_money ~= t2.max_money then
					return t1.max_money > t2.max_money
				end
				return t1.index < t2.index
			end
			table.sort(jpData,tab_sort)
		end
		for _,j in ipairs(jpData) do
			index = j.index
			if index < 100 then
				-- isFollowed = follows_bit[index]
				-- skynet.logi("isFollowed = ",isFollowed)
				isTop = 0;
				haveBid = 0
				subTime = 0
				if j.guid == guid then
					isTop = 1;
					haveBid = 1;
				elseif j.best_moeny > 0 then
					haveBid = 1;
				end
				-- if j.end_date > maxalldate then
					-- maxalldate = j.end_date
				-- end
				if curDate > j.end_date then
					isOver = 4
				elseif curDate == j.end_date then
					if curTime >= j.end_time then
						isOver = 4
					else
						subTime = j.end_time - curTime
						if subTime < 0 then
							subTime = 0
						else
							subTime = subTime * 60 - second
						end
						isOver = 3
					end
				else
					isOver = 3
				end
				if not award_value and isOver == 4 then
					if isTop == 1 and j.claim_award == 0 and jpYuanbao >= j.best_moeny then
						award_value = index * 10 + curSection
						self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,award_value)
						local mail_msg
						if ui_show == 2 then
							mail_msg = "#{ZQPM_240402_108_Ex}"
						else
							mail_msg = "#{SZPM_230913_83_Ex}"
						end
						local itemname = self:GetItemName(j.itemid)
						have_mail = self:ScriptGlobal_Format(mail_msg,times.month,times.day,j.best_moeny,j.itemcount,itemname,times.year,times.month,times.day)
					end
				end
				idx = idx + 1
				itemcount = j.itemcount
				-- if j.itemid == 30900128 then
					-- itemcount = 20
				-- end
				backData[idx] = {
					name = j.charname,
					rank_value_1 = j.end_date,
					level = index,
					menpai = j.follow,
					total = 999,
					win = j.end_time,
					rank_value_2 = j.itemid,
					rank_value_3 = itemcount,
					server_id = isOver,
				}
				backData[idx + 100] = {
					name = "",
					rank_value_1 = j.best_moeny,
					level = haveBid,
					menpai = isTop,
					total = 999,
					win = subTime,
					rank_value_2 = j.startmoney,
					rank_value_3 = j.addmoney,
					server_id = j.modelindex,
				}
			end
		end
		idx = idx + 1
		for n = idx,99 do
			backData[n] = {
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
			backData[n + 100] = {
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
		alltime = Spcial.end_time
		specialdate = Spcial.end_date
		backData[100] = {
			name = Spcial.charname,
			rank_value_1 = Spcial.end_date,
			level = Spcial.index,
			menpai = 0,
			total = 999,
			win = Spcial.end_time,
			rank_value_2 = Spcial.itemid,
			rank_value_3 = Spcial.itemcount,
			server_id = Spcial.modelindex,
		}
		backData[200] = {
			name = "",
			rank_value_1 = Spcial.best_moeny,
			level = 0,
			menpai = 0,
			total = 999,
			win = 0,
			rank_value_2 = Spcial.startmoney,
			rank_value_3 = Spcial.addmoney,
			server_id = Spcial.modelindex,
		}
		local msg = packet_def.WGCRetQueryXBWRankCharts.new()
		msg.status = 2
		msg.type = 1
		msg.guid = guid
		msg.rank_count = 200
		msg.top_list = backData
		self:get_scene():send2client(human, msg)
		if have_mail then
			self:LuaFnSendSystemMail(self:GetName(selfId), have_mail)
		end
		return ui_show,maxalldate,alltime,specialdate
	else
		self:NotifyTips(selfId,"Đấu giá chưa mở hoặc đang ở cảnh liên server:"..tostring(Section))
	end
	return -1,0,0,0
end
function JingPai:TryOpenFashionAuction( selfId, param1,Section,cdFlag,sortflag,add_ui )
	if not Section or Section < 0 or Section > 4 then
		return
	elseif not sortflag then
		return
	elseif cdFlag == 1 then
		if not self:CheckTopOpenUiCD(selfId,JingPaiUpdateTime) then
			return
		end
	end
	local migration = self:GetJingPaiSection(selfId)
	if not migration then return end
	local curSection = Section + 1
	if param1 == 0 then
		curSection = migration
	end
	if curSection == 0 then return end
	local ui_show,maxalldate,alltime,specialdate = self:BackJingPaiData(selfId,curSection,sortflag)
	-- skynet.logi("ui_show = ",ui_show,"maxalldate = ",maxalldate,"alltime = ",alltime,"specialdate = ",specialdate)
	if ui_show >= 0 then
		if add_ui then
			ui_show = ui_show + add_ui
		end
		local n_year = maxalldate // 10000
		maxalldate = maxalldate % 10000
		local n_month = maxalldate // 100
		local n_day = maxalldate % 100
		local n_hour = alltime // 60
		local n_minute = alltime - n_hour * 60
		local dateinfo = string.format("Năm %d tháng %02d ngày %02d %02d:%02d",n_year,n_month,n_day,n_hour,n_minute)
		n_year = specialdate // 10000
		specialdate = specialdate % 10000
		n_month = specialdate // 100
		n_day = specialdate % 100
		local specialdateinfo = string.format("Năm %d tháng %02d ngày %02d",n_year,n_month,n_day)
		self:BeginUICommand()
		self:UICommand_AddInt(806042021)
		self:UICommand_AddInt(curSection - 1)
		self:UICommand_AddInt(migration - 1)
		self:UICommand_AddInt(1)
		self:UICommand_AddInt(ui_show)
		self:UICommand_AddInt(sortflag)
		self:UICommand_AddStr(dateinfo)
		self:UICommand_AddStr(specialdateinfo)
		self:UICommand_AddStr(self.ride_msg)
		self:UICommand_AddStr(self.dress_msg)
		self:EndUICommand()
		self:DispatchUICommand(selfId,806042021)
		-- self:NotifyTips(selfId,"curSection:"..tostring(curSection)) 
	end
end
function JingPai:NewBidding(selfId,section,index,jPrize,sortflag)
	if not index or index < 1 or index > 99 then
		return
	elseif not jPrize or jPrize < 1 then
		return
	elseif not section or not sortflag then
		return
	end
	local migration,overdate = self:GetJingPaiSection(selfId)
	if not migration then
		return
	elseif migration ~= section + 1 then
		self:NotifyTips(selfId,"#{SZPM_230913_45}")
		return
	end
	local msg
	local curtime = self:GetHour() * 60 + self:GetMinute()
	local world_id = self:LuaFnGetServerID(selfId)
	local end_time,itemid,startmoney,addmoney,best_moeny = self:GetJingPaiItemConfig(world_id,index)
	if not end_time then
		self:NotifyTips(selfId,"Dữ liệu bất thường, xin mở thao tác lại.")
		return
	elseif end_time == 0 then
		self:NotifyTips(selfId,"Liên server không tham gia đấu giá được.")
		return
	elseif end_time <= curtime then
		msg = string.format("Kỳ [%d] vật phẩm %d (%s) đã kết thúc, không ra giá được, xin để ý vật phẩm chưa kết thúc.",migration,index,self:GetItemName(itemid))
		self:NotifyTips(selfId,msg)
		self:TryOpenFashionAuction(selfId,1,section,0,sortflag)
		return
	end
	if startmoney < 0 or addmoney < 0 then
		self:NotifyTips(selfId,"error")
		return
	end
	local curmoney
	if best_moeny > 0 then
		curmoney = best_moeny + addmoney
		if jPrize < curmoney then
			local msg = self:ScriptGlobal_Format("#{SZPM_230913_73}",curmoney)
			self:NotifyTips(selfId,msg)
			return
		end
	else
		curmoney = startmoney
		if jPrize < curmoney then
			local msg = self:ScriptGlobal_Format("#{SZPM_230913_73}",curmoney)
			self:NotifyTips(selfId,msg)
			return
		end
	end
	if not curmoney then
		return
	end
	if self:GetYuanBao(selfId) < curmoney then
		self:NotifyTips(selfId,"#{SZPM_230913_74}")
		return
	end
	local guid = self:LuaFnGetGUID(selfId)
	local name = self:LuaFnGetName(selfId)
	local addtime = 0
	if self:GetTime2Day() == overdate then
		addtime = JingPaiAddTime - (end_time - curtime)
		if addtime > 0 then
			local nowtime = end_time + addtime
			local maxaddtime = JingPaiMaxHour * 60 + JingPaiMaxMinute
			if nowtime > maxaddtime then
				addtime = maxaddtime - end_time
				end_time = maxaddtime
			else
				end_time = nowtime
			end
		end
	end
	self:LuaFnCostYuanBao(selfId, jPrize)
	local jpYuanbao = self:GetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO) + jPrize
	self:SetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO,jpYuanbao)
	if self:SubmitJingPaiBid(world_id,index,jPrize,guid,name,end_time) then
		-- if addtime > 0 then 
			-- local hour = end_time // 60
			-- local minute = end_time - hour * 60
			-- local msg = string.format("#B%s#P对#G%d号#P拍品#G%s#P出价成功,延长竞价时间至今天#G%02d:%02d#B(延时上限:%02d:%02d)#P结束。",
			-- "神秘少侠",index,self:GetItemName(itemid),hour,minute,JingPaiMaxHour,JingPaiMaxMinute)
			-- self:AddGlobalCountNews_Fun(self.script_id,"UpdateOverText",msg)
		-- end
		self:NotifyTips(selfId,"#{SZPM_230913_77}")
	else
		self:NotifyTips(selfId,"Ra giá thất bại, nguyên bảo đã trừ được gửi vào mục lưu phách, lấy lại trong giao diện hoặc tự nhận khi online.")
	end
	local ui_show,maxalldate,alltime,specialdate = self:BackJingPaiData(selfId,migration,sortflag)
	if ui_show >= 0 then
		self:BeginUICommand()
		self:UICommand_AddInt(116042021)
		self:UICommand_AddInt(section)
		self:UICommand_AddInt(index)
		self:EndUICommand()
		self:DispatchUICommand(selfId,116042021)
	end
end
function JingPai:UpdateOverText(selfId)
	self:TryOpenFashionAuction(selfId,0,0,0,0,2)
end
function JingPai:OpenBidUI(selfId,param0,section,index,cdFlag,sortflag)
	if not index or index < 1 or index > 99 then
		return
	elseif not section or not sortflag then
		return
	end
	if cdFlag ~= 0 then
		if not self:CheckTopOpenUiCD(selfId,JingPaiUpdateTime) then
			return
		end
	end
	local migration,overdate = self:GetJingPaiSection(selfId)
	if not migration then
		return
	elseif migration ~= section + 1 then
		self:NotifyTips(selfId,"#{SZPM_230913_45}")
		return
	end
	local curtime = self:GetHour() * 60 + self:GetMinute()
	local world_id = self:LuaFnGetServerID(selfId)
	local end_time,itemid = self:GetJingPaiItemConfig(world_id,index)
	if not end_time then
		self:NotifyTips(selfId,"Dữ liệu bất thường, xin mở thao tác lại.")
		return
	elseif end_time == 0 then
		self:NotifyTips(selfId,"Liên server không tham gia đấu giá được.")
		return
	end
	if self:GetTime2Day() == overdate then
		if end_time <= curtime then
			local msg = string.format("Kỳ [%d] vật phẩm %d (%s) đã kết thúc, không ra giá được, xin để ý vật phẩm chưa kết thúc.",migration,index,self:GetItemName(itemid))
			self:NotifyTips(selfId,msg)
			self:TryOpenFashionAuction(selfId,1,section,0,sortflag)
			return
		end
	end
	if self:BackJingPaiData(selfId,migration,sortflag) >= 0 then
		self:BeginUICommand()
		self:UICommand_AddInt(116042021)
		self:UICommand_AddInt(section)
		self:UICommand_AddInt(index)
		self:UICommand_AddInt(sortflag)
		self:EndUICommand()
		self:DispatchUICommand(selfId,116042021)
	end
end
function JingPai:BuyFashionCloth(selfId,param1)
	-- skynet.logi("BuyFashionCloth")
	if not self:CheckTopClaimAwardCD(selfId,1) then
		return
	end
	local migration,overdate,endtime = self:GetJingPaiSection(selfId)
	if not migration then return end
	overdate = overdate % 10000
	overdate = overdate * 10000 + endtime
	local today = self:GetTime2Day()
	local curtime = self:GetHour() * 60 + self:GetMinute()
	local curdate = today % 10000
	curdate = curdate * 10000 + curtime
	if curdate ~= self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_JINGPAI_TIME) then
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_JINGPAI_SPECIAL_COUNT,0)
		self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_JINGPAI_TIME,curdate)
	end
	if self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_JINGPAI_SPECIAL_COUNT) > 0 then
		self:NotifyTips(selfId,"Hàng đặc mãi kỳ này đã mua rồi.")
		return
	end
	local world_id = self:LuaFnGetServerID(selfId)
	local end_date,end_time,itemid,itemcount,startmoney = self:GetJingPaiSpecialItem(world_id)
	if not end_date then
		self:NotifyTips(selfId,"Đấu giá chưa mở hoặc không có hàng đặc mãi.")
		return
	elseif end_date <= 0 then
		self:NotifyTips(selfId,"Liên server không mua được.")
		return
	elseif end_date < today then
		self:NotifyTips(selfId,"Hàng đặc mãi đã bán hết.")
		return
	elseif end_date == today then
		if curtime > end_time then
			self:NotifyTips(selfId,"Hàng đặc mãi đã bán hết.")
			return
		end
	end
	if startmoney < 1 then
		self:NotifyTips(selfId,"error。")
		return
	end
	if self:GetYuanBao(selfId) < startmoney then
		self:NotifyTips(selfId,"Nguyên bảo không đủ.")
		return
	end
	self:BeginAddItem()
	self:AddItem(itemid,itemcount,true);
	if not self:EndAddItem(selfId) then
		return
	end
	self:LuaFnCostYuanBao(selfId,startmoney)
	self:AddItemListToHuman(selfId)
	self:BuyItemTip(selfId,itemid,itemcount,18)
end
function JingPai:TakeBackYuanBao(selfId,check_cd)
	if not check_cd then
		if not self:CheckTopClaimAwardCD(selfId,1) then
			return
		end
	end
	local jpYuanbao = self:GetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO)
	if jpYuanbao > 0 then
		local world_id = self:LuaFnGetServerID(selfId)
		local guid = self:LuaFnGetGUID(selfId)
		local back_yuanbao = self:TakeBackBidYuanBao(world_id,guid,jpYuanbao)
		if back_yuanbao <= 0 then
			if self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT) > 0 then
				self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT,0)
				self:BeginUICommand()
				self:EndUICommand()
				self:DispatchUICommand(selfId,88881801)
			end
			return
		end
		-- skynet.logi("jpYuanbao = ",jpYuanbao,"back_yuanbao = ",back_yuanbao)
		local subyb = jpYuanbao - back_yuanbao
		self:SetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO,subyb)
		if self:GetMissionData(selfId, ScriptGlobal.MD_JINGPAI_YUANBAO) == subyb then
			local sub_clientyb = self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT) - back_yuanbao
			if sub_clientyb < 0 then
				sub_clientyb = 0
			end
			self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT,sub_clientyb)
			local msg = string.format("Nguyên bảo đấu giá: %d, lấy về %d",jpYuanbao,back_yuanbao)
			self:CSAddYuanbao(selfId,back_yuanbao,msg)
			local msg = string.format("#WĐã hoàn cho bạn#G%s#Wnguyên bảo tham gia đấu giá.",tostring(back_yuanbao))
			self:NotifyTips(selfId,msg)
			self:LuaFnSendSystemMail(self:GetName(selfId), msg)
			self:BeginUICommand()
			self:EndUICommand()
			self:DispatchUICommand(selfId,88881801)
		end
	else
		if self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT) > 0 then
			self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO_CLIENT,0)
			self:BeginUICommand()
			self:EndUICommand()
			self:DispatchUICommand(selfId,88881801)
		end
	end
end

function JingPai:GetJingPaiSection(selfId)
	local world_id = self:LuaFnGetServerID(selfId)
	local overdate,migration,endtime = self:JingPaiCheck(world_id)
	if overdate == -1 then
		self:NotifyTips(selfId,"Liên server không tham gia đấu giá được.")
		return
	end
	local today = self:GetTime2Day()
	if today > overdate then
		self:NotifyTips(selfId,"Đấu giá chưa mở hoặc đã kết thúc.")
		return
	end
	return migration,overdate,endtime
end

function JingPai:TakeBonusFashion( selfId )
	if not self:CheckTopClaimAwardCD(selfId,1) then
		return
	end
	local migration = self:GetJingPaiSection(selfId)
	if not migration then return end
	local haveaward = self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG)
	if haveaward > 0 then
		local jpYuanbao = self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO)
		if jpYuanbao < 1 then
			self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,0)
			return
		end
		local msg
		migration = haveaward % 10
		local index = haveaward // 10
		
		local world_id = self:LuaFnGetServerID(selfId)
		local guid = self:LuaFnGetGUID(selfId)
		
		local best_moeny,itemid,itemcount = self:HaveJingPaiAward(world_id,migration,index,guid,jpYuanbao)
		if best_moeny > 0 then
			if jpYuanbao >= best_moeny then
				self:BeginAddItem()
				self:AddItem(itemid,itemcount,true);
				if not self:EndAddItem(selfId) then
					return
				end
				if self:ClaimJingPaiAward(world_id,migration,index,guid) then
					jpYuanbao = jpYuanbao - best_moeny
					self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO,jpYuanbao)
					if self:GetMissionData(selfId,ScriptGlobal.MD_JINGPAI_YUANBAO) == jpYuanbao then
						self:AddItemListToHuman(selfId)
						self:GiveItemTip(selfId,itemid,itemcount,18)
					else
						self:NotifyTips(selfId,"Trừ nguyên bảo thất bại.")
					end
					self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,0)
					self:TryOpenFashionAuction(selfId,1,migration - 1,0,0)
				else
					self:NotifyTips(selfId,"Nhận thưởng thất bại, xin thử lại.")
				end
			else
				self:NotifyTips(selfId,"In xem trước, khỏi để ý.")
			end
		elseif best_moeny == 0 then
			self:NotifyTips(selfId,"Liên server không tham gia đấu giá được.")
		elseif best_moeny == -1 then
			self:NotifyTips(selfId,"Tham số bất thường.")
		elseif best_moeny == -2 then
			local msg = string.format("Kỳ đấu giá [%d] chưa kết thúc.",migration)
			self:NotifyTips(selfId,msg)
		elseif best_moeny == -3 then
			self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,0)
		elseif best_moeny == -4 then
			self:SetMissionData(selfId,ScriptGlobal.MD_JINGPAI_AWARDFALG,0)
			local msg = string.format("Kỳ đấu giá [%d] thưởng thứ %d đã nhận.",migration,index)
			self:NotifyTips(selfId,msg)
		elseif best_moeny == -5 then
			local msg = string.format("Thưởng thứ %d kỳ đấu giá [%d] không thuộc các hạ.",migration,index)
			self:NotifyTips(selfId,msg)
		elseif best_moeny == -6 then
			self:NotifyTips(selfId,"Đấu giá chưa mở.")
		else
			self:NotifyTips(selfId,"Lỗi.")
		end
	end
end
return JingPai
