local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_chenghao = class("oluoyang_chenghao", script_base)
function oluoyang_chenghao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0005}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_chenghao
