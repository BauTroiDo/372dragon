local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_tongren_4 = class("otianlong_tongren_4", script_base)
function otianlong_tongren_4:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Các yếu huyệt của Túc Dương Minh Vị Kinh như sau: Thừa Khấp, Tứ Bạch, Giáp Xa, Hạ Quan, Khí Hộ, Lương Môn, Quan Môn, Thái Ất, Thiên Xu, Phục Thố, Âm Thị, Túc Tam Lý, Nội Đình.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_tongren_4
