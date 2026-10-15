local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_xiaofengxian = class("oluoyang_xiaofengxian", script_base)
function oluoyang_xiaofengxian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thái Hậu lệnh chúng ta đến Tống triều để tiến hành so tài đá cầu.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_xiaofengxian
