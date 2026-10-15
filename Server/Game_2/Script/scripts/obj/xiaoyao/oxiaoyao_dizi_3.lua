local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_dizi_3 = class("oxiaoyao_dizi_3", script_base)
function oxiaoyao_dizi_3:OnDefaultEvent(selfId,targetId)
self:BeginEvent(self.script_id)
self:AddText("Ta là đệ tử Tiêu Dao phái.")
self:EndEvent()
self:DispatchEventList(selfId,targetId)
end

return oxiaoyao_dizi_3