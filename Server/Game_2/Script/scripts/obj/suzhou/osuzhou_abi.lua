local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_abi = class("osuzhou_abi", script_base)
osuzhou_abi.script_id = 001022
osuzhou_abi.g_eventList = {200083, 200084, 200099, 200100}

osuzhou_abi.g_RSMissionId = 101
osuzhou_abi.g_ActivateMissionId = 15
osuzhou_abi.g_SongXinScriptId = 006668
osuzhou_abi.g_ShaGuaiScriptId = 006666
osuzhou_abi.g_XunWuScriptId = 006667
osuzhou_abi.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039500},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039501},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039502},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039503},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039504},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    }
}

osuzhou_abi.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018560},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018561},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018562},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018563},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1018564},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1018565},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1018566},
        ["script"] = osuzhou_abi.g_SongXinScriptId
    }
}

osuzhou_abi.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039505},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039506},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039507},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039508},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039509},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039510},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039511},
        ["script"] = osuzhou_abi.g_XunWuScriptId
    }
}

function osuzhou_abi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Không biết vì sao, những ngày công tử ở Tô Châu luôn buồn bã không vui.")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "阿碧任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("阿碧任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("阿碧任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_abi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_abi:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_eventList) do
        if arg== findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
    local num = index
    if num == 1 then
        if self:IsHaveMission(selfId, self.g_RSMissionId) then
            self:NotifyFailBox(selfId, targetId, "    Ồ, ngươi đã có Khác nhiệm vụ quan hệ anh hùng (nhiệm vụ tuần Khuyên cốt truyện) còn chưa hoàn thành, xin hoàn thành sau đó hãy đến tìm ta!")
            return
        end
        if (not self:IsMissionHaveDone(selfId, self.g_ActivateMissionId)) then
            return 0
        end
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_ABI_LIMITI)
        local nCount = nDayCount // 100000
        local nTime = nDayCount % 100000
        local nDayTime = nTime
        local CurTime = self:GetDayTime()
        local CurDaytime = CurTime
        if nDayTime == CurDaytime then
            if nCount >= 50 then
                self:BeginEvent(self.script_id)
                self:AddText("  Hôm nay đã làm phiền ngươi quá nhiều việc rồi, thật sự là áy náy, ngày mai lại làm phiền ngươi vậy!")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        else
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_ABI_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_ABI)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then
            playerlevel = 90
        end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 60 then
            if playerlevel == 30 then
                mission = self.g_SongXinMissionList[0]
            elseif playerlevel == 40 then
                mission = self.g_SongXinMissionList[1]
            elseif playerlevel == 50 then
                mission = self.g_SongXinMissionList[2]
            elseif playerlevel == 60 then
                mission = self.g_SongXinMissionList[3]
            elseif playerlevel == 70 then
                mission = self.g_SongXinMissionList[4]
            elseif playerlevel == 80 then
                mission = self.g_SongXinMissionList[5]
            elseif playerlevel == 90 then
                mission = self.g_SongXinMissionList[6]
            end
        elseif randtype <= 95 then
            if playerlevel == 30 then
                mission = self.g_ShaGuaiMissionList[0]
            elseif playerlevel == 40 then
                mission = self.g_ShaGuaiMissionList[1]
            elseif playerlevel == 50 then
                mission = self.g_ShaGuaiMissionList[2]
            elseif playerlevel == 60 then
                mission = self.g_ShaGuaiMissionList[3]
            elseif playerlevel == 70 then
                mission = self.g_ShaGuaiMissionList[4]
            elseif playerlevel == 80 then
                mission = self.g_ShaGuaiMissionList[5]
            elseif playerlevel == 90 then
                mission = self.g_ShaGuaiMissionList[6]
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
        self:CallScriptFunction(
            mission["script"],
            "OnDefaultEvent",
            selfId,
            targetId,
            mission["misIndex"][math.random(#(mission["misIndex"]))]
        )
        return
    end
end

function osuzhou_abi:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_abi:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_abi:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_abi:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_abi:OnDie(selfId, killerId)
end

function osuzhou_abi:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_abi:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
    for i, eventId in pairs(self.g_XunWuScriptId) do
        if eventId == scriptId then
            self:CallScriptFunction(
                scriptId,
                "OnMissionCheck",
                selfId,
                targetId,
                scriptId,
                index1,
                index2,
                index3,
                indexpet,
                missionIndex
            )
            return 1
        end
    end
end

return osuzhou_abi
