local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuliang_wangkui = class("owuliang_wangkui", script_base)
owuliang_wangkui.script_id = 0060010
function owuliang_wangkui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_wuliang_0007}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owuliang_wangkui
