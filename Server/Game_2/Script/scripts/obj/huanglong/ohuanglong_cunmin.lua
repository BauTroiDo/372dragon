local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohuanglong_cunmin = class("ohuanglong_cunmin", script_base)
function ohuanglong_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Gần đây Hoàng Long trấn bất ổn quá, nghe nói thánh vật đều bị Mãng Cái hủy hoại rồi, vậy chúng ta chẳng phải sắp phải đối mặt với tai ương ngập đầu rồi sao...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ohuanglong_cunmin
