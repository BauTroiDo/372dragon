local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_qiaozhiguang = class("oluoyang_qiaozhiguang", script_base)
oluoyang_qiaozhiguang.script_id = 000126
oluoyang_qiaozhiguang.g_shoptableindex = 34
oluoyang_qiaozhiguang.g_eventList = {1018714,1018715}

function oluoyang_qiaozhiguang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QZG_80919_1}")
    self:AddNumText("Giới thiệu Thương nhân", 11, 1)
    self:AddNumText("Mở tiệm", 7, 2)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_qiaozhiguang:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHANGREN_JIESHAO_02}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 2 then
        if (self:LuaFnGetAvailableItemCount(selfId, 40002000) == 1) then
            self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
        else
            self:BeginEvent(self.script_id)
            self:AddText(
                "Các hạ không có Thương nhân Ngân phiếu, giao dịch giữa ta và ngươi từ đâu mà bàn?")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,arg,index)
            return
        end
    end
end

function oluoyang_qiaozhiguang:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept",
                                          selfId, targetId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId,
                                        targetId, missionScriptId)
            end
            return
        end
    end
end

function oluoyang_qiaozhiguang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function oluoyang_qiaozhiguang:OnMissionContinue(selfId, targetId,
                                                 missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_qiaozhiguang:OnMissionSubmit(selfId, targetId,
                                               missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_qiaozhiguang:OnDie(selfId, killerId) end

return oluoyang_qiaozhiguang
