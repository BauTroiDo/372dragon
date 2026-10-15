local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_dingxiaolin = class("oshuhe_dingxiaolin", script_base)
oshuhe_dingxiaolin.g_MsgInfo = {"#{SHGZ_0612_31}", "#{SHGZ_0620_91}", "#{SHGZ_0620_92}", "#{SHGZ_0620_93}"}

function oshuhe_dingxiaolin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_dingxiaolin
