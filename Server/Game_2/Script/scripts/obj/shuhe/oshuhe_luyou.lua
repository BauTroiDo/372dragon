local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_luyou = class("oshuhe_luyou", script_base)
oshuhe_luyou.g_MsgInfo = {"#{SHGZ_0612_22}", "#{SHGZ_0620_64}", "#{SHGZ_0620_65}", "#{SHGZ_0620_66}"}

function oshuhe_luyou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_luyou
