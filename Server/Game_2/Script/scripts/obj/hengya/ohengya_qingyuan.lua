local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ohengya_qingyuan = class("ohengya_qingyuan", script_base)
function ohengya_qingyuan:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{CJWK_221220_57}")
    self:AddNumText("#{CJWK_221220_58}", 9, 100)
    self:AddNumText("#{CJWK_221220_59}", 9, 101)
    self:AddNumText("#{CJWK_221220_60}", 9, 102)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ohengya_qingyuan:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1292, 112, 106)
        return
    end
    if index == 101 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1293, 78, 108)
        return
    end
    if index == 102 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 1294, 91, 59)
        return
    end
end

return ohengya_qingyuan