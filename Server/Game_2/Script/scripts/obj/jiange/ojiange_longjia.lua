local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojiange_longjia = class("ojiange_longjia", script_base)
ojiange_longjia.script_id = 007113
function ojiange_longjia:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msg = "#{DG_8724_1}"
    self:AddText(msg)
    self:AddNumText("Truyền tống đến Tần Hoàng Địa Cung", 9, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ojiange_longjia:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 400, 227, 224)
    end
end

return ojiange_longjia
