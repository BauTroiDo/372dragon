local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local shiwangzhengduo_player = class("shiwangzhengduo_player", script_base)

shiwangzhengduo_player.script_id = 999987

--开启场景与活动号
shiwangzhengduo_player.needsceneId = 315
shiwangzhengduo_player.needsactId = 395

shiwangzhengduo_player.openflag = 1
shiwangzhengduo_player.backscene = 9
shiwangzhengduo_player.backposx = 10
shiwangzhengduo_player.backposz = 11
shiwangzhengduo_player.nlevel = 12

function shiwangzhengduo_player:OnWarScene(selfId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return
	elseif self.scene:get_id() ~= self.needsceneId then
		return
	end
	local getout = ""
	local warstart = self.scene:get_param(self.openflag)
	if warstart > 0 then
		local needlevel = self.scene:get_param(self.nlevel)
		local mylv = obj:get_attrib("level")
		if mylv >= needlevel then
			self:BeginUICommand()
			self:UICommand_AddInt(329042021)
			self:UICommand_AddInt(1)
			self:UICommand_AddInt(2)
			self:UICommand_AddInt(999989)
			self:UICommand_AddInt(999989)
			self:UICommand_AddStr("GetJingZhuZengLiMsg")
			self:UICommand_AddStr("GetJingZhuZengLiMsg")
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

function shiwangzhengduo_player:OnSceneHumanDie(selfId,killerId)
end

return shiwangzhengduo_player
