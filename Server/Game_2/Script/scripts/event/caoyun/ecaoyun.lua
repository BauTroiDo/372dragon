local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ecaoyun = class("ecaoyun", script_base)
ecaoyun.g_MissionId = 4021
ecaoyun.script_id = 311010
ecaoyun.g_CashItem_id = 40002109
ecaoyun.g_CashItem_count = 1
ecaoyun.g_EludeItem = {
    {["id"] = 20108157, ["num"] = 1}, {["id"] = 20108169, ["num"] = 2}
}

ecaoyun.g_ChopItem = {{["id"] = 30308020, ["num"] = 1}}

ecaoyun.g_CertificateItem = {{["id"] = 30308020, ["num"] = 1}}

ecaoyun.g_Accommodate_Distinction = {}

ecaoyun.g_Acclimatize_Distinction = {}

ecaoyun.g_Traverse_Region = {3, 4, 5, 6, 7, 8}

ecaoyun.g_Title_Times_Confine = {50000, 20000, 7500, 3000, 1000, 100, 0}

ecaoyun.g_Title_Confine = {193, 194, 195, 196, 197, 198, 199}

ecaoyun.g_Title_Name_Confine = {
    "Tổng Đề Điều Tào Vận", "Điều độ sứ Tào Vận", "Phó sứ Điều Độ Tào Vận", "Thống lĩnh Tào Vận",
    "Tào Vận Áp Giải Quan", "Tào Vận Tẩu Tốt", "Tào Vận Thương nhân"
}

ecaoyun.g_Reward_Medicine_HP = {
    30001001, 30001002, 30001003, 30001004, 30001005, 30001006, 30001007,
    30001008, 30001009, 30001010
}

ecaoyun.g_Reward_Medicine_MP = {
    30002001, 30002002, 30002003, 30002004, 30002005, 30002006, 30002007,
    30002008, 30002009, 30002010
}

ecaoyun.g_Accommodate_Distinction[1] = 3530
ecaoyun.g_Accommodate_Distinction[2] = 3531
ecaoyun.g_Accommodate_Distinction[3] = 3532
ecaoyun.g_Accommodate_Distinction[4] = 3533
ecaoyun.g_Accommodate_Distinction[5] = 3534
ecaoyun.g_Accommodate_Distinction[6] = 3535
ecaoyun.g_Accommodate_Distinction[7] = 3536
ecaoyun.g_Accommodate_Distinction[8] = 3537
ecaoyun.g_Accommodate_Distinction[9] = 3538
ecaoyun.g_Accommodate_Distinction[10] = 3539
ecaoyun.g_Acclimatize_Distinction[1] = 3540
ecaoyun.g_Acclimatize_Distinction[2] = 3541
ecaoyun.g_Acclimatize_Distinction[3] = 3542
ecaoyun.g_Acclimatize_Distinction[4] = 3543
ecaoyun.g_Acclimatize_Distinction[5] = 3544
ecaoyun.g_Acclimatize_Distinction[6] = 3545
ecaoyun.g_Acclimatize_Distinction[7] = 3546
ecaoyun.g_Acclimatize_Distinction[8] = 3547
ecaoyun.g_Acclimatize_Distinction[9] = 3548
ecaoyun.g_Acclimatize_Distinction[10] = 3549
ecaoyun.g_Accommodate_Distinction[11] = 33530
ecaoyun.g_Accommodate_Distinction[12] = 33531
ecaoyun.g_Accommodate_Distinction[13] = 33532
ecaoyun.g_Accommodate_Distinction[14] = 33533
ecaoyun.g_Accommodate_Distinction[15] = 33534
ecaoyun.g_Accommodate_Distinction[16] = 33535
ecaoyun.g_Accommodate_Distinction[17] = 33536
ecaoyun.g_Accommodate_Distinction[18] = 33537
ecaoyun.g_Accommodate_Distinction[19] = 33538
ecaoyun.g_Accommodate_Distinction[20] = 33539
ecaoyun.g_Acclimatize_Distinction[11] = 33540
ecaoyun.g_Acclimatize_Distinction[12] = 33541
ecaoyun.g_Acclimatize_Distinction[13] = 33542
ecaoyun.g_Acclimatize_Distinction[14] = 33543
ecaoyun.g_Acclimatize_Distinction[15] = 33544
ecaoyun.g_Acclimatize_Distinction[16] = 33545
ecaoyun.g_Acclimatize_Distinction[17] = 33546
ecaoyun.g_Acclimatize_Distinction[18] = 33547
ecaoyun.g_Acclimatize_Distinction[19] = 33548
ecaoyun.g_Acclimatize_Distinction[10] = 33549
ecaoyun.g_TitleTableOfMonster = {
    {["part1"] = "Cướp của", ["part2"] = "Hung đồ"},
    {["part1"] = "Đào ngục", ["part2"] = "Ác nhân"},
    {["part1"] = "Trọng án", ["part2"] = "强盗"},
    {["part1"] = "Hại mệnh", ["part2"] = "Kẻ gian"},
    {["part1"] = "Độc Thủ", ["part2"] = "Tên ác tặc"},
    {["part1"] = "Sát Tâm", ["part2"] = "Thích khách"},
    {["part1"] = "Tiệt Tiêu", ["part2"] = "恶霸"}
}

ecaoyun.g_NameTableOfMonster = {
    {["part1"] = "Nạp thêm tại: https://platform.beeknoee.com/billing", ["part2"] = "Văn", ["part3"] = "Nạp thêm tại: https://platform.beeknoee.com/billing"},
    {["part1"] = "Tiền", ["part2"] = "Nguyên", ["part3"] = "Thái"},
    {["part1"] = "Tôn", ["part2"] = "Thành", ["part3"] = "Liệt"},
    {["part1"] = "Lý", ["part2"] = "của", ["part3"] = "Hách"},
    {["part1"] = "tuần", ["part2"] = "Bá", ["part3"] = "虎"},
    {["part1"] = "Ngô", ["part2"] = "từng", ["part3"] = "Lượng"},
    {["part1"] = "Trịnh", ["part2"] = "Nhân", ["part3"] = "Lãng"},
    {["part1"] = "Vương", ["part2"] = "Ân", ["part3"] = "Cổ"}
}

ecaoyun.g_Transportation_Exit = {}

ecaoyun.g_Transportation_Exit[8] = {
    ["Scene_Name"] = "Đôn Hoàng",
    [1] = {
        ["Exit_Name"] = "Đôn Hoàng đến Lạc Dương",
        ["Exit_Reply_Number"] = 5,
        ["Exit_Position"] = {["x"] = 276, ["y"] = 145}
    },
    [2] = {
        ["Exit_Name"] = "Đôn Hoàng đến Kiếm Các",
        ["Exit_Reply_Number"] = 6,
        ["Exit_Position"] = {["x"] = 230, ["y"] = 270}
    }
}

ecaoyun.g_Transportation_Exit[7] = {
    ["Scene_Name"] = "Kiếm Các",
    [1] = {
        ["Exit_Name"] = "Kiếm Các đến Đại Lý",
        ["Exit_Reply_Number"] = 7,
        ["Exit_Position"] = {["x"] = 40, ["y"] = 278}
    },
    [2] = {
        ["Exit_Name"] = "Kiếm Các đến Đôn Hoàng",
        ["Exit_Reply_Number"] = 8,
        ["Exit_Position"] = {["x"] = 106, ["y"] = 47}
    }
}

ecaoyun.g_Transportation_Exit[6] = {
    ["Scene_Name"] = "Vô Lượng Sơn",
    [1] = {
        ["Exit_Name"] = "Vô Lượng Sơn đến Kính Hồ",
        ["Exit_Reply_Number"] = 9,
        ["Exit_Position"] = {["x"] = 276, ["y"] = 80}
    },
    [2] = {
        ["Exit_Name"] = "Vô Lượng Sơn đến Đại Lý",
        ["Exit_Reply_Number"] = 10,
        ["Exit_Position"] = {["x"] = 43, ["y"] = 172}
    }
}

ecaoyun.g_Transportation_Exit[5] = {
    ["Scene_Name"] = "Kính Hồ",
    [1] = {
        ["Exit_Name"] = "Kính Hồ đến Vô Lượng Sơn",
        ["Exit_Reply_Number"] = 11,
        ["Exit_Position"] = {["x"] = 46, ["y"] = 278}
    },
    [2] = {
        ["Exit_Name"] = "Kính Hồ đến Tô Châu",
        ["Exit_Reply_Number"] = 12,
        ["Exit_Position"] = {["x"] = 277, ["y"] = 46}
    }
}

ecaoyun.g_Transportation_Exit[4] = {
    ["Scene_Name"] = "Thái Hồ",
    [1] = {
        ["Exit_Name"] = "Thái HồchíTung Sơn",
        ["Exit_Reply_Number"] = 13,
        ["Exit_Position"] = {["x"] = 88, ["y"] = 35}
    },
    [2] = {
        ["Exit_Name"] = "Thái Hồ đến Tô Châu",
        ["Exit_Reply_Number"] = 14,
        ["Exit_Position"] = {["x"] = 218, ["y"] = 271}
    }
}

ecaoyun.g_Transportation_Exit[3] = {
    ["Scene_Name"] = "Tung Sơn",
    [1] = {
        ["Exit_Name"] = "Tung Sơn đến Lạc Dương",
        ["Exit_Reply_Number"] = 15,
        ["Exit_Position"] = {["x"] = 42, ["y"] = 54}
    },
    [2] = {
        ["Exit_Name"] = "Tung Sơn đến Thái Hồ",
        ["Exit_Reply_Number"] = 16,
        ["Exit_Position"] = {["x"] = 281, ["y"] = 250}
    }
}

ecaoyun.g_Transportation_City = {}

ecaoyun.g_Transportation_City[0] = {
    ["Scene_Name"] = "Lạc Dương",
    ["Reply_Number"] = 17,
    [0] = {["x"] = 160, ["y"] = 278},
    [1] = {["x"] = 282, ["y"] = 133},
    [2] = {["x"] = 37, ["y"] = 134}
}

ecaoyun.g_Transportation_City[1] = {
    ["Scene_Name"] = "Tô Châu",
    ["Reply_Number"] = 18,
    [0] = {["x"] = 182, ["y"] = 265},
    [1] = {["x"] = 64, ["y"] = 163},
    [2] = {["x"] = 183, ["y"] = 53}
}

ecaoyun.g_Transportation_City[2] = {
    ["Scene_Name"] = "Đại Lý",
    ["Reply_Number"] = 19,
    [0] = {["x"] = 160, ["y"] = 277},
    [1] = {["x"] = 280, ["y"] = 152},
    [2] = {["x"] = 39, ["y"] = 152}
}

ecaoyun.g_Transportation_Legate = {}

ecaoyun.g_Transportation_Legate[0] = {
    ["Scene_Name"] = "Lạc Dương",
    ["Reply_Number"] = 20,
    ["Position"] = {["x"] = 222, ["y"] = 179}
}

ecaoyun.g_Transportation_Legate[1] = {
    ["Scene_Name"] = "Tô Châu",
    ["Reply_Number"] = 21,
    ["Position"] = {["x"] = 234, ["y"] = 86}
}

ecaoyun.g_Transportation_Legate[2] = {
    ["Scene_Name"] = "Đại Lý",
    ["Reply_Number"] = 22,
    ["Position"] = {["x"] = 54, ["y"] = 185}
}

ecaoyun.g_SpecialImpact = {}

ecaoyun.g_SpecialImpact[23] = {
    ["Impact_Name"] = "Tăng thêm Ngoại Công",
    ["Impact_ID"] = {115, 116, 117, 118, 119, 30115, 30116, 30117, 30118, 30119}
}

ecaoyun.g_SpecialImpact[24] = {
    ["Impact_Name"] = "Tăng Ngoại Phòng",
    ["Impact_ID"] = {120, 121, 122, 123, 124, 30120, 30121, 30122, 30123, 30124}
}

ecaoyun.g_SpecialImpact[25] = {
    ["Impact_Name"] = "Tăng Nội Công",
    ["Impact_ID"] = {125, 126, 127, 128, 129, 30125, 30126, 30127, 30128, 30129}
}

ecaoyun.g_SpecialImpact[26] = {
    ["Impact_Name"] = "Tăng Nội Phòng",
    ["Impact_ID"] = {130, 131, 132, 133, 134, 30130, 30131, 30132, 30133, 30134}
}

ecaoyun.g_IncreaseSpeed_Impact = {}

ecaoyun.g_IncreaseSpeed_Impact[27] = {["Impact_ID"] = 135}

function ecaoyun:OnDefaultEvent(selfId, BagIndex)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 3, 0)
    local New_Time = self:LuaFnGetCurrentTime()
    local HaggleUp = 600 - New_Time +
                         self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP)
    local HaggleDown = 900 - New_Time +
                           self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
    local circle = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_HUAN)
    if (HaggleUp < 0) then HaggleUp = 0 end
    if (HaggleDown < 0) then HaggleDown = 0 end
    local iDayHuan = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT)
    local Quotiety = 1
    local Price_Sell = 15000 * Quotiety
    self:BeginUICommand()
    self:UICommand_AddInt(5)
    self:UICommand_AddInt(12)
    self:UICommand_AddInt(HaggleUp)
    self:UICommand_AddInt(HaggleDown)
    self:UICommand_AddInt(circle)
    self:UICommand_AddInt(misIndex)
    self:UICommand_AddInt(iDayHuan)
    self:UICommand_AddInt(Price_Sell)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 0)
end

function ecaoyun:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local TransNPC = self:TransPortNPC(targetId)
        if TransNPC == -1 then return end
        if TransNPC == 4 then
            local ItemNum = self:GetItemCount(selfId, self.g_CashItem_id)
            if ItemNum < self.g_CashItem_count then
                self:BeginUICommand()
                self:UICommand_AddInt(5)
                self:UICommand_AddInt(6)
                self:EndUICommand()
                self:DispatchUICommand(selfId, 0)
                return
            end
            if targetId == self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID) then
                local msg = "Xin lỗi, ta đã cung cấp dịch vụ cho ngài rồi."
                local cmsg = "Rời đi"
                self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
                return
            end
            if TRAFFICKER_CLICK_TIMES >= 30 then
                local msg =
                    "Hôm nay ta đã rất mệt mỏi rồi, không muốn phục vụ ai nữa, hy vọng lần sau có thể giúp được ngươi."
                local cmsg = "Thật không khéo..."
                self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
                return
            end
            self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID, targetId)
            local PlayerSex = self:GetSex(selfId)
            if PlayerSex == 0 then
                PlayerSex = "Hiệp Nữ"
            else
                PlayerSex = "Đại Hiệp"
            end
            self:BeginEvent(self.script_id)
            self:AddText(PlayerSex ..
                             "Ta là Thương nhân chợ đen có tiếng ở vùng này, gặp được ta coi như là duyên phận của ngươi, vừa hay hôm nay ta tâm trạng tốt, có thể cung cấp cho ngươi một vài dịch vụ, có muốn thử vận may không?")
            self:AddNumText("Ta muốn thử vận may", -1, 28)
            self:AddNumText("Thôi vậy...", -1, 0)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID, targetId)
        self:SetMissionByIndex(selfId, misIndex, 0, 0)
        self:SetMissionByIndex(selfId, misIndex, 1, 0)
        local Caoyun_Times = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_SUMTIME)
        local find = -1
        local msg, cmsg
        for i, times in pairs(self.g_Title_Times_Confine) do
            if times <= Caoyun_Times then
                find = i
                break
            end
        end
        local New_Title = self.g_Title_Confine[find]
        if self:GetTitle(selfId, 5) ~= New_Title and find >= 0 then
            self:LuaFnAwardTitle(selfId, 5, New_Title)
            self:SetCurTitle(selfId, 5, New_Title)
            self:LuaFnAddNewAgname(selfId, 5, New_Title)
            self:LuaFnDispatchAllTitle(selfId)
            if Caoyun_Times < 20000 then
                if Caoyun_Times == self.g_Title_Times_Confine[find] then
                    msg =
                        "Chúc mừng ngươi nhận được" .. self.g_Title_Name_Confine[find] ..
                            "danh hiệu của ngài, mong rằng ngài sẽ tiếp tục có những đóng góp cho Tào Vận."
                    cmsg = "Đa tạ..."
                    self:Client_Show_Message(selfId, targetId, msg, cmsg, 2)
                    return
                end
            else
                if Caoyun_Times == self.g_Title_Times_Confine[find] then
                    msg =
                        "Bởi vì đại nhân đã có những đóng góp đặc biệt cho Tào Vận, triều đình đặc biệt ủy thác ta chuyển lời, ngài được phong làm" ..
                            self.g_Title_Name_Confine[find] ..
                            "Mong rằng lần sau ngài có thể nâng đỡ tiểu của ta nhiều hơn."
                    cmsg = "Ừ, biết rồi."
                    self:Client_Show_Message(selfId, targetId, msg, cmsg, 2)
                    return
                end
            end
        end
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
    elseif 1 > 0 then
        local TransNPC = self:TransPortNPC(targetId)
        if TransNPC == 4 then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(10)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
            return
        end
        self:BeginUICommand()
        self:UICommand_AddInt(4)
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(TransNPC)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID, targetId)
    end
end

function ecaoyun:CheckAccept(selfId)
    local Quotiety = 2
    local Corpus = 10000 * Quotiety
    if self:IsTeamFollow(selfId) then
        self:BeginEvent(self.script_id)
        local strText = string.format( "Ngươi đang ở Trạng thái tổ đội theo sau, không thể tiếp nhiệm vụ Tào Vận.")
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    elseif self:GetLevel(selfId) < 40 then
        local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
        local msg =
            "Cấp độ của ngươi còn chưa đến cấp 40, vẫn là đợi sau khi đạt cấp 40 rồi hãy đến tìm ta."
        local cmsg = "Ta sẽ rất nhanh đạt đến cấp 40 của"
        self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
        return 0
    elseif self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < Corpus then
        self:BeginEvent(self.script_id)
        self:AddText("Kim tiền không đủ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    elseif self:OnAccept_Necessary(selfId) < 0 then
        return 0
    end
    return 1
end

function ecaoyun:Calculate_Modulus(selfId)
    if self:GetLevel(selfId) >= 70 then
        return 3
    elseif self:GetLevel(selfId) >= 50 then
        return 2
    elseif self:GetLevel(selfId) >= 35 then
        return 2
    elseif self:GetLevel(selfId) >= 15 then
        return 1
    end
    return 1
end

function ecaoyun:Calculate_Double(selfId)
    local ret = 1
    local Orientation_Article = 1
    local Article_Quantity
    for i, item in pairs(self.g_CertificateItem) do
        Article_Quantity = self:GetItemCount(selfId, item["id"])
        if Article_Quantity < item["num"] then Orientation_Article = 0 end
    end
    if Orientation_Article == 1 then
        local HaveChop = self:DelItem(selfId, self.g_CertificateItem[1]["id"],
                                      self.g_CertificateItem[1]["num"])
        if HaveChop then ret = ret * 2 end
    end
    return ret
end

function ecaoyun:Calculate_Calender(selfId)
    local ret = 1
    local nWeek = self:GetTodayWeek()
    if nWeek then
        ret = ret * 2
        self:Msg2Player(selfId,
                        "Bởi vì hôm nay là ngày Tào Vận, cho nên thu nhập bán lần này của ngài được tăng gấp đôi.",
                        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:BeginEvent(self.script_id)
        self:AddText(
            "Bởi vì hôm nay là ngày Tào Vận, cho nên thu nhập bán lần này của ngài được tăng gấp đôi.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    return ret
end

function ecaoyun:Calculate_Margin(selfId, now_balance)
    local Level = self:GetLevel(selfId)
    local new_balance = (now_balance - 10000) *
                            (0.625 + 0.02 * (Level - 30) / 2) + 10000
    return new_balance
end

function ecaoyun:OnHaggleUp(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP)
    local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
    local TransNpc = self:TransPortNPC(targetId)
    local Now_Time = self:LuaFnGetCurrentTime()
    if Now_Time - Pre_Time < 10 * 60 then
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(9)
        self:UICommand_AddInt(Pre_Time + 10 * 60 - Now_Time)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        return
    end
    if TransNpc <= 0 then return end
    local Quotiety = 1
    local Price_Up = 18000 * Quotiety
    Price_Up = self:Calculate_Margin(selfId, Price_Up)
    self:SetMissionByIndex(selfId, misIndex, 0, Price_Up)
    local New_Time = self:LuaFnGetCurrentTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP, New_Time)
    self:BeginEvent(self.script_id)
    local strText = "Bán chạy thành công, giá bán hàng hóa tăng lên thành #{_EXCHG" .. Price_Up ..  "}"
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(4)
    self:UICommand_AddInt(misIndex)
    Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP)
    Now_Time = self:LuaFnGetCurrentTime()
    if Now_Time - Pre_Time < 10 * 60 then
        self:UICommand_AddInt(Pre_Time + 10 * 60 - Now_Time)
    else
        self:UICommand_AddInt(0)
    end
    Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
    if Now_Time - Pre_Time < 15 * 60 then
        self:UICommand_AddInt(Pre_Time + 15 * 60 - Now_Time)
    else
        self:UICommand_AddInt(0)
    end
    self:UICommand_AddInt(TransNpc)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1)
end

function ecaoyun:OnHaggleDown(selfId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
    local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
    local TransNpc = self:TransPortNPC(targetId)
    local Now_Time = self:LuaFnGetCurrentTime()
    if Now_Time - Pre_Time < 15 * 60 then
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(9)
        self:UICommand_AddInt(Pre_Time + 15 * 60 - Now_Time)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        return
    end
    if TransNpc <= 0 then return end
    local Quotiety = 1
    local Price_Down = 8000 * Quotiety
    self:SetMissionByIndex(selfId, misIndex, 1, Price_Down)
    local New_Time = self:LuaFnGetCurrentTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN, New_Time)
    self:BeginEvent(self.script_id)
    local strText = "Mặc cả thành công, giá mua hàng giảm xuống #{_EXCHG" .. Price_Down ..
                  "}"
    self:AddText(strText)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(5)
    self:UICommand_AddInt(misIndex)
    Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP)
    Now_Time = self:LuaFnGetCurrentTime()
    if Now_Time - Pre_Time < 10 * 60 then
        self:UICommand_AddInt(Pre_Time + 10 * 60 - Now_Time)
    else
        self:UICommand_AddInt(0)
    end
    Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
    if Now_Time - Pre_Time < 15 * 60 then
        self:UICommand_AddInt(Pre_Time + 15 * 60 - Now_Time)
    else
        self:UICommand_AddInt(0)
    end
    self:UICommand_AddInt(TransNpc)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1)
end

function ecaoyun:OnKillObject(selfId, objdataId, objId)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    if monsterName == "漕运小怪" or monsterName == "漕运大怪" then
        if math.random(1000) < 25 then
            self:AddMonsterDropItem(objId, selfId, 30501035)
        end
        if math.random(1000) < 25 then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 135, 0)
        end
    end
end

function ecaoyun:OnEnterArea(selfId, zoneId) end

function ecaoyun:OnItemChanged(selfId, itemdataId) end

function ecaoyun:OnAcceptMission(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then return end
    local HumanMoney = self:LuaFnGetMoney(selfId)
    local HumanMoneyJZ = self:GetMoneyJZ(selfId)
    local checkmoney = 20000
    if HumanMoney + HumanMoneyJZ < checkmoney then
        self:BeginEvent(self.script_id)
        self:AddText("Kim tiền không đủ!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local haveImpact = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 113)
    if haveImpact then
        self:BeginEvent(self.script_id)
        local strText = "Xin lỗi, hiện tại ngài đang ở Trạng thái vận chuyển, không thể nhận phiếu."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local ItemNum = self:GetItemCount(selfId, self.g_CashItem_id)
    local Quotiety = 2
    local Corpus = 10000 * Quotiety
    local iDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT)
    if ItemNum >= self.g_CashItem_count then
        if self:OnAccept_Necessary(selfId) <= 0 then return 0 end
        local ret = self:AddMission(selfId, self.g_MissionId, self.script_id,0, 0, 0)
        if not ret  then return end
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 0)
        self:SetMissionByIndex(selfId, misIndex, 1, 0)
        self:SetMissionByIndex(selfId, misIndex, 2, 0)
        self:SetMissionByIndex(selfId, misIndex, 3, 0)
        self:SetMissionByIndex(selfId, misIndex, 4, 0)
        local r, nDelJZ, nDelMoney = self:LuaFnCostMoneyWithPriority(selfId, 20000)
        if (not r ) then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi ít nhất Yêu cầu có #{_EXCHG" .. Corpus ..
                             "}, mới có thể nhận được quan phiếu.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
        if (nDelMoney <= 0) then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi thế chấp #{_EXCHG" .. nDelJZ ..
                             "}, nhận được một tấm Tào Vận Quan Phiếu.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        elseif (nDelJZ <= 0) then
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi thế chấp #{_MONEY" .. nDelMoney ..
                             "}, nhận được một tấm Tào Vận Quan Phiếu.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi thế chấp #{_EXCHG" .. nDelJZ .. "}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi thế chấp #{_MONEY" .. nDelMoney ..
                             "}, nhận được một tấm Tào Vận Quan Phiếu.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
        self:LuaFnAuditCaoYun(selfId, iDayCount, 1, Corpus)
        self:SetMissionByIndex(selfId, misIndex, 5, Corpus)
        self:SetMissionByIndex(selfId, misIndex, 6, 0)
        self:SetMissionByIndex(selfId, misIndex, 7, 0)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 113, 0)
        if r then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(2)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
        end
    elseif self:CheckAccept(selfId) > 0 then
        local ret = self:AddMission(selfId, self.g_MissionId, self.script_id,
                                    0, 0, 0)
        if not ret then return end
        ret = self:TryRecieveItem(selfId, self.g_CashItem_id)
        if ret then
            local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            self:SetMissionByIndex(selfId, misIndex, 0, 0)
            self:SetMissionByIndex(selfId, misIndex, 1, 0)
            self:SetMissionByIndex(selfId, misIndex, 2, 0)
            self:SetMissionByIndex(selfId, misIndex, 3, 0)
            self:SetMissionByIndex(selfId, misIndex, 4, 0)
            self:SetMissionEvent(selfId, self.g_MissionId, 0)
            local _, nDelJZ, nDelMoney = self:LuaFnCostMoneyWithPriority(selfId,  20000)
            if (nDelJZ == -1) then
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi ít nhất Yêu cầu có #{_EXCHG" .. Corpus ..
                                 "}, mới có thể nhận được quan phiếu.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return 0
            end
            if (nDelMoney <= 0) then
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi thế chấp #{_EXCHG" .. nDelJZ ..
                                 "}, nhận được một tấm Tào Vận Quan Phiếu.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            elseif (nDelJZ <= 0) then
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi thế chấp #{_MONEY" .. nDelMoney ..
                                 "}, nhận được một tấm Tào Vận Quan Phiếu.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            else
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi thế chấp #{_EXCHG" .. nDelJZ .. "}")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi thế chấp #{_MONEY" .. nDelMoney ..
                                 "}, nhận được một tấm Tào Vận Quan Phiếu.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
            self:LuaFnAuditCaoYun(selfId, iDayCount, 1, Corpus)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 113, 0)
            self:SetMissionByIndex(selfId, misIndex, 5, Corpus)
            self:SetMissionByIndex(selfId, misIndex, 6, 0)
            self:SetMissionByIndex(selfId, misIndex, 7, 0)
            local Caoyun_Times = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_SUMTIME)
            if Caoyun_Times == 0 then
                local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
                local msg =
                    "Xem ra ngài là Lần đầu tham gia Tào Vận rồi, Tào Vận quả thật là một ngành nghề có lợi nhuận rất lớn, theo Cấp độcủa tăng lên, không những số lần Tào Vận mỗi ngày sẽ tăng lên, mà lợi nhuận mỗi lần Tào Vận cũng sẽ có sự tăng trưởng rất lớn."
                local msg2 =
                    "Bất quá Tào Vận cũng không phức tạp như ngài tưởng tượng, chỉ cần nhấp vào nhận quan phiếu trên giao diện là có thể mua hàng hóa Tào Vận, đem hàng hóa tương ứng Vận chuyển đến Tào Vận Sứ của các thành phố Khác để bán là được."
                local msg3 =
                    "Nên nhớ trong #YTào Vận#Wtrạng thái không thể sử dụng #YDịch trạm#W và #YMôn phái#W#YNgười truyền tống#W để truyền tống."
                local cmsg = "Đa tạ lời giải thích của ngài..."
                self:BeginEvent(self.script_id)
                self:AddText(msg)
                self:AddText(msg2)
                self:AddText(msg3)
                self:AddNumText(cmsg, -1, 1)
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                self:LuaFnAwardTitle(selfId, 5, 193)
                self:SetCurTitle(selfId, 5, 193)
                self:LuaFnAddNewAgname(selfId, 5, 193)
                self:LuaFnDispatchAllTitle(selfId)
            elseif ret > 0 then
                self:BeginUICommand()
                self:UICommand_AddInt(5)
                self:UICommand_AddInt(2)
                self:EndUICommand()
                self:DispatchUICommand(selfId, 0)
            end
        else
            self:DelMission(selfId, self.g_MissionId)
            self:BeginEvent(self.script_id)
            local strText = "Không thể #Ynhận được#W vật phẩm, không thể tiếp nhận nhiệm vụ."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function ecaoyun:OnPopupBargainingUI(selfId)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId)then
        local ItemNum = self:GetItemCount(selfId, self.g_CashItem_id)
        if ItemNum < self.g_CashItem_count then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(6)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
            self:OnAbandon(selfId)
            return
        end
        self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_HUAN)
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
        local TransNpc = self:TransPortNPC(targetId)
        if TransNpc == 0 or TransNpc == -1 then return end
        self:UICommand_AddInt(misIndex)
        local Quotiety = 1
        local Price_Buy = 10000 * Quotiety
        local Price_Sell = Price_Buy * 150 / 100
        Price_Sell = self:Calculate_Margin(selfId, Price_Sell)
        self:UICommand_AddInt(Price_Buy)
        self:UICommand_AddInt(Price_Sell)
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(1)
        local Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP)
        local  Now_Time = self:LuaFnGetCurrentTime()
        if Now_Time - Pre_Time < 10 * 60 then
            self:UICommand_AddInt(Pre_Time + 10 * 60 - Now_Time)
        else
            self:UICommand_AddInt(0)
        end
        Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
        if Now_Time - Pre_Time < 15 * 60 then
            self:UICommand_AddInt(Pre_Time + 15 * 60 - Now_Time)
        else
            self:UICommand_AddInt(0)
        end
        self:UICommand_AddInt(TransNpc)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1)
    end
end

function ecaoyun:OnTrade(selfId, ManipulateID)
    if not self:LuaFnIsCanDoScriptLogic(selfId) then return end
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
    local TransNPC = self:TransPortNPC(targetId)
    if TransNPC == 0 or TransNPC == -1 then return end
    if ManipulateID ~= 1 and ManipulateID ~= 2 and ManipulateID ~= 3 then
        return
    end
    local nData = self:GetMissionParam(selfId, misIndex, 2)
    nData = (nData % 1000)
    local nData1 = math.floor(nData / 100)
    local nData2 = math.floor((nData - nData1 * 100) / 10)
    local nData3 = math.floor(nData - nData1 * 100 - nData2 * 10)
    local sceneId = self:get_scene_id()
    if ManipulateID == 1 then
        if sceneId == 0 then
            if nData1 ~= 0 then return end
        else
            if nData1 == 0 then return end
        end
    end
    if ManipulateID == 2 then
        if sceneId == 2 then
            if nData2 ~= 0 then return end
        else
            if nData2 == 0 then return end
        end
    end
    if ManipulateID == 3 then
        if sceneId == 1 then
            if nData3 ~= 0 then return end
        else
            if nData3 == 0 then return end
        end
    end
    if ManipulateID == TransNPC then
        misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local Price_Down = self:GetMissionParam(selfId, misIndex, 1)
        local Cargo = self:GetMissionParam(selfId, misIndex, 2)
        local Cargo_Standard = 0
        local purchased = 0
        if TransNPC == 1 then
            Cargo_Standard = 100
            if Cargo % 1000 >= Cargo_Standard then
                purchased = 1
            end
        elseif TransNPC == 2 then
            Cargo_Standard = 10
            if Cargo % 100 >= Cargo_Standard then
                purchased = 1
            end
        elseif TransNPC == 3 then
            Cargo_Standard = 1
            if Cargo % 10 >= Cargo_Standard then
                purchased = 1
            end
        elseif TransNPC == 4 then
            Cargo_Standard = 1000
            if Cargo % 10000 >= Cargo_Standard then
                purchased = 1
            end
        end
        if purchased > 0 then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(7)
            self:UICommand_AddInt(ManipulateID)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
            return
        end
        if Price_Down == 0 then
            local Quotiety = 1
            Price_Down = 10000 * Quotiety
            local Pre_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN)
            local Now_Time = self:LuaFnGetCurrentTime()
            local nMoney = self:GetMoney(selfId)
            local nLevel = self:GetLevel(selfId)
            if (Now_Time - Pre_Time >= 15 * 60) and
                math.floor(
                    (nMoney / 31 * 17 + 73 + nLevel % 21596 + Quotiety)) ==
                15982 then
                self:BeginAddItem()
                self:AddItem(30103001, 1)
                local ret = self:EndAddItem(selfId)
                if ret then
                    self:AddItemListToHuman(selfId)
                    self:BeginEvent(self.script_id)
                    local strText =
                        "Ngươi không mặc cả, may mắn thay, một bát cháo dương sâm thổ miết từ trời rơi vào túi."
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                else
                    self:BeginEvent(self.script_id)
                    local  strText = "Túi đã đầy, không nhận được vật phẩm phần thưởng"
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                end
            end
        end
        local Balance = self:GetMissionParam(selfId, misIndex, 5)
        if Balance < Price_Down then
            self:BeginEvent(self.script_id)
            local strText = "Vốn lưu động của Tào Vận không đủ để mua hàng hóa này."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        if self:OnAdd_CaoyunTime(selfId) <= 0 then return 0 end
        Balance = Balance - Price_Down
        self:SetMissionByIndex(selfId, misIndex, 5, Balance)
        self:SetMissionByIndex(selfId, misIndex, 1, 0)
        Cargo = Cargo + Cargo_Standard
        self:SetMissionByIndex(selfId, misIndex, 2, Cargo)
        self:BeginEvent(self.script_id)
        local strText
        if (ManipulateID == 1) then
            strText = "Ngươi đã mua thành công một phần muối"
        elseif (ManipulateID == 2) then
            strText = "Ngươi đã mua thành công một phần sắt"
        elseif (ManipulateID == 3) then
            strText = "Ngươi đã mua thành công một phần gạo"
        elseif (ManipulateID == 4) then
            strText = "Ngươi đã mua thành công một phần muối lậu"
        end
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(11)
        self:UICommand_AddInt(Price_Down)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        self:SetMissionByIndex(selfId, misIndex, 3, ManipulateID)
    else
        misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local Price_Up = self:GetMissionParam(selfId, misIndex, 0)
        local bUp = 0
        if Price_Up == 0 then
            bUp = 0
        else
            bUp = 1
        end
        if bUp == 0 then
            Price_Up = 15000
        else
            Price_Up = 18000
        end
        local Cargo = self:GetMissionParam(selfId, misIndex, 2)
        local Cargo_Standard = 0
        local purchased = 0
        if ManipulateID == 1 then
            Cargo_Standard = 100
            if Cargo % 1000 < Cargo_Standard then
                purchased = 1
            end
        elseif ManipulateID == 2 then
            Cargo_Standard = 10
            if Cargo % 100 < Cargo_Standard then
                purchased = 1
            end
        elseif ManipulateID == 3 then
            Cargo_Standard = 1
            if Cargo % 10 < Cargo_Standard then
                purchased = 1
            end
        elseif ManipulateID == 4 then
            Cargo_Standard = 1000
            if Cargo % 10000 < Cargo_Standard then
                purchased = 1
            end
        end
        if purchased > 0 then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(8)
            self:UICommand_AddInt(ManipulateID)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
            return
        end
        local HaveChop = self:Calculate_Double(selfId)
        if HaveChop == 2 then
            Price_Up = (Price_Up - 10000) * 2 + 10000
            self:BeginEvent(self.script_id)
            local strText = string.format(
                          "Bởi vì có lộ dẫn vận chuyển đường sông, ngài bán hàng nhận được lợi nhuận gấp đôi.")
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:Msg2Player(selfId,
                            "Bởi vì có lộ dẫn vận chuyển đường sông, ngài bán hàng nhận được lợi nhuận gấp đôi.",
                            define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
        local SpecialDay = self:Calculate_Calender(selfId)
        if SpecialDay == 2 then Price_Up = (Price_Up - 10000) * 2 + 10000 end
        if self:GetMissionParam(selfId, misIndex, 4) == ManipulateID then
            Price_Up = math.floor(Price_Up * 110 / 100)
            self:SetMissionByIndex(selfId, misIndex, 4, 0)
        end
        Price_Up = self:Calculate_Margin(selfId, Price_Up)
        local Balance = self:GetMissionParam(selfId, misIndex, 5)
        Balance = Balance + Price_Up
        self:SetMissionByIndex(selfId, misIndex, 5, Balance)
        self:SetMissionByIndex(selfId, misIndex, 0, 0)
        Cargo = Cargo - Cargo_Standard
        self:SetMissionByIndex(selfId, misIndex, 2, Cargo)
        local trade = 1
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(11)
        self:UICommand_AddInt(Price_Up)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        if trade == 1 then
            misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            local Mission_Round = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_HUAN)
            self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_HUAN, Mission_Round + 1)
            self:BeginEvent(self.script_id)
            local strText
            if (ManipulateID == 1) then
                strText = "Ngươi đã thành công bán một phần muối."
            elseif (ManipulateID == 2) then
                strText = "Ngươi đã thành công bán một phần sắt."
            elseif (ManipulateID == 3) then
                strText = "Ngươi đã thành công bán một phần gạo."
            elseif (ManipulateID == 4) then
                strText = "Ngươi đã thành công bán một phần muối lậu."
            end
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            strText =
                string.format("Chuyến Tào Vận này là Khuyên thứ %d.", (Mission_Round + 1))
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:LuaFnAuditCaoyunDone(selfId)
            self:LuaFnAddMissionHuoYueZhi(selfId, 25)
            local  Sum_Time = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_SUMTIME)
            self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_SUMTIME, Sum_Time + 1)
            if math.random(100) <= 5 then
                local my_level = self:GetLevel(selfId)
                local reward_item
                local medicine_level = math.floor(my_level / 10)
                if medicine_level < 1 then
                    medicine_level = 1
                elseif medicine_level > 10 then
                    medicine_level = 10
                end
                if math.random(100) <= 50 then
                    reward_item = self.g_Reward_Medicine_HP[medicine_level]
                else
                    reward_item = self.g_Reward_Medicine_MP[medicine_level]
                end
                local ret = self:TryRecieveItem(selfId, reward_item)
                if ret then
                    self:BeginEvent(self.script_id)
                    strText = string.format("Ngươi nhận được #{_ITEM%d}.", reward_item)
                    self:AddText(strText)
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                else
                    self:SetMissionByIndex(selfId, misIndex, 3, 4)
                    targetId = self:GetMissionData(selfId,
                                                         define.MD_ENUM.MD_CAOYUN_TARGETID)
                    self:BeginEvent(self.script_id)
                    self:AddText(
                        "Để thưởng cho cống hiến của ngươi đối với Tào Vận, ta đặc biệt chuẩn bị cho ngươi một phần #{_ITEM" ..
                            reward_item ..
                            "}, nhưng túi của ngươi đã đầy, không thể trao tặng, xin hãy thu xếp lại túi rồi báo cho ta.")
                    self:AddNumText("Túi của ta đã thu xếp xong rồi.", -1, 3)
                    self:AddNumText("Thôi vậy ta không cần nữa.", -1, 0)
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                end
            end
        end
    end
end

function ecaoyun:OnRedeemUI(selfId)
    if not self:LuaFnIsCanDoScriptLogic(selfId) then return end
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then return end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local ItemNum = self:GetItemCount(selfId, self.g_CashItem_id)
        if ItemNum < self.g_CashItem_count then
            self:BeginUICommand()
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(4)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 0)
            return
        end
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local Cargo = self:GetMissionParam(selfId, misIndex, 2)
        if Cargo > 0 then
            self:BeginEvent(self.script_id)
            local strText = string.format("Phải thanh khoang mới có thể đổi quan phiếu.")
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        local iDayCount = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT)
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(3)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
        misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local Balance = self:GetMissionParam(selfId, misIndex, 5)
        local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
        local TransNPC = self:TransPortNPC(targetId)
        if TransNPC == 4 then return end
        local Quotiety = 2
        local Corpus = 10000 * Quotiety
        local Margin = Balance - Corpus
        if self:OnAccomplished(selfId) ~= 1 then return end
        if Margin > 0 then
            self:AddMoneyJZ(selfId, 1.2 * (Margin + Corpus))
            self:LuaFnAuditCaoYun(selfId, iDayCount, 0, Margin)
            local msg =
                "Chúc mừng ngài kết thúc Tào Vận, vòng Tào Vận này ngài nhận được thu nhập #{_EXCHG" ..
                    Balance ..
                    ", sau khi khấu trừ Tiền thế chấp #{_EXCHG20000} và thêm vào khoản lợi nhuận bổ sung nhận được của việc sử dụng ngân phiếu #{_EXCHG" ..
                    0.2 * Balance ..
                    "} rồi, cuối cùng chư vị nhận được tiền hoa hồng là #{_EXCHG" .. 1.2 *
                    Balance - Corpus .. "}。"
            local cmsg = "Tham tài tham tài..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
        elseif Balance > 0 then
            self:AddMoneyJZ(selfId, Balance)
            self:LuaFnAuditCaoYun(selfId, iDayCount, 0, 0)
            self:BeginEvent(self.script_id)
            local strText = string.format(
                          "Ngươi kinh doanh không tốt, không nhận được hoa hồng, chỉ lấy lại vốn liếng vận chuyển ban đầu #{_EXCHG" ..
                              Balance .. "}。")
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:LuaFnAuditCaoYun(selfId, iDayCount, 0, -Corpus)
            self:BeginEvent(self.script_id)
            local strText = string.format(
                          "Ngươi kinh doanh không tốt, không nhận được hoa hồng, ngay cả vốn liếng cũng mất sạch.")
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end

function ecaoyun:OnFinishHaggleDown(selfId)
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINDOWN, 0)
    self:BeginUICommand()
    self:UICommand_AddInt(5)
    self:UICommand_AddInt(14)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 0)
    return
end

function ecaoyun:OnFinishHaggleUp(selfId)
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_BARGAINUP, 0)
    self:BeginUICommand()
    self:UICommand_AddInt(5)
    self:UICommand_AddInt(13)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 0)
    return
end

function ecaoyun:OnAbandon(selfId)
    self:OnAccomplished(selfId)
    self:OnAbandon_Necessary(selfId)
end

function ecaoyun:OnAccomplished(selfId)
    if not self:DelItem(selfId, self.g_CashItem_id, self.g_CashItem_count) then
        return 0
    end
    local ret = self:DelMission(selfId, self.g_MissionId)
    if ret then
        self:SetCurTitle(selfId, 0, 193)
        self:DeleteTitle(selfId, 5)
        self:LuaFnDispatchAllTitle(selfId)
        self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_MONSTERTIMER, 0)
    end
    self:LuaFnCancelSpecificImpact(selfId, 113)
    return 1
end

function ecaoyun:OnHumanDie(selfId, killerId)
    self:OnAccomplished(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("#{CYSB_081107_1}")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    self:BroadMsgByChatPipe(selfId, "#{CYSB_081107_1}", 8)
end

function ecaoyun:OnAccept_Necessary(selfId)
    local Max_Time_EveryDay = 20
    local iDayHuan = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iQuarterTime = (iTime % 100)
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if iTime == CurTime then
        self:BeginEvent(self.script_id)
        local strText = string.format("Thời gian chưa đến, vẫn chưa thể tiếp nhận nhiệm vụ Tào Vận.")
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return -1
    end
    if CurDaytime == iDayTime then
        if iDayHuan >= Max_Time_EveryDay then
            local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
            local msg =
                "Xin lỗi, số lần nhiệm vụ Tào Vận mà ngài làm hôm nay đã đạt" ..
                    Max_Time_EveryDay .. "đến giới hạn, xin ngài ngày mai hãy đến lại!"
            local cmsg = "Ta đã biết..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
            return -1
        end
    else
        iDayHuan = 0
    end
    local newTime = CurDaytime * 100 + iQuarterTime
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT, iDayHuan)
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYTIME, newTime)
    return 1
end

function ecaoyun:OnAdd_CaoyunTime(selfId)
    local Max_Time_EveryDay = 20
    local iDayHuan = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT)
    local iTime = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYTIME)
    local iDayTime = math.floor(iTime / 100)
    local iQuarterTime = iTime % 100
    local CurTime = self:GetQuarterTime()
    local CurDaytime = math.floor(CurTime / 100)
    if CurDaytime == iDayTime then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local Cargo = self:GetMissionParam(selfId, misIndex, 2)
        if Cargo > 0 and iDayHuan >= Max_Time_EveryDay - 1 then end
        if (iDayHuan >= Max_Time_EveryDay) then
            local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
            local msg = "Tào Vận của ngài hôm nay đã đạt đến giới hạn 20 lần."
            local cmsg = "Ta đã biết..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
            return -1
        end
        iDayHuan = iDayHuan + 1
    else
        iDayHuan = 0
    end
    local newTime = CurDaytime * 100 + iQuarterTime
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYCOUNT, iDayHuan)
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYTIME, newTime)
    return 1
end

function ecaoyun:OnAbandon_Necessary(selfId)
    local CurTime = self:GetQuarterTime()
    self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_DAYTIME, CurTime)
    return 1
end

function ecaoyun:OnPlayerCaoyunTimer(selfId)
    local Detect = 0
    local sceneId = self:get_scene_id()
    for i, eachId in pairs(self.g_Traverse_Region) do
        if eachId == sceneId then Detect = 1 end
    end
    local Orientation_Article = 0
    local Article_Quantity
    for i, item in pairs(self.g_EludeItem) do
        Article_Quantity = self:GetItemCount(selfId, item["id"])
        if Article_Quantity ~= item["num"] then Orientation_Article = 1 end
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 137) then return end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 136) and
        math.random(2) == 1 then return end
    if Detect == 1 and Orientation_Article == 1 then
        local rrr = math.random(100)
        if math.random(2) < 3 then
            local iMonsterCount = self:GetMissionData(selfId,
                                                      define.MD_ENUM.MD_CAOYUN_MONSTERTIMER)
            if iMonsterCount < 4 then
                iMonsterCount = iMonsterCount + 1
            end
            if iMonsterCount == 1 or iMonsterCount == 2 then
                self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_MONSTERTIMER,
                                    iMonsterCount)
                if math.random(100) <= 20 then
                    self:LuaFnSendGuajiQuestion(selfId)
                    return
                end
                local pos_x = self:GetHumanWorldX(selfId)
                local pos_z = self:GetHumanWorldZ(selfId)
                local Level_Self = self:GetLevel(selfId)
                local Adapt = math.floor((Level_Self - 1) / 10)
                if Adapt < 1 then
                    Adapt = 1
                elseif Adapt > 20 then
                    Adapt = 20
                end
                local Monster_Id = self.g_Accommodate_Distinction[Adapt]
                local npcobjid = self:LuaFnCreateMonster(Monster_Id, pos_x, pos_z, 10,
                                                   95, 311011)
                self:Diversification(npcobjid)
                self:SetLevel(npcobjid, Level_Self - 1)
                self:SetCharacterTimer(npcobjid, 60000)
                self:SetCharacterDieTime(npcobjid, 60000 * 4)
                self:AddPrimaryEnemy(npcobjid, selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, npcobjid, npcobjid,
                                                   114, 0)
                self:BeginEvent(self.script_id)
                local strText = string.format("Xin chú ý, nơi này có cường đạo lui tới!")
                self:AddText(strText)
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 37, 0)
                self:LuaFnSendSpecificImpactToUnit(selfId, npcobjid, npcobjid,
                                                   37, 0)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 38, 0)
                for i = 1, 2 do
                    if (rrr > 5 and i == 1) or (rrr > 35 and i == 2) then
                        Monster_Id = self.g_Acclimatize_Distinction[Adapt]
                        local this_x, this_z =
                            self:Random_Nativity(pos_x, pos_z, i)
                        npcobjid = self:LuaFnCreateMonster(Monster_Id, this_x,
                                                           this_z, 10, 95,
                                                           311011)
                        self:Diversification(npcobjid)
                        if i == 1 then
                            self:Msg2Player(selfId,
                                            "@*;npcpaopao;" .. npcobjid .. ";15",
                                            define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                        else
                            self:Msg2Player(selfId,
                                            "@*;npcpaopao;" .. npcobjid .. ";16",
                                            define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
                        end
                        self:SetLevel(npcobjid, Level_Self - 2)
                        self:SetCharacterTimer(npcobjid, 60000)
                        self:SetCharacterDieTime(npcobjid, 60000 * 4)
                        self:AddPrimaryEnemy(npcobjid, selfId)
                        self:LuaFnSendSpecificImpactToUnit(selfId, npcobjid,
                                                           npcobjid, 114, 0)
                        self:LuaFnSendSpecificImpactToUnit(selfId, npcobjid,
                                                           npcobjid, 37, 0)
                    end
                end
            elseif iMonsterCount == 100 then
                self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_MONSTERTIMER, 0)
            end
        end
    else
        self:SetCharacterTimer(selfId, 0)
    end
end

function ecaoyun:OnPlayerEnterCaoyunScene(selfId)
    local find = 0
    local sceneId = self:get_scene_id()
    for i, eachId in pairs(self.g_Traverse_Region) do
        if eachId == sceneId then find = 1 end
    end
    if find == 1 then
        self:SetCharacterTimer(selfId, 45000)
        self:SetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_MONSTERTIMER, 100)
        self:BeginEvent(self.script_id)
        local strText = string.format("Xin chú ý, nơi này có cường đạo lui tới!")
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:SetCharacterTimer(selfId, 0)
    end
    return 1
end

function ecaoyun:Diversification(MonsterId)
    local ret = math.random(7)
    local part1 = self.g_TitleTableOfMonster[ret]["part1"]
    ret = math.random(7)
    local part2 = self.g_TitleTableOfMonster[ret]["part2"]
    local str = string.format("%s%s", part1, part2)
    self:SetCharacterTitle(MonsterId, str)
    ret = math.random(8)
    part1 = self.g_NameTableOfMonster[ret]["part1"]
    ret = math.random(8)
    part2 = self.g_NameTableOfMonster[ret]["part2"]
    ret = math.random(8)
    local part3 = self.g_NameTableOfMonster[ret]["part3"]
    local part4
    local rd = math.random(4)
    if rd == 1 then
        part4 = string.format("%s%s", part2, part3)
    elseif rd == 2 then
        part4 = part2
    elseif rd == 3 then
        part4 = part3
    else
        part4 = string.format("%s%s", part3, part2)
    end
    str = string.format("%s%s", part1, part4)
    self:SetCharacterName(MonsterId, str)
    return 1
end

function ecaoyun:IsSkillLikeScript(selfId) return 0 end

function ecaoyun:Random_Nativity(position_x, position_z, Range)
    local Variety_X, Variety_Z
    if position_x > 2 then
        Variety_X = position_x - 1 + math.random(3) + math.random(Range + 1)
    end
    if position_z > 2 then
        Variety_Z = position_z - 1 + math.random(3) + math.random(Range + 1)
    end
    return Variety_X, Variety_Z
end

function ecaoyun:Client_Show_Message(selfId, targetId, Message, CloseMessage,
                                     NumText)
    self:BeginEvent(self.script_id)
    self:AddText(Message)
    self:AddNumText(CloseMessage, -1, NumText)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ecaoyun:OnHandle_QuestUI(selfId, targetId, NumText)
    if NumText == 0 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    elseif NumText == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
    elseif NumText == 2 then
        local Caoyun_Times = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_SUMTIME)
        local find = -1
        for i, times in pairs(self.g_Title_Times_Confine) do
            if times <= Caoyun_Times then
                find = i
                break
            end
        end
        self:BeginUICommand()
        self:UICommand_AddInt(5)
        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 0)
    elseif NumText == 3 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        local my_level = self:GetLevel(selfId)
        local medicine_level = math.floor(my_level / 10)
        local reward_item
        if medicine_level < 1 then
            medicine_level = 1
        elseif medicine_level > 10 then
            medicine_level = 10
        end
        if math.random(100) < 50 then
            reward_item = self.g_Reward_Medicine_HP[medicine_level]
        else
            reward_item = self.g_Reward_Medicine_MP[medicine_level]
        end
        self:TryRecieveItem(selfId, reward_item)
    elseif NumText > 3 and NumText < 17 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        local sceneId = self:get_scene_id()
        local Scene_Info = self.g_Transportation_Exit[sceneId]
        if Scene_Info then
            for i = 1, 2 do
                if Scene_Info[i]["Exit_Reply_Number"] == NumText then
                    self:SetPos(selfId, Scene_Info[i]["Exit_Position"]["x"],
                                Scene_Info[i]["Exit_Position"]["y"])
                end
            end
        end
    elseif NumText > 16 and NumText < 20 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        local Scene_Info = self.g_Transportation_City[NumText - 17]
        if Scene_Info then
            local rrr = math.random(3) - 1
            self:NewWorld(selfId, NumText - 17, nil, Scene_Info[rrr]["x"],
                          Scene_Info[rrr]["y"])
        end
    elseif NumText > 19 and NumText < 23 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        local Scene_Info = self.g_Transportation_Legate[NumText - 20]
        if Scene_Info then
            self:NewWorld(selfId, NumText - 20, nil, Scene_Info["Position"]["x"],
                          Scene_Info["Position"]["y"])
        end
    elseif NumText > 22 and NumText < 27 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        local my_level = self:GetLevel(selfId)
        local level_phase
        if my_level >= 30 and my_level < 40 then
            level_phase = 1
        elseif my_level >= 40 and my_level < 55 then
            level_phase = 2
        elseif my_level >= 55 and my_level < 65 then
            level_phase = 3
        elseif my_level >= 65 and my_level < 75 then
            level_phase = 4
        elseif my_level >= 75 and my_level < 85 then
            level_phase = 5
        elseif my_level >= 85 and my_level < 95 then
            level_phase = 6
        elseif my_level >= 95 and my_level < 105 then
            level_phase = 7
        elseif my_level >= 105 and my_level < 115 then
            level_phase = 8
        elseif my_level >= 115 then
            level_phase = 9
        end
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                           self.g_SpecialImpact[NumText]["Impact_ID"][level_phase],
                                           0)
    elseif NumText == 27 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                           self.g_IncreaseSpeed_Impact[NumText]["Impact_ID"],
                                           0)
    elseif NumText == 28 then
        self:Monger_Random(selfId)
    end
end

function ecaoyun:TransPortNPC(targetId)
    local TransportNPCName = self:GetName(targetId)
    local type = self:GetCharacterType(targetId)
    if type ~= 2 then return -1 end
    if TransportNPCName == "赵明诚" then
        return 1
    elseif TransportNPCName == "陆士铮" then
        return 3
    elseif TransportNPCName == "王若禹" then
        return 2
    elseif TransportNPCName == "黑市商人" then
        return 4
    else
        return -1
    end
end

function ecaoyun:Close_Carriage_UI(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local Statue = self:GetMissionParam(selfId, misIndex, 3)
    if Statue == 1 or Statue == 2 or Statue == 3 then
        self:SetMissionByIndex(selfId, misIndex, 3, 0)
        local rrr = math.random(100)
        local strText
        if rrr <= 2 and self:GetMissionParam(selfId, misIndex, 4) <= 0 then
            if (Statue == 1) then
                strText = "muối"
            elseif (Statue == 2) then
                strText = "sắt"
            elseif (Statue == 3) then
                strText = "gạo"
            end
            local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
            local msg = "Chúc mừng ngài, hàng hóa Tào Vận lần này của ngài là cấp 1" ..
                            strText ..
                            "Lần Tào Vận này lợi nhuận của ngài sẽ tăng 10%."
            local cmsg = "Vận khí không tệ..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
            self:SetMissionByIndex(selfId, misIndex, 4, Statue)
        elseif rrr <= 5 then
            local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
            local msg =
                "Chúc mừng ngài, lần Tào Vận này của ngài sẽ có nha dịch bảo vệ dọc đường, như vậy ngài sẽ không gặp phải cường nhân cướp Tào Hóa."
            local cmsg = "Vận khí không tệ..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 137, 0)
        elseif rrr <= 10 then
            local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
            local msg =
                "Chúc mừng ngài, ngài rất may mắn, trong quá trình Tào Vận, tỷ lệ ngài gặp phải cường nhân sẽ giảm 50%."
            local cmsg = "Vận khí không tệ..."
            self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 136, 0)
        end
    end
end

function ecaoyun:Monger_Random(selfId)
    local targetId = self:GetMissionData(selfId, define.MD_ENUM.MD_CAOYUN_TARGETID)
    --TRAFFICKER_CLICK_TIMES = TRAFFICKER_CLICK_TIMES + 1
    local PlayerSex = self:GetSex(selfId)
    if PlayerSex == 0 then
        PlayerSex = "Hiệp Nữ"
    else
        PlayerSex = "Đại Hiệp"
    end
    local rrr = math.random(100)
    if rrr < 0 then
        local msg = "Xin lỗi, vận may của ngươi không tốt."
        local cmsg = "Ta lần sau lại đến..."
        self:Client_Show_Message(selfId, targetId, msg, cmsg, 0)
    elseif rrr <= 20 then
        local sceneId = self:get_scene_id()
        local City_Exit = self.g_Transportation_Exit[sceneId]
        if City_Exit then
            self:BeginEvent(self.script_id)
            self:AddText(PlayerSex ..
                             ", ngài cũng thật vất vả, ta cũng giúp ngài một chút vậy, hy vọng lần sau có thể chiếu cố chút sinh ý cho ta, ta có thể giúp ngài truyền tống đến chỗ lối vào của bản đồ tiếp theo, ngài muốn đi đâu?")
            self:AddNumText("Ta muốn đến" .. City_Exit[1]["Exit_Name"] ..
                                "của lối vào", -1,
                            City_Exit[1]["Exit_Reply_Number"])
            self:AddNumText("Ta muốn đến" .. City_Exit[2]["Exit_Name"] ..
                                "của lối vào", -1,
                            City_Exit[2]["Exit_Reply_Number"])
            self:AddNumText("Ta vẫn là tự mình chạy thì hơn.", -1, 0)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif rrr <= 40 then
        self:BeginEvent(self.script_id)
        self:AddText(PlayerSex ..
                         ", ngài cũng thật vất vả, ta cũng giúp ngài một chút việc nhỏ vậy, mong rằng lần sau có thể chiếu cố mối làm ăn của ta, ta có thể giúp ngài truyền tống đến thành thị mà ngài muốn đến, ngài muốn đi đâu?")
        for i = 0, #(self.g_Transportation_City) do
            self:AddNumText("Ta muốn đi" ..
                                self.g_Transportation_City[i]["Scene_Name"], -1,
                            self.g_Transportation_City[i]["Reply_Number"])
        end
        self:AddNumText("Ta vẫn là tự mình chạy thì hơn.", -1, 0)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif rrr <= 40 then
        self:BeginEvent(self.script_id)
        self:AddText(PlayerSex ..
                         ", ngài cũng thật vất vả, ta cũng giúp ngài một chút việc nhỏ vậy, mong rằng lần sau có thể chiếu cố mối làm ăn của ta, ta có thể giúp ngài truyền tống đến gần Tào Vận Sứ, ngài muốn đi đâu?")
        for i = 0, #(self.g_Transportation_Legate) do
            self:AddNumText("Ta muốn đi" ..
                                self.g_Transportation_Legate[i]["Scene_Name"] ..
                                "của chỗ Tào Vận Sứ", -1,
                            self.g_Transportation_Legate[i]["Reply_Number"])
        end
        self:AddNumText("Ta vẫn là tự mình chạy thì hơn.", -1, 0)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif rrr <= 48 then
        local find
        if rrr < 43 then
            find = 23
        elseif rrr < 45 then
            find = 24
        elseif rrr < 47 then
            find = 25
        elseif rrr < 49 then
            find = 26
        end
        self:BeginEvent(self.script_id)
        self:AddText(
            "Đường vận chuyển Tào Vận một đường hung hiểm, ta ở đây có thể cho ngươi một chút giúp đỡ, tăng thêm một ít" ..
                self.g_SpecialImpact[find]["Impact_Name"] ..
                ", bất quá lần sau nếu ta có hàng lậu muốn ra tay thì ngươi phải giúp ta đó.")
        self:AddNumText("Được thôi", -1, find)
        self:AddNumText("Ta vẫn là tự mình chạy thì hơn.", -1, 0)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText(
            "Đường sá Tào Vận còn rất dài, ta ở đây có thể giúp ngươi một chút, tăng Tốc độ di chuyển của ngươi trong thời gian ngắn, nhưng lần sau nhất định phải nhớ chiếu cố sinh ý của ta nhiều hơn, cả nhà già trẻ của ta đều nhờ ta nuôi sống đấy.")
        self:AddNumText("Được thôi", -1, 27)
        self:AddNumText("Ta vẫn là tự mình chạy thì hơn.", -1, 0)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    return
end

return ecaoyun
