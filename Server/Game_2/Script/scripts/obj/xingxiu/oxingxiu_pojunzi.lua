local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_pojunzi = class("oxingxiu_pojunzi", script_base)
oxingxiu_pojunzi.script_id = 016008
function oxingxiu_pojunzi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_08}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_pojunzi:OnEventRequest(selfId, targetId, arg, index)
end

return oxingxiu_pojunzi
