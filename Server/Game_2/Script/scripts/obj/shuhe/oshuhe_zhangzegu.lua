local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_zhangzegu = class("oshuhe_zhangzegu", script_base)
oshuhe_zhangzegu.g_MsgInfo = {"#{SHGZ_0612_23}", "#{SHGZ_0620_67}", "#{SHGZ_0620_68}", "#{SHGZ_0620_69}"}

function oshuhe_zhangzegu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_zhangzegu
