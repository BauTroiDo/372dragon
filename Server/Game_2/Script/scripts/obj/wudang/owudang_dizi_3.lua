local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_dizi_3 = class("owudang_dizi_3", script_base)
function owudang_dizi_3:OnDefaultEvent(selfId,targetId)
self:BeginEvent(self.script_id)
self:AddText("Ta là đệ tử Võ Đang phái.")
self:EndEvent()
self:DispatchEventList(selfId,targetId)
end

return owudang_dizi_3