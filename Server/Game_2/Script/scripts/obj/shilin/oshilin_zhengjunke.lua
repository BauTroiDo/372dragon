local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_zhengjunke = class("oshilin_zhengjunke", script_base)
function oshilin_zhengjunke:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ta tên là Trịnh Quân Khả, phụ thân và cô phụ đều đi xa rồi. Cô cô Thiên Thiên đều khóc cả. Thật ra cô ấy không cần khóc đâu, phụ thân và cô phụ rồi sẽ có một ngày trở về thôi mà.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshilin_zhengjunke
