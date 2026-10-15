local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_xiaoyuanshan = class("oshaolin_xiaoyuanshan", script_base)
function oshaolin_xiaoyuanshan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Không cho xem, ta lại càng muốn xem!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshaolin_xiaoyuanshan
