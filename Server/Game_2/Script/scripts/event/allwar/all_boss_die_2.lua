local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local all_boss_die_2 = class("all_boss_die_2", script_base)
-- local gbk = require "wire_charset"
--非配置信息
all_boss_die_2.script_id = 999965
all_boss_die_2.sceneflag = define.SCENE_BOXTIME
--多点刷新BOSS
-- 4：每周二，四，六，周日 开启跨服地四（21-2点）
-- 跨服地宫四层：一个小时刷新BOSS  5个点   
-- 分别是    98,44    214,73     52,198     188,190     134,104  
-- 5个点同时刷新   点数卡20点数卡50%      
-- 50点数10%   100点数卡3%     重楼之泪0.5%（不绑定）     重楼之忙0.5% （不绑定）            
all_boss_die_2.actinfo = 
{
	--秦皇地宫四层 BOSS
	[1299] = {
		--活动弹窗函数名	gotoposx = 31,gotoposz = 33, 弹窗飞机传送位置	
		box_fun_name = "digongfour_box",actname = "BOSS Địa Tứ",gotoposx = 31,gotoposz = 33,
		--BOSS 相关  bosshp 是否修正BOSS血量  > 0 则修正血量 否则以怪物表血量为准
		bossname = "",bosstitle = "",
		bossId = 49262,bosshp = 50000000,posx = {98,214,52,188,134},posz = {44,73,198,190,104},live_time = 3540 * 1000,
		-- --击杀盒保护时间:秒
		-- kill_box_protect_time = 60,
		-- --击杀盒消失时间:毫秒
		-- kill_box_del_time = 120 * 1000,
		-- kill_box =
		-- {
			-- {
				-- --机率 86%
				-- itemrate = 860,
				-- --给予随机一种道具
				-- item = 
				-- {
					-- {id = 38008168,num = 1,isbind = true},
				-- },
			-- },
			-- {
				-- --机率 10%
				-- itemrate = 100,
				-- --给予随机一种道具
				-- item = 
				-- {
					-- {id = 38008170,num = 1,isbind = true},
				
				-- },
			-- },
			-- {
				-- --机率 3%
				-- itemrate = 30,
				-- --给予随机一种道具
				-- item = 
				-- {
					-- {id = 38008172,num = 1,isbind = true},
				-- },
			-- },
			-- {
				-- --机率 0.5%
				-- itemrate = 5,
				-- --给予随机一种道具
				-- item = 
				-- {
					-- {id = 20310101,num = 1,isbind = false},
				-- },
			-- },
			-- {
				-- --机率 0.5%
				-- itemrate = 5,
				-- --给予随机一种道具
				-- item = 
				-- {
					-- {id = 20310102,num = 1,isbind = false},
				-- },
			-- },
		-- },
	
	
	
	},
	--秦皇地宫四层 BOSS
	-- [5] = {
		-- --活动弹窗函数名	gotoposx = 31,gotoposz = 33, 弹窗飞机传送位置	
		-- --box_fun_name = "digongfour_box",actname = "地四BOSS",gotoposx = 31,gotoposz = 33,
		-- --BOSS 相关  bosshp 是否修正BOSS血量  > 0 则修正血量 否则以怪物表血量为准
		-- bossname = "",bosstitle = "",
		-- bossId = 3517,bosshp = 0,posx = {136,137,138,139,140,141,142,143,144,145,146,135,134,133,132,131,130,129,128,127,126,147,148,149,150,125,124,123,122,121},posz = {113,114,115,116,117,118,119,120,121,122,123,112,111,110,109,108,107,106,105,104,103,124,125,126,127,102,101,100,99,98},live_time = 3540 * 1000,
	
	-- },

}

all_boss_die_2.special_boss = {
	[420] = 11392,


}

function all_boss_die_2:closebox(selfId,msg)
	if msg then
		self:notify_tips(selfId,msg)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,410142021)
end
function all_boss_die_2:digongfour_box(selfId,goings)
	local sceneId = -1303
	self:call_box(sceneId,selfId,goings)
end
function all_boss_die_2:xuanwudao_box(selfId,goings)
	local sceneId = -39
	self:call_box(sceneId,selfId,goings)
end
function all_boss_die_2:call_box(subsceneid,selfId,goings)
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
function all_boss_die_2:activity_start(subsceneId,boxtime)
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
	local have_boss = {}
	local monster_count = self:GetMonsterCount()
	for i = 1,monster_count do
		objId = self:GetMonsterObjID(i)
		obj = scene:get_obj_by_id(objId)
		if obj then
			value = self:GetMonsterDataID(objId)
			if value == istrue.bossId and self:LuaFnIsCharacterLiving(objId) then
				for j,boss_index in ipairs(istrue.posx) do
					if boss_index == obj:get_scene_params(define.MONSTER_CREATE_POSX)
					and istrue.posz[j] == obj:get_scene_params(define.MONSTER_CREATE_POSZ) then
						have_boss[j] = true
						break
					end
				end
			end
		end
	end
	local create_num = 0
	local bossname = ""
	for i,boss_index in ipairs(istrue.posx) do
		if not have_boss[i] and istrue.posz[i] then
			objId = self:LuaFnCreateMonster(istrue.bossId,boss_index,istrue.posz[i],17,136,self.script_id)
			if objId and objId ~= -1 then
				obj = scene:get_obj_by_id(objId)
				if obj then
					obj:set_scene_params(define.MONSTER_CREATE_POSX,boss_index)
					obj:set_scene_params(define.MONSTER_CREATE_POSZ,istrue.posz[i])
					obj:set_die_time(istrue.live_time)
					if istrue.bosshp > 0 then
						self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,istrue.bosshp)
						self:RestoreHp(objId)
					end
					bossname = istrue.bossname
					if bossname ~= "" then
						self:SetCharacterName(objId,bossname)
					else
						bossname = obj:get_name()
					end
					if istrue.bosstitle ~= "" then
						self:SetCharacterTitle(objId,istrue.bosstitle)
					end
					self:SetUnitReputationID(objId,objId,29)
					create_num = create_num + 1
				end
			end
		end
	end
	if create_num > 0 then
		local msg = string.format("#G%d#Pcon#B[%s]#Phiện thân tại#B[%s]#P, có dũng sĩ nào tới giết không! Tương truyền#Gngười giết#Pnhận được#Gtrân bảo hiếm đời#P.",
		create_num,bossname,self:GetSceneName())
		if boxtime and boxtime > 0 then
			local curtime = os.time() + boxtime
			scene:set_param(self.sceneflag,curtime)
			msg = "@*;SrvMsg;SCA:#{_NEWMSG_999965"..tostring(istrue.box_fun_name).."}"..msg
		end
		self:AddGlobalCountNews(msg)
	end
	
end
function all_boss_die_2:activity_over(subsceneId)
	if not subsceneId or subsceneId >= 0 then
		return
	end
	local sceneId = math.abs(subsceneId)
	if sceneId ~= self:get_scene():get_id() then
		return
	end
end
function all_boss_die_2:OnDie(objId,killerId)
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(objId)
	if not obj then
		return
	end
	local sceneId = scene:get_id()
	local model = self.special_boss[sceneId]
	if model then
		if obj:get_scene_params(define.MONSTER_DATAID) == model then
			local respawn_time = obj:get_scene_params(define.MONSTER_KILLBOX_PROTECT_TIME)
			if respawn_time > 0 then
				local create_index = obj:get_scene_params(define.MONSTER_CREATE_INDEX)
				local curtime = os.time() + respawn_time
				scene:set_param(create_index,curtime)
			end
		end
		return
	end
	local bossname = obj:get_name()
	local world_pos = obj:get_world_pos()
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
return all_boss_die_2