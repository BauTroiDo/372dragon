local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_atong = class("ogusu_atong", script_base)

function ogusu_atong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  A Đồng chờ sẵn nơi đây.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_atong
