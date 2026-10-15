local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_fanchuncui = class("osuzhou_fanchuncui", script_base)
osuzhou_fanchuncui.script_id = 001084
osuzhou_fanchuncui.g_eventList = {600000}

function osuzhou_fanchuncui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BHCS_090219_01}")
    self:AddNumText("#{BHCS_090219_04}", 11, 10)
    self:AddNumText("#{BHCS_090219_05}", 6, 2)
    self:AddNumText("#{BHCS_090219_06}", 6, 4)
    if (self:GetHumanGuildID(selfId) ~= -1) then
        if (self:CityGetSelfCityID(selfId) ~= -1) then
            self:AddNumText("#{BHCS_090219_07}", 9, 6)
        end
    end
    self:AddNumText("#{BHCS_090219_08}", 11, 11)
    self:AddNumText("#{BHCS_090219_09}", 11, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_fanchuncui:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_069}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{Guild_Boom_Help}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{TM_20080331_07}" .. "#{TM_20080320_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local sel = index
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId, arg, sel)
    end
end

return osuzhou_fanchuncui
