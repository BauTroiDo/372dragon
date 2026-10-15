local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local yingshen_boss = class("yingshen_boss", script_base)
-- local gbk = require "wire_charset"
yingshen_boss.script_id = 999977
function yingshen_boss:OnDefaultEvent(selfId, targetId)
    local human = self.scene:get_obj_by_id(selfId)
	if not human then
		return 1
	end
	local sceneId = self.scene:get_id()
	local guid = human:get_guid()
	local name = human:get_name()
	local objId,obj,ai,value
	obj = self.scene:get_obj_by_id(targetId)
	if obj then
		ai = obj:get_ai()
		if ai:get_int_param_by_index(1) == sceneId
		and ai:get_int_param_by_index(2) == guid then
			self:BeginEvent(self.script_id)
			-- self:AddText("    ")
			self:AddNumText("Bắt đầu chiến đấu...", 6, 1)
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		else
			self:BeginEvent(self.script_id)
			self:AddText("    Ta không do ngài thả, xin tìm người thả tới kích hoạt chiến đấu.")
			self:EndEvent()
			self:DispatchEventList(selfId, targetId)
		end
	end
end

function yingshen_boss:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		local human = self.scene:get_obj_by_id(selfId)
		if not human then
			return 1
		end
		local sceneId = self.scene:get_id()
		local guid = human:get_guid()
		local name = human:get_name()
		local objId,obj,ai,value
		obj = self.scene:get_obj_by_id(targetId)
		if obj then
			ai = obj:get_ai()
			if ai:get_int_param_by_index(1) == sceneId
			and ai:get_int_param_by_index(2) == guid then
				self:SetUnitReputationID(targetId,targetId,29)
				
				self:BeginUICommand()
				self:EndUICommand()
				self:DispatchUICommand(selfId,1000)
				
			end
		end
	end
end
function yingshen_boss:OnDie(objId,killerId)
end


return yingshen_boss