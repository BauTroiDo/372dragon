local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_huyulang = class("erengu_huyulang", script_base)
erengu_huyulang.script_id = 018050
function erengu_huyulang:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_162}")
	else
		self:AddText("#{ERMP_240620_162}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_huyulang
