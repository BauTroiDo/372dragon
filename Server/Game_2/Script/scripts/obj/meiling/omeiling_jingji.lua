local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_jingji = class("omeiling_jingji", script_base)
function omeiling_jingji:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nơi nào có áp bức, nơi đó có phản kháng. Chúng ta, Hộ Pháp Sơn Việt, không thể giống như tổ tiên cha ông, chịu sự áp bức của nữ tế tư Sơn Việt nữa! Dù thế hệ chúng ta thất bại, con cháu chúng ta cũng sẽ phản kháng đến cùng!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_jingji
