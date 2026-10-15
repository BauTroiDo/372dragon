local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogusu_shouhulaotai = class("ogusu_shouhulaotai", script_base)

function ogusu_shouhulaotai:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lão thân trông coi sơn trang tại đây.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogusu_shouhulaotai
