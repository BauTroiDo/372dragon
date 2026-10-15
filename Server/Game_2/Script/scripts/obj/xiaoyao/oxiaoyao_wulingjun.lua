local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_wulingjun = class("oxiaoyao_wulingjun", script_base)
oxiaoyao_wulingjun.script_id = 014004
function oxiaoyao_wulingjun:OnDefaultEvent(selfId,targetId)
self:BeginEvent(self.script_id)
self:AddText("#{QXQS_130106_11}")
self:EndEvent()
self:DispatchEventList(selfId,targetId)
end

function oxiaoyao_wulingjun:OnEventRequest(selfId,targetId,arg,index)
end

return oxiaoyao_wulingjun