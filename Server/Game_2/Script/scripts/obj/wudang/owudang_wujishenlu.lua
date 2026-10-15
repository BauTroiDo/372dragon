local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_wujishenlu = class("owudang_wujishenlu", script_base)
function owudang_wujishenlu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("<?????????>")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_wujishenlu
