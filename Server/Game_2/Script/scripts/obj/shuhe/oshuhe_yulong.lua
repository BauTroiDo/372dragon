local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_yulong = class("oshuhe_yulong", script_base)
oshuhe_yulong.g_MsgInfo = {"#{SHGZ_0612_35}", "#{SHGZ_0620_103}", "#{SHGZ_0620_104}", "#{SHGZ_0620_105}"}

function oshuhe_yulong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_yulong
