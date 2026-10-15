local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yinpo = class("erengu_yinpo", script_base)
erengu_yinpo.script_id = 018043
function erengu_yinpo:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_10}")
	else
		self:AddText("#{ERMP_240620_32}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_yinpo
