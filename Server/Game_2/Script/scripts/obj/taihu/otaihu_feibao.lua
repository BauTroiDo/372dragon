local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otaihu_feibao = class("otaihu_feibao", script_base)
function otaihu_feibao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thiên Tiên muội muội~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otaihu_feibao
