local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_ating = class("ogusu_ating", script_base)

function ogusu_ating:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  A Đình chờ sẵn nơi đây.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_ating
