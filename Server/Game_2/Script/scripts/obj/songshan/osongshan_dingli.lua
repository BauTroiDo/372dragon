local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osongshan_dingli = class("osongshan_dingli", script_base)
function osongshan_dingli:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nghe nói Thái Lão Gia còn sống, sao có thể chứ? Năm xưa lúc Thái Lão Gia qua đời, ta đã tận mắt chứng kiến, lẽ nào trên đời lại có chuyện như vậy sao? Thật không thể tin nổi...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osongshan_dingli
