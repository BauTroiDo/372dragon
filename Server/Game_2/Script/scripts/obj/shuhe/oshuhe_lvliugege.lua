local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_lvliugege = class("oshuhe_lvliugege", script_base)
oshuhe_lvliugege.g_MsgInfo = {"#{SHGZ_0612_34}", "#{SHGZ_0620_100}", "#{SHGZ_0620_101}", "#{SHGZ_0620_102}"}

function oshuhe_lvliugege:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_lvliugege
