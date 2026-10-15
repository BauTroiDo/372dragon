local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_shanyao = class("erengu_shanyao", script_base)
erengu_shanyao.script_id = 018045
function erengu_shanyao:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_12}")
	else
		self:AddText("#{ERMP_240620_34}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_shanyao
