local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local oshunanzhuhai_jiangxingyun = class("oshunanzhuhai_jiangxingyun", script_base)
oshunanzhuhai_jiangxingyun.g_eventList = { 888808 }
function oshunanzhuhai_jiangxingyun:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SWXT_221213_5}")
    if self:GetMissionData(selfId, ScriptGlobal.LingWuLiuPai) == 2 then
        self:AddNumText("#{SWXT_221213_239}", 6, 1)
    else
        self:AddNumText("#{SWXT_221213_211}", 6, 1)
    end
    self:AddNumText("#{SWXT_221213_219}", 11, 2)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshunanzhuhai_jiangxingyun:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:DispatchShengWangInfo(selfId, 2)
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

function oshunanzhuhai_jiangxingyun:JoinCamp(selfId, targetId, camp)
    self:SetMissionData(selfId, ScriptGlobal.LingWuLiuPai, 2)
    self:notify_tips(selfId, "Đã vào phe chú pháp - Thủ Tâm")
end

return oshunanzhuhai_jiangxingyun