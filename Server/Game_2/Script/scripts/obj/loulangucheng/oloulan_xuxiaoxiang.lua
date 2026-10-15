local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_xuxiaoxiang = class("oloulan_xuxiaoxiang", script_base)
function oloulan_xuxiaoxiang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_17}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oloulan_xuxiaoxiang
