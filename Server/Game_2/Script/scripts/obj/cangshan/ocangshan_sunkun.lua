local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ocangshan_sunkun = class("ocangshan_sunkun", script_base)
ocangshan_sunkun.script_id = 025113
function ocangshan_sunkun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SHGZ_0612_38}")
    self:AddNumText("Đến #YThúc Hà Cổ Trấn#W", 9, 3436)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ocangshan_sunkun:OnEventRequest(selfId, targetId, arg, index)
    if index == 3436 then
        self:GotoShuHeGuZhen(selfId, targetId)
        return
    end
end

function ocangshan_sunkun:GotoShuHeGuZhen(selfId, targetId)
    self:CallScriptFunction((400900), "TransferFunc", selfId, 420, 26, 288, 20)
    return
end

function ocangshan_sunkun:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ocangshan_sunkun
