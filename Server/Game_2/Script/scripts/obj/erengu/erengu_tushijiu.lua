local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_tushijiu = class("erengu_tushijiu", script_base)
erengu_tushijiu.script_id = 018048
function erengu_tushijiu:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_163}")
	else
		self:AddText("#{ERMP_240620_163}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return erengu_tushijiu
