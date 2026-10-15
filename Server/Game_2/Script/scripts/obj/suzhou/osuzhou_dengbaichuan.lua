local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_dengbaichuan = class("osuzhou_dengbaichuan", script_base)
function osuzhou_dengbaichuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Công tử gia giơ tay nhấc chân đều giống hệt lão gia, chỉ là tuổi còn nhỏ, cần thêm thời gian trưởng thành thôi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_dengbaichuan
