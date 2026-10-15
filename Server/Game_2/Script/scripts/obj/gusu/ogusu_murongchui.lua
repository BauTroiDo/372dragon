--慕容山庄NPC
--慕容垂
--掌门人
local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local ogusu_murongchui = class("ogusu_murongchui", script_base)

function ogusu_murongchui:OnDefaultEvent(selfId, targetId)
    local menpai = self:GetMenPai(selfId)
    if menpai == 10 then
        self:BeginEvent(self.script_id)
		    self:AddText("Ta là Mộ Dung Thùy, trang chủ Mộ Dung Sơn Trang. Thiếu hiệp có gì chỉ giáo?")
            self:AddNumText("Học Kỹ năng",12,0)
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
		    self:AddText("Ta là Mộ Dung Thùy, trang chủ Mộ Dung Sơn Trang. Các hạ tìm ta có việc gì?")
            self:AddNumText("Giới thiệu tâm pháp củatửu quán",11,10)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function ogusu_murongchui:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
		    self:AddText("#{function_xinfajieshao_001}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 11 then
        self:BeginEvent(self.script_id)
            self:AddText("Tâm pháp là gốc võ học, tu luyện tâm pháp tăng nội lực và tu vi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:DispatchXinfaLevelInfo(selfId, targetId, 10)
end

return ogusu_murongchui
