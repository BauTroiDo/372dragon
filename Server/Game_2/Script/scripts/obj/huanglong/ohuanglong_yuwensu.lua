local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_yuwensu = class("ohuanglong_yuwensu", script_base)
function ohuanglong_yuwensu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  A Văn dạo này không hiểu sao, không ăn cơm, không ngủ, cả ngày cứ ngồi đó thẫn thờ...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_yuwensu
