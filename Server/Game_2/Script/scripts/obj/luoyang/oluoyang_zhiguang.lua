local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhiguang = class("oluoyang_zhiguang", script_base)
function oluoyang_zhiguang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0010}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zhiguang
