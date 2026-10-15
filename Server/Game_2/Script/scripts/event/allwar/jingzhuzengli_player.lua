local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local jingzhuzengli_player = class("jingzhuzengli_player", script_base)

jingzhuzengli_player.script_id = 999990

--开启场景与活动号
jingzhuzengli_player.needsceneId = 490
jingzhuzengli_player.act_isopen = 1
jingzhuzengli_player.GoBackScene = 0
jingzhuzengli_player.GoBackPosx = 160
jingzhuzengli_player.GoBackPosz = 105


function jingzhuzengli_player:OnWarScene(selfId)
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(selfId)
	if not obj then
		return
	end
	local sceneId = scene:get_id()
	if sceneId == self.needsceneId then
		local getout = ""
		local act_isopen = self:GetActivityParamEx(define.ACTIVITY_JINZHU_ID,self.act_isopen)
		if act_isopen > 0 then
			self:BeginUICommand()
			self:UICommand_AddInt(329042021)
			self:UICommand_AddInt(0)
			self:UICommand_AddInt(1)
			self:UICommand_AddInt(999992)
			self:UICommand_AddInt(999992)
			self:UICommand_AddStr("GetJingZhuZengLiMsg")
			self:UICommand_AddStr("GetJingZhuZengLiMsg")
			self:EndUICommand()
			self:DispatchUICommand(selfId,329042021)
			return
		else
			obj:notify_tips("Hoạt động chưa mở.")
		end
	end
	self:NewWorld(selfId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
end

function jingzhuzengli_player:OnSceneHumanDie(selfId,killerId)
end

return jingzhuzengli_player
