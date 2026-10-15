local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_wangfuren = class("osuzhou_wangfuren", script_base)
osuzhou_wangfuren.script_id = 001021
osuzhou_wangfuren.g_eventList = {229022, 200099, 200100}

osuzhou_wangfuren.g_RSMissionId = 101
osuzhou_wangfuren.g_ActivateMissionId = 15
osuzhou_wangfuren.g_SongXinScriptId = 006668
osuzhou_wangfuren.g_ShaGuaiScriptId = 006666
osuzhou_wangfuren.g_XunWuScriptId = 006667
osuzhou_wangfuren.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039200},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039201},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039202},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039203},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039204},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    }
}

osuzhou_wangfuren.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018400, 1018407, 1018414, 1018421, 1018428, 1018435, 1018442, 1018449},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018401, 1018408, 1018415, 1018422, 1018429, 1018436, 1018443, 1018450},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018402, 1018409, 1018416, 1018423, 1018430, 1018437, 1018444, 1018451},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018403, 1018410, 1018417, 1018424, 1018431, 1018438, 1018445, 1018452},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1018404, 1018411, 1018418, 1018425, 1018432, 1018439, 1018446, 1018453},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1018405, 1018412, 1018419, 1018426, 1018433, 1018440, 1018447, 1018454},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1018406, 1018413, 1018420, 1018427, 1018434, 1018441, 1018448, 1018455},
        ["script"] = osuzhou_wangfuren.g_SongXinScriptId
    }
}

osuzhou_wangfuren.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039205},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039206},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039207},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039208},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039209},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039210},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039211},
        ["script"] = osuzhou_wangfuren.g_XunWuScriptId
    }
}

function osuzhou_wangfuren:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0008}")
    self:AddNumText("Nhiệm vụ Liên Hoàn tửu quán", 11, 10)
    self:AddNumText("#{JZBZ_081031_02}", 11, 11)
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "王语嫣任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("王语嫣任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("王语嫣任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_wangfuren:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_wangfuren:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_070}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    elseif index == 11 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JZBZ_081031_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
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
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_WANGYUYAN_LIMITI)
        local nCount = math.floor(nDayCount / 100000)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_WANGYUYAN_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_WANGYUYAN)
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

function osuzhou_wangfuren:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_wangfuren:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_wangfuren:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_wangfuren:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_wangfuren:OnDie(selfId, killerId)
end

function osuzhou_wangfuren:OnCharacterTimer(selfId, dataId, nowtime)
end

function osuzhou_wangfuren:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_wangfuren:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return osuzhou_wangfuren
