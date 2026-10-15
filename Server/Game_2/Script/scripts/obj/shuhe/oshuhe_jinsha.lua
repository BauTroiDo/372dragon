local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_jinsha = class("oshuhe_jinsha", script_base)
oshuhe_jinsha.g_MsgInfo = {"#{SHGZ_0612_36}", "#{SHGZ_0620_106}", "#{SHGZ_0620_107}", "#{SHGZ_0620_108}"}

function oshuhe_jinsha:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_jinsha
