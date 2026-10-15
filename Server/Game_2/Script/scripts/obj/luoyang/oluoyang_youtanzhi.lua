local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_youtanzhi = class("oluoyang_youtanzhi", script_base)
function oluoyang_youtanzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  A Tử tiểu thư, đẹp... đẹp tựa thiên tiên... thật muốn... muốn Thiên Thiên đều thấy nàng...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_youtanzhi
