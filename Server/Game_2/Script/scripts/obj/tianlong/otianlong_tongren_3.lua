local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_tongren_3 = class("otianlong_tongren_3", script_base)
function otianlong_tongren_3:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Các yếu huyệt của Túc Dương Minh Vị Kinh như sau: Ẩn Bạch, Đại Đô, Thái Bạch, Công Tôn, Thương Khâu, Tam Âm Giao, Lậu Cốc, Huyết Hải, Ki Môn, Xung Môn, Đại Hoành, Thiên Khê, Đại Bao.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_tongren_3
