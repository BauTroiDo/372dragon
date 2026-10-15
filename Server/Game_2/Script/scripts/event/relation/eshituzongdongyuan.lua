local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local eshituzongdongyuan = class("eshituzongdongyuan", script_base)
eshituzongdongyuan.script_id = 806020
eshituzongdongyuan.g_Validate_Time_Mail = {["startTime"] = 20080703, ["endTime"] = 20080814}
eshituzongdongyuan.g_Validate_Time_Change = {["startTime"] = 20080703, ["endTime"] = 20080821}
eshituzongdongyuan.g_Need_Item_List = {20310109, 20310108, 20310107, 20310106}
eshituzongdongyuan.g_Prize_List = {
    {["id"] = 30309713, ["count"] = 1, ["rand"] = 400, ["bind"] = 0},
    {["id"] = 30309716, ["count"] = 1, ["rand"] = 160, ["bind"] = 0},
    {["id"] = 30309717, ["count"] = 1, ["rand"] = 80, ["bind"] = 0},
    {["id"] = 30900006, ["count"] = 1, ["rand"] = 920, ["bind"] = 1},
    {["id"] = 30008034, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900045, ["count"] = 1, ["rand"] = 100, ["bind"] = 1},
    {["id"] = 30008021, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008022, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008023, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008024, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008025, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30505034, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505035, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505036, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505037, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505038, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505039, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505040, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505041, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30008016, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30008002, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30008003, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30501017, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30501023, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30503018, ["count"] = 1, ["rand"] = 1100, ["bind"] = 1},
    {["id"] = 30503019, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900009, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30900011, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30900010, ["count"] = 1, ["rand"] = 140, ["bind"] = 1},
    {["id"] = 30008009, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900015, ["count"] = 1, ["rand"] = 800, ["bind"] = 1},
    {["id"] = 30900016, ["count"] = 1, ["rand"] = 200, ["bind"] = 1}
}

eshituzongdongyuan.g_Prize_List_long = {
    {["id"] = 30309713, ["count"] = 1, ["rand"] = 500, ["bind"] = 0},
    {["id"] = 30309716, ["count"] = 1, ["rand"] = 200, ["bind"] = 0},
    {["id"] = 30309717, ["count"] = 1, ["rand"] = 100, ["bind"] = 0},
    {["id"] = 30900006, ["count"] = 1, ["rand"] = 860, ["bind"] = 1},
    {["id"] = 30008034, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900045, ["count"] = 1, ["rand"] = 100, ["bind"] = 1},
    {["id"] = 30008021, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008022, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008023, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008024, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30008025, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30505034, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505035, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505036, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505037, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505038, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505039, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505040, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30505041, ["count"] = 1, ["rand"] = 125, ["bind"] = 0},
    {["id"] = 30008016, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30008002, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30008003, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30501017, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30501023, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30503018, ["count"] = 1, ["rand"] = 1000, ["bind"] = 1},
    {["id"] = 30503019, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900009, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30900011, ["count"] = 1, ["rand"] = 500, ["bind"] = 1},
    {["id"] = 30900010, ["count"] = 1, ["rand"] = 140, ["bind"] = 1},
    {["id"] = 30008009, ["count"] = 1, ["rand"] = 200, ["bind"] = 1},
    {["id"] = 30900015, ["count"] = 1, ["rand"] = 800, ["bind"] = 1},
    {["id"] = 30900016, ["count"] = 1, ["rand"] = 200, ["bind"] = 1}
}

eshituzongdongyuan.g_Prize_List_30_master = {
    {["type"] = 0, ["value"] = 20310106},
    {["type"] = 0, ["value"] = 20310107},
    {["type"] = 1, ["value"] = 300000}
}

eshituzongdongyuan.g_Prize_List_30_prentice = {
    {["type"] = 0, ["value"] = 30008027}
}

eshituzongdongyuan.g_Prize_List_45_master = {
    {["type"] = 0, ["value"] = 20310106},
    {["type"] = 0, ["value"] = 20310107},
    {["type"] = 1, ["value"] = 300000}
}

eshituzongdongyuan.g_Prize_List_45_prentice = {
    {["type"] = 0, ["value"] = 31000006}
}

eshituzongdongyuan.g_Impact_List = {8058, 8059, 8060, 8061}

function eshituzongdongyuan:IsValidateTime_Mail()
    local curDayTime = self:GetTime2Day()
    if (curDayTime >= self.g_Validate_Time_Mail["startTime"]) and (curDayTime <= self.g_Validate_Time_Mail["endTime"]) then
        return 1
    elseif curDayTime > self.g_Validate_Time_Mail["endTime"] then
        return 2
    end
    return 0
end

function eshituzongdongyuan:IsValidateTime_Change()
    local curDayTime = self:GetTime2Day()
    if
        (curDayTime >= self.g_Validate_Time_Change["startTime"]) and
            (curDayTime <= self.g_Validate_Time_Change["endTime"])
     then
        return 1
    elseif curDayTime >= self.g_Validate_Time_Change["startTime"] then
        return 2
    end
    return 0
end

function eshituzongdongyuan:OnPlayerLogin(selfId)
    if (self:IsValidateTime_Mail() == 1 and self:GetLevel(selfId) >= 10) then
        local flag = self:GetMissionFlag(selfId, ScriptGlobal.MF_ShiTuHelp_Mail)
        if (flag == 0) then
            self:LuaFnSendSystemMail(self:GetName(selfId), "#{STZDY_20080513_04}")
            self:SetMissionFlag(selfId, ScriptGlobal.MF_ShiTuHelp_Mail, 1)
        end
    end
end

function eshituzongdongyuan:OnPlayerLevelUp(selfId)
    if self:IsValidateTime_Mail() == 0 then
        return
    end
    if not self:LuaFnHaveMaster(selfId) and self:GetMissionFlag(selfId, ScriptGlobal.MF_ShiTu_ChuShi_Flag) ~= 1 then
        return
    end
    local CurLevel = self:GetLevel(selfId)
    local masterGuid = self:LuaFnGetMasterGUID(selfId)
    if CurLevel == 30 then
        local prenticeMsg = string.format("#{STZDY_20080513_05}%d#{STZDY_20080513_06}", CurLevel)
        local masterMsg =
            string.format(
            "#{STZDY_20080513_07}%s#{STZDY_20080513_08}%d#{STZDY_20080513_09}",
            self:GetName(selfId),
            CurLevel
        )
        self:LuaFnSendSystemMail(self:GetName(selfId), prenticeMsg)
        self:LuaFnSendMailToGUID(masterGuid, masterMsg)
        return
    end
    if CurLevel == 45 then
        local prenticeMsg = string.format("#{STZDY_20080513_05}%d#{STZDY_20080513_06}", CurLevel)
        local masterMsg =
            string.format(
            "#{STZDY_20080513_07}%s#{STZDY_20080513_08}%d#{STZDY_20080513_09}",
            self:GetName(selfId),
            CurLevel
        )
        self:LuaFnSendSystemMail(self:GetName(selfId), prenticeMsg)
        self:LuaFnSendMailToGUID(masterGuid, masterMsg)
        return
    end
end

function eshituzongdongyuan:OnDefaultEvent(selfId, targetId, index)
    if self:IsValidateTime_Change() == 0 then
        self:NotifyMsg(selfId, targetId, "Tạm thời không có hoạt động đổi thưởng.")
    end
    if (index == 1) then
        self:BeginEvent(self.script_id)
        self:AddText("#{STZDY_20080513_19}")
        self:AddNumText("Tham gia rút thăm trúng thưởng", 6, 3)
        self:AddNumText("Lĩnh Thưởng Thăng Cấp Sư Đồ", 6, 4)
        self:AddNumText("Đổi Buff Luyện Sư Đồ Đoạt Bảo", 6, 5)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif (index == 2) then
        self:BeginEvent(self.script_id)
        self:AddText("#{STZDY_20080513_45}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif (index == 3) then
        local level = self:GetLevel(selfId)
        if level < 10 then
            self:BeginEvent(self.script_id)
            self:AddText("#{STZDY_20080513_21}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local dayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHITUZONGDONGYUAN_PRIZE_COUNT)
        local curDayTime = self:GetTime2Day()
        if curDayTime == math.floor(dayCount / 100) then
            if dayCount - curDayTime * 100 >= 1 then
                self:BeginEvent(self.script_id)
                self:AddText("#{STZDY_20080513_22}")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        end
        for i = 1, #(self.g_Need_Item_List) do
            if self:LuaFnGetAvailableItemCount(selfId, self.g_Need_Item_List[i]) < 1 then
                self:BeginEvent(self.script_id)
                self:AddText("#{STZDY_20080513_27}")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return
            end
        end
        local prizeList
        if self:IsValidateTime_Change() == 1 then
            prizeList = self.g_Prize_List
        elseif self:IsValidateTime_Change() == 2 then
            prizeList = self.g_Prize_List_long
        end
        if prizeList == nil or #(prizeList) < 1 then
            return
        end
        local randMax = 0
        for i = 1, #(prizeList) do
            randMax = randMax + prizeList[i]["rand"]
        end
        local randIndex = math.random(randMax)
        if randMax < 1 then
            return
        end
        for i = 1, #(prizeList) do
            if randIndex <= prizeList[i]["rand"] then
                if self:LuaFnGetPropertyBagSpace(selfId) < prizeList[i]["count"] then
                    self:NotifyTips(selfId, "#{STZDY_20080513_24}")
                    return
                end
                self:LuaFnBeginAddItem()
                self:LuaFnAddItem(prizeList[i]["id"], prizeList[i]["count"])
                local ret = self:LuaFnEndAddItem(selfId)
                if ret then
                    for i = 1, #(self.g_Need_Item_List) do
                        if not self:LuaFnDelAvailableItem(selfId, self.g_Need_Item_List[i], 1) then
                            self:BeginEvent(self.script_id)
                            self:AddText("#{STZDY_20080513_27}")
                            self:EndEvent()
                            self:DispatchEventList(selfId, targetId)
                            return
                        end
                    end
                    dayCount = self:GetMissionData(selfId, ScriptGlobal.MD_SHITUZONGDONGYUAN_PRIZE_COUNT)
                    curDayTime = self:GetTime2Day()
                    if curDayTime == math.floor(dayCount / 100) then
                        self:SetMissionData(selfId, ScriptGlobal.MD_SHITUZONGDONGYUAN_PRIZE_COUNT, dayCount + 1)
                    else
                        self:SetMissionData(selfId, ScriptGlobal.MD_SHITUZONGDONGYUAN_PRIZE_COUNT, curDayTime * 100 + 1)
                    end
                    local bagPos = -1
                    for count = 1, prizeList[i]["count"] do
                        bagPos = self:TryRecieveItem(selfId, prizeList[i]["id"], true)
                    end
                    self:AuditShiTuZongDongYuan(selfId, " GetAward_Random: id=" .. prizeList[i]["id"])
                    if
                        prizeList[i]["id"] == 30309713 or prizeList[i]["id"] == 30309716 or
                            prizeList[i]["id"] == 30309717 or
                            prizeList[i]["id"] == 30008034 or
                            prizeList[i]["id"] == 30900045
                     then
                        local scrollMsg =
                            string.format(
                            "@*;SrvMsg;SCA:#{STZDY_20080513_10}#{_INFOUSR%s}#{STZDY_20080513_11}#{_INFOMSG%s}#{STZDY_20080513_12}",
                            gbk.fromutf8(self:GetName(selfId)),
                            self:GetBagItemTransfer(selfId, bagPos)
                        )
                        self:BroadMsgByChatPipe(selfId, scrollMsg, 4)
                    else
                        self:SetMissionFlag(selfId, ScriptGlobal.MF_ActiveWenZhouCard, 1)
                        local scrollMsg =
                            string.format(
                            "#{STZDY_20080513_13}#{_INFOUSR%s}#{STZDY_20080513_14}#{_INFOMSG%s}#{STZDY_20080513_15}",
                            gbk.fromutf8(self:GetName(selfId)),
                            self:GetBagItemTransfer(selfId, bagPos)
                        )
                        self:BroadMsgByChatPipe(selfId, scrollMsg, 4)
                    end
                    local msg =
                        string.format(
                        "#{STZDY_20080513_25}#{_INFOMSG%s}#{STZDY_20080513_26}",
                        self:GetBagItemTransfer(selfId, bagPos)
                    )
                    self:BeginEvent(self.script_id)
                    self:AddText(msg)
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                end
                return
            else
                randIndex = randIndex - prizeList[i]["rand"]
            end
        end
    elseif (index == 4) then
        self:BeginEvent(self.script_id)
        self:AddText("#{STZDY_20080513_28}")
        self:AddNumText("Lĩnh phần thưởng cấp 30", 6, 6)
        self:AddNumText("Lĩnh phần thưởng cấp 45", 6, 7)
        self:AddNumText("Tạm biệt", 6, 8)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif (index == 5) then
        self:BeginEvent(self.script_id)
        self:AddText("#{STZDY_20080513_43}")
        self:AddNumText("Tiến hành đổi", 6, 9)
        self:AddNumText("Vẫn chưa chuẩn bị xong.", 6, 8)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif (index == 6) or (index == 7) then
        local sNotifyMsg = "#{STZDY_20080513_31}"
        local sNotifyTips = "#{STZDY_20080513_32}"
        if self:GetMissionFlag(selfId, ScriptGlobal.MF_ShiTu_ChuShi_Flag) == 1 then
            if index == 6 then
                sNotifyMsg = "#{STZDY_20080513_29}"
                sNotifyTips = "#{STZDY_20080513_30}"
            else
                sNotifyMsg = "#{STZDY_20080513_41}"
                sNotifyTips = "#{STZDY_20080513_42}"
            end
        end
        if not self:LuaFnHasTeam(selfId) then
            self:NotifyMsg(selfId, targetId, sNotifyMsg)
            self:NotifyTips(selfId, sNotifyTips)
            return
        end
        if self:LuaFnGetTeamSize(selfId) ~= 2 then
            self:NotifyMsg(selfId, targetId, sNotifyMsg)
            self:NotifyTips(selfId, sNotifyTips)
            return
        end
        local numMem = self:GetNearTeamCount(selfId)
        if numMem ~= self:LuaFnGetTeamSize(selfId) then
            self:NotifyMsg(selfId, targetId, sNotifyMsg)
            self:NotifyTips(selfId, sNotifyTips)
            return
        end
        local otherId = self:LuaFnGetTeamSceneMember(selfId, 1)
        if not self:LuaFnIsMasterEver(selfId, otherId) and not self:LuaFnIsMasterEver(otherId, selfId) then
            self:NotifyMsg(selfId, targetId, sNotifyMsg)
            self:NotifyTips(selfId, sNotifyTips)
            return
        end
        if self:LuaFnGetFriendPoint(selfId, otherId) < 500 or self:LuaFnGetFriendPoint(otherId, selfId) < 500 then
            self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_33}")
            self:NotifyTips(selfId, "#{STZDY_20080513_34}")
            return
        end
        local levelReq
        local strTip = ""
        local strMsg = ""
        local prizeList_master
        local prizeList_prentice
        local MF_master
        local MF_prentice
        local strAwardLevel
        if index == 6 then
            levelReq = 30
            strTip = "#{STZDY_20080513_39}"
            strMsg = "#{STZDY_20080513_40}"
            prizeList_master = self.g_Prize_List_30_master
            prizeList_prentice = self.g_Prize_List_30_prentice
            MF_master = ScriptGlobal.MF_ShiTuHelp_30_master
            MF_prentice = ScriptGlobal.MF_ShiTuHelp_30_prentice
            strAwardLevel = 30
        elseif index == 7 then
            levelReq = 45
            strTip = "Đồ đệ lên đến cấp 45 mới có thể lĩnh phần thưởng!"
            strMsg = "Đồ đệ phải lên đến cấp 45 mới có thể lĩnh!"
            prizeList_master = self.g_Prize_List_45_master
            prizeList_prentice = self.g_Prize_List_45_prentice
            MF_master = ScriptGlobal.MF_ShiTuHelp_45_master
            MF_prentice = ScriptGlobal.MF_ShiTuHelp_45_prentice
            strAwardLevel = 45
        end
        if self:LuaFnIsMasterEver(otherId, selfId) then
            if self:GetLevel(otherId) < levelReq then
                self:NotifyMsg(selfId, targetId, strTip)
                self:NotifyTips(selfId, strMsg)
                return
            end
            local flag = self:GetMissionFlag(otherId, MF_master)
            if flag == 1 then
                self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_35}")
                self:NotifyTips(selfId, "#{STZDY_20080513_35}")
                return
            end
            if (self:GivePrize(selfId, prizeList_master) == 0) then
                self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_36}")
                self:NotifyTips(selfId, "#{STZDY_20080513_37}")
                return
            end
            self:AuditShiTuZongDongYuan(selfId, " GetAward_Master_" .. strAwardLevel)
            self:SetMissionFlag(otherId, MF_master, 1)
            self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_38}")
        elseif self:LuaFnIsMasterEver(selfId, otherId) then
            if self:GetLevel(selfId) < levelReq then
                self:NotifyMsg(selfId, targetId, strTip)
                self:NotifyTips(selfId, strMsg)
                return
            end
            local flag = self:GetMissionFlag(selfId, MF_prentice)
            if flag == 1 then
                self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_35}")
                self:NotifyTips(selfId, "#{STZDY_20080513_35}")
                return
            end
            if (self:GivePrize(selfId, prizeList_prentice) == 0) then
                self:NotifyMsg(selfId, targetId, "#{STL_0623_01}")
                self:NotifyTips(selfId, "#{STZDY_20080513_37}")
                return
            end
            self:AuditShiTuZongDongYuan(selfId, " GetAward_Prentice_" .. strAwardLevel)
            self:SetMissionFlag(selfId, MF_prentice, 1)
            self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_38}")
        end
    elseif (index == 8) then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    elseif (index == 9) then
        for i = 1, #(self.g_Need_Item_List) do
            if self:LuaFnGetAvailableItemCount(selfId, self.g_Need_Item_List[i]) > 0 then
                if self:LuaFnDelAvailableItem(selfId, self.g_Need_Item_List[i], 1) then
                    local buffId = self.g_Impact_List[math.random(#(self.g_Impact_List))]
                    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, buffId, 0)
                    self:AuditShiTuZongDongYuan(selfId, " GetAward_Buff")
                    self:NotifyMsg(selfId, targetId, "Đổi thành công.")
                    return
                end
            end
        end
        self:NotifyMsg(selfId, targetId, "#{STZDY_20080513_44}")
        return
    end
end

function eshituzongdongyuan:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsValidateTime_Change() == 0 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, "Hoạt động Đoạt Bảo Sư Đồ Luyện", 6, 1)
    caller:AddNumTextWithTarget(self.script_id, "Trợ giúp Hoạt động Đoạt Bảo Sư Đồ Luyện", 11, 2)
end

function eshituzongdongyuan:NotifyTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function eshituzongdongyuan:NotifyMsg(selfId, targetId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function eshituzongdongyuan:GivePrize(selfId, pList)
    self:LuaFnBeginAddItem()
    for i = 1, #(pList) do
        if pList[i]["type"] == 0 then
            self:LuaFnAddItem(pList[i]["value"], 1)
        end
    end
    local ret = self:LuaFnEndAddItem(selfId)
    if ret then
        self:AddItemListToHuman(selfId)
    else
        return 0
    end
    for i = 1, #(pList) do
        if pList[i]["type"] == 1 then
            self:AddExp(selfId, pList[i]["value"])
        end
    end
    return 1
end

return eshituzongdongyuan
