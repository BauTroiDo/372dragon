local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local jingzhuzengli_activity = class("jingzhuzengli_activity", script_base)
-- local gbk = require "wire_charset"
-- local skynet = require "skynet"
jingzhuzengli_activity.script_id = 999992
jingzhuzengli_activity.DataValidator = 0

--*********************************
-- 活动添加：（活动图不可定位，不可传送）

-- 金猪赠礼：14:00-14:30
-- 金猪赠礼：19:00-19:30
-- 地图采用 校场 市集 都可以 传送进入地图随机范围
-- 90级进入泡点元宝，增加进入提示，#G当场景内人数大于50人的时候，所有人无法获得泡点奖励。
-- 30秒可得100元宝
-- 活动期间 每5分钟 刷新8只金猪BOSS 模型采用 萌宝猪（搞个金色的 看看有没有 小猪外观） 金猪最后一击掉落 1元充值卡
-- 活动结束 踢出所有玩家
--*********************************

--返回位置
jingzhuzengli_activity.GoBackScene = 0
jingzhuzengli_activity.GoBackPosx = 160
jingzhuzengli_activity.GoBackPosz = 105

--开启场景与活动号
jingzhuzengli_activity.needsceneId = 490

jingzhuzengli_activity.box_fun_name = "jinzhu_box"
jingzhuzengli_activity.actname = "Băng Tuyết Bất Dạ Thành"
-- boxtime = 弹窗持续时长(单位:秒) 0=不弹窗  > 0 则弹窗有效时长
jingzhuzengli_activity.boxtime = 0

--开启时间   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.timetab = 
{
	-- {starthour = 21,startminue = 16,endhour = 23,endminue = 0},
	{starthour = 19,startminue = 30,endhour = 20,endminue = 30,openweek = {[1] = true,[3] = true,[5] = true,[7] = true}},
	--{starthour = 0,startminue = 4,endhour = 9,endminue = 55},
}
--结束后N秒后清场   活动初始化时生效  过程修改不生效
jingzhuzengli_activity.backtick = 60
--需求等级   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.needlevel = 50
--需求血量   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.needmaxhp = 50000
--需求点数   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.needpoint = 0
--限制活动场景最大人数   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.humancount_max = 700




--泡点间隙  不开写0   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.paodiantime = 30
--泡点奖励 元宝  不开写0   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.paodianaward = 500
--泡点限制人数  不限写0   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.paodianmaxplayer = 50
--刷新BOSS时间  秒  不开写0   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.createbosstime = 600
--最后一击BOSS得到物品ID   不管活动是否在进行中，配置数据实时生效
jingzhuzengli_activity.killbossaward = 38008168


--createboss 刷几只boss配置几只的信息  bosshp == 0 时 则默认怪物表血量  > 0 时则在创建时修正该血量
jingzhuzengli_activity.createboss = 
{
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 140,posz = 191,bosshp = 1000000,createflag = false},
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 135,posz = 186,bosshp = 1000000,createflag = false},
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 130,posz = 181,bosshp = 1000000,createflag = false},

  {bossname = "Quà băng tuyết",bossid = 30636,posx = 140,posz = 185,bosshp = 1000000,createflag = false},
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 135,posz = 190,bosshp = 1000000,createflag = false},

  {bossname = "Quà băng tuyết",bossid = 30636,posx = 130,posz = 186,bosshp = 1000000,createflag = false},
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 133,posz = 183,bosshp = 1000000,createflag = false},
  {bossname = "Quà băng tuyết",bossid = 30636,posx = 140,posz = 181,bosshp = 1000000,createflag = false},

}

jingzhuzengli_activity.act_isopen = 1
jingzhuzengli_activity.act_tick = 2
jingzhuzengli_activity.act_close_flag = 3
jingzhuzengli_activity.act_close_tick = 4
jingzhuzengli_activity.act_paodian_tick = 5
jingzhuzengli_activity.act_create_boss_tick = 6
jingzhuzengli_activity.act_index = 7
jingzhuzengli_activity.act_load_date = 8
jingzhuzengli_activity.act_name = 9

jingzhuzengli_activity.backtopinfo = 
{
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
	{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "",guild_name_1 = "",guild_name_2 = "",guild_name_3 = ""},
}


function jingzhuzengli_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
end
function jingzhuzengli_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
--*********************************
-- 关闭活动  接口
--*********************************
function jingzhuzengli_activity:CloseActivity(actId)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if define.ACTIVITY_JINZHU_ID ~= newId then
		return
	elseif not self:CheckActiviyValidity(newId) then
		return
	end
	self:StopOneActivity(newId)
end
--*********************************
-- 开启活动
--*********************************
function jingzhuzengli_activity:StartActivity(actId)
	-- skynet.logi("jingzhuzengli_activity:StartActivity actId = ",actId,"sceneId = ",self:get_scene():get_id())
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if define.ACTIVITY_JINZHU_ID ~= newId then
		return
	elseif self:HaveActivity(newId) then
		return
	end
	self:StartOneActivity(newId,2100000000,0,-1)
end
function jingzhuzengli_activity:CheckOpen(actId,minute,hminute,hour,today)
	-- skynet.logi("actId = ",actId,"minute = ",minute,"hminute = ",hminute,"hour = ",hour,",today = ",today)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if define.ACTIVITY_JINZHU_ID ~= newId then
		return
	end
	local week = self:GetWeek()
	local ischeck
	local statrtime,overtime,value
	local load_date = today % 10000
	load_date = load_date * 10000
	local old_date
	local sceneId = self.needsceneId
	for _,info in pairs(self.timetab) do
		ischeck = true
		if info.openweek then
			ischeck = info.openweek[week]
		end
		if ischeck then
			statrtime = info.starthour * 60 + info.startminue
			overtime = info.endhour * 60 + info.endminue
			if hminute >= statrtime and hminute <= overtime then
				value = load_date + statrtime
				old_date = self:GetActivityKey(newId,"load_date",sceneId)
				if old_date and old_date ~= value then
				
					self:SetCsLog(
						"jingzhuzengli_activity",
						{
							sceneId = sceneId,
							old_date = old_date,
							value = value,
						}
					)
					self:CallDestSceneFunctionEx(sceneId,self.script_id,"StartActivity",actId)
					return
				end
			end
		end
	end
end
function jingzhuzengli_activity:CheckActiviyIsOpen()
	if not self:CheckActiviyValidity(define.ACTIVITY_JINZHU_ID) then
		return
	end
	return self:get_scene():get_activity_scene_param_on_key(define.ACTIVITY_JINZHU_ID,self.act_isopen) > 0
end

--*********************************
-- 活动描述
--*********************************
function jingzhuzengli_activity:GetJingZhuZengLiMsg(selfId)
	local msgtab = 
	{
		"    Quà băng tuyết: bản thân đạt cấp >=",
		self.needlevel,
		", máu >=",
		self.needmaxhp,
		", điểm đổi >=",
		self.needpoint,
		"người chơi được tham gia\\nTreo máy: mỗi",
		self.paodiantime,
		"giây trao cho người có mặt",
		self.paodianmaxplayer,
		"người chơi",
		self.paodianaward,
		"Thưởng nguyên bảo (nếu vượt",
		self.paodianmaxplayer,
		"người chơi, thì chờ đấu tới khi còn",
		self.paodianmaxplayer,
		"người chơi).",
		-- "\n金猪BOSS：每",
		-- self.createbosstime,
		-- "秒刷新",
		-- #self.createboss,
		-- "只BOSS，给予BOSS最后一击将得到[",
		-- self:GetItemName(self.killbossaward),
		-- "]。"
	}
	local msg = table.concat(msgtab)
	self:BeginUICommand()
	self:UICommand_AddInt(329042022)
	self:UICommand_AddStr(msg)
	self:EndUICommand()
	self:DispatchUICommand(selfId,329042022)
end
--*********************************
-- 清场
--*********************************
function jingzhuzengli_activity:CheckActiviyParticipation(selfId)
	local human_count = self:GetActivityKey(define.ACTIVITY_JINZHU_ID,"human_count",self.needsceneId)
	if human_count < self.humancount_max then
		local obj = self:get_scene():get_obj_by_id(selfId)
		if obj and obj:is_alive() then
			if obj:get_attrib("level") >= self.needlevel
			and obj:get_attrib("hp_max") >= self.needmaxhp
			and obj:get_mission_data_by_script_id(388) / 3000  >= self.needpoint then
				if obj:get_team_id() == define.INVAILD_ID then
					return 0
				else
					return "    Hoạt động này không cho tổ đội."
				end
			else
				local msg = string.format("    Yêu cầu hoạt động: cấp >=%d, máu >=%d, điểm đổi >=%d mới tham gia được.",self.needlevel,self.needmaxhp,self.needpoint)
				return msg
			end
		end
		return "    Ngươi đã chết."
	end
	return "Hoạt động đã đủ người tham gia, xin thử lại sau."
end
function jingzhuzengli_activity:CheckPlayerOnActivity(selfId)
	local obj = self:get_scene():get_obj_by_id(selfId)
	if obj and obj:is_alive() then
		if obj:get_attrib("level") >= self.needlevel
		and obj:get_attrib("hp_max") >= self.needmaxhp
		and obj:get_mission_data_by_script_id(388) / 2500  >= self.needpoint then
			if obj:get_team_id() == define.INVAILD_ID then
				return true
			else
				obj:notify_tips("Hoạt động này không cho tổ đội.")
			end
		else
			local msg = string.format("Yêu cầu hoạt động: cấp >=%d, máu >=%d, điểm đổi >=%d mới tham gia được.",self.needlevel,self.needmaxhp,self.needpoint)
			obj:notify_tips(msg)
		end
		self:NewWorld(selfId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
	end
end
--*********************************
-- 战场心跳
--*********************************
function jingzhuzengli_activity:over_notify_ui(actId,quit_tick,human_num)
	if not actId or actId >= 0 then
		return
	end
	self.backtopinfo[1].crystal_hold_score = 0
	self.backtopinfo[1].flag_capture_score = 0
	self.backtopinfo[1].league_id = quit_tick
	self.backtopinfo[1].guild_id_1 = 1
	self.backtopinfo[2].crystal_hold_score = 0
	self.backtopinfo[2].flag_capture_score = 0
	self.backtopinfo[2].league_id = human_num
	self.backtopinfo[2].guild_id_1 = 0
	self:NotifyAllScore(self.backtopinfo)
end
function jingzhuzengli_activity:OnTimer_Second(actId,minute,hminute,hour)
	if not actId or actId >= 0 then
		return
	end
	local newId = -1 * actId
	if define.ACTIVITY_JINZHU_ID ~= newId then
		return
	end
	local scene = self:get_scene()
	local sceneId = scene:get_id()
	local params = scene:get_activity_scene_param(newId)
	if not params then return end
	local human_count = self:LuaFnGetCopyScene_HumanCount()
	local objId,obj
	if not params[self.act_isopen] then
		for i = 1,human_count do
			objId = self:LuaFnGetCopyScene_HumanObjId(i)
			self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
		end
		local act_index
		local actinfo
		local statrtime
		local overtime
		for i,j in ipairs(self.timetab) do
			statrtime = j.starthour * 60 + j.startminue
			overtime = j.endhour * 60 + j.endminue
			if hminute >= statrtime and hminute <= overtime then
				actinfo = j
				act_index = i
				break
			end
		end
		if not actinfo or not act_index then
			self:StopOneActivity(newId)
			return
		end
		params[self.act_name] = actinfo.actname
		self:SetActivityKey(newId,"act_name",actinfo.actname)
		local today = tonumber(os.date("%Y%m%d"))
		local load_date = today % 10000
		load_date = load_date * 10000 + statrtime
		params[self.act_load_date] = load_date
		local long_minute = overtime - hminute
		params[self.act_tick] = long_minute * 60 - 1
		if params[self.act_tick] < 0 then
			params[self.act_tick] = 0
		end
		params[self.act_close_flag] = 0
		params[self.act_close_tick] = self.backtick
		params[self.act_paodian_tick] = self.paodiantime
		params[self.act_create_boss_tick] = self.createbosstime
		params[self.act_index] = self.act_index
		params[self.act_isopen] = overtime
		local havebox = ""
		if self.boxtime > 0 then
			local curtime = os.time()
			self:SetActivityKey(newId,"box_time",actinfo.boxtime + curtime)
			havebox = "#{_NEWMSG_999992"..tostring(self.box_fun_name).."}"
		end
		local msg = string.format("%s%s#BQuà băng tuyết#P mở, hoạt động kéo dài#B%d phút#P.","@*;SrvMsg;SCA:",havebox,long_minute)
		self:AddGlobalCountNews(msg)
		return
	end
	if sceneId ~= self.needsceneId then
		self:StopOneActivity(newId)
		return
	end
	local actname = params[self.act_name]
	local bossname = params[self.act_boss_name]
	if params[self.act_close_flag] > 0 then
		if params[self.act_close_tick] > 1 then
			params[self.act_close_tick] = params[self.act_close_tick] - 1
			local cur_human_num = 0
			for i = 1,human_count do
				objId = self:LuaFnGetCopyScene_HumanObjId(i)
				if objId ~= -1 then
					if self:CheckPlayerOnActivity(objId) then
						cur_human_num = cur_human_num + 1
					end
				end
			end
			self:over_notify_ui(actId,params[self.act_close_tick],cur_human_num)
		else
			self:StopOneActivity(newId)
			for i = 1,human_count do
				objId = self:LuaFnGetCopyScene_HumanObjId(i)
				if objId ~= -1 then
					self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
				end
			end
		end
		return
	end
	local human_ids = {}
	for i = 1,human_count do
		objId = self:LuaFnGetCopyScene_HumanObjId(i)
		if objId ~= -1 then
			if self:CheckPlayerOnActivity(objId) then
				table.insert(human_ids,objId)
			end
		end
	end
	human_count = #human_ids
	-- skynet.logi("human_count = ",#human_ids)
	if hminute >= params[self.act_isopen] then
		self:SetActivityKey(newId,"load_date",params[self.act_load_date])
		self:SetActivityKey(newId,"human_count",human_count)
		params[self.act_close_flag] = 1
		self:over_notify_ui(actId,params[self.act_close_tick],#human_ids)
		self:AddGlobalCountNews("@*;SrvMsg;SCA:#BQuà băng tuyết#P kết thúc.")
		return
	end
	if params[self.act_tick] > 0 then
		params[self.act_tick] = params[self.act_tick] - 1
	end
	self:SetActivityKey(newId,"human_count",human_count)
	local pd_load = false
	local act_paodian_tick = params[self.act_paodian_tick]
	if self.paodianmaxplayer > 0 then
		if human_count <= self.paodianmaxplayer then
			pd_load = true
		end
	else
		pd_load = true
	end
	if pd_load then
		if self.paodiantime > 0 and self.paodianaward > 0 then
			if act_paodian_tick > 1 then
				act_paodian_tick = act_paodian_tick - 1
				params[self.act_paodian_tick] = act_paodian_tick
			else
				act_paodian_tick = self.paodiantime
				params[self.act_paodian_tick] = act_paodian_tick
				local yblog = tostring(actname).."Nguyên bảo treo máy"
				local msg = string.format("Ngươi treo máy nhận %d nguyên bảo.",self.paodianaward)
				for _,id in ipairs(human_ids) do
					obj = scene:get_obj_by_id(id)
					if obj then
						obj:add_yuanbao(self.paodianaward,yblog)
						obj:notify_tips(msg)
					end
				end
			end
		end
	end
	
	local act_create_boss_tick = params[self.act_create_boss_tick]
	if self.createbosstime > 0 then
		if act_create_boss_tick > 1 then
			act_create_boss_tick = act_create_boss_tick - 1
			params[self.act_create_boss_tick] = act_create_boss_tick
		else
			for _,j in ipairs(self.createboss) do
				j.createflag = true
			end
			act_create_boss_tick = self.createbosstime
			params[self.act_create_boss_tick] = act_create_boss_tick
			local monster_count = self:GetMonsterCount()
			local objId,obj,index,posx,posz
			for i = 1,monster_count do
				objId = self:GetMonsterObjID(i)
				if objId ~= -1 then
					obj = scene:get_obj_by_id(objId)
					if obj and obj:is_alive() then
						index = obj:get_scene_params(define.MONSTER_CREATE_INDEX)
						if index > 0 then
							if self.createboss[index]
							and self.createboss[index].posx == obj:get_scene_params(define.MONSTER_CREATE_POSX)
							and self.createboss[index].posz == obj:get_scene_params(define.MONSTER_CREATE_POSZ) then
								self.createboss[index].createflag = false
							end
						end
					end
				end
			end
			local bosss_cript_id = 999991
			local item_name = self:GetItemName(self.killbossaward)
			if item_name == -1 then
				item_name = ""
			end
			local create_count = 0
			for i,j in ipairs(self.createboss) do
				if j.createflag then
					objId = self:LuaFnCreateMonster(j.bossid,j.posx,j.posz,4,0,bosss_cript_id)
					if objId then
						obj = scene:get_obj_by_id(objId)
						if obj then
							create_count = create_count + 1
							obj:set_die_time(params[self.act_tick] * 1000)
							obj:set_scene_params(define.MONSTER_CREATE_POSX,j.posx)
							obj:set_scene_params(define.MONSTER_CREATE_POSZ,j.posz)
							obj:set_scene_params(define.MONSTER_CREATE_INDEX,i)
							if item_name ~= "" then
								obj:set_scene_params(define.MONSTER_KILLBOX_ITEM_COUNT,1)
								index = define.MONSTER_KILLBOX_ITEM_COUNT + 1
								obj:set_scene_params(index,self.killbossaward)
								index = index + 1
								obj:set_scene_params(index,1)
								index = index + 1
								obj:set_scene_params(index,true)
							end
							if j.bosshp > 0 then
								self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,j.bosshp)
								self:RestoreHp(objId)
							end
							self:SetCharacterName(objId,j.bossname)
							self:SetCharacterTitle(objId,item_name..i)
							self:SetUnitReputationID(objId,objId,29)
						end
					end
				end
			end
			if create_count > 0 then
				self:MonsterTalk(-1,"Quà băng tuyết","#PBOSS trời giáng#B["..self.createboss[1].bossname.."]#P, giết xong nhận thưởng giết.")
			end
		end
	end
	self.backtopinfo[1].crystal_hold_score = params[self.act_tick]
	self.backtopinfo[1].flag_capture_score = self.paodianaward
	self.backtopinfo[1].league_id = params[self.act_close_tick]
	self.backtopinfo[1].guild_id_1 = params[self.act_close_flag]
	self.backtopinfo[2].crystal_hold_score = act_create_boss_tick
	self.backtopinfo[2].flag_capture_score = act_paodian_tick
	self.backtopinfo[2].league_id = human_count
	self.backtopinfo[2].guild_id_1 = self.paodianmaxplayer
	self:NotifyAllScore(self.backtopinfo)
end
function jingzhuzengli_activity:OnTimer(actId, uTime, param1)
end
function jingzhuzengli_activity:closebox(selfId,msg)
	if msg then
		self:notify_tips(selfId,msg)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,410142021)
end
function jingzhuzengli_activity:jinzhu_box(selfId,goings)
	local cur_time = os.time()
	local max_time = self:GetActivityKey(define.ACTIVITY_XIYOU_ID,"box_time")
	if cur_time > max_time then
		-- self:closebox(selfId,"传送盒已失效。")
		return
	end
	local sceneId = self.needsceneId
	local mylv = obj:get_attrib("level")
	local myhp = obj:get_attrib("hp_max")
	local mypoint = obj:get_mission_data_by_script_id(388) // 2500
	local posx_min = 130
	local posx_max = 180
	local posz_min = 140
	local posz_max = 191
	if goings then
		local exida,exidb = self:LuaFnActivityBoxCheck(sceneId,selfId,max_time,cur_time)
		if not exida or not exidb then
			return
		end
		self:SetMissionDataEx(selfId,exida,sceneId)
		self:SetMissionDataEx(selfId,exidb,max_time)
		self:closebox(selfId)
		local posx = math.random(posx_min,posx_max)
		local posz = math.random(posz_min,posz_max)
		if mylv >= self.needlevel
		and myhp >= self.needmaxhp
		and mypoint >= self.needpoint then
			if sceneId == self:get_scene():get_id() then
				self:TelePort(selfId, posx, posz)
			else
				self:NewWorld(selfId, sceneId, nil, posx, posz)
			end
		end
	else
		local act_name = self.actname
		local scenename = self:GetSceneName(sceneId)
		local msgtab = {"#B    ",act_name,"#WHoạt động đã mở,"}
		if mylv >= self.needlevel
		and myhp >= self.needmaxhp
		and mypoint >= self.needpoint then
			table.insert(msgtab,"Có tới không\\n#B[")
			table.insert(msgtab,self:GetSceneName(sceneId))
			table.insert(msgtab,",x(")
			table.insert(msgtab,posx_min)
			table.insert(msgtab,"-")
			table.insert(msgtab,posx_max)
			table.insert(msgtab,"),z(")
			table.insert(msgtab,posz_min)
			table.insert(msgtab,"-")
			table.insert(msgtab,posz_max)
			table.insert(msgtab,")]#W.\\n#G(Mẹo: cửa sổ này có giới hạn giờ, để ý đếm ngược góc trái dưới)")
		else
			table.insert(msgtab,"Yêu cầu tham gia hoạt động:\\n")
			if mylv >= self.needlevel then
				table.insert(msgtab,"#GCấp:")
			else
				table.insert(msgtab,"#cff0000Cấp:")
			end
			table.insert(msgtab,mylv)
			table.insert(msgtab," / ")
			table.insert(msgtab,self.needlevel)
			if myhp >= self.needmaxhp then
				table.insert(msgtab,",\\n#GMáu:")
			else
				table.insert(msgtab,",\\n#cff0000Máu:")
			end
			table.insert(msgtab,myhp)
			table.insert(msgtab," / ")
			table.insert(msgtab,self.needmaxhp)
			if mypoint >= self.needpoint then
				table.insert(msgtab,",\\n#GĐiểm:")
			else
				table.insert(msgtab,",\\n#cff0000Điểm:")
			end
			table.insert(msgtab,mypoint)
			table.insert(msgtab," / ")
			table.insert(msgtab,self.needpoint)
			table.insert(msgtab,",\\n#WThực lực hiện tại của ngươi chưa đủ tham gia.")
		end
		local msg = table.concat(msgtab)
		self:BeginUICommand()
		self:UICommand_AddInt(410142022)
		self:UICommand_AddInt(max_time - cur_time)
		self:UICommand_AddInt(self.script_id)
		self:UICommand_AddStr("#ccc33cc"..act_name)
		self:UICommand_AddStr(msg)
		self:UICommand_AddStr(self.box_fun_name)
		self:EndUICommand()
		self:DispatchUICommand(selfId,410142022)
	end
end


return jingzhuzengli_activity
