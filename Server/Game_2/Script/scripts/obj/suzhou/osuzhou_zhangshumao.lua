local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhangshumao = class("osuzhou_zhangshumao", script_base)
function osuzhou_zhangshumao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0014}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhangshumao
