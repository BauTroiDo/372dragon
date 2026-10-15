local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_shibing = class("omingjiao_shibing", script_base)
function omingjiao_shibing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Quang Minh Điện là nơi trọng yếu, đừng chạy loạn! Cẩn thận lạc đường!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omingjiao_shibing
