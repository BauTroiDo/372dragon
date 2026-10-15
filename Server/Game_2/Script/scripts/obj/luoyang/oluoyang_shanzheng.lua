local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_shanzheng = class("oluoyang_shanzheng", script_base)
function oluoyang_shanzheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0011}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_shanzheng
