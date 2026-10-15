local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_shanwang = class("erengu_shanwang", script_base)
erengu_shanwang.script_id = 018046
function erengu_shanwang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
	self:AddText("#{MPDYR_20220427_23}")
	self:AddNumText("#{JXGZ_220427_17}", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_shanwang:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JXGZ_220427_18}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return erengu_shanwang
