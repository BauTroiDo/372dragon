local class = require "class"
local define = require "define"
local ScriptGloabl = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local odunhuang_jiumozhi = class("odunhuang_jiumozhi", script_base)
odunhuang_jiumozhi.script_id = 008011
odunhuang_jiumozhi.g_eventList = {200099, 200100}
odunhuang_jiumozhi.g_RSMissionId = 101
odunhuang_jiumozhi.g_ActivateMissionId = 37
odunhuang_jiumozhi.g_SongXinScriptId = 006668
odunhuang_jiumozhi.g_ShaGuaiScriptId = 006666
odunhuang_jiumozhi.g_XunWuScriptId = 006667
odunhuang_jiumozhi.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039550},
        ["script"] = odunhuang_jiumozhi.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039551},
        ["script"] = odunhuang_jiumozhi.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039552},
        ["script"] = odunhuang_jiumozhi.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039553},
        ["script"] = odunhuang_jiumozhi.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039554},
        ["script"] = odunhuang_jiumozhi.g_XunWuScriptId
    }

}

odunhuang_jiumozhi.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018530, 1018534, 1018538},
        ["script"] = odunhuang_jiumozhi.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018531, 1018535, 1018539},
        ["script"] = odunhuang_jiumozhi.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018532, 1018536, 1018540},
        ["script"] = odunhuang_jiumozhi.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018533, 1018537, 1018541},
        ["script"] = odunhuang_jiumozhi.g_SongXinScriptId
    }

}

odunhuang_jiumozhi.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1009100},
        ["script"] = odunhuang_jiumozhi.g_ShaGuaiScriptId
    },
    [1] = {
        ["misIndex"] = {1009101},
        ["script"] = odunhuang_jiumozhi.g_ShaGuaiScriptId
    },
    [2] = {
        ["misIndex"] = {1009102},
        ["script"] = odunhuang_jiumozhi.g_ShaGuaiScriptId
    },
    [3] = {
        ["misIndex"] = {1009103},
        ["script"] = odunhuang_jiumozhi.g_ShaGuaiScriptId
    }

}

function odunhuang_jiumozhi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thí chủ phong trần mệt mỏi đến Ngọc Môn Quan, là muốn đến Tây Hạ quốc sao? Xin tiểu tăng mạo muội, thí chủ ấn đường phát ám, chuyến đi Tây Hạ quốc này tất gặp hung nhiều cát ít, chi bằng sớm quay về Trung Nguyên, mới là thượng sách.")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "鸠摩智任务" and
            self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("鸠摩智任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("鸠摩智任务", 3, 1)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odunhuang_jiumozhi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odunhuang_jiumozhi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    local num = index
    if num == 1 then
        if self:IsHaveMission(selfId, self.g_RSMissionId) then
            self:NotifyFailBox(selfId, targetId, "    Ồ, ngươi đã có Khác nhiệm vụ quan hệ anh hùng (nhiệm vụ tuần Khuyên cốt truyện) còn chưa hoàn thành, xin hoàn thành sau đó hãy đến tìm ta!")
            return
        end
        if not self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            return 0
        end
        local nDayCount = self:GetMissionData(selfId, ScriptGloabl.MD_JQXH_JIUMOZHI_LIMITI)
        local nCount = math.floor(nDayCount / 100000)
        local nTime = math.mod(nDayCount, 100000)
        local nDayTime = nTime
        local CurTime = self:GetDayTime()
        local CurDaytime = CurTime
        if nDayTime == CurDaytime then
            if nCount >= 50 then
                self:BeginEvent(self.script_id)
                self:AddText( "  Hôm nay đã làm phiền ngươi quá nhiều việc rồi, thật sự là áy náy, ngày mai lại làm phiền ngươi vậy!")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        else
            self:SetMissionData(selfId, ScriptGloabl.MD_JQXH_JIUMOZHI_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, ScriptGloabl.MD_RELATION_JIUMOZHI)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then playerlevel = 90 end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 60 then
            if playerlevel == 60 then
                mission = self.g_SongXinMissionList[0]
            elseif playerlevel == 70 then
                mission = self.g_SongXinMissionList[1]
            elseif playerlevel == 80 then
                mission = self.g_SongXinMissionList[2]
            elseif playerlevel == 90 then
                mission = self.g_SongXinMissionList[3]
            end
        elseif randtype <= 95 then
            if playerlevel == 60 then
                mission = self.g_ShaGuaiMissionList[0]
            elseif playerlevel == 70 then
                mission = self.g_ShaGuaiMissionList[1]
            elseif playerlevel == 80 then
                mission = self.g_ShaGuaiMissionList[2]
            elseif playerlevel == 90 then
                mission = self.g_ShaGuaiMissionList[3]
            end
        elseif randtype <= 100 then
            if relation <= 999 then
                mission = self.g_RoundStorytelling[0]
            elseif relation <= 1999 then
                mission = self.g_RoundStorytelling[1]
            elseif relation <= 3999 then
                mission = self.g_RoundStorytelling[2]
            elseif relation <= 6499 then
                mission = self.g_RoundStorytelling[3]
            elseif relation <= 9999 then
                mission = self.g_RoundStorytelling[4]
            end
        end
        self:CallScriptFunction(mission["script"], "OnDefaultEvent", selfId, targetId, mission["misIndex"][math.random(#(mission["misIndex"]))])
        return
    end
end

function odunhuang_jiumozhi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odunhuang_jiumozhi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odunhuang_jiumozhi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odunhuang_jiumozhi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odunhuang_jiumozhi:OnDie(selfId, killerId) end

function odunhuang_jiumozhi:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odunhuang_jiumozhi:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
    for i, eventId in pairs(self.g_XunWuScriptId) do
        if eventId == scriptId then
            self:CallScriptFunction(scriptId, "OnMissionCheck", selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
            return 1
        end
    end
end

return odunhuang_jiumozhi
