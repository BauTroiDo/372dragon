local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_qianxiaojiang = class("oshuhe_qianxiaojiang", script_base)
oshuhe_qianxiaojiang.g_MsgInfo = {"#{SHGZ_0612_30}", "#{SHGZ_0620_88}", "#{SHGZ_0620_89}", "#{SHGZ_0620_90}"}

function oshuhe_qianxiaojiang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_qianxiaojiang
