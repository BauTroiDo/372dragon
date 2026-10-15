local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local weapon_npc = class("weapon_npc", script_base)
weapon_npc.script_id = 900070
weapon_npc.ui_ids = {
	[1] = 201208094,
	[2] = 201208093,
	[3] = 201208092,
	[4] = 815052022,
	[5] = 201208098,
}

function weapon_npc:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText("    Cường hóa thần khí.")
	self:AddNumText("神器通灵",6,1)
	self:AddNumText("Thần Khí Khế Hợp",6,2)
	self:AddNumText("Thần Khí Tiến Giai",6,3)
	self:AddNumText("Tẩy lại thần khí",6,4)
	self:AddNumText("Thần Khí Thoái Linh",6,5)
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end
function weapon_npc:OnEventRequest(selfId, targetId, arg, index)
	local ui_ids = self.ui_ids[index]
	if ui_ids then
		if index == 4 then
			self:BeginUICommand()
			self:UICommand_AddInt(targetId)
			self:UICommand_AddInt(900069)
			self:UICommand_AddInt(30505831)
			self:UICommand_AddInt(30505832)
			self:UICommand_AddInt(5)
			self:UICommand_AddInt(50000)
			self:EndUICommand()
			self:DispatchUICommand(selfId,ui_ids)
			return
		end
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		-- self:UICommand_AddStr(STR)
		self:EndUICommand()
		self:DispatchUICommand(selfId,ui_ids)
		return
	end
end
return weapon_npc