local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_wenyanbo = class("osuzhou_wenyanbo", script_base)
osuzhou_wenyanbo.script_id = 001009
function osuzhou_wenyanbo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BBLP_90209_1}")
    self:CallScriptFunction(808125, "OnEnumerate", self, selfId, targetId)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_wenyanbo:OnEventRequest(selfId, targetId, arg, index)
    self:CallScriptFunction(808125, "OnDefaultEvent", selfId, targetId,arg,index)
end

return osuzhou_wenyanbo
