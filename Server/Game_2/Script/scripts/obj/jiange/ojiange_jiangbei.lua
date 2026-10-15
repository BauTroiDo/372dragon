local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_jiangbei = class("ojiange_jiangbei", script_base)

function ojiange_jiangbei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_jiange_0003}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ojiange_jiangbei
