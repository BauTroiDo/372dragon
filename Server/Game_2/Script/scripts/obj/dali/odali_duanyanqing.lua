local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_duanyanqing = class("odali_duanyanqing", script_base)
odali_duanyanqing.script_id = 002016
odali_duanyanqing.g_eventList = {210275,210274,210280,210225, 210226, 210227, 210228, 210229, 200099, 200100}

odali_duanyanqing.g_RSMissionId = 101
odali_duanyanqing.g_ActivateMissionId = 8
odali_duanyanqing.g_SongXinScriptId = 006668
odali_duanyanqing.g_ShaGuaiScriptId = 006666
odali_duanyanqing.g_XunWuScriptId = 006667
odali_duanyanqing.g_RewardsId = 10155001
odali_duanyanqing.g_BoundRewardsId = 10155004
odali_duanyanqing.g_cdLimid = 1000
odali_duanyanqing.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039400},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039401},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039402},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039403},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039404},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    }
}

odali_duanyanqing.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1018100, 1018108, 1018116, 1018124, 1018132, 1018140, 1018148},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1018101, 1018109, 1018117, 1018125, 1018133, 1018141, 1018149},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1018102, 1018110, 1018118, 1018126, 1018134, 1018142, 1018150},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1018103, 1018111, 1018119, 1018127, 1018135, 1018143, 1018151},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1018104, 1018112, 1018120, 1018128, 1018136, 1018144, 1018152},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1018105, 1018113, 1018121, 1018129, 1018137, 1018145, 1018153},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1018106, 1018114, 1018122, 1018130, 1018138, 1018146, 1018154},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    },
    [7] = {
        ["misIndex"] = {1018107, 1018115, 1018123, 1018131, 1018139, 1018147, 1018155},
        ["script"] = odali_duanyanqing.g_SongXinScriptId
    }
}

odali_duanyanqing.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039405},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039406},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039407},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039408},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039409},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039410},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039411},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    },
    [7] = {
        ["misIndex"] = {1039412},
        ["script"] = odali_duanyanqing.g_XunWuScriptId
    }
}

function odali_duanyanqing:UpdateEventList(selfId, targetId)
    local PlayerName = self:GetName(selfId)
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Cô nương"
    else
        PlayerSex = "Thiếu hiệp"
    end
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0006}")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "段延庆任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("段延庆任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("段延庆任务", 3, 1)
    end
    for _, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_duanyanqing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function odali_duanyanqing:OnEventRequest(selfId, targetId, arg, index)
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
        if not self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            return 0
        end
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_DUANYANQING)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then
            playerlevel = 90
        end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 75 then
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

function odali_duanyanqing:OnMissionAccept(selfId, targetId, missionScriptId)
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

function odali_duanyanqing:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function odali_duanyanqing:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function odali_duanyanqing:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function odali_duanyanqing:OnDie(selfId, killerId)
end

function odali_duanyanqing:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_duanyanqing:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

function odali_duanyanqing:NPCTalkOnFirstSubmission(selfId, missionIndex, isDone)
    local ret = self:IsQualified(selfId, missionIndex)
    if ret == 0 then
        return 0
    end
    local countValue = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_COUNT)
    if not countValue then
        return 0
    end
    local adCount = countValue % self.g_cdLimid
    local msCount = math.floor(countValue / self.g_cdLimid)
    if isDone == 0 then
        if adCount == 0 and msCount == 0 then
            local PlayerName = self:GetName(selfId)
            local msg = string.format("#{_INFOUSR%s}#{AQFC_090115_03}", PlayerName)
            self:AddText(msg)
            return 1
        end
    else
        if adCount == 1 and msCount == 1 then
            local PlayerName = self:GetName(selfId)
            local msg = string.format("#{_INFOUSR%s}#{AQFC_090115_03}", PlayerName)
            self:AddText(msg)
            return 1
        end
    end
    return 0
end

function odali_duanyanqing:IsQualified(selfId, missionIndex)
    local mdLocation, _, _ = self:TGetRelationShipAwardInfo(missionIndex)
    if not mdLocation or mdLocation ~= define.MD_ENUM.MD_RELATION_DUANYANQING then
        return 0
    end
    local value = self:GetMissionData(selfId, mdLocation)
    if not value or value < 480 then
        return 0
    end
    return 1
end

function odali_duanyanqing:OnAddRewards(selfId, missionIndex)
    local ret = self:IsQualified(selfId, missionIndex)
    if ret == 0 then
        return 0
    end
    local countValue = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_COUNT)
    if not countValue then
        return 0
    end
    local adCount = countValue % self.g_cdLimid
    local msCount = math.floor(countValue / self.g_cdLimid)
    if adCount == 0 and msCount == 0 then
        self:AddItem(self.g_BoundRewardsId, 1)
        return 1
    else
        local testCount = 50 * self:myPower(2, adCount - 1)
        if adCount > 0 and msCount + 1 == testCount then
            self:AddItem(self.g_RewardsId, 1)
            return 1
        end
    end
    return 0
end

function odali_duanyanqing:OnMissionSubmitionSuccess(selfId, targetId, missionIndex)
    local ret = self:IsQualified(selfId, missionIndex)
    if ret == 0 then
        return 0
    end
    local countValue = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_COUNT)
    if not countValue then
        return 0
    end
    local adCount = countValue % self.g_cdLimid
    local msCount = math.floor(countValue / self.g_cdLimid)
    msCount = msCount + 1
    if msCount == 1 then
        local bagIndex = self:RecevieRewards(selfId, targetId, self.g_BoundRewardsId)
        if bagIndex < 0 then
            return 0
        end
        adCount = adCount + 1
    else
        local testCount = 50 * self:myPower(2, adCount - 1)
        if testCount == msCount then
            local bagIndex = self:RecevieRewards(selfId, targetId, self.g_RewardsId)
            if bagIndex < 0 then
                return 0
            end
            local ItemTransfer = self:GetBagItemTransfer(selfId, bagIndex)
            local PlayerName = self:GetName(selfId)
            PlayerName = gbk.fromutf8(PlayerName)
            local msg = string.format("#{AQ_05}#{_INFOUSR%s}#{AQ_06}#{_INFOMSG%s}#{AQ_07}", PlayerName, ItemTransfer)
            self:BroadMsgByChatPipe(selfId, msg, 4)
            adCount = adCount + 1
        end
    end
    local newCountValue = math.floor(msCount * self.g_cdLimid) + adCount
    self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_DUANYANQING_COUNT, newCountValue)
    return 1
end

function odali_duanyanqing:RecevieRewards(selfId, targetId, ItemId)
    if ItemId == self.g_BoundRewardsId then
        local guid = self:LuaFnObjId2Guid(selfId)
        self:ScriptGlobal_AuditGeneralLog(define.LUAAUDIT_FEIHUANGSHI_BOUND, guid)
    else
        local guid = self:LuaFnObjId2Guid(selfId)
        self:ScriptGlobal_AuditGeneralLog(define.LUAAUDIT_FEIHUANGSHI, guid)
    end
    local pos = self:GetItemBagPos(selfId, ItemId, 0)
    if pos >= 0 then
        local msg = string.format("#{AQFC_090115_02}")
        self:NotifyTips(selfId, msg)
    end
    return pos
end

function odali_duanyanqing:NotifyTips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function odali_duanyanqing:myPower(n, m)
    if m == 0 then
        return 1
    else
        return n * self:myPower(n, m - 1)
    end
end

return odali_duanyanqing
