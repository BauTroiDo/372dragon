local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_fengxiao = class("ogusu_fengxiao", script_base)

function ogusu_fengxiao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Phong Tiêu ở đây. Thiếu hiệp có việc gì?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_fengxiao
