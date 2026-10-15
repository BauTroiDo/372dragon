local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_cunmin = class("ojiange_cunmin", script_base)
function ojiange_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Khương Gia Tập đang có trộm hoành hành!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ojiange_cunmin
