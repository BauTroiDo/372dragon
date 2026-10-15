local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_youzuo = class("oluoyang_youzuo", script_base)
function oluoyang_youzuo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Lâu lắm rồi chưa gặp Ân Sư, thật là nhớ nhung a!#r Ân Sư dạy dỗ chúng ta rất tốt, khiến chúng ta lĩnh ngộ rất nhiều đạo lý trên đời, hôm nay đặc biệt đến thăm Ân Sư.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_youzuo
