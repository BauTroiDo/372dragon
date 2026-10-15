--天山NPC
--兰剑
--普通

local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local otianshan_lanjian = class("otianshan_lanjian", script_base)

function otianshan_lanjian:OnDefaultEvent(selfId, targetId)
    local menpai = self:GetMenPai(selfId)
    if menpai == 7 then
        self:BeginEvent(self.script_id)
		    self:AddText("#{TYJZ_081103_02}")
            self:AddNumText("Học Kỹ năng",12,0)
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
		    self:AddText("  Thật ra ta là nhị sư tỷ của đệ tử Thiên Sơn, Mai Kiếm tỷ tỷ mới là đại sư tỷ. Hì hì")
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function otianshan_lanjian:OnEventRequest(selfId, targetId, arg, index)
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
    self:DispatchXinfaLevelInfo(selfId, targetId, 7)
end

return otianshan_lanjian