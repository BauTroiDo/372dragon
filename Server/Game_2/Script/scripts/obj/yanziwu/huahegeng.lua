local class = require "class"
local define = require "define"
local script_base = require "script_base"
local huahegeng = class("huahegeng", script_base)
huahegeng.script_id = 402249
huahegeng.g_eventList = {}

function huahegeng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nStep = self:LuaFnGetCopySceneData_Param(8)
    self:AddText("#{dazhan_yzw_007}")
    if self:GetName(targetId) == "华赫艮" then
        if nStep == 15 then
            self:AddNumText("Từ địa đạo tiến vào Yến Tử Ổ", 9, 1)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function huahegeng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function huahegeng:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:SetPos(selfId, 154, 96)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

function huahegeng:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId, targetId)
            end
            return
        end
    end
end

function huahegeng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function huahegeng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function huahegeng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function huahegeng:OnDie()
end

return huahegeng
