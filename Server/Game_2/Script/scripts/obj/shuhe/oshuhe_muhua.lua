local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_muhua = class("oshuhe_muhua", script_base)
oshuhe_muhua.g_MsgInfo = {"#{SHGZ_0612_20}", "#{SHGZ_0620_58}", "#{SHGZ_0620_59}", "#{SHGZ_0620_60}"}

function oshuhe_muhua:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_muhua
