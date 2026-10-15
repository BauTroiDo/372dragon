local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_kangsitanding = class("oloulan_kangsitanding", script_base)
oloulan_kangsitanding.script_id = 001105
function oloulan_kangsitanding:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  #{LLGC_20080321_09}")
    self:AddNumText("#{JZBZ_081031_02}", 11, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_kangsitanding:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JZBZ_081031_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return oloulan_kangsitanding
