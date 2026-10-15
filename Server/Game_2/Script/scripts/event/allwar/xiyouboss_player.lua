local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local xiyouboss_player = class("xiyouboss_player", script_base)
xiyouboss_player.script_id = 999981

xiyouboss_player.act_isopen = 2
xiyouboss_player.GoBackScene = 0
xiyouboss_player.GoBackPosx = 90
xiyouboss_player.GoBackPosz = 182

function xiyouboss_player:OnWarScene(selfId)
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(selfId)
	if not obj then return end
	local sceneId = scene:get_id()
	if sceneId == 814 or sceneId == 818 then
		local act_isopen = self:GetActivityParamEx(define.ACTIVITY_XIYOU_ID, self.act_isopen)
		if act_isopen > 0 then
			return
		end
		self:CallScriptFunction(999983, "EnsureActivityOpen")
		act_isopen = self:GetActivityParamEx(define.ACTIVITY_XIYOU_ID, self.act_isopen)
		if act_isopen > 0 then
			return
		end
		obj:notify_tips("Hoạt động chưa mở.")
	end
	self:NewWorld(selfId, self.GoBackScene, nil, self.GoBackPosx, self.GoBackPosz)
end

function xiyouboss_player:OnSceneHumanDie(selfId, killerId)
end

return xiyouboss_player