local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_murongfu = class("osuzhou_murongfu", script_base)
osuzhou_murongfu.script_id = 001015
osuzhou_murongfu.g_eventList = {200013, 200085, 200099, 200100}

osuzhou_murongfu.g_RSMissionId = 101
osuzhou_murongfu.g_ActivateMissionId = 37
osuzhou_murongfu.g_SongXinScriptId = 006668
osuzhou_murongfu.g_ShaGuaiScriptId = 006666
osuzhou_murongfu.g_XunWuScriptId = 006667
osuzhou_murongfu.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039300},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039301},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039302},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039303},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039304},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    }
}

osuzhou_murongfu.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018200, 1018204, 1018208, 1018212, 1018216, 1018220, 1018224, 1018228, 1018232},
        ["script"] = osuzhou_murongfu.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018201, 1018205, 1018209, 1018213, 1018217, 1018221, 1018225, 1018229, 1018233},
        ["script"] = osuzhou_murongfu.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018202, 1018206, 1018210, 1018214, 1018218, 1018222, 1018226, 1018230, 1018234},
        ["script"] = osuzhou_murongfu.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018203, 1018207, 1018211, 1018215, 1018219, 1018223, 1018227, 1018231, 1018235},
        ["script"] = osuzhou_murongfu.g_SongXinScriptId
    }
}

osuzhou_murongfu.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039305, 1039309},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039306, 1039310},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039307, 1039311},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039308, 1039312},
        ["script"] = osuzhou_murongfu.g_XunWuScriptId
    }
}

function osuzhou_murongfu:UpdateEventList(selfId, targetId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  Vị này" .. PlayerSex .. ", ngươi có từng gặp một vị Lạt-ma Thổ Phồn nào gần đây không?")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "慕容复任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("慕容复任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("慕容复任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_murongfu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_murongfu:OnEventRequest(selfId, targetId, arg, index)
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
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_MURONGFU_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_MURONGFU_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_MURONGFU)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then
            playerlevel = 90
        end
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

function osuzhou_murongfu:OnMissionAccept(selfId, targetId, missionScriptId)
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

function osuzhou_murongfu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_murongfu:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_murongfu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function osuzhou_murongfu:OnDie(selfId, killerId)
end

function osuzhou_murongfu:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_murongfu:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return osuzhou_murongfu
