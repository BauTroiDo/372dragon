local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_tongren_2 = class("otianlong_tongren_2", script_base)
function otianlong_tongren_2:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thủ Dương Minh Đại Trường Kinh yếu huyệt như sau: Thương Dương, Hợp Cốc, Dương Khê, Thiên Lịch, Ôn Lựu, Thủ Tam Lý, Khúc Trì, Thủ Ngũ Lý, Cự Cốt, Thiên Đỉnh, Nghênh Hương.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_tongren_2
