local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuliang_xuedama = class("owuliang_xuedama", script_base)
owuliang_xuedama.script_id = 006009
function owuliang_xuedama:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_wuliang_0006}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owuliang_xuedama
