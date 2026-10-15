local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_qiguidie = class("otianlong_qiguidie", script_base)
function otianlong_qiguidie:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Gần đây may cho Bổn Nhân đại sư một chiếc áo cà sa mới, không biết có vừa người hay không.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianlong_qiguidie
