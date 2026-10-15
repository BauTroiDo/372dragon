local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_yanghongruo = class("oshuhe_yanghongruo", script_base)
oshuhe_yanghongruo.g_MsgInfo = {"#{SHGZ_0612_25}", "#{SHGZ_0620_73}", "#{SHGZ_0620_74}", "#{SHGZ_0620_75}"}

function oshuhe_yanghongruo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_yanghongruo
