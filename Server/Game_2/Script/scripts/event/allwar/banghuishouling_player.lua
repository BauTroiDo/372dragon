local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local banghuishouling_player = class("banghuishouling_player", script_base)

banghuishouling_player.script_id = 999984
--开启场景与活动号
banghuishouling_player.needsceneId = 313
banghuishouling_player.needsactId = 397

banghuishouling_player.openflag = 1
banghuishouling_player.opentime = 6
banghuishouling_player.backscene = 9
banghuishouling_player.backposx = 10
banghuishouling_player.backposz = 11
banghuishouling_player.nlevel = 12
banghuishouling_player.selfboss = 14

function banghuishouling_player:OnWarScene(selfId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return
	end
	local sceneId = self.scene:get_id()
	if sceneId ~= self.needsceneId then
		return
	end
	local getout = ""
	local warstart = self.scene:get_param(self.openflag)
	if warstart > 0 then
		local needlevel = self.scene:get_param(self.nlevel)
		local mylv = obj:get_attrib("level")
		if mylv >= needlevel then
			local opentime = self.scene:get_param(self.opentime)
			local playertime = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_ONTIME)
			local damage = 0
			if opentime ~= playertime then
				obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_DAMAGE,damage)
				obj:set_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_ONTIME,opentime)
			else
				damage = obj:get_mission_data_ex_by_script_id(ScriptGlobal.MDEX_BANGHUIBOSS_DAMAGE)
			end
			local bossid = self.scene:get_param(self.selfboss)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEDATA,damage)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGENEEDSCENE,sceneId + 1)
			obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEOBJID,bossid)
			self:BeginUICommand()
			self:UICommand_AddInt(329042021)
			self:UICommand_AddInt(1)
			self:UICommand_AddInt(3)
			self:UICommand_AddInt(999986)
			self:UICommand_AddInt(999980)
			self:UICommand_AddStr("GetJingZhuZengLiMsg")
			self:UICommand_AddStr("BangHuiShouLing_Damage")
			self:EndUICommand()
			self:DispatchUICommand(selfId,329042021)
			return
		else
			getout = "Cấp yêu cầu hoạt động này"..tostring(needlevel).."cấp, ngươi không đủ cấp."
		end
	else
		getout = "Hoạt động chưa mở hoặc đã kết thúc."
	end
	obj:notify_tips(getout)
end

function banghuishouling_player:OnSceneHumanDie(selfId,killerId)
end

return banghuishouling_player
