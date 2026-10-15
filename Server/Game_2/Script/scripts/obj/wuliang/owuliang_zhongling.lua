local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owuliang_zhongling = class("owuliang_zhongling", script_base)
owuliang_zhongling.script_id = 006001
owuliang_zhongling.g_eventList = {200099, 200100}

owuliang_zhongling.g_RSMissionId = 101
owuliang_zhongling.g_ActivateMissionId = 8
owuliang_zhongling.g_SongXinScriptId = 006668
owuliang_zhongling.g_ShaGuaiScriptId = 006666
owuliang_zhongling.g_XunWuScriptId = 006667
owuliang_zhongling.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039600},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039601},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039602},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039603},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039604},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    }
}

owuliang_zhongling.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018360},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018361},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018362},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018363},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1018364},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1018365},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1018366},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    },
    [7] = {
        ["misIndex"] = {1018367},
        ["script"] = owuliang_zhongling.g_SongXinScriptId
    }
}

owuliang_zhongling.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039605},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039606},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039607},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039608},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039609},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039610},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039611},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    },
    [7] = {
        ["misIndex"] = {1039612},
        ["script"] = owuliang_zhongling.g_XunWuScriptId
    }
}

function owuliang_zhongling:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  Người ta trúng độc rồi, không muốn chạy tới chạy lui mà. Không biết Đoàn ca ca có tìm được nương thân ta không, sao còn chưa đến cứu ta a!")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "钟灵任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("钟灵任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("钟灵任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuliang_zhongling:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function owuliang_zhongling:OnEventRequest(selfId, targetId, arg, index)
    for _, findId in pairs(self.g_eventList) do
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
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_ZHONGLING_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_ZHONGLING_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_ZHONGLING)
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

function owuliang_zhongling:OnMissionAccept(selfId, targetId, missionScriptId)
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

function owuliang_zhongling:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function owuliang_zhongling:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function owuliang_zhongling:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function owuliang_zhongling:OnDie(selfId, killerId)
end

function owuliang_zhongling:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owuliang_zhongling:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return owuliang_zhongling
