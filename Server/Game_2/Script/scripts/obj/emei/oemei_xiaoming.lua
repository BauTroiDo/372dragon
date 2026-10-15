local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_xiaoming = class("oemei_xiaoming", script_base)
function oemei_xiaoming:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chưởng môn tỷ tỷ từ Tô Châu trở về, mấy ngày liền ăn không ngon ngủ không yên, hình như có rất nhiều tâm sự.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oemei_xiaoming
