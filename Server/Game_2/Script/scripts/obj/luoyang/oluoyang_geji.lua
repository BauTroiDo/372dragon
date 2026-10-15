local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_geji = class("oluoyang_geji", script_base)
oluoyang_geji.script_id = 000045
function oluoyang_geji:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là tiểu A hoàn, chuyện của chủ tử ta không biết đâu.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_geji
