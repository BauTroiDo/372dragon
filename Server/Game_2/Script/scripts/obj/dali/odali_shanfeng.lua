local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_jianning = class("odali_jianning", script_base)
odali_jianning.script_id = 002095
odali_jianning.g_eventList = {210209}

function odali_jianning:UpdateEventList(selfId, targetId)
    local Menpai = self:LuaFnGetMenPai(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Nha đầu"
    else
        PlayerSex = "Huynh đệ"
    end
    self:BeginEvent(self.script_id)
    if Menpai == 9 then
        self:AddText("#{XKDRZ_240619_01}")
    elseif Menpai == 11 then
        self:AddText("  " .. PlayerSex .. ", đã lâu không gặp, #Yvõ#W công của ngươi lại tinh tiến thêm không ít. Thế nào, tục ngữ có câu chim sẻ cũng có ngày về tổ, thỉnh thoảng cũng nên về Ác Nhân Cốc lộ mặt đi chứ.")
    else
        self:AddText("#{XKDRZ_240619_05}")
    end
    if self:GetLevel(selfId) >= 10 then
        self:AddNumText("Đến Ác Nhân Cốc xem thử", 9, 0)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_jianning:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_jianning:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:IsHaveMission(selfId, 4021) then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi mang Tào Vận Hàng Khoang, Dịch trạm chúng ta không thể cung cấp dịch vụ truyền tống cho ngươi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 987, 123, 151)
        end
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XKDRZ_240619_47}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XKDRZ_240619_48}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XKDRZ_240619_49}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 13 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XKDRZ_240619_50}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 14 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XKDRZ_240626_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        for i, findId in pairs(self.g_eventList) do
            if arg == findId then
                self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
                return
            end
        end
    end
end

function odali_jianning:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function odali_jianning:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_jianning:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_jianning:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_jianning:OnDie(selfId, killerId)
end

return odali_jianning
