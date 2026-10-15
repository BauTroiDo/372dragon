local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhangjun = class("oluoyang_zhangjun", script_base)
function oluoyang_zhangjun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Năm nay, Đại Tống ta nhất định vẫn sẽ đoạt ngôi vị quán quân.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zhangjun
