local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_canglan = class("oshuhe_canglan", script_base)
oshuhe_canglan.g_MsgInfo = {"#{SHGZ_0612_37}", "#{SHGZ_0620_109}", "#{SHGZ_0620_110}", "#{SHGZ_0620_111}"}

function oshuhe_canglan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_canglan
