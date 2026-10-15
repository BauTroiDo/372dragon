local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_dingmian = class("osongshan_dingmian", script_base)
function osongshan_dingmian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Từ khi xảy ra chuyện đó, tinh thần công tử nhà ta vẫn luôn không tốt, rốt cuộc là người đã thấy những gì chứ?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osongshan_dingmian
