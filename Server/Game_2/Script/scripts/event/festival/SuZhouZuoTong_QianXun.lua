local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local SuZhouZuoTong_QianXun = class("SuZhouZuoTong_QianXun", script_base)
SuZhouZuoTong_QianXun.script_id = 229024
SuZhouZuoTong_QianXun.g_Position_X = 129.2676
SuZhouZuoTong_QianXun.g_Position_Z = 213.0914
SuZhouZuoTong_QianXun.g_SceneID = 1
SuZhouZuoTong_QianXun.g_AccomplishNPC_Name = "左桐"
SuZhouZuoTong_QianXun.g_MissionId = 421
SuZhouZuoTong_QianXun.g_MissionIdNext = 421
SuZhouZuoTong_QianXun.g_Name = "左桐"
SuZhouZuoTong_QianXun.g_MissionKind = 12
SuZhouZuoTong_QianXun.g_MissionLevel = 10
SuZhouZuoTong_QianXun.g_IfMissionElite = 0
SuZhouZuoTong_QianXun.g_IsMissionOkFail = 0
SuZhouZuoTong_QianXun.g_MissionName = "Thiên Tầm"
SuZhouZuoTong_QianXun.g_MissionInfo = "#{QX_20071129_026}"
SuZhouZuoTong_QianXun.g_MissionTarget = "#{QX_20071129_025}"
SuZhouZuoTong_QianXun.g_ContinueInfo = "#{QIANXUN_INFO_19}"
SuZhouZuoTong_QianXun.g_MissionComplete = "#{QX_20071129_039}"
SuZhouZuoTong_QianXun.g_MaxRound = 10
SuZhouZuoTong_QianXun.g_ControlScript = 001066
SuZhouZuoTong_QianXun.g_Mission_IsComplete = 0
SuZhouZuoTong_QianXun.g_Mission_RoundNum = 5
SuZhouZuoTong_QianXun.g_Mission_ItemIdx = 6
SuZhouZuoTong_QianXun.g_QianXunMission_IDX = 120
SuZhouZuoTong_QianXun.g_MissionInfo_IDX = 121
SuZhouZuoTong_QianXun.g_FuQiMission_IDX = 131
SuZhouZuoTong_QianXun.g_JieBaiMission_IDX = 132
SuZhouZuoTong_QianXun.g_ShiTuMission_IDX = 133
SuZhouZuoTong_QianXun.g_EventList = {}
SuZhouZuoTong_QianXun.g_Impact_Accept_Mission = 47
SuZhouZuoTong_QianXun.g_PlayerSlow_LVL = 10
SuZhouZuoTong_QianXun.g_Activity_DayTime = 5
SuZhouZuoTong_QianXun.g_ItemId =
{
    { ["id"] = 40004435, ["num"] = 1 },
    { ["id"] = 40004436, ["num"] = 1 },
    { ["id"] = 40004437, ["num"] = 1 },
    { ["id"] = 40004438, ["num"] = 1 }
}
SuZhouZuoTong_QianXun.g_Impact_Complete_Mission = 43
SuZhouZuoTong_QianXun.g_scenePosInfoList = {
    {
        ["sceneId"] = 7,
        ["scenename"] = "Kiếm Các",
        ["PosName"] = "Kiếm Môn Điệp Thúy",
        ["PosX"] = 130,
        ["PosY"] = 140,
        ["PosR"] = 10,
        ["Area"] = 711
    }
    , {
    ["sceneId"] = 8,
    ["scenename"] = "Đôn Hoàng",
    ["PosName"] = "Hãn Hải Cầu Phật",
    ["PosX"] = 267,
    ["PosY"] = 251,
    ["PosR"] = 10,
    ["Area"] = 811
}
, {
    ["sceneId"] = 5,
    ["scenename"] = "Kính Hồ",
    ["PosName"] = "Ngọc Đới Lâm Phong",
    ["PosX"] = 35,
    ["PosY"] = 265,
    ["PosR"] = 10,
    ["Area"] = 511
}
, {
    ["sceneId"] = 4,
    ["scenename"] = "Thái Hồ",
    ["PosName"] = "Vũ Tạ Ca Đài",
    ["PosX"] = 155,
    ["PosY"] = 255,
    ["PosR"] = 10,
    ["Area"] = 411
}
, {
    ["sceneId"] = 3,
    ["scenename"] = "Tung Sơn",
    ["PosName"] = "Giang sơn tú lệ",
    ["PosX"] = 280,
    ["PosY"] = 80,
    ["PosR"] = 10,
    ["Area"] = 311
}
,
    {
        ["sceneId"] = 30,
        ["scenename"] = "Tây Hồ",
        ["PosName"] = "Một thoáng Hổ Bào",
        ["PosX"] = 170,
        ["PosY"] = 230,
        ["PosR"] = 10,
        ["Area"] = 3011
    }
    ,
    {
        ["sceneId"] = 31,
        ["scenename"] = "Long Tuyền",
        ["PosName"] = "Phi lưu trực hạ",
        ["PosX"] = 270,
        ["PosY"] = 280,
        ["PosR"] = 10,
        ["Area"] = 3111
    }
    ,
    {
        ["sceneId"] = 25,
        ["scenename"] = "Thương Sơn",
        ["PosName"] = "Tựa nước trôi năm tháng",
        ["PosX"] = 260,
        ["PosY"] = 110,
        ["PosR"] = 10,
        ["Area"] = 2512
    }
    , {
    ["sceneId"] = 32,
    ["scenename"] = "Võ Di",
    ["PosName"] = "Sương khóa Nhị Kiều",
    ["PosX"] = 50,
    ["PosY"] = 180,
    ["PosR"] = 10,
    ["Area"] = 3211
}
, {
    ["sceneId"] = 0,
    ["scenename"] = "Lạc Dương",
    ["PosName"] = "Kim Thành Thang Trì",
    ["PosX"] = 50,
    ["PosY"] = 220,
    ["PosR"] = 10,
    ["Area"] = 11
}
}
SuZhouZuoTong_QianXun.g_BonusFuJie = 20310010
SuZhouZuoTong_QianXun.g_BonusItem = { { ["ItemID01"] = 10410118, ["ItemID02"] = 10410108 }
, { ["ItemID01"] = 10410119, ["ItemID02"] = 10410109 }
, { ["ItemID01"] = 10410120, ["ItemID02"] = 10410110 }
, { ["ItemID01"] = 10410121, ["ItemID02"] = 10410111 }
, { ["ItemID01"] = 10410122, ["ItemID02"] = 10410112 }
, { ["ItemID01"] = 10410123, ["ItemID02"] = 10410113 }
, { ["ItemID01"] = 10410124, ["ItemID02"] = 10410114 }
, { ["ItemID01"] = 10410125, ["ItemID02"] = 10410115 }
, { ["ItemID01"] = 10410126, ["ItemID02"] = 10410116 }
, { ["ItemID01"] = 10410127, ["ItemID02"] = 10410117 }
}
SuZhouZuoTong_QianXun.g_BonusEXP_List = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 17436, 18416, 19369, 20328, 21326, 22297, 23274,
    24291, 25280, 26309, 53543, 55908, 58352, 60811, 63284, 65707, 68209, 70727, 73259, 75739, 126150, 130300, 134474,
    138564, 142784, 147029, 151297, 155479, 159795, 164133, 245746, 252138, 258454, 264914, 271409, 277827, 284391,
    290989, 297509, 304176, 310878, 317500, 324270, 331075, 337914, 344672, 351580, 358523, 365383, 372394, 379440,
    386403, 393517, 400666, 407731, 414948, 422200, 429367, 436688, 444043, 451433, 458736, 466195, 473688, 481093,
    488655, 496251, 503759, 511424, 519123, 526733, 534501, 542303, 550140, 557887, 565792, 573732, 581581, 589590,
    597633, 605584, 613696, 621842, 629895, 638110, 646360, 654515, 662834, 671187, 679574, 679574, 679574, 679574,
    679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574, 679574,
    679574, 679574, 679574 }
function SuZhouZuoTong_QianXun:OnDefaultEvent(selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local key = index
    if key == self.g_QianXunMission_IDX then
        self:BeginEvent(self.script_id)
        self:AddText("#{QX_20071129_023}")
        self:AddNumText("Phu thê lĩnh nhiệm vụ", 6, self.g_FuQiMission_IDX)
        self:AddNumText("Kết bái lĩnh nhiệm vụ", 6, self.g_JieBaiMission_IDX)
        self:AddNumText("Sư đồ lĩnh nhiệm vụ", 6, self.g_ShiTuMission_IDX)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == self.g_MissionInfo_IDX then
        self:TalkInfo(selfId, targetId, "#{QIANXUN_INFO_02}")
        return 0
    elseif key == self.g_FuQiMission_IDX or key == self.g_JieBaiMission_IDX or key == self.g_ShiTuMission_IDX then
        if key == self.g_FuQiMission_IDX then
            if self:CheckMission_FuQi(selfId) == 0 then
                return 0
            end
        elseif key == self.g_JieBaiMission_IDX then
            if self:CheckMission_JieBai(selfId) == 0 then
                return 0
            end
        elseif key == self.g_ShiTuMission_IDX then
            if self:CheckMission_ShiTu(selfId) == 0 then
                return 0
            end
        end
        if self:IsHaveMission(selfId, self.g_MissionId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_ContinueInfo)
            self:EndEvent()
            local bDone = self:CheckSubmit(selfId)
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
        else
            if self:IsMissionFull(selfId) == 1 then
                self:NotifyTip(selfId, "#{QIANXUN_INFO_23}")
                return 0
            end
            self:SetMissionDataEx(selfId, 118, key)
            self:AcceptMission(selfId, targetId)
        end
    else
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
end

function SuZhouZuoTong_QianXun:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        return 0
    end
    if self:CheckHuoDongTime() == 1 then
        caller:AddNumTextWithTarget(self.script_id,"Thiên Tầm",6, self.g_QianXunMission_IDX)
    end
    caller:AddNumTextWithTarget(self.script_id,"Về Thiên Tầm",11, self.g_MissionInfo_IDX)
end

function SuZhouZuoTong_QianXun:CheckAccept(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:TalkInfo(selfId, targetId, "#{QIANXUN_INFO_19}")
        return 0
    end
    return 1
end

function SuZhouZuoTong_QianXun:OnAccept(selfId, targetId, scriptId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:CheckAccept(selfId, targetId) <= 0 then
        return 0
    end
    local nMisType = self:GetMissionDataEx(selfId, 118)
    if nMisType == self.g_FuQiMission_IDX then
        if self:CheckMission_FuQi(selfId) == 0 then
            return 0
        end
    elseif nMisType == self.g_JieBaiMission_IDX then
        if self:CheckMission_JieBai(selfId) == 0 then
            return 0
        end
    elseif nMisType == self.g_ShiTuMission_IDX then
        if self:CheckMission_ShiTu(selfId) == 0 then
            return 0
        end
    else
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local itemidx = math.random(#(self.g_ItemId))
    if self:LuaFnGetTaskItemBagSpace(selfId) < self.g_ItemId[itemidx]["num"] then
        self:NotifyTip(selfId, "#{QX_20071129_027}")
        return 0
    end
    local nNowTime = os.date("%Y%m%d",os.time())
    local nYear = math.floor(nNowTime/10000)
    local nMonth = (math.floor(nNowTime/100) % 100)
    local nDay = (nNowTime % 100)
    local curDayTime = nYear * 10000 + (nMonth + 1) * 100 + nDay
    self:BeginAddItem()
    self:AddItem(self.g_ItemId[itemidx]["id"], self.g_ItemId[itemidx]["num"])
    local canAdd = self:EndAddItem(selfId)
    if canAdd then
        local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 1, 0)
        if bAdd then
            self:AddItemListToHuman(selfId)
            local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 0)
            self:SetMissionByIndex(selfId, misIndex, 2, scriptId)
            self:SetMissionByIndex(selfId, misIndex, self.g_Mission_RoundNum, 1)
            self:SetMissionByIndex(selfId, misIndex, self.g_Mission_ItemIdx, itemidx)
            self:SetMissionDataEx(selfId, 118, nMisType)
            if nMisType == self.g_FuQiMission_IDX then
                self:SetMissionDataEx(selfId, 119, curDayTime)
            elseif nMisType == self.g_JieBaiMission_IDX then
                self:SetMissionDataEx(selfId, 120, curDayTime)
            elseif nMisType == self.g_ShiTuMission_IDX then
                self:SetMissionDataEx(selfId, 121, curDayTime)
            end
            local ScintInfo = self.g_scenePosInfoList[1]
            self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, ScintInfo["sceneId"], ScintInfo["PosX"],
                ScintInfo["PosY"], self.g_MissionName)
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText(self.g_MissionInfo)
            self:AddText("#{M_MUBIAO}#r")
            self:AddText("#{QX_20071129_025}")
            local strText = string.format("Thiên Tầm nhiệm vụ đệ 1 Khuyên: Ngươi chỉ có đến %scủa #{_INFOAIM%d,%d,%d,%s} mới có thể sử dụng Tầm Lộ Chi Tâm",
                ScintInfo["scenename"], ScintInfo["PosX"], ScintInfo["PosY"], ScintInfo["sceneId"],
                ScintInfo["scenename"])
            self:AddText(strText)
            self:AddText("#e00f000Mẹo: #e000000Sử dụng #gfff0f0chuột phải#g000000 click vào #gfff0f0Tầm Lộ Chi Tâm#g000000 trong túi nhiệm vụ, có thể Hiển thị địa điểm nhiệm vụ Yêu cầu tìm.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
    return 1
end

function SuZhouZuoTong_QianXun:OnAbandon(selfId)
    local itemidx = 1
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        itemidx = self:GetMissionParam(selfId, misIndex, self.g_Mission_ItemIdx)
    end
    if self:HaveItem(selfId, self.g_ItemId[itemidx]["id"]) > 0 then
        if self:LuaFnGetAvailableItemCount(selfId, self.g_ItemId[itemidx]["id"]) >= self.g_ItemId[itemidx]["num"] then
            self:LuaFnDelAvailableItem(selfId, self.g_ItemId[itemidx]["id"],
                self:LuaFnGetAvailableItemCount(selfId, self.g_ItemId[itemidx]["id"]))
            if self:IsHaveMission(selfId, self.g_MissionId) then
                self:DelMission(selfId, self.g_MissionId)
            else
                return 0
            end
        else
            self:NotifyTip(selfId, "Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
            return 0
        end
    else
        if self:IsHaveMission(selfId, self.g_MissionId) then
            self:DelMission(selfId, self.g_MissionId)
        else
            return 0
        end
    end
end

function SuZhouZuoTong_QianXun:OnContinue(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_PlayerSlow_LVL then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId) ~= 1 then
        return 0
    end
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function SuZhouZuoTong_QianXun:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:GetMissionParam(selfId, misIndex, 0) > 0 then
        return 1
    end
    return 0
end

function SuZhouZuoTong_QianXun:CheckMission_FuQi(selfId)
    local nNowTime = os.date("%Y%m%d",os.time())
    local nYear = math.floor(nNowTime/10000)
    local nMonth = (math.floor(nNowTime/100) % 100)
    local nDay = (nNowTime % 100)
    local curDayTime = nYear * 10000 + (nMonth + 1) * 100 + nDay
    local nMisDaytime = 0
    local IsHaveMis = 0
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local nMisType = self:GetMissionDataEx(selfId, 118)
        if nMisType ~= self.g_FuQiMission_IDX then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_18}")
            return 0
        end
        IsHaveMis = 1
    else
        nMisDaytime = self:GetMissionDataEx(selfId, 119)
        if nMisDaytime == curDayTime then
            self:NotifyTip(selfId, "#{QX_20071129_032}")
            return 0
        end
        IsHaveMis = 0
    end
    if self:GeneralRule(selfId) == 0 then
        return 0
    end
    local NumMem = self:LuaFnGetTeamSize(selfId)
    if NumMem < 2 then
        if IsHaveMis == 1 then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_08}")
        else
            self:NotifyTip(selfId, "#{QIANXUN_INFO_07}")
        end
        return 0
    end
    local nNearTeamCount = self:GetNearTeamCount(selfId)
    if self:GetNearTeamCount(selfId) < 2 then
        self:NotifyTip(selfId, "#{QX_20071129_034}")
        return 0
    end
    local ObjID0 = selfId
    local ObjID1
    for i = 0, nNearTeamCount - 1 do
        ObjID1 = self:GetNearTeamMember(selfId, i)
        if ObjID0 ~= ObjID1 then
            local SelfGUID = self:LuaFnObjId2Guid(ObjID0)
            local SpouGUID = self:LuaFnGetSpouseGUID(ObjID1)
            if self:LuaFnIsMarried(ObjID0) and self:LuaFnIsMarried(ObjID1) and SelfGUID == SpouGUID then
                return 1
            end
        end
    end
    self:NotifyTip(selfId, "#{QIANXUN_INFO_11}")
    return 0
end

function SuZhouZuoTong_QianXun:CheckMission_JieBai(selfId)
    local nNowTime = os.date("%Y%m%d",os.time())
    local nYear = math.floor(nNowTime/10000)
    local nMonth = (math.floor(nNowTime/100) % 100)
    local nDay = (nNowTime % 100)
    local curDayTime = nYear * 10000 + (nMonth + 1) * 100 + nDay
    local nMisDaytime = 0
    local IsHaveMis = 0
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local nMisType = self:GetMissionDataEx(selfId, 118)
        if nMisType ~= self.g_JieBaiMission_IDX then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_18}")
            return 0
        end
        IsHaveMis = 1
    else
        nMisDaytime = self:GetMissionDataEx(selfId, 120)
        if nMisDaytime == curDayTime then
            self:NotifyTip(selfId, "#{QX_20071129_033}")
            return 0
        end
        IsHaveMis = 0
    end
    if self:GeneralRule(selfId) == 0 then
        return 0
    end
    local NumMem = self:LuaFnGetTeamSize(selfId)
    if NumMem < 2 then
        if IsHaveMis == 1 then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_15}")
        else
            self:NotifyTip(selfId, "#{QIANXUN_INFO_14}")
        end
        return 0
    end
    local nNearTeamCount = self:GetNearTeamCount(selfId)
    if self:GetNearTeamCount(selfId) < 2 then
        self:NotifyTip(selfId, "#{QX_20071129_035}")
        return 0
    end
    local firstPlayer = selfId
    local otherPlayer
    for i = 0, nNearTeamCount - 1 do
        otherPlayer = self:GetNearTeamMember(selfId, i)
        if firstPlayer ~= otherPlayer then
            if self:LuaFnIsBrother(firstPlayer, otherPlayer) then
                return 1
            end
        end
    end
    self:NotifyTip(selfId, "#{QIANXUN_INFO_16}")
    return 0
end

function SuZhouZuoTong_QianXun:CheckMission_ShiTu(selfId)
    local nNowTime = os.date("%Y%m%d",os.time())
    local nYear = math.floor(nNowTime/10000)
    local nMonth = (math.floor(nNowTime/100) % 100)
    local nDay = (nNowTime % 100)
    local curDayTime = nYear * 10000 + (nMonth + 1) * 100 + nDay
    local nMisDaytime = 0
    local IsHaveMis = 0
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local nMisType = self:GetMissionDataEx(selfId, 118)
        if nMisType ~= self.g_ShiTuMission_IDX then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_18}")
            return 0
        end
        IsHaveMis = 1
    else
        nMisDaytime = self:GetMissionDataEx(selfId, 121)
        if nMisDaytime == curDayTime then
            self:NotifyTip(selfId, "#{QX_20071129_039}")
            return 0
        end
        IsHaveMis = 0
    end
    if self:GeneralRule(selfId) == 0 then
        return 0
    end
    local NumMem = self:LuaFnGetTeamSize(selfId)
    if NumMem < 2 then
        if IsHaveMis == 1 then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_15}")
        else
            self:NotifyTip(selfId, "#{QIANXUN_INFO_14}")
        end
        return 0
    end
    local nNearTeamCount = self:GetNearTeamCount(selfId)
    if self:GetNearTeamCount(selfId) < 2 then
        self:NotifyTip(selfId, "#{QIANXUN_INFO_17}")
        return 0
    end
    local firstPlayer = selfId
    local otherPlayer
    for i = 0, nNearTeamCount - 1 do
        otherPlayer = self:GetNearTeamMember(selfId, i)
        if firstPlayer ~= otherPlayer then
            if self:LuaFnIsMaster(otherPlayer, firstPlayer) then
                return 1
            end
            if self:LuaFnIsMaster(firstPlayer, otherPlayer) then
                return 1
            end
        end
    end
    self:NotifyTip(selfId, "#{QX_20071129_036}")
    return 0
end

function SuZhouZuoTong_QianXun:OnSubmit(selfId, targetId, selectRadioId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:LuaFnGetLevel(selfId) < self.g_PlayerSlow_LVL then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    if self:CheckSubmit(selfId) ~= 1 then
        self:NotifyTip(selfId, "Nộp nhiệm vụ thất bại")
        return 0
    end
    local nMisType = self:GetMissionDataEx(selfId, 118)
    if nMisType == self.g_FuQiMission_IDX then
        if self:CheckMission_FuQi(selfId) == 0 then
            return 0
        end
    elseif nMisType == self.g_JieBaiMission_IDX then
        if self:CheckMission_JieBai(selfId) == 0 then
            return 0
        end
    elseif nMisType == self.g_ShiTuMission_IDX then
        if self:CheckMission_ShiTu(selfId) == 0 then
            return 0
        end
    else
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    if selfId == self:GetTeamLeader(selfId) then
        local temp = ""
        if nMisType == self.g_FuQiMission_IDX then
            temp = "#{QX_20071129_043}"
        elseif nMisType == self.g_JieBaiMission_IDX then
            temp = "#{QX_20071129_046}"
        elseif nMisType == self.g_ShiTuMission_IDX then
            temp = "#{QX_20071129_047}"
        end
        local strText = string.format("#{_INFOUSR%s}#{QX_20071129_048}%s#{QIANXUN_INFO_24}", self:GetName(selfId), temp)
        strText = gbk.fromutf8(strText)
        self:BroadMsgByChatPipe(0, strText, 4)
    end
    local playerlvl = self:LuaFnGetLevel(selfId)
    self:LuaFnAddExp(selfId, self.g_BonusEXP_List[playerlvl])
    self:DelMission(selfId, self.g_MissionId)
end

function SuZhouZuoTong_QianXun:OnKillObject(selfId, objdataId, objId)
end

function SuZhouZuoTong_QianXun:OnEnterArea(selfId, zoneId)
    local sceneId = self:GetSceneID()
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local index = self:GetMissionParam(selfId, misIndex, self.g_Mission_RoundNum)
    if sceneId ~= self.g_scenePosInfoList[index]["sceneId"] or zoneId ~= self.g_scenePosInfoList[index]["Area"] then
        return 0
    end
    local nposX = math.random(3)
    local nposY = math.random(3)
    self:CreateSpecialObjByDataIndex(selfId, self.g_Impact_Complete_Mission,
        self.g_scenePosInfoList[index]["PosX"] + nposX, self.g_scenePosInfoList[index]["PosY"] + nposY, 0)
end

function SuZhouZuoTong_QianXun:OnItemChanged(selfId, itemdataId)
end

function SuZhouZuoTong_QianXun:AcceptDialog(selfId, rand, g_Dialog, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(g_Dialog)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function SuZhouZuoTong_QianXun:SubmitDialog(selfId, rand)
end

function SuZhouZuoTong_QianXun:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function SuZhouZuoTong_QianXun:TalkInfo(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function SuZhouZuoTong_QianXun:GetEventMissionId(selfId)
    return self.g_MissionId
end

function SuZhouZuoTong_QianXun:AcceptMission(selfId, targetId)
    if self:LuaFnGetName(targetId) ~= self.g_Name then
        self:NotifyTip(selfId, "Nhận nhiệm vụ thất bại")
        return 0
    end
    local PlayerName = self:GetName(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionInfo)
    self:AddText("#{M_MUBIAO}")
    self:AddText("#{QX_20071129_025}")
    self:AddText("#{M_SHOUHUO}")
    self:AddText("#{QX_20071129_050}")
    self:EndEvent()
    self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function SuZhouZuoTong_QianXun:GetItemDetailInfo(itemId)
    local itemId, itemName, itemDesc = self:GetItemInfoByItemId(itemId)
    if itemId == -1 then
        local strText = self:format("Vật phẩm %s không thấy trong 'EquipBase.txt'!!", itemName)
    end
    return itemId
end

function SuZhouZuoTong_QianXun:GeneralRule(selfId)
    if self:GetLevel(selfId) < self.g_PlayerSlow_LVL then
        self:NotifyTip(selfId, "#{QIANXUN_INFO_10}")
        return 0
    end
    if self:CheckHuoDongTime() ~= 1 then
        return 0
    end
    if self:LuaFnGetTaskItemBagSpace(selfId) < self.g_ItemId[1]["num"] then
        self:NotifyTip(selfId, "#{QX_20071129_027}")
        return 0
    end
    if self:LuaFnHasTeam(selfId) == 0 then
        if self:IsHaveMission(selfId, self.g_MissionId) then
            self:NotifyTip(selfId, "#{QIANXUN_INFO_05}")
        else
            self:NotifyTip(selfId, "#{QIANXUN_INFO_03}")
        end
        return 0
    end
    return 1
end

function SuZhouZuoTong_QianXun:CheckHuoDongTime()
    local nDay = self:GetTodayWeek()
    if nDay == self.g_Activity_DayTime then
        return 1
    else
        return 0
    end
end

function SuZhouZuoTong_QianXun:OnUseItem(selfId, bagIndex)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local nRoundNum = self:GetMissionParam(selfId, misIndex, self.g_Mission_RoundNum)
    local ScintInfo = self.g_scenePosInfoList[nRoundNum]
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerY = self:GetHumanWorldZ(selfId)
    local Distance = math.floor(self:sqrt((ScintInfo["PosX"] - PlayerX) * (ScintInfo["PosX"] - PlayerX) +
        (ScintInfo["PosY"] - PlayerY) * (ScintInfo["PosY"] - PlayerY)))
    local str = ""
    if nRoundNum >= self.g_MaxRound then
        local missitemid = self:GetItemTableIndexByIndex(selfId, bagIndex)
        local ret = self:DelItem(selfId, missitemid)
        if not ret then
            return 0
        end
        local nItemId = 0
        local nItemCount = 0
        local rand = math.random(100)
        local ntype = 1
        local IsTalkWorld = 0
        local playerlvl = self:LuaFnGetLevel(selfId)
        if math.random(1) == 10 then
            if playerlvl < 12 then
                ntype = 1
            elseif playerlvl < 22 then
                ntype = 2
            elseif playerlvl < 32 then
                ntype = 3
            elseif playerlvl < 42 then
                ntype = 4
            elseif playerlvl < 52 then
                ntype = 5
            elseif playerlvl < 62 then
                ntype = 6
            elseif playerlvl < 72 then
                ntype = 7
            elseif playerlvl < 82 then
                ntype = 8
            elseif playerlvl < 92 then
                ntype = 9
            else
                ntype = 10
            end
            if rand <= 96 then
                nItemId = self.g_BonusItem[ntype]["ItemID01"]
                nItemCount = 1
            else
                nItemId = self.g_BonusItem[1]["ItemID02"]
                nItemCount = 1
                IsTalkWorld = 1
            end
        end
        self:SetMissionByIndex(selfId, misIndex, self.g_Mission_IsComplete, 1)
    else
        self:NotifyTip(selfId, "hoàn thành tình huống: Đã khám phá " .. nRoundNum .. "/" .. self.g_MaxRound)
        nRoundNum = nRoundNum + 1
        self:SetMissionByIndex(selfId, misIndex, self.g_Mission_RoundNum, nRoundNum)
        ScintInfo = self.g_scenePosInfoList[nRoundNum]
        PlayerX = self:GetHumanWorldX(selfId)
        PlayerY = self:GetHumanWorldZ(selfId)
        Distance = math.floor(self:sqrt((ScintInfo["PosX"] - PlayerX) * (ScintInfo["PosX"] - PlayerX) +
            (ScintInfo["PosY"] - PlayerY) * (ScintInfo["PosY"] - PlayerY)))
        nRoundNum = self:GetMissionParam(selfId, misIndex, self.g_Mission_RoundNum)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, ScintInfo["sceneId"], ScintInfo["PosX"],
            ScintInfo["PosY"], self.g_MissionName)
        str = self:format("Nhiệm vụ Thiên Tầm Khuyên thứ %d: Đến #G%s#W khám phá #G%s#{_INFOAIM%d,%d,%d,%s}#W, ngắm nhìn cảnh đẹp giang hồ. Sau khi đến, xin hãy sử dụng #YTầm Lộ Chi Tâm#W.",
            nRoundNum, ScintInfo["scenename"], ScintInfo["PosName"], ScintInfo["PosX"], ScintInfo["PosY"],
            ScintInfo["sceneId"], ScintInfo["scenename"])
        self:BeginEvent(self.script_id)
        self:AddText(str)
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
    end
end

return SuZhouZuoTong_QianXun
