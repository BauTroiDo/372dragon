--庞万春

--普通
local class = require "class"
local script_base = require "script_base"
local omingjiao_pangwanchun = class("omingjiao_pangwanchun", script_base)

function omingjiao_pangwanchun:OnDefaultEvent(selfId, targetId)
    local menpai = self:GetMenPai(selfId)
    if menpai == 1 then
        self:BeginEvent(self.script_id)
		    self:AddText("#{TYJZ_081103_02}")
            self:AddNumText("Học Kỹ năng",12,0)
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
		    self:AddText("Ngươi tìm ta có việc gì?")
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function omingjiao_pangwanchun:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
		    self:AddText("#{function_xinfajieshao_001}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 11 then
        self:BeginEvent(self.script_id)
            self:AddText("#{JZBZ_081031_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:DispatchXinfaLevelInfo(selfId, targetId, 1)
end

return omingjiao_pangwanchun