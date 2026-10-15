local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_wangmohan = class("oshuhe_wangmohan", script_base)
oshuhe_wangmohan.g_MsgInfo = {"#{SHGZ_0612_33}", "#{SHGZ_0620_97}", "#{SHGZ_0620_98}", "#{SHGZ_0620_99}"}

function oshuhe_wangmohan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_wangmohan
