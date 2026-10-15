local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local shiwangzhengduo_die = class("shiwangzhengduo_die", script_base)
-- local gbk = require "wire_charset"
shiwangzhengduo_die.script_id = 999988
--开启场景与活动号
shiwangzhengduo_die.needsceneId = 315
shiwangzhengduo_die.needsactId = 396

shiwangzhengduo_die.openflag = 1
shiwangzhengduo_die.boxid = 6
shiwangzhengduo_die.playerid = 7

function shiwangzhengduo_die:OnDie(objId,killerId)
	local obj = self.scene:get_obj_by_id(objId)
	if not obj then
		return
	end
	local ai = obj:get_ai()
	local mosterscene = ai:get_int_param_by_index(1)
	local mosteractid = ai:get_int_param_by_index(2)
	local mosteraward = ai:get_int_param_by_index(3)
	-- local bossdataid = obj:get_model()
	local bossname = obj:get_name()
	-- local world_pos = obj:get_world_pos()
	-- local bossposx = math.floor(world_pos.x)
	-- local bossposz = math.floor(world_pos.y)
	self.scene:delete_temp_monster(obj)
	if self.needsceneId == mosterscene
	and self.needsactId == mosteractid
	and self.scene:get_param(self.openflag) > 0
	and mosteraward > 0 then
		local playerid
		local guid,name,human,nsex
		if objId ~= killerId then
			human = self.scene:get_obj_by_id(killerId)
			if human then
				if human:get_obj_type() == "human" then
					playerid = killerId
					-- guid = human:get_guid()
					name = human:get_name()
				elseif human:get_obj_type() == "pet" then
					playerid = human:get_owner_obj_id()
					human = self.scene:get_obj_by_id(playerid)
					if human then
						-- guid = human:get_guid()
						name = human:get_name()
					else
						playerid = nil
					end
				else
					human = nil
				end
			end
		end
		if human and playerid then
			self.scene:set_param(self.playerid,playerid + 1)
			self.scene:set_param(self.boxid,0)
			local psex = self:GetSex(playerid)
			if psex == 0 then
				mosteraward = mosteraward + 1
			end
			self:LuaFnSendSpecificImpactToUnit(playerid, playerid, playerid, mosteraward, 100);
			self:LuaFnSendSpecificImpactToUnit(playerid, playerid, playerid, mosteraward + 2, 100);
			local scenename = self:GetSceneName()
			local msg = string.format("#PNgười chơi#B[%s]#Pgiết BOSS của#B%s#P#Btừ giờ bị#Gđánh dấu, bị giết dấu#Gbiến mất#P, rơi tại chỗ#Bhộp#P, người mở lại được#Gđánh dấu#P, ai giữ dấu tới#Gkết thúc#Phoạt động nhận thưởng#Gthẻ nạp#Pở sứ giả Lạc Dương.",name,scenename,bossname)
			self:MonsterTalk(-1,"Tranh đoạt Thi Vương",msg)
		end
	end
end
return shiwangzhengduo_die