local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_tongren_1 = class("otianlong_tongren_1", script_base)
function otianlong_tongren_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thủ Thái Âm Phế Kinh yếu huyệt như sau: Trung Phủ, Vân Môn, Thiên Phủ, Hiệp Bạch, Xích Trạch, Khổng Tối, Liệt Khuyết, Kinh Cừ, Thái Uyên, Ngư Tế, Thiếu Thương.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_tongren_1
