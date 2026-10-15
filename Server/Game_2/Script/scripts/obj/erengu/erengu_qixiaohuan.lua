local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_qixiaohuan = class("erengu_qixiaohuan", script_base)
erengu_qixiaohuan.script_id = 018051
function erengu_qixiaohuan:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_16}")
	else
		self:AddText("#{ERMP_240620_16}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_qixiaohuan
