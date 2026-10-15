local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_xueren = class("oxihu_xueren", script_base)
oxihu_xueren.script_id = 050200
function oxihu_xueren:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Ta... ta là Người tuyết đó!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxihu_xueren
