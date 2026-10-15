local class = require "class"
local define = require "define"
local script_base = require "script_base"
local erengu_shanliang = class("erengu_shanliang", script_base)
erengu_shanliang.script_id = 018047
function erengu_shanliang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
	self:AddText("#{MPDYR_20220427_171}")
	self:AddNumText("#{MPDYR_20220427_25}", 11, 10)
	self:AddNumText("#{MPDYR_20220427_161}", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function erengu_shanliang:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MPDYR_20220427_26}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
	elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MPDYR_20220427_128}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:DispatchXinfaLevelInfo(selfId, targetId, 15)
end

return erengu_shanliang
