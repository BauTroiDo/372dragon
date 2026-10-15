local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_yexihuboss_award = class("event_yexihuboss_award", script_base)
-- local gbk = require "wire_charset"
event_yexihuboss_award.script_id = 999996

--杀人榜奖励配置  bind = true(给予绑定)  bind = false(给予不绑定) 
event_yexihuboss_award.killtop = 
{
	[1] = {
		{itemid = 38008160,count = 600,bind = true},
	
	},
	[2] = {
		{itemid = 38008160,count = 400,bind = true},
	
	},
	[3] = {
		{itemid = 38008160,count = 300,bind = true},
	
	},
	[4] = {
		{itemid = 38008160,count = 200,bind = true},
	
	},
	[5] = {
		{itemid = 38008160,count = 100,bind = true},
	
	},
	[6] = {
		{itemid = 38008160,count = 90,bind = true},
	
	},
	[7] = {
		{itemid = 38008160,count = 80,bind = true},
	
	},
	[8] = {
		{itemid = 38008160,count = 70,bind = true},
	
	},
	[9] = {
		{itemid = 38008160,count = 60,bind = true},
	
	},
	[10] = {
		{itemid = 38008160,count = 50,bind = true},
	
	},
}

--伤害榜奖励配置  bind = true(给予绑定)  bind = false(给予不绑定) 
event_yexihuboss_award.damagetop = 
{
	[1] = {
		{itemid = 38008005,count = 200,bind = true},
	
	},
	[2] = {
		{itemid = 38008005,count = 100,bind = true},
	
	},
	[3] = {
		{itemid = 38008005,count = 50,bind = true},
	
	},
	[4] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[5] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[6] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[7] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[8] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[9] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
	[10] = {
		{itemid = 38008005,count = 40,bind = true},
	
	},
}

--BOSS死亡时掉落包奖励配置
--bind = true(给予绑定)  bind = false(给予不绑定)
--rate = 1000(百分百给予)  1-1000(xx / 1000机率得到该道具)
event_yexihuboss_award.bossdie = 
{
	{itemid = 20101001,count = 10,bind = true,rate = 1000},
	{itemid = 20101001,count = 4,bind = true,rate = 10},
	{itemid = 20101001,count = 2,bind = true,rate = 100},
	{itemid = 20101001,count = 1,bind = true,rate = 666},


}

--BOSS死亡最后击杀掉落包奖励配置
--bind = true(给予绑定)  bind = false(给予不绑定)
--rate = 1000(百分百给予)  1-1000(xx / 1000机率得到该道具)
event_yexihuboss_award.playerkillboss = {
	{itemid = 20101001,count = 10,bind = true,rate = 1000},
	{itemid = 20101001,count = 4,bind = true,rate = 10},
	{itemid = 20101001,count = 2,bind = true,rate = 100},
	{itemid = 20101001,count = 1,bind = true,rate = 666},
}

event_yexihuboss_award.needscene = 66

event_yexihuboss_award.box_itemnum = 1
event_yexihuboss_award.box_deltime = 2
event_yexihuboss_award.box_guid = 3
event_yexihuboss_award.box_protecttime = 4
event_yexihuboss_award.box_dataid = 5
--**********************************
--特殊交互:聚气类成功生效处理
--**********************************
function event_yexihuboss_award:OnActivateEffectOnce(selfId, activatorId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return 1
	end
	local human = self.scene:get_obj_by_id(activatorId)
	if not human then
		return 1
	end
	local bossdataid = obj:get_model()
	local boxname = obj:get_name()
	if self.scene:get_id() ~= self:LuaFnGetCopySceneData_Param(0,self.needscene) then
		return 1
	elseif bossdataid ~= 99998 and bossdataid ~= 99999 then
		return 1
	end
	local ai = obj:get_ai()
	local curtime = os.time()
	local box_deltime = ai:get_int_param_by_index(self.box_deltime)
	if curtime > box_deltime then
		self.scene:delete_temp_monster(obj)
		 human:notify_tips("Rương đã hết hiệu lực")
		 return 1
	end
	local haveguid = self:LuaFnGetCopySceneData_Param(self.box_guid)
	if haveguid > 0 then
		local myguid = human:get_guid()
		if myguid ~= haveguid then
			local box_protecttime = ai:get_int_param_by_index(self.box_protecttime)
			if curtime < box_protecttime then
				return 1
			end
		end
	end
	local additem = {}
	local itemnum = ai:get_int_param_by_index(self.box_itemnum)
	local idx,rate
	if itemnum == 0 then
		if bossdataid == 99998 then
			for i,j in ipairs(self.bossdie) do
				if j.rate >= 1000 then
					table.insert(additem,j)
					itemnum = itemnum + 1
					idx = itemnum * 3
					ai:set_int_param_by_index(idx - 2,j.itemid)
					ai:set_int_param_by_index(idx - 1,j.count)
					if j.bind then
						ai:set_int_param_by_index(idx,1)
					else
						ai:set_int_param_by_index(idx,0)
					end
				else
					if math.random(1,1000) <= j.rate then
					-- if math.random(1,1000) <= j.rate and math.random(1,1000) > 1000 - j.rate then
						table.insert(additem,j)
						itemnum = itemnum + 1
						idx = itemnum * 3
						ai:set_int_param_by_index(idx - 2,j.itemid)
						ai:set_int_param_by_index(idx - 1,j.count)
						if j.bind then
							ai:set_int_param_by_index(idx,1)
						else
							ai:set_int_param_by_index(idx,0)
						end
					end
				end
			end
		else
			for i,j in ipairs(self.playerkillboss) do
				if j.rate >= 1000 then
					table.insert(additem,j)
					itemnum = itemnum + 1
					idx = itemnum * 3
					ai:set_int_param_by_index(idx - 2,j.itemid)
					ai:set_int_param_by_index(idx - 1,j.count)
					if j.bind then
						ai:set_int_param_by_index(idx,1)
					else
						ai:set_int_param_by_index(idx,0)
					end
				else
					if math.random(1,1000) <= j.rate then
					-- if math.random(1,1000) <= j.rate and math.random(1,1000) > 1000 - j.rate then
						table.insert(additem,j)
						itemnum = itemnum + 1
						idx = itemnum * 3
						ai:set_int_param_by_index(idx - 2,j.itemid)
						ai:set_int_param_by_index(idx - 1,j.count)
						if j.bind then
							ai:set_int_param_by_index(idx,1)
						else
							ai:set_int_param_by_index(idx,0)
						end
					end
				end
			end
		end
	else
		local itemid,count,bind
		local maxid = itemnum + 10
		for i = 11,maxid,3 do
			itemid = ai:get_int_param_by_index(i)
			count = ai:get_int_param_by_index(i + 1)
			bind = ai:get_int_param_by_index(i + 2)
			if itemid > 0 and count > 0 then
				if bind == 1 then
					table.insert(additem,{itemid = itemid,count = count,bind = true})
				else
					table.insert(additem,{itemid = itemid,count = count,bind = false})
				end
			end
		end
		ai:set_int_param_by_index(self.box_itemnum,#additem)
	end
	if #additem > 0 then
		local msgtab = {"Bạn mở [",boxname,"]nhận được:\\n"}
		self:BeginAddItem()
		for i,j in ipairs(additem) do
			table.insert(msgtab,self:GetItemName(j.itemid).." * "..tostring(j.count).."\n")
			self:AddItem(j.itemid, j.count, j.bind)
		end
		if not self:EndAddItem(activatorId) then
			human:notify_tips("Túi hành trang không đủ chỗ")
			return 1
		end
		ai:set_int_param_by_index(self.box_deltime,0)
		self.scene:delete_temp_monster(obj)
		self:AddItemListToHuman(activatorId)
		local msg = table.concat(msgtab)
		self:BeginEvent(self.script_id)
		self:AddText(msg)
		self:EndEvent()
		self:DispatchEventList(activatorId,activatorId)
	else
		human:notify_tips("Mở rương thất bại, xin thử lại")
	end
	return 1
end

--**********************************
--特殊交互:条件判断
--**********************************
function event_yexihuboss_award:OnActivateConditionCheck(selfId, activatorId )
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return 0
	end
	local human = self.scene:get_obj_by_id(activatorId)
	if not human then
		return 0
	end
	local ai = obj:get_ai()
	if ai:get_int_param_by_index(self.box_deltime) == 0 then
		self:notify_tips(activatorId, "Rương đã hết hiệu lực")
		return 0
	end
	local haveguid = ai:get_int_param_by_index(self.box_guid)
	if haveguid > 0 then
		local myguid = human:get_guid()
		if myguid ~= haveguid then
			local curtime = os.time()
			local box_protecttime = ai:get_int_param_by_index(self.box_protecttime)
			if curtime < box_protecttime then
				self:notify_tips(activatorId, "Thời gian bảo hộ còn lại của rương riêng:"..tostring(box_protecttime - curtime).."Giây")
				return 0
			end
		end
	end
	return 1
end
--**********************************
--特殊交互:消耗和扣除处理
--**********************************
function event_yexihuboss_award:OnActivateDeplete(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:引导类每时间间隔生效处理
--**********************************
function event_yexihuboss_award:OnActivateEffectEachTick(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互开始时的特殊处理
--**********************************
function event_yexihuboss_award:OnActivateActionStart(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互撤消时的特殊处理
--**********************************
function event_yexihuboss_award:OnActivateCancel(selfId, activatorId)
	return 0
end

--**********************************
--特殊交互:交互中断时的特殊处理
--**********************************
function event_yexihuboss_award:OnActivateInterrupt(selfId, activatorId)
	return 0
end
function event_yexihuboss_award:AwardInfo(selfId,index,topid)
	if index == 0 then
		local obj = self.scene:get_obj_by_id(selfId)
		if not obj then
			return
		end
		local yexihu_boss = self:GetActivityWar("yexihu_boss",false,false,"findOne",{_id = 0})
		if not yexihu_boss then
			return
		end
		local needlv = yexihu_boss.warini.needlevel
		local needmaxhp = yexihu_boss.warini.needmaxhp
		local selflv = obj:get_attrib("level")
		local selfhp = obj:get_attrib("hp_max")
		if selflv < needlv or selfhp < needmaxhp then
			return
		end
		local guid = obj:get_guid()
		local yexihu_damage = self:GetActivityWar("yexihu_damage","playerguid",guid,"findOne",{_id = 0})
		local yexihu_kill = self:GetActivityWar("yexihu_kill","playerguid",guid,"findOne",{_id = 0})
		if not yexihu_damage and not yexihu_kill then
			return
		end
		local awardflag = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_AWARDTIME)
		local additem = {}
		local textinfo = {}
		local newdamage,newkill
		local damagetop,killtop
		local newawardflag
		if yexihu_damage then
			if awardflag >= yexihu_damage.opentime then
				return
			end
			newawardflag = yexihu_damage.opentime
			newdamage = {playerguid = 0,warini = "Thưởng: đã nhận"}
			damagetop = yexihu_damage.topid
			local awardinfo = self.damagetop[damagetop]
			if awardinfo then
				table.insert(textinfo,"Bảng sát thương thứ [")
				table.insert(textinfo,damagetop)
				table.insert(textinfo,"]hạng nhận thưởng:\\n")
				local itemid,count,bind
				for i,j in ipairs(awardinfo) do
					itemid = j.itemid
					count = j.count
					bind = j.bind
					table.insert(additem,{itemid,count,bind})
					table.insert(textinfo,self:GetItemName(itemid))
					table.insert(textinfo," * ")
					table.insert(textinfo,tostring(count))
					if bind then
						table.insert(textinfo,"(cấp khóa)\\n")
					else
						table.insert(textinfo,"\n")
					end
				end
			end
		end
		if yexihu_kill then
			if awardflag >= yexihu_kill.opentime then
				return
			end
			newawardflag = yexihu_kill.opentime
			newkill = {playerguid = 0,warini = "Thưởng: đã nhận"}
			killtop = yexihu_kill.topid
			local awardinfo = self.killtop[killtop]
			if awardinfo then
				table.insert(textinfo,"Bảng sát nhân thứ [")
				table.insert(textinfo,killtop)
				table.insert(textinfo,"]hạng nhận thưởng:\\n")
				local itemid,count,bind
				for i,j in ipairs(awardinfo) do
					itemid = j.itemid
					count = j.count
					bind = j.bind
					table.insert(additem,{itemid,count,bind})
					table.insert(textinfo,self:GetItemName(itemid))
					table.insert(textinfo," * ")
					table.insert(textinfo,tostring(count))
					if bind then
						table.insert(textinfo,"(cấp khóa)\\n")
					else
						table.insert(textinfo,"\n")
					end
				end
			end
		end
		if newawardflag and #additem > 0 then
			self:BeginAddItem()
			for i,j in ipairs(additem) do
				self:AddItem(j[1],j[2],j[3])
			end
			if not self:EndAddItem(selfId) then
				 obj:notify_tips("Túi không đủ chỗ, xin dọn túi rồi vào lại cảnh này tự nhận")
				return
			end
			obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_YXH_AWARDTIME,awardflag)
			if damagetop and newdamage then
				self:UpdateActivityWar("yexihu_damage","topid",damagetop,newdamage)
			end
			if killtop and newkill then
				self:UpdateActivityWar("yexihu_kill","topid",killtop,newkill)
			end
			self:AddItemListToHuman(selfId)
			self:SetLog(selfId,"Nhận thưởng xếp hạng chiến boss","Lĩnh thưởng thành công.","Lĩnh thưởng thành công.","Lĩnh thưởng thành công.")
			local text = table.concat(textinfo)
			self:BeginEvent(self.script_id)
			self:AddText(text)
			self:EndEvent()
			self:DispatchEventList(selfId,selfId)
		end
	elseif index == 1 then
		if not topid or topid < 0 or topid > 10 then
			return
		end
		local topinfo = self.damagetop[topid]
		if not topinfo then
			self:BeginEvent(self.script_id)
			self:AddText("    第"..tostring(topid).."cấu hình thưởng hạng bất thường!\\nXin báo GM.")
			self:EndEvent()
			self:DispatchEventList(selfId,selfId)
			return
		end
		local awardtext = {"Bảng sát thương BOSS thứ",topid,"chi tiết thưởng hạng:\\n"}
		for i,j in ipairs(topinfo) do
			table.insert(awardtext,"    ")
			table.insert(awardtext,self:GetItemName(j.itemid))
			table.insert(awardtext," * ")
			table.insert(awardtext,j.count)
			if j.bind then
				table.insert(awardtext,"(cấp khóa)\\n")
			else
				table.insert(awardtext,"\n")
			end
		end
		table.insert(awardtext,"    Mẹo: có mặt lúc kết thúc sẽ tự nhận, nếu chưa nhận xin đổi cảnh vào lại tự nhận, hạn tới trước đợt chiến BOSS sau")
		local text = table.concat(awardtext)
		self:BeginEvent(self.script_id)
		self:AddText(text)
		self:EndEvent()
		self:DispatchEventList(selfId,selfId)
	elseif index == 2 then
		if not topid or topid < 0 or topid > 10 then
			return
		end
		local topinfo = self.killtop[topid]
		if not topinfo then
			self:BeginEvent(self.script_id)
			self:AddText("    第"..tostring(topid).."cấu hình thưởng hạng bất thường!\\nXin báo GM.")
			self:EndEvent()
			self:DispatchEventList(selfId,selfId)
			return
		end
		local awardtext = {"Bảng sát nhân thứ",topid,"chi tiết thưởng hạng:\\n"}
		for i,j in ipairs(topinfo) do
			table.insert(awardtext,"    ")
			table.insert(awardtext,self:GetItemName(j.itemid))
			table.insert(awardtext," * ")
			table.insert(awardtext,j.count)
			if j.bind then
				table.insert(awardtext,"(cấp khóa)\\n")
			else
				table.insert(awardtext,"\n")
			end
		end
		table.insert(awardtext,"    Mẹo: có mặt lúc kết thúc sẽ tự nhận, nếu chưa nhận xin đổi cảnh vào lại tự nhận, hạn tới trước đợt chiến BOSS sau")
		local text = table.concat(awardtext)
		self:BeginEvent(self.script_id)
		self:AddText(text)
		self:EndEvent()
		self:DispatchEventList(selfId,selfId)
	end
end


return event_yexihuboss_award