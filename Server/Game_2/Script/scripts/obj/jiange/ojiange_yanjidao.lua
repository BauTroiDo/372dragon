local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_yanjidao = class("ojiange_yanjidao", script_base)

function ojiange_yanjidao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_jiange_0007}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ojiange_yanjidao
