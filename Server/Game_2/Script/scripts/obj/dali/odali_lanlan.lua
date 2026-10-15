local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_lanlan = class("odali_lanlan", script_base)
function odali_lanlan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Vương phi mỗi ngày ăn không vô, ngủ không yên, cứ như vậy thân thể sẽ suy sụp mất.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_lanlan
