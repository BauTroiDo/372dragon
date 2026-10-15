local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_dizi_4 = class("oxingxiu_dizi_4", script_base)
function oxingxiu_dizi_4:OnDefaultEvent(selfId,targetId)
self:BeginEvent(self.script_id)
self:AddText("Ta là đệ tử Tinh Túc phái.")
self:EndEvent()
self:DispatchEventList(selfId,targetId)
end

return oxingxiu_dizi_4