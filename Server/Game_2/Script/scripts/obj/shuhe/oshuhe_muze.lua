local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_muze = class("oshuhe_muze", script_base)
oshuhe_muze.g_MsgInfo = {"#{SHGZ_0612_19}", "#{SHGZ_0620_55}", "#{SHGZ_0620_56}", "#{SHGZ_0620_57}"}

function oshuhe_muze:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_muze
