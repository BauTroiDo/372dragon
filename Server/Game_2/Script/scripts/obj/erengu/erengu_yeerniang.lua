local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_yeerniang = class("erengu_yeerniang", script_base)
erengu_yeerniang.script_id = 018037
function erengu_yeerniang:OnDefaultEvent(selfId, targetId)
    local nMenPai = self:GetMenPai(selfId)
    self:BeginEvent(self.script_id)
    if nMenPai == 15 then
		self:AddText("#{ERMP_240620_03}")
        self:AddNumText("Học Kỹ năng",12,0)
        self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
	else
		self:AddText("#{ERMP_240620_25}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_yeerniang:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_xinfajieshao_001}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:DispatchXinfaLevelInfo(selfId, targetId, 15)
end

return erengu_yeerniang
