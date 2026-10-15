local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_cunmin = class("oshilin_cunmin", script_base)

function oshilin_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Viên Nguyệt Thôn, than ôi, trong thôn còn được mấy nhà trọn vẹn đoàn viên...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshilin_cunmin
