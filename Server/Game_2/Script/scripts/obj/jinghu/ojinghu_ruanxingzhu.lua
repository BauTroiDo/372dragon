local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojinghu_ruanxingzhu = class("ojinghu_ruanxingzhu", script_base)
ojinghu_ruanxingzhu.script_id = 005001
ojinghu_ruanxingzhu.g_eventList = {200099, 200100}

ojinghu_ruanxingzhu.g_lifeeventList = {713507, 713566, 713606}

ojinghu_ruanxingzhu.g_RSMissionId = 101
ojinghu_ruanxingzhu.g_ActivateMissionId = 15
ojinghu_ruanxingzhu.g_SongXinScriptId = 006668
ojinghu_ruanxingzhu.g_ShaGuaiScriptId = 006666
ojinghu_ruanxingzhu.g_XunWuScriptId = 006667
ojinghu_ruanxingzhu.g_RoundStorytelling = {
    [0] = {
        ["misIndex"] = {1039115},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039116},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039117},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039118},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039119},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    }
}

ojinghu_ruanxingzhu.g_SongXinMissionList = {
    [0] = {
        ["misIndex"] = {1010402},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [1] = {
        ["misIndex"] = {1010403},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [2] = {
        ["misIndex"] = {1010404},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [3] = {
        ["misIndex"] = {1010405},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [4] = {
        ["misIndex"] = {1010406},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [5] = {
        ["misIndex"] = {1010407},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [6] = {
        ["misIndex"] = {1010408},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    },
    [7] = {
        ["misIndex"] = {1010409},
        ["script"] = ojinghu_ruanxingzhu.g_SongXinScriptId
    }
}

ojinghu_ruanxingzhu.g_ShaGuaiMissionList = {
    [0] = {
        ["misIndex"] = {1039120},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [1] = {
        ["misIndex"] = {1039121},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [2] = {
        ["misIndex"] = {1039122},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [3] = {
        ["misIndex"] = {1039123},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [4] = {
        ["misIndex"] = {1039124},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [5] = {
        ["misIndex"] = {1039125},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    },
    [6] = {
        ["misIndex"] = {1039126},
        ["script"] = ojinghu_ruanxingzhu.g_XunWuScriptId
    }
}

ojinghu_ruanxingzhu.g_awardItems = {
    [1] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410004,
            [40] = 10410005,
            [50] = 10410006,
            [60] = 10410007,
            [70] = 10410008,
            [80] = 10410009,
            [90] = 10410010,
            [100] = 10410011
        }
    },
    [2] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410012,
            [40] = 10410013,
            [50] = 10410014,
            [60] = 10410015,
            [70] = 10410016,
            [80] = 10410017,
            [90] = 10410018,
            [100] = 10410019
        }
    },
    [3] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410020,
            [40] = 10410021,
            [50] = 10410022,
            [60] = 10410023,
            [70] = 10410024,
            [80] = 10410025,
            [90] = 10410026,
            [100] = 10410027
        }
    },
    [4] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410028,
            [40] = 10410029,
            [50] = 10410030,
            [60] = 10410031,
            [70] = 10410032,
            [80] = 10410033,
            [90] = 10410034,
            [100] = 10410035
        }
    }
}

ojinghu_ruanxingzhu.g_awardItemsNew = {
    [1] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410082,
            [40] = 10410083,
            [50] = 10410084,
            [60] = 10410085,
            [70] = 10410086,
            [80] = 10410087,
            [90] = 10410088,
            [100] = 10410089
        }
    },
    [2] = {
        ["odds"] = 50,
        ["itemIdxs"] = {
            [30] = 10410090,
            [40] = 10410091,
            [50] = 10410092,
            [60] = 10410093,
            [70] = 10410094,
            [80] = 10410095,
            [90] = 10410096,
            [100] = 10410097
        }
    }
}

function ojinghu_ruanxingzhu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Mỗi ngày ta đều nhớ về đoạn lang của ta, và hai đứa con khổ mệnh của chúng ta...")
    local missionIndex = self:GetScriptIDByMissionID(selfId, self.g_RSMissionId)
    if missionIndex ~= -1 then
        local missionName = self:TGetMissionName(missionIndex)
        if missionName ~= "阿朱任务" and self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
            self:AddNumText("阿朱任务", 3, 1)
        end
    elseif self:IsMissionHaveDone(selfId, self.g_ActivateMissionId) then
        self:AddNumText("阿朱任务", 3, 1)
    end
    local checkDay = self:IsMidAutumnPeriod(selfId)
    if checkDay and checkDay == 1 then
        self:AddNumText("#{TED_90305_1}", 11, 2)
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

function ojinghu_ruanxingzhu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ojinghu_ruanxingzhu:OnEventRequest(selfId, targetId, arg, index)
    for _, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
    for i, findId in pairs(self.g_lifeeventList) do
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
        local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_AZHU_LIMITI)
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
            self:SetMissionData(selfId, define.MD_ENUM.MD_JQXH_AZHU_LIMITI, 0)
        end
        local mission = self.g_RoundStorytelling[0]
        local relation = self:GetMissionData(selfId, define.MD_ENUM.MD_RELATION_AZHU)
        local playerlevel = self:GetLevel(selfId)
        if playerlevel >= 100 then
            playerlevel = 90
        end
        playerlevel = math.floor(playerlevel / 10) * 10
        local randtype = math.random(100)
        if randtype <= 20 then
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
        elseif randtype <= 40 then
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
    elseif num == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{MWQ_227_2}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function ojinghu_ruanxingzhu:OnMissionAccept(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function ojinghu_ruanxingzhu:OnMissionRefuse(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function ojinghu_ruanxingzhu:OnMissionContinue(selfId, targetId, missionScriptId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function ojinghu_ruanxingzhu:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    for _, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

function ojinghu_ruanxingzhu:OnDie(selfId, killerId)
end

function ojinghu_ruanxingzhu:OnModEvent_Submit(selfId, targetId, missionIndex)
    local checkDay = self:IsMidAutumnPeriod(selfId)
    if not checkDay or checkDay ~= 1 then
        return 0
    end
    local mdLocation, _, _ = self:TGetRelationShipAwardInfo(missionIndex)
    if not mdLocation or mdLocation ~= define.MD_ENUM.MD_RELATION_AZHU then
        return 0
    end
    local value = self:GetMissionData(selfId, mdLocation)
    if not value or value < 1000 then
        self:NotifyMessage(selfId, targetId)
        return 0
    end
    local count = self:GetMissionData(selfId, define.MD_ENUM.MD_AZHU_TUERDUO_COUNT)
    if not count then
        return 0
    end
    count = count + 1
    self:SetMissionData(selfId, define.MD_ENUM.MD_AZHU_TUERDUO_COUNT, count)
    local testValue = 50
    local hit = 0
    for i = 0, 16 do
        if testValue == count then
            hit = 1
            break
        end
        testValue = testValue * 2
    end
    if hit ~= 1 then
        self:NotifyMessage(selfId, targetId)
        return 0
    end
    if count == 50 then
        self:GiveSmallRabbitEar(selfId)
    else
        self:GiveRabbitEar(selfId)
    end
    return 1
end

function ojinghu_ruanxingzhu:IsMidAutumnPeriod(selfId)
    return 1
end

function ojinghu_ruanxingzhu:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ojinghu_ruanxingzhu:NotifyMessage(selfId, targetId)
    local nDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_JQXH_AZHU_LIMITI)
    local nCount = math.floor(nDayCount / 100000)
    if (nCount == 10 or nCount == 20 or nCount == 30 or nCount == 40) then
        local msg =
            string.format("[%s]:#W#{_INFOUSR%s} #GA Châu#P#{JINGHU_RUANXINZHU}", self:GetSceneName(), self:GetName(selfId))
        self:LuaFnNpcChat(targetId, 1, msg)
    end
    if (nCount == 50) then
        local msg = string.format("#W#{_INFOUSR%s} #GA Châu#P#{JINGHU_RUANXINZHU}", self:GetName(selfId))
        msg = gbk.fromutf8(msg)
        self:BroadMsgByChatPipe(selfId, msg, 2)
    end
end

function ojinghu_ruanxingzhu:GiveRabbitEar(selfId)
    local totalOdds = 0
    for _, item in pairs(self.g_awardItems) do
        totalOdds = totalOdds + item["odds"]
    end
    if totalOdds < 1 then
        return 0
    end
    local selItem
    local randValue = math.random(1, totalOdds)
    randValue = randValue - 1
    for _, item in pairs(self.g_awardItems) do
        if item["odds"] >= randValue then
            selItem = item
            break
        end
        randValue = randValue - item["odds"]
    end
    if not selItem then
        return 0
    end
    local level = self:GetLevel(selfId)
    if not level then
        return 0
    end
    if level >= 110 then
        level = 100
    end
    local idx = math.floor(level / 10)
    idx = idx * 10
    local itemIdx = selItem["itemIdxs"][idx]
    if not itemIdx then
        return 0
    end
    local itemAddPos
    self:BeginAddItem()
    itemAddPos = self:AddItem(itemIdx, 1)
    local ret = self:EndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
        local selfName = self:GetName(selfId)
        local itemTransfer
        if itemAddPos then
            itemTransfer = self:GetItemTransfer(selfId, itemAddPos)
        end
        if itemTransfer and selfName then
            selfName = gbk.fromutf8(selfName)
            local msg =
                "#YNguyễn Tinh Trúc:#W #{_INFOUSR" ..
                selfName ..
                    "}#P#{tuerduo}#{_INFOMSG" .. itemTransfer .. "}#Pđội lên#W #{_INFOUSR" .. selfName .. "}#Ptrên đầu để tỏ lòng cảm tạ!"
            self:BroadMsgByChatPipe(selfId, msg, 4)
        end
    end
end

function ojinghu_ruanxingzhu:GiveSmallRabbitEar(selfId)
    local totalOdds = 0
    for _, item in pairs(self.g_awardItemsNew) do
        totalOdds = totalOdds + item["odds"]
    end
    if totalOdds < 1 then
        return 0
    end
    local selItem
    local randValue = math.random(1, totalOdds)
    randValue = randValue - 1
    for _, item in pairs(self.g_awardItemsNew) do
        if item["odds"] >= randValue then
            selItem = item
            break
        end
        randValue = randValue - item["odds"]
    end
    if not selItem then
        return 0
    end
    local level = self:GetLevel(selfId)
    if not level then
        return 0
    end
    if level >= 110 then
        level = 100
    end
    local idx = math.floor(level / 10)
    idx = idx * 10
    local itemIdx = selItem["itemIdxs"][idx]
    if not itemIdx then
        return 0
    end
    local itemAddPos
    self:BeginAddItem()
    itemAddPos = self:AddItem(itemIdx, 1)
    local ret = self:EndAddItem(selfId)
    if ret and ret > 0 then
        self:AddItemListToHuman(selfId)
        local selfName = self:GetName(selfId)
        local itemTransfer
        if itemAddPos then
            itemTransfer = self:GetItemTransfer(selfId, itemAddPos)
        end
        if itemTransfer and selfName then
            selfName = gbk.fromutf8(selfName)
            local msg = "#YNguyễn Tinh Trúc:#W #{_INFOUSR" ..  selfName ..  "}#P#{tuerduo2}#{_INFOMSG" .. itemTransfer .. "}#Pgửi tặng#W #{_INFOUSR" .. selfName .. "}#P#{tuerduo3}"
            self:BroadMsgByChatPipe(selfId, msg, 4)
        end
    end
end

function ojinghu_ruanxingzhu:OnMissionCheck(selfId, targetId, scriptId, index1, index2, index3, indexpet, missionIndex)
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

return ojinghu_ruanxingzhu
