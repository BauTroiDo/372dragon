local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local banghuishouling_activity = class("banghuishouling_activity", script_base)
-- local gbk = require "wire_charset"
banghuishouling_activity.script_id = 999986
banghuishouling_activity.DataValidator = 0
--*********************************
-- 活动添加：（活动图不可定位，不可传送）

-- 帮会首领：19:30-19:45

-- 所有帮会刷新一只 BOSS  外观搞个 安琪儿·辉光 的外观  血量定到1亿  玩家参与击杀的时候 给个伤害面板 
-- 19:45 boss 未 死亡 就消失  在此之前 boss被打死 的 按伤害面板 前十 给与 元宝奖励  前十 分别给 20 18 16 一次类推的壹元充值卡 其他玩家给与 1000元宝
--*********************************
--返回位置
banghuishouling_activity.GoBackScene = 0
banghuishouling_activity.GoBackPosx = 160
banghuishouling_activity.GoBackPosz = 105
--开启场景与活动号
banghuishouling_activity.needsceneId = 313
banghuishouling_activity.needsactId = 397
--开启时间
banghuishouling_activity.timetab = 
{
	--{starthour = 19,startminue = 30,endhour = 19,endminue = 45},
}
--结束后N秒后清场
banghuishouling_activity.backtick = 10
--需求等级
banghuishouling_activity.needlevel = 10
--结束奖励在场人员 元宝
banghuishouling_activity.overaward = 1000
--BOSS信息
banghuishouling_activity.bossId = 24741
banghuishouling_activity.bossname = "Thủ lĩnh bang hội"
banghuishouling_activity.bosstitle = "Tới đây, đua sát thương nào~~"
banghuishouling_activity.posx = 32
banghuishouling_activity.posz = 14
--bosshp  = 0 则默认怪物表血量  > 0 时则在创建时修正该血量
banghuishouling_activity.bosshp = 100000000

banghuishouling_activity.box_fun_name = "banghui_box"
banghuishouling_activity.actname = "Thủ lĩnh bang hội"
-- boxtime = 弹窗持续时长(单位:秒) 0=不弹窗  > 0 则弹窗有效时长
banghuishouling_activity.boxtime = 0


--非配置信息
banghuishouling_activity.openflag = 1
banghuishouling_activity.scenesectick = 2
banghuishouling_activity.minuetick = 3
banghuishouling_activity.startminue = 4
banghuishouling_activity.longtick = 5
banghuishouling_activity.opentime = 6
banghuishouling_activity.selfboss = 14
banghuishouling_activity.bossmaxhp = 15
banghuishouling_activity.upopenminute = 16
banghuishouling_activity.upopenday = 17

banghuishouling_activity.scene_boxtime = 18


banghuishouling_activity.quitwar = 8
banghuishouling_activity.backscene = 9
banghuishouling_activity.backposx = 10
banghuishouling_activity.backposz = 11
banghuishouling_activity.nlevel = 12

--51 - 60 damage
--61 - 70 guid
--71 - 80 name
--81 - 90 guild

banghuishouling_activity.backtopinfo = 
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
banghuishouling_activity.bossflag = 
{ 
	--第一个水晶
	[1] = 
	{
		world_pos = {x = -1, y = -1}, --水晶位置
		league_id = -1, --占领水晶同盟id
		guild_id = -1, --占领水晶帮会id
		league_name = "", --占领水晶同盟名称
		hp = 0, -- 写死传0
	},
	--第二个水晶
	[2] = 
	{
		world_pos = {x = -1, y = -1}, --水晶位置
		league_id = -1, --占领水晶同盟id
		guild_id = -1, --占领水晶帮会id
		league_name = "", --占领水晶同盟名称
		hp = 0, -- 写死传0
	},
	--第三个水晶
	[3] = 
	{
		world_pos = {x = -1, y = -1}, --水晶位置
		league_id = -1, --占领水晶同盟id
		guild_id = -1, --占领水晶帮会id
		league_name = "", --占领水晶同盟名称
		hp = 0, -- 写死传0
	},
	--第四个水晶
	[4] = 
	{
		world_pos = {x = -1, y = -1}, --水晶位置
		league_id = -1, --占领水晶同盟id
		guild_id = -1, --占领水晶帮会id
		league_name = "", --占领水晶同盟名称
		hp = 0, -- 写死传0
	},
}


function banghuishouling_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	-- if param6 ~= self.DataValidator then
		-- return
	-- elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		-- return
	-- end
	-- local sceneId = self.scene:get_id()
	-- if sceneId == self.needsceneId and actId == self.needsactId then
		-- self:EmptyActivityData(-1,actId)
		-- self:StartOneActivity(actId,2100000000,iNoticeType)
	-- end
end
function banghuishouling_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
--*********************************
-- 活动描述
--*********************************
function banghuishouling_activity:GetJingZhuZengLiMsg(selfId)
	local msgtab = 
	{
		"    Thủ lĩnh bang hội: đạt cấp",
		self.needlevel,
		"cấp trở lên tham gia được\\nĐua sát thương, BOSS chết hoặc hết hoạt động, top 10 sát thương nhận thưởng nguyên bảo khác nhau.",
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
function banghuishouling_activity:BackOldScene(param0)
	if param0 ~= -1 and param0 ~= -2 then return end
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	local objId,obj
	for i = 1,nHumanCount do
		objId = self:LuaFnGetCopyScene_HumanObjId(i)
		obj = self.scene:get_obj_by_id(objId)
		if obj and obj:is_alive() then
			if param0 == -2 then
				if obj:get_attrib("level") < self.needlevel then
					obj:notify_tips("Ngươi không đủ cấp"..tostring(self.needlevel).."cấp, không tham gia được hoạt động này.")
					self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
				else
					if obj:get_team_id() ~= define.INVAILD_ID then
						obj:notify_tips("Xin giải tán đội rồi tham gia hoạt động")
						self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
					end
				end
			else
				self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
			end
		end
	end
end

function banghuishouling_activity:EmptyActivityData(param,actId)
	if not param or param >= 0 then return end
	if param == -1 then
		self.scene:set_param(self.quitwar,0)
		self.scene:set_param(self.openflag,0)
		self.scene:set_param(self.backscene,self.GoBackScene)
		self.scene:set_param(self.backposx,self.GoBackPosx)
		self.scene:set_param(self.backposz,self.GoBackPosz)
		for i = 51,90 do
			self.scene:set_param(i,0)
		end
	end
	local sceneId = self.scene:get_id()
	local objId,obj,ai,value
	local mostercount = self:GetMonsterCount()
	for i = 1,mostercount do
		objId = self:GetMonsterObjID(i)
		obj = self.scene:get_obj_by_id(objId)
		if obj and obj:is_alive() then
			-- value = obj:get_model()
			-- if value == 99998
			-- or value == 99999
			-- or value == self.timetab[1].bossId
			-- or value == self.timetab[2].bossId
			-- or value == self.timetab[3].bossId then
			ai = obj:get_ai()
			value = ai:get_int_param_by_index(1)
			if value == sceneId then
				value = ai:get_int_param_by_index(2)
				if value == actId then
					self.scene:delete_temp_monster(obj)
				end
			end
		end
	end
	
end
--*********************************
-- 战场心跳
--*********************************
function banghuishouling_activity:OnTimer(actId, uTime, param1)
	if not uTime or uTime ~= param1 then
		return
	elseif actId ~= self.needsactId then
		return
	end
	local sceneId = self.scene:get_id()
	if sceneId ~= self.needsceneId then
		return
	end
	local timer = os.date("*t")
	local isover = self.scene:get_param(self.quitwar)
	if isover > 1 then
		if timer.sec ~= self.scene:get_param(self.scenesectick) then
			self.scene:set_param(self.scenesectick,timer.sec)
			isover = isover - 1
			self.scene:set_param(self.quitwar,isover)
			self:BackOldScene(-2)
			self:MonsterTalk(-1,"Thủ lĩnh bang hội","#PHoạt động đã kết thúc, sẽ vào#G"..tostring(isover).."giây sau dọn trận#P.")
		end
		return
	elseif isover == 1 then
		if timer.sec ~= self.scene:get_param(self.scenesectick) then
			self.scene:set_param(self.scenesectick,timer.sec)
			self.scene:set_param(self.quitwar,0)	
			self:BackOldScene(-1)
		end
		return
	end
	local openflag = self.scene:get_param(self.openflag)
	if openflag <= 0 then
		if timer.min ~= self.scene:get_param(self.minuetick) then
			self.scene:set_param(self.minuetick,timer.min)
			local curminue = timer.hour * 60 + timer.min
			-- local startminue = self.scene:get_param(self.startminue)
			local startminue = 0
			local upopenminute,upopenday
			-- if startminue == 0 or startminue < curminue then
				local minuemin,minuemax
				if #self.timetab > 0 then
					for i,j in ipairs(self.timetab) do
						minuemin = j.starthour * 60 + j.startminue
						minuemax = j.endhour * 60 + j.endminue
						if curminue >= minuemin and curminue < minuemax then
							if curminue < minuemin then
								startminue = minuemin
							else
								startminue = curminue
							end
							-- self.scene:set_param(self.startminue,startminue)
							local longtick = (minuemax - startminue) * 60
							self.scene:set_param(self.longtick,longtick)
							break
						end
					end
				end
			-- end
			if startminue > 0 and startminue == curminue then
				if minuemin == self.scene:get_param(self.upopenminute)
				and timer.day == self.scene:get_param(self.upopenday) then
					return
				end
				self.scene:set_param(self.upopenminute,minuemin)
				self.scene:set_param(self.upopenday,timer.day)
				local curtime = os.time()
				self.scene:set_param(self.opentime,curtime)
				local objId,obj,ai,value
				self:EmptyActivityData(-2,actId)
				objId = self:LuaFnCreateMonster(self.bossId,self.posx,self.posz,4,0,999988)
				if objId and objId ~= -1 then
					obj = self.scene:get_obj_by_id(objId)
					if obj then
						self.scene:set_param(self.selfboss,objId + 1)
						ai = obj:get_ai()
						ai:set_int_param_by_index(1,sceneId)
						ai:set_int_param_by_index(2,actId)
						if self.bosshp > 0 then
							self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,self.bosshp)
							self:RestoreHp(objId)
							self.scene:set_param(self.bossmaxhp,self.bosshp)
						else
							local maxhp = obj:get_attrib("hp_max")
							self.scene:set_param(self.bossmaxhp,maxhp)
						end
						self:SetCharacterName(objId, self.bossname)
						self:SetCharacterTitle(objId,self.bosstitle)
						self:SetUnitReputationID(objId,objId,29)
						self:MonsterTalk(-1,"Thủ lĩnh bang hội","#PBOSS#B["..self.bossname.."]#Pgiá lâm tại#B["..tostring(self.posx)..","..tostring(self.posz).."]#P, có thể tới giết.")
					end
				end
				for i = 51,90 do
					self.scene:set_param(i,0)
				end
				self.scene:set_param(self.backscene,self.GoBackScene)
				self.scene:set_param(self.backposx,self.GoBackPosx)
				self.scene:set_param(self.backposz,self.GoBackPosz)
				self.scene:set_param(self.nlevel,self.needlevel)
				local longtick = self.scene:get_param(self.longtick)
				self.scene:set_param(self.openflag,longtick + curtime)
				local msg = string.format("%s#BThủ lĩnh bang hội#P mở, người chơi từ#B%d cấp trở lên#Ptham gia được, giới hạn#B%s(giây)#P.","@*;SrvMsg;SCA:",self.needlevel,longtick)
				self:AddGlobalCountNews(msg)
				self.BackOldScene(-1)
			end
		end
	else
		if timer.sec ~= self.scene:get_param(self.scenesectick) then
			self.scene:set_param(self.scenesectick,timer.sec)
			if openflag > 0 then
				local curtime = os.time()
				if curtime > openflag then
					isover = self.backtick > 0 and self.backtick or 10
					self.scene:set_param(self.quitwar,isover)
					self.scene:set_param(self.openflag,0)
					local objId,obj,ai,value
					self:EmptyActivityData(-2,actId)
					local opentime = self.scene:get_param(self.opentime)
					local addData = {
						actname = "banghuishouling",
						opentime = opentime,
						closetime = curtime,
						topid = 0,
						topvalue = 0,
						playerguid = 0,
						playername = "",
						leaguename = "",
						warini = "Thưởng: chưa nhận",
					}
					local damage = {}
					local idx = 0
					for i = 51,60 do
						idx = i - 50
						damage[idx] = {
							self.scene:get_param(i),
							self.scene:get_param(i + 10),
							self.scene:get_param(i + 20),
							self.scene:get_param(i + 30),
						}
					end
					table.sort(damage,function(t1,t2) return t1[1] > t2[1] end)
					local istrue = self:GetActivityWar("banghuishouling",false,false,"findOne")
					if istrue then
						self:DelActivityWar("banghuishouling")
					end
					for i = 1,10 do
						addData.topid = i
						addData.topvalue = damage[i][1]
						addData.playerguid = damage[i][2]
						addData.playername = damage[i][3]
						addData.leaguename = damage[i][4]
						self:SetActivityWar(addData)
					end
					self.bossflag[1].world_pos = {x = -1,y = -1}
					self.bossflag[1].league_id = -1
					self.bossflag[1].guild_id = -1
					self.bossflag[1].league_name = ""
					self:DispatchPhoenixPlainWarCrystalPos(self.bossflag)
					local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
					for i = 1,nHumanCount do
						objId = self:LuaFnGetCopyScene_HumanObjId(i)
						obj = self.scene:get_obj_by_id(objId)
						if obj and obj:get_attrib("level") >= self.needlevel then
							obj:add_yuanbao(self.overaward, "Nguyên bảo kết thúc thủ lĩnh bang hội")
							obj:notify_tips("Ngươi nhận được"..tostring(self.overaward).."Nguyên bảo.")
						else
							obj:notify_tips("Ngươi không đủ cấp"..tostring(self.needlevel).."cấp, không tham gia được hoạt động này.")
							self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
						end
					end
					self:AddGlobalCountNews("@*;SrvMsg;SCA:#BThủ lĩnh bang hội#P kết thúc.")
					self.bossflag[1].world_pos = {x = -1,y = -1}
					self.bossflag[1].league_id = -1
					self.bossflag[1].guild_id = -1
					self.bossflag[1].league_name = ""
					self:DispatchPhoenixPlainWarCrystalPos(self.bossflag)
					
					return
				else
					self:BackOldScene(-2)
					local bossname = "Thủ lĩnh bang hội"
					local bossposx,bossposz = 0,0
					local bosslive = self.scene:get_param(self.selfboss)
					local bossmaxhp = self.scene:get_param(self.bossmaxhp)
					if bosslive > 0 then
						bosslive = bosslive - 1
						local obj = self.scene:get_obj_by_id(bosslive)
						if obj and obj:is_alive() then
							bosslive = obj:get_attrib("hp")
							local world_pos = obj:get_world_pos()
							bossposx = math.floor(world_pos.x)
							bossposz = math.floor(world_pos.y)
							bossname = obj:get_name()
						else
							openflag = curtime
							bosslive = 0
							self.scene:set_param(self.selfboss,bosslive)
						end
					end
					local damage = {}
					local idx = 0
					for i = 51,60 do
						idx = i - 50
						damage[idx] = {
							self.scene:get_param(i),
							self.scene:get_param(i + 10),
							self.scene:get_param(i + 20),
							self.scene:get_param(i + 30),
						}
					end
					local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
					local objId,obj,value,guid,name,guildname
					local istrue,minvalue,minpos
					for i = 1,nHumanCount do
						objId = self:LuaFnGetCopyScene_HumanObjId(i)
						obj = self.scene:get_obj_by_id(objId)
						if obj then
							if obj:get_attrib("level") >= self.needlevel then
								value = obj:get_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEDATA)
								obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_DAMAGE,value)
								guid = obj:get_guid()
								name = obj:get_name()
								guildname = obj:get_guild_name()
								if not guildname or guildname == "" then
									guildname = "Không bang hội"
								end
								if value > 0 then
									istrue = false
									minvalue = 2100000000
									minpos = 0
									for m,n in ipairs(damage) do
										if n[2] == guid then
											n[1] = value
											n[3] = name
											n[4] = guildname
											istrue = true
											break
										elseif n[1] < minvalue then
											minvalue = n[1]
											minpos = m
										end
									end
									if not istrue and minpos > 0 and value > minvalue then
										damage[minpos][1] = value
										damage[minpos][2] = guid
										damage[minpos][3] = name
										damage[minpos][4] = guildname
									end
								end
							end
						end
					end
					for i,j in ipairs(damage) do
						self.scene:set_param(i + 50,j[1])
						self.scene:set_param(i + 60,j[2])
						self.scene:set_param(i + 70,j[3])
						self.scene:set_param(i + 80,j[4])
					end
					for i,j in ipairs(self.backtopinfo) do
						j.league_id = i
						j.flag_capture_score = damage[i][1]
						j.league_name = damage[i][3]
						j.guild_name_1 = damage[i][4]
					end
					self.backtopinfo[3].crystal_hold_score = bossmaxhp
					self.backtopinfo[2].crystal_hold_score = bosslive
					self.backtopinfo[1].crystal_hold_score = openflag - curtime
					self.backtopinfo[1].guild_id_1 = bossposx
					self.backtopinfo[1].guild_id_2 = bossposz
					self.backtopinfo[1].guild_id_3 = self.overaward
					self.backtopinfo[1].guild_name_2 = bossname
					if bosslive == 0 then
						self.scene:set_param(self.openflag,curtime)
					end
					if bossposx > 0 and bossposz > 0 then
						self.bossflag[1].world_pos = {x = bossposx,y = bossposz}
						self.bossflag[1].league_id = 1
						self.bossflag[1].guild_id = 1
						self.bossflag[1].league_name = bossname
					else
						self.bossflag[1].world_pos = {x = -1,y = -1}
						self.bossflag[1].league_id = -1
						self.bossflag[1].guild_id = -1
						self.bossflag[1].league_name = ""
					end
					self:LuaFnDispatchPhoenixPlainWarScore(self.backtopinfo)
					self:DispatchPhoenixPlainWarCrystalPos(self.bossflag)
					return
				end
			end
			self:BackOldScene(-1)
		end
	end
end
function banghuishouling_activity:closebox(selfId,msg)
	if msg then
		self:notify_tips(selfId,msg)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,410142021)
end
function banghuishouling_activity:banghui_box(selfId,goings)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return
	end
	local sceneId = self.needsceneId
	
	
	local curtime = os.time()
	local scenetime = self:LuaFnGetCopySceneData_Param(sceneId,self.scene_boxtime)
	if curtime > scenetime then
		self:closebox(selfId,"Truyền tống đã hết hiệu lực.")
		return
	end
	local posx_min = 17
	local posx_max = 45
	local posz_min = 30
	local posz_max = 49
	local posx = math.random(posx_min,posx_max)
	local posz = math.random(posz_min,posz_max)
	local istrue = true
	if istrue then
		local mylv = obj:get_attrib("level")
		-- local myhp = obj:get_attrib("hp_max")
		-- local mypoint = obj:get_mission_data_by_script_id(388)
		local boxtitle = self.actname
		if goings then
			local exida,exidb = self:LuaFnActivityBoxCheck(sceneId,selfId,scenetime,curtime)
			if not exida or not exidb then
				return
			end
			self:SetMissionDataEx(selfId,exida,sceneId)
			self:SetMissionDataEx(selfId,exidb,scenetime)
			self:closebox(selfId)
			if mylv >= self.needlevel then
			-- and myhp >= self.needmaxhp
			-- and mypoint >= self.needpoint then
				if sceneId == self.scene:get_id() then
					self:TelePort(selfId, posx, posz)
				else
					self:NewWorld(selfId, sceneId, nil, posx, posz)
				end
			end
		else
			local scenename = self:GetSceneName(sceneId)
			local msgtab = {"#B    ",boxtitle,"#WHoạt động đã mở,"}
			if mylv >= self.needlevel then
			-- and myhp >= self.needmaxhp
			-- and mypoint >= self.needpoint then
				table.insert(msgtab,"Có tới không\\n#B[")
				table.insert(msgtab,self:GetSceneName(sceneId))
				table.insert(msgtab,",")
				table.insert(msgtab,posx)
				table.insert(msgtab,",")
				table.insert(msgtab,posz)
				table.insert(msgtab,"]#W.\\n#G(Mẹo: cửa sổ này có giới hạn giờ, để ý đếm ngược góc trái dưới)")
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
				-- if myhp >= self.needmaxhp then
					-- table.insert(msgtab,"、\n#G血量:")
				-- else
					-- table.insert(msgtab,"、\n#cff0000血量:")
				-- end
				-- table.insert(msgtab,myhp)
				-- table.insert(msgtab," / ")
				-- table.insert(msgtab,self.needmaxhp)
				-- if mypoint >= self.needpoint then
					-- table.insert(msgtab,"、\n#G点数:")
				-- else
					-- table.insert(msgtab,"、\n#cff0000点数:")
				-- end
				-- table.insert(msgtab,mypoint)
				-- table.insert(msgtab," / ")
				-- table.insert(msgtab,self.needpoint)
				table.insert(msgtab,",\\n#WThực lực hiện tại của ngươi chưa đủ tham gia.")
			end
			local msg = table.concat(msgtab)
			self:BeginUICommand()
			self:UICommand_AddInt(410142022)
			self:UICommand_AddInt(scenetime - curtime)
			self:UICommand_AddInt(self.script_id)
			self:UICommand_AddStr("#ccc33cc"..boxtitle)
			self:UICommand_AddStr(msg)
			self:UICommand_AddStr(self.box_fun_name)
			self:EndUICommand()
			self:DispatchUICommand(selfId,410142022)
		end
	else
		self:closebox(selfId)
	end
end

return banghuishouling_activity
