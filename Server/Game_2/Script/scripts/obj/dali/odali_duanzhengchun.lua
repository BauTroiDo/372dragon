local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_duanzhengchun = class("odali_duanzhengchun", script_base)
odali_duanzhengchun.script_id = 002004
odali_duanzhengchun.g_eventList = {200002, 200004, 200080, 200081, 200087, 200088, 200092, 200093, 200099, 200100}

odali_duanzhengchun.g_RSMissionId = 101
odali_duanzhengchun.g_ActivateMissionId = 8
odali_duanzhengchun.g_SongXinScriptId = 006668
odali_duanzhengchun.g_ShaGuaiScriptId = 006666
odali_duanzhengchun.g_XunWuScriptId = 006667
odali_duanzhengchun.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039450},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039451},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039452},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039453},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039454},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    }
}

odali_duanzhengchun.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018000},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018001},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018002, 1018008, 1018014, 1018020},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018003, 1018009, 1018015, 1018021},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1018004, 1018010, 1018016, 1018022},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1018005, 1018011, 1018017, 1018023},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1018006, 1018012, 1018018, 1018024, 1018027, 1018028, 1018031, 1018033},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    },
    [7] = {
        ["misIndex"] = {1018007, 1018013, 1018019, 1018025, 1018026, 1018029, 1018030, 1018032},
        ["script"] = odali_duanzhengchun.g_SongXinScriptId
    }
}

odali_duanzhengchun.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039455},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039456},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039457},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039458},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039459},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039460},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039461},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    },
    [7] = {
        ["misIndex"] = {1039462},
        ["script"] = odali_duanzhengchun.g_XunWuScriptId
    }
}

function odali_duanzhengchun:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. "#{OBJ_dali_0001}")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "段誉任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("段誉任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("段誉任务", 3, 1)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_duanzhengchun:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_duanzhengchun:OnEventRequest(selfId, targetId, arg, index)
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
        if (not self:IsMissionHaveDone(selfId, self.g_ActivateMissionId)) then
            return 0
        end
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYU_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYU_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_DUANYU)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then
            playerlevel = 90
        end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 60 then
            if playerlevel == 20 then
                mission = self.g_SongXinMissionList[0]
            elseif playerlevel == 30 then
                mission = self.g_SongXinMissionList[1]
            elseif playerlevel == 40 then
                mission = self.g_SongXinMissionList[2]
            elseif playerlevel == 50 then
                mission = self.g_SongXinMissionList[3]
            elseif playerlevel == 60 then
                mission = self.g_SongXinMissionList[4]
            elseif playerlevel == 70 then
                mission = self.g_SongXinMissionList[5]
            elseif playerlevel == 80 then
                mission = self.g_SongXinMissionList[6]
            elseif playerlevel == 90 then
                mission = self.g_SongXinMissionList[7]
            end
        elseif randtype <= 95 then
            if playerlevel == 20 then
                mission = self.g_ShaGuaiMissionList[0]
            elseif playerlevel == 30 then
                mission = self.g_ShaGuaiMissionList[1]
            elseif playerlevel == 40 then
                mission = self.g_ShaGuaiMissionList[2]
            elseif playerlevel == 50 then
                mission = self.g_ShaGuaiMissionList[3]
            elseif playerlevel == 60 then
                mission = self.g_ShaGuaiMissionList[4]
            elseif playerlevel == 70 then
                mission = self.g_ShaGuaiMissionList[5]
            elseif playerlevel == 80 then
                mission = self.g_ShaGuaiMissionList[6]
            elseif playerlevel == 90 then
                mission = self.g_ShaGuaiMissionList[7]
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

function odali_duanzhengchun:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_duanzhengchun:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_duanzhengchun:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_duanzhengchun:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_duanzhengchun:OnDie(selfId, killerId)
end

function odali_duanzhengchun:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_duanzhengchun:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return odali_duanzhengchun
