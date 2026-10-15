local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_yelvdashi = class("oluoyang_yelvdashi", script_base)
oluoyang_yelvdashi.script_id = 000031
oluoyang_yelvdashi.g_eventList = {200099, 200100}

oluoyang_yelvdashi.g_lifeeventList = {713505, 713564, 713604}

oluoyang_yelvdashi.g_RSMissionId = 101
oluoyang_yelvdashi.g_ActivateMissionId = 23
oluoyang_yelvdashi.g_SongXinScriptId = 006668
oluoyang_yelvdashi.g_ShaGuaiScriptId = 006666
oluoyang_yelvdashi.g_XunWuScriptId = 006667
oluoyang_yelvdashi.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039020},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039021},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039022},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039023},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039024},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    }
}

oluoyang_yelvdashi.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018050, 1018056},
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018051, 1018057, 1018062},
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018052, 1018058, 1018063, 1018067, 1018071},
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018053, 1018059, 1018064, 1018068, 1018072, 1018075},
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {
            1018054, 1018060, 1018065, 1018069, 1018073, 1018076, 1018078,
            1018080
        },
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {
            1018055, 1018061, 1018066, 1018070, 1018074, 1018077, 1018079,
            1018081, 1018082, 1018083, 1018084
        },
        ["script"] = oluoyang_yelvdashi.g_SongXinScriptId
    }
}

oluoyang_yelvdashi.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039000},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039001},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039002},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039003},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039004},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039005},
        ["script"] = oluoyang_yelvdashi.g_XunWuScriptId
    }
}

function oluoyang_yelvdashi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hoàng thượng phái chúng ta đến Lạc Dương đâu phải để du ngoạn.")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "萧峰任务" and
            self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("萧峰任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("萧峰任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    for i, eventId in pairs(self.g_lifeeventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_yelvdashi:OnEventRequest(selfId, targetId, arg, index)
    for _, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
    for i, findId in pairs(self.g_lifeeventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId,
                                    index, self.g_scriptId)
            return
        end
    end
    local num = index
    if num == 1 then
        if self:IsHaveMission(selfId, self.g_RSMissionId) then
            self:NotifyFailBox(selfId, targetId,
                               "    Ồ, ngươi đã có Khác nhiệm vụ quan hệ anh hùng (nhiệm vụ tuần Khuyên cốt truyện) còn chưa hoàn thành, xin hoàn thành sau đó hãy đến tìm ta!")
            return
        end
        if (not self:IsMissionHaveDone(selfId, self.g_ActivateMissionId)) then
            return 0
        end
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_XIAOFENG_LIMITI)
        local nCount = math.floor(nDayCount / 100000)
        local nTime = (nDayCount % 100000)
        local nDayTime = nTime
        local CurTime = self:GetDayTime()
        local CurDaytime = CurTime
        if nDayTime == CurDaytime then
            if nCount >= 50 then
                self:BeginEvent(self.script_id)
                self:AddText(
                    "  Hôm nay đã làm phiền ngươi quá nhiều việc rồi, thật sự là áy náy, ngày mai lại làm phiền ngươi vậy!")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        else
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_XIAOFENG_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_XIAOFENG)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then playerlevel = 90 end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 20 then
            if playerlevel == 40 then
                mission = self.g_SongXinMissionList[0]
            elseif playerlevel == 50 then
                mission = self.g_SongXinMissionList[1]
            elseif playerlevel == 60 then
                mission = self.g_SongXinMissionList[2]
            elseif playerlevel == 70 then
                mission = self.g_SongXinMissionList[3]
            elseif playerlevel == 80 then
                mission = self.g_SongXinMissionList[4]
            elseif playerlevel == 90 then
                mission = self.g_SongXinMissionList[5]
            end
        elseif randtype <= 40 then
            if playerlevel == 40 then
                mission = self.g_ShaGuaiMissionList[0]
            elseif playerlevel == 50 then
                mission = self.g_ShaGuaiMissionList[1]
            elseif playerlevel == 60 then
                mission = self.g_ShaGuaiMissionList[2]
            elseif playerlevel == 70 then
                mission = self.g_ShaGuaiMissionList[3]
            elseif playerlevel == 80 then
                mission = self.g_ShaGuaiMissionList[4]
            elseif playerlevel == 90 then
                mission = self.g_ShaGuaiMissionList[5]
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
        self:CallScriptFunction(mission["script"], "OnDefaultEvent", selfId,
                                targetId, mission["misIndex"][math.random(
                                    #(mission["misIndex"]))])
        return
    end
end

function oluoyang_yelvdashi:OnMissionAccept(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret =
                self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function oluoyang_yelvdashi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:OnDefaultEvent(selfId, targetId)
            return
        end
    end
end

function oluoyang_yelvdashi:OnMissionContinue(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId,
                                    targetId)
            return
        end
    end
end

function oluoyang_yelvdashi:OnMissionSubmit(selfId, targetId, missionScriptId,
                                            selectRadioId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId,
                                    targetId, selectRadioId)
            return
        end
    end
end

function oluoyang_yelvdashi:OnDie(selfId, killerId) end

function oluoyang_yelvdashi:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_yelvdashi:OnMissionCheck(selfId, targetId, scriptId, index1,
                                           index2, index3, indexpet,
                                           missionIndex)
    for i, eventId in pairs(self.g_XunWuScriptId) do
        if eventId == scriptId then
            self:CallScriptFunction(scriptId, "OnMissionCheck", selfId,
                                    targetId, scriptId, index1, index2, index3,
                                    indexpet, missionIndex)
            return 1
        end
    end
end

return oluoyang_yelvdashi
