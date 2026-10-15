local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_shanliuer = class("erengu_shanliuer", script_base)
erengu_shanliuer.script_id = 018044
function erengu_shanliuer:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_11}")
	else
		self:AddText("#{ERMP_240620_33}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
return erengu_shanliuer
