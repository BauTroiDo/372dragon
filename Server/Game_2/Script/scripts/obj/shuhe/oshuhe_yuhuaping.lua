local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_yuhuaping = class("oshuhe_yuhuaping", script_base)
oshuhe_yuhuaping.g_MsgInfo = {"#{SHGZ_0612_24}", "#{SHGZ_0620_70}", "#{SHGZ_0620_71}", "#{SHGZ_0620_72}"}

function oshuhe_yuhuaping:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_yuhuaping
