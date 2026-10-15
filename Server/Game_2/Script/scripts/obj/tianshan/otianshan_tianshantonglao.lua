local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_tianshantonglao = class("otianshan_tianshantonglao", script_base)
function otianshan_tianshantonglao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("……")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return otianshan_tianshantonglao
