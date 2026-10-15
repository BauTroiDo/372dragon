local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tengyuanzuowei = class("oluoyang_tengyuanzuowei", script_base)
oluoyang_tengyuanzuowei.script_id = 000029
function oluoyang_tengyuanzuowei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Rất vui được gặp ngươi, Đại Tống triều thật là một quốc gia xinh đẹp. Ta rất thích nơi này, hy vọng sau này còn có cơ hội đến nữa.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_tengyuanzuowei
