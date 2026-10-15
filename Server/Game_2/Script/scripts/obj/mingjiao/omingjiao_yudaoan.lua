local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_yudaoan = class("omingjiao_yudaoan", script_base)
function omingjiao_yudaoan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thánh Nữ đại nhân gần đây có lẽ không vui cho lắm.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omingjiao_yudaoan
