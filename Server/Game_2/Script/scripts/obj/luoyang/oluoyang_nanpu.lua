local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_nanpu = class("oluoyang_nanpu", script_base)
function oluoyang_nanpu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lão gia đang nghỉ ngơi, bất kỳ ai cũng không được quấy rầy.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_nanpu
