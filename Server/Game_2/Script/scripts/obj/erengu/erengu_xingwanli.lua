local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_xingwanli = class("erengu_xingwanli", script_base)
erengu_xingwanli.script_id = 018042
function erengu_xingwanli:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_10}")
	else
		self:AddText("#{ERMP_240620_10}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end
return erengu_xingwanli
