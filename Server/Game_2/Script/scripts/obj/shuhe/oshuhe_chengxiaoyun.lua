local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_chengxiaoyun = class("oshuhe_chengxiaoyun", script_base)
oshuhe_chengxiaoyun.g_MsgInfo = {"#{SHGZ_0612_29}", "#{SHGZ_0620_85}", "#{SHGZ_0620_86}", "#{SHGZ_0620_87}"}

function oshuhe_chengxiaoyun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_chengxiaoyun
