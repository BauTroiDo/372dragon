local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuliang_xueyunlai = class("owuliang_xueyunlai", script_base)
owuliang_xueyunlai.script_id = 006008
function owuliang_xueyunlai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_wuliang_0005}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owuliang_xueyunlai
