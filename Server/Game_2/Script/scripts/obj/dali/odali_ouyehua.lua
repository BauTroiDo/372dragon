local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odali_ouyehua = class("odali_ouyehua", script_base)
odali_ouyehua.script_id = 890286

function odali_ouyehua:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SBFW_20230707_234}")
    self:AddNumText("#{SBFW_20230707_27}", 6, 1)
    self:AddNumText("#{SBFW_20230707_210}", 6, 2)
    self:AddNumText("#{SBFW_20230707_28}", 6, 3)
    self:AddNumText("#{SBFW_20230707_30}", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_ouyehua:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_ouyehua:OnEventRequest(selfId, targetId, arg, index)
	if index == 0 then
		self:UpdateEventList(selfId, targetId)
	elseif index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881501)
	elseif index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881503)
	elseif index == 3 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 88881502)
	elseif index == 100 then
		self:BeginEvent(self.script_id)
			self:AddText("#{SBFW_20230707_32}")
		self:AddNumText("#{SBFW_20230707_240}", 8, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
	end
end

return odali_ouyehua
