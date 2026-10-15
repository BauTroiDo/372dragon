local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oqiongzhou_bangzhong = class("oqiongzhou_bangzhong", script_base)
function oqiongzhou_bangzhong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Bang chủ chúng ta võ công cái thế, thiên hạ vô địch, văn thành võ đức, điểu sinh ngư thang!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oqiongzhou_bangzhong
