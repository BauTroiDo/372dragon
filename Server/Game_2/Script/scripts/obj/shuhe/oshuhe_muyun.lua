local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_muyun = class("oshuhe_muyun", script_base)
oshuhe_muyun.g_MsgInfo = {"#{SHGZ_0612_21}", "#{SHGZ_0620_61}", "#{SHGZ_0620_62}", "#{SHGZ_0620_63}"}

function oshuhe_muyun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_muyun
