local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local all_boss_die = class("all_boss_die", script_base)
-- local gbk = require "wire_charset"
--非配置信息
all_boss_die.script_id = 999971
all_boss_die.sceneflag = define.SCENE_BOXTIME

all_boss_die.actinfo = 
{
	--玄武岛终极BOSS
	[1303] = {
		--活动弹窗函数名	gotoposx = 90,gotoposz = 180, 弹窗飞机传送位置	
		box_fun_name = "xuanwudao_box",actname = "BOSS tối thượng",gotoposx = 189,gotoposz = 190,
		--BOSS 相关  bosshp 是否修正BOSS血量  > 0 则修正血量 否则以怪物表血量为准
		bossname = "",bosstitle = "BOSS tối thượng",
		bossId = 51660,bosshp = 2000000000,posx = 189,posz = 190,live_time = 7200 * 1000,
		--击杀盒保护时间:秒
		kill_box_protect_time = 120,
		--击杀盒消失时间:毫秒
		kill_box_del_time = 120 * 1000,
		kill_box =
		{
			--概率1 产出
			{
				--机率 100%
				itemrate = 100,
				--给予随机一种道具
				item = 
				{
				},
			},
		},
		--掉落盒消失时间:毫秒
		drop_box_del_time = 120 * 1000,
		--掉落盒数量
		drop_box_count = 50,
		--掉落盒道具信息  按概率出一种道具
		drop_box = {
		},
	},

	--秦皇地宫四层 BOSS
	[1299] = {
		--活动弹窗函数名	gotoposx = 31,gotoposz = 33, 弹窗飞机传送位置	
		box_fun_name = "digongfour_box",actname = "BOSS Địa Tứ",gotoposx = 31,gotoposz = 33,
		--BOSS 相关  bosshp 是否修正BOSS血量  > 0 则修正血量 否则以怪物表血量为准
		bossname = "BOSS Địa Tứ",bosstitle = "Chúa Tể Địa Tứ",
		bossId = 49264,bosshp = 2000000000,posx = 135,posz = 105,live_time = 7200 * 1000,
		--击杀盒保护时间:秒
		kill_box_protect_time = 120,
		--击杀盒消失时间:毫秒
		kill_box_del_time = 120 * 1000,
		kill_box =
		{
			{
				--机率 100%
				itemrate = 100,
				--给予随机一种道具
				item = 
				{
				
				},
			},
		},
		
		--掉落盒消失时间:毫秒
		drop_box_del_time = 120 * 1000,
		--掉落盒数量
		drop_box_count = 50,
		--掉落盒道具信息  按概率出一种道具
		drop_box = {
		},
	},
	
	
}

function all_boss_die:closebox(selfId,msg)
	if msg then
		self:notify_tips(selfId,msg)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,410142021)
end
function all_boss_die:digongfour_box(selfId,goings)
	local sceneId = -1303
	self:call_box(sceneId,selfId,goings)
end
function all_boss_die:xuanwudao_box(selfId,goings)
	local sceneId = -39
	self:call_box(sceneId,selfId,goings)
end
function all_boss_die:call_box(subsceneid,selfId,goings)
	if 0 == 0 then return end
	if not subsceneid or subsceneid >= 0 then return end
	local sceneId = math.abs(subsceneid)
	local curtime = os.time()
	local scenetime = self:LuaFnGetCopySceneData_Param(sceneId,self.sceneflag)
	if curtime > scenetime then
		self:closebox(selfId,"Truyền tống đã hết hiệu lực.")
		return
	end
	local istrue
	for i,j in ipairs(self.actinfo) do
		if j.sceneId == sceneId then
			istrue = j
			break
		end
	end
	if istrue then
		local boxtitle = istrue.actname
		if goings then
			local exida,exidb = self:LuaFnActivityBoxCheck(sceneId,selfId,scenetime,curtime)
			if not exida or not exidb then
				return
			end
			self:SetMissionDataEx(selfId,exida,sceneId)
			self:SetMissionDataEx(selfId,exidb,scenetime)
			self:closebox(selfId)
			if sceneId == self.scene:get_id() then
				self:TelePort(selfId, istrue.gotoposx, istrue.gotoposz)
			else
				self:NewWorld(selfId, sceneId, nil, istrue.gotoposx, istrue.gotoposz)
			end
		else
			local scenename = self:GetSceneName(sceneId)
			local msgtab = {"#B    ",boxtitle,"#WHoạt động đã mở, có tới không\\n#B["}
			table.insert(msgtab,self:GetSceneName(sceneId))
			table.insert(msgtab,",")
			table.insert(msgtab,istrue.gotoposx)
			table.insert(msgtab,",")
			table.insert(msgtab,istrue.gotoposz)
			table.insert(msgtab,"]#W.\\n#G(Mẹo: cửa sổ này có giới hạn giờ, để ý đếm ngược góc trái dưới)")
			local msg = table.concat(msgtab)
			self:BeginUICommand()
			self:UICommand_AddInt(410142022)
			self:UICommand_AddInt(scenetime - curtime)
			self:UICommand_AddInt(self.script_id)
			self:UICommand_AddStr("#ccc33cc"..boxtitle)
			self:UICommand_AddStr(msg)
			self:UICommand_AddStr(istrue.box_fun_name)
			self:EndUICommand()
			self:DispatchUICommand(selfId,410142022)
		end
	else
		self:closebox(selfId)
	end
end
function all_boss_die:activity_start(subsceneId,boxtime)
	if not subsceneId or subsceneId >= 0 then
		return
	end
	local scene = self:get_scene()
	local sceneId = -1 * subsceneId
	if sceneId ~= scene:get_id() then
		return
	end
	local istrue = self.actinfo[sceneId]
	if not istrue then
		return
	end
	local objId,obj,ai,value
	local monster_count = self:GetMonsterCount()
	for i = 1,monster_count do
		objId = self:GetMonsterObjID(i)
		value = self:GetMonsterDataID(objId)
		if value == istrue.bossId and self:LuaFnIsCharacterLiving(objId) then
			return
		end
	end
	objId = self:LuaFnCreateMonster(istrue.bossId,istrue.posx,istrue.posz,17,136,self.script_id)
	if objId and objId ~= -1 then
		obj = scene:get_obj_by_id(objId)
		if obj then
			obj:set_die_time(istrue.live_time)
			if istrue.bosshp > 0 then
				self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,istrue.bosshp)
				self:RestoreHp(objId)
			end
			local bossname = istrue.bossname
			if istrue.bossname ~= "" then
				self:SetCharacterName(objId,istrue.bossname)
			else
				bossname = obj:get_name()
			end
			if istrue.bosstitle ~= "" then
				self:SetCharacterTitle(objId,istrue.bosstitle)
			end
			self:SetUnitReputationID(objId,objId,29)
			local msg = string.format("#B[%s]#Phiện thân tại#B[%s,%d,%d]#P, có dũng sĩ nào tới giết không! Tương truyền#Gngười giết#Pnhận được#Gtrân bảo hiếm đời#P.",
			bossname,self:GetSceneName(),istrue.posx,istrue.posz)
			if boxtime and boxtime > 0 then
				local curtime = os.time() + boxtime
				scene:set_param(self.sceneflag,curtime)
				msg = "@*;SrvMsg;SCA:#{_NEWMSG_999971"..tostring(istrue.box_fun_name).."}"..msg
			end
			self:AddGlobalCountNews(msg)
		end
	end
end
function all_boss_die:activity_over(subsceneId)
	if not subsceneId or subsceneId >= 0 then
		return
	end
	local sceneId = math.abs(subsceneId)
	if sceneId ~= self:get_scene():get_id() then
		return
	end
end
function all_boss_die:OnDie(objId,killerId)
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(objId)
	if not obj then
		return
	end
	local bossname = obj:get_name()
	local world_pos = obj:get_world_pos()
	local sceneId = scene:get_id()
	local have = self.actinfo[sceneId]
	if have then
		local bossposx = math.floor(world_pos.x)
		local bossposz = math.floor(world_pos.y)
		local scenename = scene:get_name()
		local minposx = bossposx - 5
		if minposx < 0 then
			minposx = 0
		end
		local minposz = bossposz - 5
		if minposz < 0 then
			minposz = 0
		end
		local maxposx = bossposx + 5
		local maxposz = bossposz + 5
		local boxId,box,boxname,boxtitle
		local iscreate = 0
		local iscreate_2 = 0
		if have.kill_box and #have.kill_box > 0 then
			local guid,name = 0,""
			local human = scene:get_obj_by_id(killerId)
			if human and human:get_obj_type() == "human" then
				guid = human:get_guid()
				name = human:get_name()
			end
			local rate = {}
			local all_rate = 0
			for i,j in ipairs(have.kill_box) do
				all_rate = all_rate + j.itemrate
				table.insert(rate,all_rate)
			end
			local kill_box
			local random_value = math.random(1,all_rate)
			for i,j in ipairs(rate) do
				if random_value <= j then
					kill_box = have.kill_box[i].item
					break
				end
			end
			if kill_box then
				local idx = math.random(1,#kill_box)
				local item = kill_box[idx]
				if item then
					boxId = self:LuaFnCreateMonster(52346,bossposx,bossposz,3,0,-1)
					box = scene:get_obj_by_id(boxId)
					if box then
						boxname = bossname.."宝箱"
						boxtitle = name.."Riêng người giết"
						local kill_box_del_time = have.kill_box_del_time or 120000
						box:set_die_time(kill_box_del_time)
						box:set_name(boxname)
						box:set_title(boxtitle)
						box:set_scene_params(define.MONSTER_KILLBOX_GUID,guid)
						local kill_box_protect_time = have.kill_box_protect_time or 60
						box:set_scene_params(define.MONSTER_KILLBOX_PROTECT_TIME,kill_box_protect_time + os.time())
						local item_num = 0
						local index = define.MONSTER_DROPBOX_ITEM_COUNT + 1
						box:set_scene_params(index,item.id)
						index = index + 1
						box:set_scene_params(index,item.num)
						index = index + 1
						box:set_scene_params(index,item.isbind)
						index = index + 1
						item_num = item_num + 1
						box:set_scene_params(define.MONSTER_DROPBOX_ITEM_COUNT,item_num)
						iscreate = kill_box_del_time
					end
				end
			end
		end
		if have.drop_box_count and have.drop_box_count > 0
		and have.drop_box and #have.drop_box > 0 then
			boxname = bossname.."宝箱"
			local posx,posz
			local item_num
			local index
			local rate = {}
			local all_rate = 0
			local random_value,item
			for i,j in ipairs(have.drop_box) do
				all_rate = all_rate + j.rate
				table.insert(rate,all_rate)
			end
			local drop_box_del_time = have.drop_box_del_time or 120000
			for i = 1,have.drop_box_count do
				item = nil
				random_value = math.random(1,all_rate)
				for j,value in ipairs(rate) do
					if random_value <= value then
						item = have.drop_box[j]
						break
					end
				end
				if item then
					posx = math.random(minposx,maxposx)
					posz = math.random(minposz,maxposz)
					boxId = self:LuaFnCreateMonster(49471,posx,posz,3,0,-1)
					if boxId then
						box = scene:get_obj_by_id(boxId)
						if box then
							box:set_die_time(drop_box_del_time)
							box:set_name(boxname)
							item_num = 0
							index = define.MONSTER_DROPBOX_ITEM_COUNT + 1
							box:set_scene_params(index,item.id)
							index = index + 1
							box:set_scene_params(index,item.num)
							index = index + 1
							box:set_scene_params(index,item.isbind)
							index = index + 1
							item_num = item_num + 1
							box:set_scene_params(define.MONSTER_DROPBOX_ITEM_COUNT,item_num)
							iscreate_2 = drop_box_del_time
						end
					end
				end
			end
			
		
		end
		local max_create = math.max(iscreate,iscreate_2)
		if max_create > 0 then
			boxId = self:LuaFnCreateMonster(52338,bossposx,bossposz,3,0,-1)
			if boxId  then
				box = scene:get_obj_by_id(boxId)
				if box then
					box:set_die_time(max_create)
				end
			end
			local msg = string.format("%s bị giết tại %s[%d,%d], có thể tới xem nhặt sót được không!",bossname,scenename,bossposx,bossposz)
			self:AddGlobalCountNews(msg)
		end
	end
end
return all_boss_die