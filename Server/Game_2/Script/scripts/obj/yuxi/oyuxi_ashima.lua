local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_ashima = class("oyuxi_ashima", script_base)

function oyuxi_ashima:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Là ngươi cứu ta sao? A Hắc, A Hắc ca ca hắn ở đâu?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_ashima
