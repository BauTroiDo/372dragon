local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_yeerniang = class("odali_yeerniang", script_base)
odali_yeerniang.script_id = 002003
odali_yeerniang.g_eventList = {200099, 200100}

odali_yeerniang.g_RSMissionId = 101
odali_yeerniang.g_ActivateMissionId = 37
odali_yeerniang.g_SongXinScriptId = 006668
odali_yeerniang.g_ShaGuaiScriptId = 006666
odali_yeerniang.g_XunWuScriptId = 006667
odali_yeerniang.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039650},
        ["script"] = odali_yeerniang.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039651},
        ["script"] = odali_yeerniang.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039652},
        ["script"] = odali_yeerniang.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039653},
        ["script"] = odali_yeerniang.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039654},
        ["script"] = odali_yeerniang.g_XunWuScriptId
    }
}

odali_yeerniang.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018300, 1018304, 1018308},
        ["script"] = odali_yeerniang.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018301, 1018305, 1018309},
        ["script"] = odali_yeerniang.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018302, 1018306, 1018310},
        ["script"] = odali_yeerniang.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018303, 1018307, 1018311},
        ["script"] = odali_yeerniang.g_SongXinScriptId
    }
}

odali_yeerniang.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1009000, 1009004, 1009008, 1009012, 1009016, 1009020, 1009024},
        ["script"] = odali_yeerniang.g_ShaGuaiScriptId
    },
    [1] = {
        ["misIndex"] = {1009001, 1009005, 1009009, 1009013, 1009017, 1009021, 1009025},
        ["script"] = odali_yeerniang.g_ShaGuaiScriptId
    },
    [2] = {
        ["misIndex"] = {1009002, 1009006, 1009010, 1009014, 1009018, 1009022, 1009026},
        ["script"] = odali_yeerniang.g_ShaGuaiScriptId
    },
    [3] = {
        ["misIndex"] = {1009003, 1009007, 1009011, 1009015, 1009019, 1009023, 1009027},
        ["script"] = odali_yeerniang.g_ShaGuaiScriptId
    }
}

function odali_yeerniang:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("  " .. PlayerName .. PlayerSex .. ", ta lạnh lùng nhìn ngươi ở #YĐại Lý#W thành đi đi lại lại, vội vã vàng. Luôn nhịn không được muốn hỏi ngươi, những việc ngươi làm, là vì chính ngươi, hay là vì người khác?")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "虚竹任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("虚竹任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("虚竹任务", 3, 1)
    end
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_yeerniang:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_yeerniang:OnEventRequest(selfId, targetId, arg, index)
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
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_XUZHU_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_XUZHU_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_XUZHU)
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

function odali_yeerniang:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_yeerniang:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_yeerniang:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_yeerniang:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_yeerniang:OnDie(selfId, killerId)
end

function odali_yeerniang:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_yeerniang:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return odali_yeerniang
