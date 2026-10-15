local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_shanyue = class("erengu_shanyue", script_base)
erengu_shanyue.script_id = 018052
function erengu_shanyue:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_13}")
	else
		self:AddText("#{ERMP_240620_13}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
return erengu_shanyue
