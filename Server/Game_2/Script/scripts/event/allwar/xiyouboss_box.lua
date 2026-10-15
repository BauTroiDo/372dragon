local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local xiyouboss_box = class("xiyouboss_box", script_base)
-- local gbk = require "wire_charset"
xiyouboss_box.script_id = 999976
xiyouboss_box.GoBackScene = 0
xiyouboss_box.GoBackPosx = 160
xiyouboss_box.GoBackPosz = 105
function xiyouboss_box:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{DHYR_240515_131}")
	self:AddNumText("#{DHYR_240515_127}",6,1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
function xiyouboss_box:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		local sceneId = self:GetSceneID()
		if sceneId < 713 or sceneId > 715 then
			return
		end
		self:NewWorld(selfId,self.GoBackScene,nil,self.GoBackPosx,self.GoBackPosz)
	end
end
return xiyouboss_box