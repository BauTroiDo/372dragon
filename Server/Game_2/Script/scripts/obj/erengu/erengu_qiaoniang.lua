local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_qiaoniang = class("erengu_qiaoniang", script_base)
erengu_qiaoniang.script_id = 018049
function erengu_qiaoniang:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_161}")
	else
		self:AddText("#{ERMP_240620_161}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_qiaoniang
