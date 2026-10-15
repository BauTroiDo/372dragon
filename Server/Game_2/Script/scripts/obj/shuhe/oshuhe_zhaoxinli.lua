local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_zhaoxinli = class("oshuhe_zhaoxinli", script_base)
oshuhe_zhaoxinli.g_MsgInfo = {"#{SHGZ_0612_28}", "#{SHGZ_0620_82}", "#{SHGZ_0620_83}", "#{SHGZ_0620_84}"}

function oshuhe_zhaoxinli:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_zhaoxinli
