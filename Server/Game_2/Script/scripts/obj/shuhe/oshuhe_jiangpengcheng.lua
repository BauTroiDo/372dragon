local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_jiangpengcheng = class("oshuhe_jiangpengcheng", script_base)
oshuhe_jiangpengcheng.g_MsgInfo = {"#{SHGZ_0612_32}", "#{SHGZ_0620_94}", "#{SHGZ_0620_95}", "#{SHGZ_0620_96}"}

function oshuhe_jiangpengcheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_jiangpengcheng
