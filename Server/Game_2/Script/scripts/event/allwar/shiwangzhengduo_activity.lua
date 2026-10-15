local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
-- local packet_def = require "game.packet"
local script_base = require "script_base"
local shiwangzhengduo_activity = class("shiwangzhengduo_activity", script_base)
-- local gbk = require "wire_charset"
shiwangzhengduo_activity.script_id = 999989
shiwangzhengduo_activity.DataValidator = 0

--*********************************
-- 活动添加：（活动图不可定位，不可传送）

-- 尸王争夺：10:00-10:30
-- 尸王争夺：17:00-17:30
-- 地图采用 校场 市集 都可以 传送进入地图随机范围  上面用校场的话 这个就用市集 
-- 90级玩家可进入，增加进入提示，
-- 活动开始 创建一只 幽灵 模型的BoSS  最后一击击杀的玩家 可获得一个道具 神秘宝箱 （任务道具，不可传送，不可回成。限时1小时。） 头顶给一个buff  神鼎的外观 小鼎的
-- 玩家被击杀后 扣除任务道具  在地上创建一个包裹 或者 宝箱  其他玩家可以随意拾取 拾取后同理给一个buff 和 一个任务道具 
-- 玩家在这里掉线 再次创建一个 宝箱 在中心点。

-- 活动结束 前 给场景内 所有玩家结算 元宝 1000  踢出所有玩家  拥有道具的 可在npc 领取 20元充值卡 
--*********************************
--返回位置
shiwangzhengduo_activity.GoBackScene = 0
shiwangzhengduo_activity.GoBackPosx = 91
shiwangzhengduo_activity.GoBackPosz = 182
--开启场景与活动号
shiwangzhengduo_activity.needsceneId = 315
shiwangzhengduo_activity.needsactId = 396
--开启时间
shiwangzhengduo_activity.timetab = 
{
	--{starthour = 10,startminue = 0,endhour = 10,endminue = 30},
	--{starthour = 17,startminue = 0,endhour = 17,endminue = 30},
}
--结束后N秒后清场
shiwangzhengduo_activity.backtick = 10
--需求等级
shiwangzhengduo_activity.needlevel = 90
--结束奖励在场人员 元宝
shiwangzhengduo_activity.overaward = 1000
--拾取宝箱时给予的标记BUFF 
--修改此ID还需要在 scene.lua function scene:OnScenePlayerEnter(selfId) 函数中
--self:LuaFnCancelSpecificImpact(selfId,3019) --清理战旗状态   加入此一句

shiwangzhengduo_activity.addbuff = 3020
--BOSS信息
shiwangzhengduo_activity.bossId = 51712
shiwangzhengduo_activity.bossname = "Thi Vương: U Linh"
shiwangzhengduo_activity.bosstitle = "Lũ kiến hôi, ngươi sẽ thành vong hồn dưới đao ta"
shiwangzhengduo_activity.posx = 31
shiwangzhengduo_activity.posz = 31
--bosshp  = 0 则默认怪物表血量  > 0 时则在创建时修正该血量
shiwangzhengduo_activity.bosshp = 100000000

shiwangzhengduo_activity.box_fun_name = "shiwang_box"
shiwangzhengduo_activity.actname = "Tranh đoạt Thi Vương"
-- boxtime = 弹窗持续时长(单位:秒) 0=不弹窗  > 0 则弹窗有效时长
shiwangzhengduo_activity.boxtime = 0


--非配置信息
shiwangzhengduo_activity.openflag = 1
shiwangzhengduo_activity.scenesectick = 2
shiwangzhengduo_activity.minuetick = 3
shiwangzhengduo_activity.startminue = 4
shiwangzhengduo_activity.longtick = 5
shiwangzhengduo_activity.boxid = 6
shiwangzhengduo_activity.playerid = 7
shiwangzhengduo_activity.notboxtick = 13
shiwangzhengduo_activity.selfboss = 14
shiwangzhengduo_activity.bossmaxhp = 15

shiwangzhengduo_activity.scene_boxtime = 16



shiwangzhengduo_activity.quitwar = 8
shiwangzhengduo_activity.backscene = 9
shiwangzhengduo_activity.backposx = 10
shiwangzhengduo_activity.backposz = 11
shiwangzhengduo_activity.nlevel = 12


shiwangzhengduo_activity.backtopinfo = 
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
shiwangzhengduo_activity.playerflag = 
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


function shiwangzhengduo_activity:OnDefaultEvent(actId, iNoticeType, param2, param3, param4, param5, param6)
	-- if param6 ~= self.DataValidator then
		-- return
	-- elseif not iNoticeType or not param2 or not param3 or not param4 or not param5 then
		-- return
	-- end
	-- if self.scene:get_id() == self.needsceneId and actId == self.needsactId then
		-- self:EmptyActivityData(-1,actId)
		-- self:StartOneActivity(actId,2100000000,iNoticeType)
	-- end
end
function shiwangzhengduo_activity:GetDataValidator(param1,param2)
	self.DataValidator = math.random(1,2100000000)
	return self.DataValidator
end
--*********************************
-- 活动描述
--*********************************
function shiwangzhengduo_activity:GetJingZhuZengLiMsg(selfId)
	local msgtab = 
	{
		"    Tranh đoạt Thi Vương: đạt cấp",
		self.needlevel,
		"cấp trở lên tham gia được\\nDũng sĩ kết liễu Thi Vương sẽ thành Thi Vương mới (khi bị giết rơi tại chỗ một rương Thi Vương).\\n",
		"Rương Thi Vương: ai mở thành công sẽ thành Thi Vương mới.\\n",
		"Thi Vương mới nếu sống tới hết hoạt động thì tới sứ giả Lạc Dương nhận một thẻ nạp\\n",
		"Giải tham gia: ai có mặt lúc kết thúc đều nhận",
		self.overaward,
		"Nguyên bảo."
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
function shiwangzhengduo_activity:BackOldScene(param0)
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
--*********************************
-- 初始化
--*********************************
function shiwangzhengduo_activity:EmptyActivityData(param,actId)
	if not param or param >= 0 then return end
	if param == -1 then
		self.scene:set_param(self.quitwar,0)
		self.scene:set_param(self.openflag,0)
		self.scene:set_param(self.backscene,self.GoBackScene)
		self.scene:set_param(self.backposx,self.GoBackPosx)
		self.scene:set_param(self.backposz,self.GoBackPosz)
		self.scene:set_param(self.nlevel,self.needlevel)
		self.scene:set_param(self.playerid,0)
		self.scene:set_param(self.notboxtick,0)
		self.scene:set_param(self.selfboss,0)
	end
	local sceneId = self.scene:get_id()
	local objId,obj,ai,value
	local mostercount = self:GetMonsterCount()
	for i = 1,mostercount do
		objId = self:GetMonsterObjID(i)
		obj = self.scene:get_obj_by_id(objId)
		if obj and obj:is_alive() then
			-- value = obj:get_model()
			-- if value == self.bossId or value == 99998 then
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
function shiwangzhengduo_activity:OnTimer(actId, uTime, param1)
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
	if isover > 0 then
		if timer.sec ~= self.scene:get_param(self.scenesectick) then
			self.scene:set_param(self.scenesectick,timer.sec)
			isover = isover - 1
			self.scene:set_param(self.quitwar,isover)
			if isover <= 0 then
				self:BackOldScene(-1)
				return
			end
			self:BackOldScene(-2)
			self:MonsterTalk(-1,"Tranh đoạt Thi Vương","#PHoạt động đã kết thúc, sẽ vào#G"..tostring(isover).."giây sau dọn trận#P.")
		end
		return
	end
	-- if isover > 1 then
		-- if timer.sec ~= self.scene:get_param(self.scenesectick) then
			-- self.scene:set_param(self.scenesectick,timer.sec)
			-- isover = isover - 1
			-- self.scene:set_param(self.quitwar,isover)
			-- self:BackOldScene(-2)
			-- self:MonsterTalk(-1,"尸王争夺","#P活动已结束，将在#G"..tostring(isover).."秒后清场#P。")
		-- end
		-- return
	-- elseif isover == 1 then
		-- if timer.sec ~= self.scene:get_param(self.scenesectick) then
			-- self.scene:set_param(self.scenesectick,timer.sec)
			-- self.scene:set_param(self.quitwar,0)	
			-- self:BackOldScene(-1)
		-- end
		-- return
	-- end
	local openflag = self.scene:get_param(self.openflag)
	if openflag <= 0 then
		if timer.min ~= self.scene:get_param(self.minuetick) then
			self.scene:set_param(self.minuetick,timer.min)
			local curminue = timer.hour * 60 + timer.min
			-- local startminue = self.scene:get_param(self.startminue)
			local startminue = 0
			-- if startminue == 0 or startminue < curminue then
				if #self.timetab > 0 then
					local minuemin,minuemax
					for i,j in ipairs(self.timetab) do
						minuemin = j.starthour * 60 + j.startminue
						minuemax = j.endhour * 60 + j.endminue
						if curminue >= minuemin and curminue < minuemax then
							if curminue < minuemin then
								startminue = minuemin
							else
								startminue = curminue
							end
							--开启时间记录上  关联工具查询 
							self.scene:set_param(self.startminue,startminue)
							local longtick = (minuemax - startminue) * 60
							self.scene:set_param(self.longtick,longtick)
							break
						end
					end
				end
			-- end
			if startminue > 0 and startminue == curminue then
				self:BackOldScene(-1)
				self.scene:set_param(self.playerid,0)
				self.scene:set_param(self.notboxtick,0)
				self.scene:set_param(self.selfboss,0)
				local objId,obj,ai,value
				self:EmptyActivityData(-2,actId)
				objId = self:LuaFnCreateMonster(self.bossId,self.posx,self.posz,4,0,999988)
				if objId and objId ~= -1 then
					obj = self.scene:get_obj_by_id(objId)
					if obj then
						self.scene:set_param(self.selfboss,objId + 1)
						ai = obj:get_ai()
						ai:set_int_param_by_index(1,sceneId)
						ai = obj:get_ai()
						ai:set_int_param_by_index(2,actId)
						ai = obj:get_ai()
						ai:set_int_param_by_index(3,self.addbuff)
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
						self:MonsterTalk(-1,"Tranh đoạt Thi Vương","#PBOSS#B["..self.bossname.."]#Pgiá lâm tại#B["..tostring(self.posx)..","..tostring(self.posz).."]#P, có thể tới giết.")
					
						local curtime = os.time()
						self.scene:set_param(self.backscene,self.GoBackScene)
						self.scene:set_param(self.backposx,self.GoBackPosx)
						self.scene:set_param(self.backposz,self.GoBackPosz)
						self.scene:set_param(self.nlevel,self.needlevel)
						local longtick = self.scene:get_param(self.longtick)
						self.scene:set_param(self.openflag,longtick + curtime)
						local havebox = ""
						if self.boxtime > 0 then
							self.scene:set_param(self.scene_boxtime,self.boxtime + curtime)
							havebox = "#{_NEWMSG_999989"..tostring(self.box_fun_name).."}"
						end
						local msg = string.format("%s%s#BTranh đoạt Thi Vương#P mở, người chơi từ#B%d cấp trở lên#Ptham gia được, giới hạn#B%s(giây)#P.","@*;SrvMsg;SCA:",havebox,self.needlevel,longtick)
						self:AddGlobalCountNews(msg)
							
						
					end
				end
			end
			self.BackOldScene(-1)
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
					local addData = {
						actname = "shiwangzhengduo",
						opentime = 0,
						closetime = curtime,
						topid = 0,
						topvalue = 0,
						playerguid = 0,
						playername = "Trống trải chờ mong",
						leaguename = "Thi Vương cuối",
						warini = "Thưởng: chưa nhận",
					}
					local winplayer = self.scene:get_param(self.playerid)
					if winplayer > 0 then
						winplayer = winplayer - 1
						obj = self.scene:get_obj_by_id(winplayer)
						if obj:get_obj_type() == "human" and obj:is_alive() then
							obj:impact_cancel_impact_in_specific_data_index(self.addbuff)
							obj:impact_cancel_impact_in_specific_data_index(self.addbuff + 2)
							addData.playerguid = obj:get_guid()
							addData.playername = obj:get_name()
						end
					end
					local istrue = self:GetActivityWar("shiwangzhengduo",false,false,"findOne")
					if istrue then
						self:DelActivityWar("shiwangzhengduo")
					end
					self:SetActivityWar(addData)
					self.playerflag[1].world_pos = {x = -1,y = -1}
					self.playerflag[1].league_id = -1
					self.playerflag[1].guild_id = -1
					self.playerflag[1].league_name = ""
					self:DispatchPhoenixPlainWarCrystalPos(self.playerflag)
					local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
					for i = 1,nHumanCount do
						objId = self:LuaFnGetCopyScene_HumanObjId(i)
						obj = self.scene:get_obj_by_id(objId)
						if obj and obj:get_attrib("level") >= self.needlevel then
							obj:add_yuanbao(self.overaward, "Nguyên bảo kết thúc tranh đoạt Thi Vương")
							obj:notify_tips("Ngươi nhận được"..tostring(self.overaward).."Nguyên bảo.")
						else
							obj:notify_tips("Ngươi không đủ cấp"..tostring(self.needlevel).."cấp, không tham gia được hoạt động này.")
							self:NewWorld(objId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
						end
					end
					self:AddGlobalCountNews("@*;SrvMsg;SCA:#BTranh đoạt Thi Vương#P kết thúc.")
					self.playerflag[1].world_pos = {x = -1,y = -1}
					self.playerflag[1].league_id = -1
					self.playerflag[1].guild_id = -1
					self.playerflag[1].league_name = ""
					self:DispatchPhoenixPlainWarCrystalPos(self.playerflag)
					self.scene:set_param(self.selfboss,0)
					self.scene:set_param(self.playerid,0)
					self.scene:set_param(self.boxid,0)
					self.scene:set_param(self.notboxtick,0)
					return
				else
					self:BackOldScene(-2)
					local boxname = "Rương Thi Vương"
					local boxposx,boxposz = 0,0
					local bossmaxhp = self.scene:get_param(self.bossmaxhp)
					local bosslive = self.scene:get_param(self.selfboss)
					if bosslive > 0 then
						bosslive = bosslive - 1
						local obj = self.scene:get_obj_by_id(bosslive)
						if obj and obj:is_alive() then
							bosslive = obj:get_attrib("hp")
							local world_pos = obj:get_world_pos()
							boxposx = math.floor(world_pos.x)
							boxposz = math.floor(world_pos.y)
							boxname = obj:get_name()
						else
							bosslive = 0
							self.scene:set_param(self.selfboss,bosslive)
						end
					end
					if bosslive == 0 then
						local notboxtick = self.scene:get_param(self.notboxtick)
						local playerid = self.scene:get_param(self.playerid)
						local boxid = self.scene:get_param(self.boxid)
						if notboxtick > 0 then
							local newbox = -1
							if notboxtick >= 2 then
								self.scene:set_param(self.notboxtick,0)
								local mostercount = self:GetMonsterCount()
								local objId,obj,ai,value
								for i = 1,mostercount do
									objId = self:GetMonsterObjID(i)
									obj = self.scene:get_obj_by_id(objId)
									if obj and obj:is_alive() then
										value = obj:get_model()
										if value == self.bossId or value == 99998 then
											self.scene:delete_temp_monster(obj)
										end
									end
								end
								newbox = self:LuaFnCreateMonster(99998,self.posx,self.posz,3,0,999974)
								if newbox and newbox >= 0 then
									local box = self.scene:get_obj_by_id(newbox)
									if box then
										local ai = box:get_ai()
										ai:set_int_param_by_index(1,sceneId)
										ai:set_int_param_by_index(2,actId)
										ai:set_int_param_by_index(3,self.addbuff)
										box:set_name("Rương Thi Vương")
										box:set_title("Mở xong sẽ thành Thi Vương")
										boxposx,boxposz = self.posx,self.posz
									else
										newbox = -1
									end
								else
									newbox = -1
								end
							else
								notboxtick = notboxtick + 1
								self.scene:set_param(self.notboxtick,notboxtick)
							end
							self.scene:set_param(self.playerid,0)
							if newbox ~= -1 then
								self.scene:set_param(self.boxid,newbox + 1)
							else
								self.scene:set_param(self.boxid,0)
							end
						elseif playerid > 0 then
							playerid = playerid - 1
							local obj = self.scene:get_obj_by_id(playerid)
							if obj and obj:get_obj_type() == "human" and obj:is_alive() then
								local world_pos = obj:get_world_pos()
								boxposx = math.floor(world_pos.x)
								boxposz = math.floor(world_pos.y)
								boxname = "Thi Vương mới:"..obj:get_name()
								bossmaxhp = obj:get_attrib("hp_max")
								bosslive = obj:get_attrib("hp")
							else
								self.scene:set_param(self.playerid,0)
								self.scene:set_param(self.boxid,0)
								self.scene:set_param(self.notboxtick,1)
							end
						elseif boxid > 0 then
							boxid = boxid -1
							local obj = self.scene:get_obj_by_id(boxid)
							if obj and obj:get_obj_type() == "monster" and obj:is_alive() then
								local world_pos = obj:get_world_pos()
								boxposx = math.floor(world_pos.x)
								boxposz = math.floor(world_pos.y)
								boxname = obj:get_name()
								bossmaxhp = obj:get_attrib("hp_max")
								bosslive = obj:get_attrib("hp")
							else
								self.scene:set_param(self.playerid,0)
								self.scene:set_param(self.boxid,0)
								self.scene:set_param(self.notboxtick,1)
							end
						else
							self.scene:set_param(self.playerid,0)
							self.scene:set_param(self.boxid,0)
							self.scene:set_param(self.notboxtick,1)
						end
					end
					self.backtopinfo[1].crystal_hold_score = openflag - curtime
					self.backtopinfo[1].league_id = self.overaward
					self.backtopinfo[1].league_name = boxname
					self.backtopinfo[2].crystal_hold_score = bosslive
					self.backtopinfo[2].flag_capture_score = bossmaxhp
					self.backtopinfo[2].league_id = boxposx
					self.backtopinfo[2].guild_id_1 = boxposz
					
					if boxposx > 0 and boxposz > 0 then
						self.playerflag[1].world_pos = {x = boxposx,y = boxposz}
						self.playerflag[1].league_id = 1
						self.playerflag[1].guild_id = 1
						self.playerflag[1].league_name = boxname
					else
						self.playerflag[1].world_pos = {x = -1,y = -1}
						self.playerflag[1].league_id = -1
						self.playerflag[1].guild_id = -1
						self.playerflag[1].league_name = ""
					end
					self:LuaFnDispatchPhoenixPlainWarScore(self.backtopinfo)
					self:DispatchPhoenixPlainWarCrystalPos(self.playerflag)
					return
				end
			end
			self:BackOldScene(-1)
		end
	end
end
function shiwangzhengduo_activity:closebox(selfId,msg)
	if msg then
		self:notify_tips(selfId,msg)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,410142021)
end
function shiwangzhengduo_activity:shiwang_box(selfId,goings)
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
	local posx_min = 15
	local posx_max = 44
	local posz_min = 17
	local posz_max = 46
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

return shiwangzhengduo_activity
