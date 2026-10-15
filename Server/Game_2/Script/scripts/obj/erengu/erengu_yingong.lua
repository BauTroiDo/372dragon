local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yingong = class("erengu_yingong", script_base)
erengu_yingong.script_id = 018054
function erengu_yingong:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_15}")
	else
		self:AddText("#{ERMP_240620_15}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_yingong
