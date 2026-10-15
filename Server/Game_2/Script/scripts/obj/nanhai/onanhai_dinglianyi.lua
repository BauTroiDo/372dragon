local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanhai_dinglianyi = class("onanhai_dinglianyi", script_base)
function onanhai_dinglianyi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Sư phụ, sư nương... còn có đại sư huynh... cứ như vậy, cứ như vậy, đều đã không còn sao? Huhu... Đừng ai quản ta, ta không muốn sống nữa...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return onanhai_dinglianyi
