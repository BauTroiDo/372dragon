local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_liuyuehong = class("osuzhou_liuyuehong", script_base)
osuzhou_liuyuehong.script_id = 1025
osuzhou_liuyuehong.g_ControlScript = 808071
function osuzhou_liuyuehong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Từ nay về sau, nàng chỉ được thương ta một mình, phải chiều chuộng ta, không được gạt ta, mọi việc nàng hứa với ta đều phải làm được.")
    self:CallScriptFunction(self.g_ControlScript, "OnEnumerate", self, selfId, targetId)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_liuyuehong:OnEventRequest(selfId, targetId, arg, index)
    if arg == self.g_ControlScript then
        self:CallScriptFunction(self.g_ControlScript, "OnDefaultEvent", selfId, targetId, arg, index)
        return
    end
end

return osuzhou_liuyuehong
