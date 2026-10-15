local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_yexihuboss_die = class("event_yexihuboss_die", script_base)
-- local gbk = require "wire_charset"
event_yexihuboss_die.script_id = 999997

event_yexihuboss_die.needscene = 66
event_yexihuboss_die.openflag = 2
event_yexihuboss_die.bossid = 28
event_yexihuboss_die.dieboxcount = 33
event_yexihuboss_die.dieboxdeltime = 34
event_yexihuboss_die.playerboxcount = 35
event_yexihuboss_die.playerboxprotecttime = 36

event_yexihuboss_die.box_itemnum = 1
event_yexihuboss_die.box_deltime = 2
event_yexihuboss_die.box_guid = 3
event_yexihuboss_die.box_protecttime = 4
event_yexihuboss_die.box_dataid = 5


function event_yexihuboss_die:OnDie(objId,killerId)
	local obj = self.scene:get_obj_by_id(objId)
	if not obj then
		return
	end
	local bossdataid = obj:get_model()
	local bossname = obj:get_name()
	local world_pos = obj:get_world_pos()
	local bossposx = math.floor(world_pos.x)
	local bossposz = math.floor(world_pos.y)
	self.scene:delete_temp_monster(obj)
	local guid,name
	if objId ~= killerId then
		local human = self.scene:get_obj_by_id(killerId)
		if human then
			if human:get_obj_type() == "human" then
				guid = human:get_guid()
				name = human:get_name()
			elseif human:get_obj_type() == "pet" then
				local playerid = human:get_owner_obj_id()
				human = self.scene:get_obj_by_id(playerid)
				if human then
					guid = human:get_guid()
					name = human:get_name()
				end
			end
		end
	end
	if self.scene:get_id() ~= self:LuaFnGetCopySceneData_Param(0,self.needscene) then
		return
	elseif bossdataid ~= self:LuaFnGetCopySceneData_Param(self.bossid) then
		return
	end
	local scenename = self:GetSceneName()
	local minposx = bossposx - 5
	if minposx < 0 then
		minposx = 0
	end
	local minposz = bossposz - 5
	if minposz < 0 then
		minposz = 0
	end
	local iscreate = false
	local maxposx = bossposx + 5
	local maxposz = bossposz + 5
	local cuttime = os.time()
	local dieboxdeltimex = self:LuaFnGetCopySceneData_Param(self.dieboxdeltime)
	local dieboxdeltime = cuttime + dieboxdeltimex
	local dieboxcount = self:LuaFnGetCopySceneData_Param(self.dieboxcount)
	if dieboxcount > 0 then
		local boxname = "Rương vô chủ"
		local boxtitle = "Hết giờ hoạt động\\nhoặc\\nrơi khi BOSS chết"
		local posx,posz
		for i = 1,dieboxcount do
			posx = math.random(minposx,maxposx)
			posz = math.random(minposz,maxposz)
			local boxId = self:LuaFnCreateMonster(99998,posx,posz,3,0,999996)
			if boxId and boxId >= 0 then
				local box = self.scene:get_obj_by_id(boxId)
				if box then
					local ai = box:get_ai()
					ai:set_int_param_by_index(self.box_guid,0)
					ai:set_int_param_by_index(self.box_protecttime,0)
					ai:set_int_param_by_index(self.box_deltime,dieboxdeltime)
					ai:set_int_param_by_index(self.box_itemnum,0)
					ai:set_int_param_by_index(self.box_dataid,99998)
					box:set_name(boxname)
					box:set_title(boxtitle)
				end
			end
		end
		iscreate = true
		local msg = string.format("#B"..scenename.."#PBOSS#B[%s]#Pgục xuống rơi#G%d#P#Brương vô chủ#P, tồn tại#G%d giây#P, xông lên~ tay nhanh thì có, tay chậm thì không (#GMẹo: mở bản đồ nhỏ xem phạm vi rơi#P).",
		bossname,dieboxcount,dieboxdeltimex)
		self:SceneBroadcastMsgEx(msg)
	end
	local playerboxcount = self:LuaFnGetCopySceneData_Param(self.playerboxcount)
	if playerboxcount > 0 and guid and name then
		local playerboxprotecttime = self:LuaFnGetCopySceneData_Param(self.playerboxprotecttime)
		local boxname = "Rương Báu Đặc Biệt"
		local boxtitle = "Người chơi:"..name.."\\nRơi cho người\\nkết liễu BOSS"
		local boxId = self:LuaFnCreateMonster(99999,bossposx,bossposz,3,0,999996)
		if boxId and boxId >= 0 then
			local box = self.scene:get_obj_by_id(boxId)
			if box then
				local ai = box:get_ai()
				ai:set_int_param_by_index(self.box_guid,guid)
				ai:set_int_param_by_index(self.box_protecttime,cuttime + playerboxprotecttime)
				ai:set_int_param_by_index(self.box_deltime,dieboxdeltime)
				ai:set_int_param_by_index(self.box_itemnum,0)
				ai:set_int_param_by_index(self.box_dataid,99999)
				box:set_name(boxname)
				box:set_title(boxtitle)
			end
		end
		if playerboxcount > 1 then
			local posx,posz
			for i = 1,playerboxcount - 1 do
				posx = math.random(minposx,maxposx)
				posz = math.random(minposz,maxposz)
				local boxId = self:LuaFnCreateMonster(99999,posx,posz,3,0,999996)
				if boxId and boxId >= 0 then
					local box = self.scene:get_obj_by_id(boxId)
					if box then
						local ai = box:get_ai()
						ai:set_int_param_by_index(self.box_guid,guid)
						ai:set_int_param_by_index(self.box_protecttime,cuttime + playerboxprotecttime)
						ai:set_int_param_by_index(self.box_deltime,dieboxdeltime)
						ai:set_int_param_by_index(self.box_itemnum,0)
						ai:set_int_param_by_index(self.box_dataid,99999)
						box:set_name(boxname)
						box:set_title(boxtitle)
					end
				end
			end
		end
		local msg = string.format("#PNgười chơi#B[%s]#Pvới#B"..scenename.."#PBOSS#B[%s]#Pkẻ kết liễu rơi#G%d#P#Brương riêng#P, thời gian bảo hộ riêng#G%d giây#P.",
		name,bossname,playerboxcount,playerboxprotecttime)
		self:SceneBroadcastMsgEx(msg)
		iscreate = true
	end
	if iscreate then
		local boxId = self:LuaFnCreateMonster(52338,minposx,minposz,3,0,999993)
		if boxId and boxId >= 0 then
			local box = self.scene:get_obj_by_id(boxId)
			if box then
				local ai = box:get_ai()
				ai:set_int_param_by_index(1,52338)
				ai:set_int_param_by_index(2,dieboxdeltime)
			end
		end
	end
end
return event_yexihuboss_die