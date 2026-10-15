local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local oxiliangfenglin_ruanfengmian = class("oxiliangfenglin_ruanfengmian", script_base)
oxiliangfenglin_ruanfengmian.g_eventList = { 888808 }
function oxiliangfenglin_ruanfengmian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SWXT_221213_6}")
    if self:GetMissionData(selfId, ScriptGlobal.LingWuLiuPai) == 3 then
        self:AddNumText("#{SWXT_221213_240}", 6, 1)
    else
        self:AddNumText("#{SWXT_221213_212}", 6, 1)
    end
    self:AddNumText("#{SWXT_221213_4}", 11, 2)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiliangfenglin_ruanfengmian:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:DispatchShengWangInfo(selfId, 3)
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SWXT_221213_221}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function oxiliangfenglin_ruanfengmian:JoinCamp(selfId, targetId, camp)
    self:SetMissionData(selfId, ScriptGlobal.LingWuLiuPai, 3)
    self:notify_tips(selfId, "Đã vào phe chú pháp - Phá Trận")
end

return oxiliangfenglin_ruanfengmian