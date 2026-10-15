local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_tuobawen = class("ohuanglong_tuobawen", script_base)
function ohuanglong_tuobawen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hôm đó Tịch Nhan đi đến khu rừng phía bắc, việc nàng làm, ta đều thấy cả... Nhưng, nếu đem việc này nói với Mộ Dung Trưởng Lão, ắt ông ấy sẽ xử tử Tịch Nhan... Ta phải làm sao đây...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_tuobawen
