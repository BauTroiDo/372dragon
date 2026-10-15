--慕容山庄NPC
--慕容随风
--轻功传授人
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_murongsuifeng = class("ogusu_murongsuifeng", script_base)

function ogusu_murongsuifeng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Mộ Dung Tùy Phong, dạy khinh công bổn phái. Thiếu hiệp có gì chỉ giáo?")
    self:AddNumText("Học khinh công", 12, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogusu_murongsuifeng:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:DispatchQinggongLevelInfo(selfId, targetId)
    end
end

return ogusu_murongsuifeng
