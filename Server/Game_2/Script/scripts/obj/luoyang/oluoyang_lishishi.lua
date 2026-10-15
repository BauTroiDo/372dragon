local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_lishishi = class("oluoyang_lishishi", script_base)
function oluoyang_lishishi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Vô khả nại hà hoa lạc khứ, tự tằng tương thức yến quy lai. Tiểu viên hương kính độc bồi hồi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_lishishi
