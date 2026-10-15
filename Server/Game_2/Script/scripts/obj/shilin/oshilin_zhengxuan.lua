local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshilin_zhengxuan = class("oshilin_zhengxuan", script_base)
oshilin_zhengxuan.script_id = 026000
oshilin_zhengxuan.g_eventList = {212103, 212104}
function oshilin_zhengxuan:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  $N, ta biết ngươi, danh tiếng của ngươi đã lan khắp Đại Lý rồi, rất vui khi được gặp ngươi ở Thạch Lâm này. Nhưng, hiện giờ Thạch Lâm là một nơi vô cùng nguy hiểm, ngươi làm việc gì cũng phải cẩn thận.")
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    if self:IsHaveMission(selfId, 602) then
        self:AddNumText("Câu chuyện của Tuyệt Vọng Chi Địa", 6, 1)
        self.nDescIndex = 1
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshilin_zhengxuan:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function oshilin_zhengxuan:OnEventRequest(selfId, targetId, arg, index)
    local arg = index
    if arg == 6 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 415, 45, 34)
        return
    end
    if arg == self.script_id then
        self:BeginEvent(self.script_id)
        if self.nDescIndex == 1 then
            self:AddText("#{Lua_Shilin_002}")
            self:AddNumText("Cái gì? Ôn dịch đáng sợ! Rồi sau đó?", 8, 1)
        elseif self.nDescIndex == 2 then
            self:AddText("#{Lua_Shilin_003}")
            self:AddNumText("Xem ra là Yển Sư đã cứu Viên Nguyệt Thôn, đúng không?", 8, 1)
        elseif self.nDescIndex == 3 then
            self:AddText("#{Lua_Shilin_004}")
        end
        self.nDescIndex = self.nDescIndex + 1
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        if self.nDescIndex == 4 then
            local misIndex = self:GetMissionIndexByID(selfId, 602)
            local num0 = self:GetMissionParam(selfId, misIndex, 0)
            if num0 < 1 then
                self:SetMissionByIndex(selfId, misIndex, 0, 1)
                self:BeginEvent(self.script_id)
                self:AddText("Đã nghe xong câu chuyện của Trịnh Huyền: 1/1")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        end
    end
    if not self:IsHaveMission(selfId, 602) then
        self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
        end
    end
end

function oshilin_zhengxuan:OnMissionAccept(selfId, targetId, missionScriptId)
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

function oshilin_zhengxuan:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function oshilin_zhengxuan:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function oshilin_zhengxuan:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function oshilin_zhengxuan:OnDie(selfId, killerId) end

return oshilin_zhengxuan
