local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local erengu_shangui = class("erengu_shangui", script_base)
erengu_shangui.script_id = 018035
function erengu_shangui:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local PlayerName = self:GetName(selfId)
	if self:GetMenPai(selfId) ~= 15 then
		 self:AddText("#{ERMP_240620_23}")
	else
		 self:AddText("#{ERMP_240620_01}")
	end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_shangui:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

return erengu_shangui
