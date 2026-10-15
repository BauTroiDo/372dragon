local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yinzu = class("erengu_yinzu", script_base)
erengu_yinzu.script_id = 018053
function erengu_yinzu:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_14}")
	else
		self:AddText("#{ERMP_240620_14}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_yinzu
