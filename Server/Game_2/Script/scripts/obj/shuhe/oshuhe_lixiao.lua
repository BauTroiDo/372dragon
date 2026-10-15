local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_lixiao = class("oshuhe_lixiao", script_base)
oshuhe_lixiao.g_MsgInfo = {"#{SHGZ_0612_27}", "#{SHGZ_0620_76}", "#{SHGZ_0620_77}", "#{SHGZ_0620_78}"}

function oshuhe_lixiao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_lixiao
