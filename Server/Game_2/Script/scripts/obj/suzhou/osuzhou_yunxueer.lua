local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yunxueer = class("osuzhou_yunxueer", script_base)
osuzhou_yunxueer.script_id = 001089
function osuzhou_yunxueer:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSZB_090421_01}")
    self:AddNumText("#{ZSZB_090421_02}", 6, 1)
    self:AddNumText("#{ZSZB_090421_03}", 6, 2)
    self:AddNumText("#{ZSZB_090421_08}", 11, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunxueer:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20092461)
    end
    if index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20092462)
    end
    if index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZSZB_090820_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return osuzhou_yunxueer
