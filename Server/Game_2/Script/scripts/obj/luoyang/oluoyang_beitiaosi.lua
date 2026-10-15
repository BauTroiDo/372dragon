local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_beitiaosi = class("oluoyang_beitiaosi", script_base)
oluoyang_beitiaosi.script_id = 000047
function oluoyang_beitiaosi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nghe nói quốc lễ mà Cao Ly quốc tiến cống bị mất, thật sao?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_beitiaosi
