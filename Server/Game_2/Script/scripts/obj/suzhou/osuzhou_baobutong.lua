local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_baobutong = class("osuzhou_baobutong", script_base)
function osuzhou_baobutong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Không phải vậy, không phải vậy., phải là \"Bình vu tận xứ thị xuân sơn, hành nhân cánh tại xuân sơn ngoại.\" mới đúng.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_baobutong
