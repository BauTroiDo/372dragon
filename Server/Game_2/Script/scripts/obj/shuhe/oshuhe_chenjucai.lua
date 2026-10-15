local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_chenjucai = class("oshuhe_chenjucai", script_base)
oshuhe_chenjucai.script_id = 001182
oshuhe_chenjucai.g_MsgInfo = {"#{SHGZ_0612_07}", "#{SHGZ_0620_19}", "#{SHGZ_0620_20}", "#{SHGZ_0620_21}"}

function oshuhe_chenjucai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("#{JZBZ_081031_02}", 11, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_chenjucai:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JZBZ_081031_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return oshuhe_chenjucai
