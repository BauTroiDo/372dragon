--少林NPC
--玄难
--普通
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local oshaolin_xuannan = class("oshaolin_xuannan", script_base)

function oshaolin_xuannan:OnDefaultEvent(selfId, targetId)
    local menpai = self:GetMenPai(selfId)
    if menpai == 0 then
        self:BeginEvent(self.script_id)
		    self:AddText("#{TYJZ_081103_02}")
            self:AddNumText("Học Kỹ năng",12,0)
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
		    self:AddText("Lão nạp Huyền Nan, thí chủ tìm bần tăng có việc chi chăng?")
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function oshaolin_xuannan:OnEventRequest(selfId, targetId, arg, index)
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
    self:DispatchXinfaLevelInfo(selfId, targetId, 0)
end

return oshaolin_xuannan