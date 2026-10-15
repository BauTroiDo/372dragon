local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_fengqianli = class("ogusu_fengqianli", script_base)

function ogusu_fengqianli:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là Phong Thiên Lý, quản lý việc tọa kỵ. Thiếu hiệp cần giúp gì?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_fengqianli
