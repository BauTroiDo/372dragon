local class = require "class"
local define = require "define"
local script_base = require "script_base"
local onanzhao_miaobing = class("onanzhao_miaobing", script_base)
function onanzhao_miaobing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thiên Tiên muội muội~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return onanzhao_miaobing
