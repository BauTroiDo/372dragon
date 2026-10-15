local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_wangying = class("odali_wangying", script_base)
odali_wangying.script_id = 002025
function odali_wangying:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0009}")
    self:AddNumText("Ngân hàng tửu quán", 11, 100)
    self:AddNumText("#{JZBZ_081031_02}", 11, 101)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_wangying:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_049}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 101 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JZBZ_081031_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return odali_wangying
