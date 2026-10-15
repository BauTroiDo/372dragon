local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_liyao = class("oshuhe_liyao", script_base)
oshuhe_liyao.g_MsgInfo = {"#{SHGZ_0612_26}", "#{SHGZ_0620_79}", "#{SHGZ_0620_80}", "#{SHGZ_0620_81}"}

function oshuhe_liyao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_liyao
