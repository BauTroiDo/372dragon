local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yanchasan = class("osuzhou_yanchasan", script_base)
function osuzhou_yanchasan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Khoa thi lần này, nhân tài khắp nơi tụ hội Tô Châu, trong lòng ta thật sự không chắc chắn.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_yanchasan
