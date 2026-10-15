--丐帮NPC
--奚长老
--普通

local class = require "class"
local script_base = require "script_base"
local ogaibang_xizhanglao = class("ogaibang_xizhanglao", script_base)

function ogaibang_xizhanglao:OnDefaultEvent(selfId, targetId)
    local menpai = self:GetMenPai(selfId)
    if menpai == 2 then
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

function ogaibang_xizhanglao:OnEventRequest(selfId, targetId, arg, index)
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
    self:DispatchXinfaLevelInfo(selfId, targetId, 2)
end

return ogaibang_xizhanglao