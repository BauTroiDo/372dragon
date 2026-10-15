local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_lusanniang = class("odali_lusanniang", script_base)
odali_lusanniang.script_id = 002042
odali_lusanniang.g_eventList = {210209, 210287}

function odali_lusanniang:UpdateEventList(selfId, targetId)
    local Menpai = self:LuaFnGetMenPai(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Sư muội"
    else
        PlayerSex = "Sư đệ"
    end
    self:BeginEvent(self.script_id)
    if Menpai == 9 then
        self:AddText("#{OBJ_dali_0021}")
    elseif Menpai == 4 then
        self:AddText("  " .. PlayerSex .. ", để Tam Nương xem xem. Ha ha, #Yvõ#W công của ngươi tiến bộ thật nhanh, người cũng càng thêm tuấn tú, vẫn là #YNga My#W sơn của nước dưỡng người a.")
    else
        self:AddText("  Đã lâu không gặp ngươi, với thiên tư của ngươi như vậy, đáng tiếc không tu hành ở #YNga My#W, chung quy quanh thân lệ khí, thật đáng than, thật đáng tiếc.")
    end
    if self:GetLevel(selfId) >= 10 then
        self:AddNumText("Đi #YNga My#W sơn xem xem", 9, 0)
    end
    local misIndex = self:GetMissionIndexByID(selfId, 1060)
    if self:IsHaveMission(selfId, 1060) then
        if self:GetMissionParam(selfId, misIndex, 0) < 1 and self:GetMissionParam(selfId, misIndex, 2) == 2 then
            self:AddNumText("Đây là thư của sư huynh ta gửi cho ngươi", 4, 1)
        end
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_lusanniang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_lusanniang:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:IsHaveMission(selfId, 4021) then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi mang Tào Vận Hàng Khoang, Dịch trạm chúng ta không thể cung cấp dịch vụ truyền tống cho ngươi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 15, 89, 144)
        end
    elseif index == 1 then
        local misIndex = self:GetMissionIndexByID(selfId, 1060)
        self:DelItem(selfId, 40002115, 1)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:BeginEvent(self.script_id)
        self:AddText("Xin trở về nói với sư huynh #YTuệ Phương#W, thư của huynh ấy ta đã nhận được, cảm tạ ngươi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:BeginEvent(self.script_id)
        self:AddText("Nhiệm vụ hoàn thành!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MnepaiDesc_emei_1}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MnepaiDesc_emei_2}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MnepaiDesc_emei_3}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 13 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MnepaiDesc_emei_4}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif index == 14 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XSRW_200909_20}")
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

function odali_lusanniang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_lusanniang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_lusanniang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_lusanniang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_lusanniang:OnDie(selfId, killerId)
end

return odali_lusanniang
