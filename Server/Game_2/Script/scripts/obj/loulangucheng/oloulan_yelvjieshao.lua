local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_yelvjieshao = class("oloulan_yelvjieshao", script_base)
function oloulan_yelvjieshao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_19}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_yelvjieshao
