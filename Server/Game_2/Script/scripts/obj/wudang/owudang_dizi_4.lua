local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_dizi_4 = class("owudang_dizi_4", script_base)
function owudang_dizi_4:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là đệ tử Võ Đang phái.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_dizi_4
