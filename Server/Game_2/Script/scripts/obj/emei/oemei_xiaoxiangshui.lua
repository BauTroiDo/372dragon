local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_xiaoxiangshui = class("oemei_xiaoxiangshui", script_base)
oemei_xiaoxiangshui.script_id = 015007
function oemei_xiaoxiangshui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_07}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oemei_xiaoxiangshui:OnEventRequest(selfId, targetId, arg, index)
end

return oemei_xiaoxiangshui
