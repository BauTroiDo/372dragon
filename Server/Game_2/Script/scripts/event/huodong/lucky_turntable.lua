
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local lucky_turntable = class("lucky_turntable", script_base)
lucky_turntable.script_id = 808071
lucky_turntable.g_UICommand = 1999986
lucky_turntable.g_BufferId = 8057
lucky_turntable.g_GetXingYunDataParameter = {1, 2, 3, 4, 5, 6}

lucky_turntable.g_DragonItem = {20310103, 20310104, 20310105}

lucky_turntable.g_Exp = {
    [20] = 1274,
    [21] = 1354,
    [22] = 1434,
    [23] = 1514,
    [24] = 1594,
    [25] = 1674,
    [26] = 1754,
    [27] = 1834,
    [28] = 1914,
    [29] = 1994,
    [30] = 2074,
    [31] = 2154,
    [32] = 2234,
    [33] = 2314,
    [34] = 2394,
    [35] = 2474,
    [36] = 2554,
    [37] = 2634,
    [38] = 2714,
    [39] = 2794,
    [40] = 2874,
    [41] = 2954,
    [42] = 3034,
    [43] = 3114,
    [44] = 3194,
    [45] = 3274,
    [46] = 3354,
    [47] = 3434,
    [48] = 3514,
    [49] = 3594,
    [50] = 3674,
    [51] = 3754,
    [52] = 3834,
    [53] = 3914,
    [54] = 3994,
    [55] = 4074,
    [56] = 4154,
    [57] = 4234,
    [58] = 4314,
    [59] = 4394,
    [60] = 4474,
    [61] = 4554,
    [62] = 4634,
    [63] = 4714,
    [64] = 4794,
    [65] = 4874,
    [66] = 4954,
    [67] = 5034,
    [68] = 5114,
    [69] = 5194,
    [70] = 5274,
    [71] = 5354,
    [72] = 5434,
    [73] = 5514,
    [74] = 5594,
    [75] = 5674,
    [76] = 5754,
    [77] = 5834,
    [78] = 5914,
    [79] = 5994,
    [80] = 6074,
    [81] = 6154,
    [82] = 6234,
    [83] = 6314,
    [84] = 6394,
    [85] = 6474,
    [86] = 6554,
    [87] = 6634,
    [88] = 6714,
    [89] = 6794,
    [90] = 6874,
    [91] = 6954,
    [92] = 7034,
    [93] = 7114,
    [94] = 7194,
    [95] = 7274,
    [96] = 7354,
    [97] = 7434,
    [98] = 7514,
    [99] = 7594,
    [100] = 7674,
    [101] = 7754,
    [102] = 7834,
    [103] = 7914,
    [104] = 7994,
    [105] = 8074,
    [106] = 8154,
    [107] = 8234,
    [108] = 8314,
    [109] = 8394,
    [110] = 8474,
    [111] = 8554,
    [112] = 8634,
    [113] = 8714,
    [114] = 8794,
    [115] = 8874,
    [116] = 8954,
    [117] = 9034,
    [118] = 9114,
    [119] = 9194,
    [120] = 9274,
    [121] = 9354,
    [122] = 9434,
    [123] = 9514,
    [124] = 9594,
    [125] = 9674,
    [126] = 9754,
    [127] = 9834,
    [128] = 9914,
    [129] = 9994,
    [130] = 10074,
    [131] = 10154,
    [132] = 10234,
    [133] = 10314,
    [134] = 10394,
    [135] = 10474,
    [136] = 10554,
    [137] = 10634,
    [138] = 10714,
    [139] = 10794,
    [140] = 10874,
    [141] = 10954,
    [142] = 11034,
    [143] = 11114,
    [144] = 11194,
    [145] = 11274,
    [146] = 11354,
    [147] = 11434,
    [148] = 11514,
    [149] = 11594,
    [150] = 11674
}

function lucky_turntable:OnDefaultEvent(selfId, targetId, arg, index)
    local NumText = index
    if NumText == 111 then
        self:JoinCampaign(selfId, targetId)
    elseif NumText == 112 then
        self:CheckTime(selfId)
        if (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[1]) ~= 3 or
            (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[4]) == 0 and
                self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[5]) ==
                0 and
                self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[6]) ==
                0)) then
            self:BeginEvent(self.script_id)
            self:AddText("#{XYLP_20071222_02}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:GivePlayerPrize(selfId, targetId)
    elseif NumText == 113 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYLP_20071222_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 114 then
        if (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[2]) == 0) then
            return
        end
        if (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[2]) == 2) then
            return
        end
        local DragonOdds = math.random(1, 150)
        self:BeginEvent(self.script_id)
        if (DragonOdds == 150) then
            local PlayerName = self:GetName(selfId)
            self:AddText("#{XYLP_20071222_16}")
            local msg = string.format(
                            "@*;SrvMsg;SCA:#{XYLP_20071222_17}#{_INFOUSR%s}#{XYLP_20071222_18}",
                            PlayerName)
            self:AddGlobalCountNews(msg)
            self:SetXingYunData(selfId, -1, 2, 1, -1, -1, -1)
            self:LuaFnAuditLuckyTurnTableDragon(selfId, 6, 0)
        else
            self:AddText("#{XYLP_20071222_15}")
            self:SetXingYunData(selfId, -1, 0, -1, -1, -1, -1)
        end
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif NumText == 115 then
        if (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[3]) ~= 1) then
            self:BeginEvent(self.script_id)
            self:AddText("#{XYLP_20071222_19}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
            self:BeginEvent(self.script_id)
            self:AddText("Túi của ngươi không đủ chỗ, không thể lĩnh phần thưởng.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        self:GetItem(selfId, 7, targetId)
        self:SetXingYunData(selfId, -1, 0, 0, -1, -1, -1)
    elseif NumText == 116 then
        self:SwitchDragon(selfId, targetId)
    end
end

function lucky_turntable:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Xổ số May mắn", 6, 111)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh phần thưởng \"Tam Khoái Hoạt May Mắn\"", 6, 112)
    caller:AddNumTextWithTarget(self.script_id, "Thuyết minh rút thưởng \"Tam Khoái Hoạt May Mắn\"", 11, 113)
    if (self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[2]) ~= 0) then
        caller:AddNumTextWithTarget(self.script_id, "Tam Khoái Hoạt: Phi Long!", 6, 114)
        caller:AddNumTextWithTarget(self.script_id, "Lĩnh Phi Long", 6, 115)
    end
    caller:AddNumTextWithTarget(self.script_id, "Đổi Phi Long", 6, 116)
end

function lucky_turntable:JoinCampaign(selfId, targetId)
    if self:GetLevel(selfId) < 20 then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Cấp độ của ngươi chưa đủ cấp 20, chưa thể tham gia hoạt động rút thưởng \"Tam Khoái Hoạt May Mắn\"!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:CheckTime(selfId)
    local join = self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[1])
    if (join ~= 0) then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Hôm nay ngươi đã tham gia hoạt động rút thưởng \"Tam Khoái Hoạt May Mắn\"! Xin hãy quay lại vào ngày mai!")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_BufferId) then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYLP_20071222_08}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 19999)
end

function lucky_turntable:GetXingYunData(selfId, index)
    local temp = 0
    local XingYunData = self:GetMissionData(selfId, define.MD_ENUM.MD_XINGYUN_DATA)
    local IsJoin = math.floor(XingYunData / 100000)
    temp = XingYunData % 100000
    local JoinDragon = math.floor(temp / 10000)
    temp = XingYunData % 10000
    local DragonPrize = math.floor(temp / 1000)
    temp = XingYunData % 1000
    local Prize1 = math.floor(temp / 100)
    temp = XingYunData % 100
    local Prize2 = math.floor(temp / 10)
    local Prize3 = XingYunData % 10
    if (self.g_GetXingYunDataParameter[1] == index) then
        return IsJoin
    elseif (self.g_GetXingYunDataParameter[2] == index) then
        return JoinDragon
    elseif (self.g_GetXingYunDataParameter[3] == index) then
        return DragonPrize
    elseif (self.g_GetXingYunDataParameter[4] == index) then
        return Prize1
    elseif (self.g_GetXingYunDataParameter[5] == index) then
        return Prize2
    elseif (self.g_GetXingYunDataParameter[6] == index) then
        return Prize3
    else
        return -1
    end
end

function lucky_turntable:SetXingYunData(selfId, IJoin, JDragon, DPrize, P1, P2,
                                        P3)
    local IsJoin, JoinDragon, DragonPrize, Prize1, Prize2, Prize3 = -1
    if (IJoin == -1) then
        IsJoin =
            self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[1]) *
                100000
    else
        IsJoin = IJoin * 100000
    end
    if (JDragon == -1) then
        JoinDragon = self:GetXingYunData(selfId,
                                         self.g_GetXingYunDataParameter[2]) *
                         10000
    else
        JoinDragon = JDragon * 10000
    end
    if (DPrize == -1) then
        DragonPrize = self:GetXingYunData(selfId,
                                          self.g_GetXingYunDataParameter[3]) *
                          1000
    else
        DragonPrize = DPrize * 1000
    end
    if (P1 == -1) then
        Prize1 =
            self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[4]) * 100
    else
        Prize1 = P1 * 100
    end
    if (P2 == -1) then
        Prize2 =
            self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[5]) * 10
    else
        Prize2 = P2 * 10
    end
    if (P3 == -1) then
        Prize3 = self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[6])
    else
        Prize3 = P3
    end
    local val = IsJoin + JoinDragon + DragonPrize + Prize1 + Prize2 + Prize3
    self:SetMissionData(selfId, define.MD_ENUM.MD_XINGYUN_DATA, val)
end

function lucky_turntable:OnAugury(selfId, pos_ui)
    local IsJoin = self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[1])
    local JoinDragon, DragonPrize = 0, 0
    local prizetype_1, prizetype_2, prizetype_3
    if (IsJoin == 0) then
        prizetype_1 = self:OnPrize()
        prizetype_2 = self:OnPrize()
        while (prizetype_2 == 5) do prizetype_2 = self:OnPrize() end
        prizetype_3 = self:OnPrize()
        while (prizetype_3 == 5) do prizetype_3 = self:OnPrize() end
        if (prizetype_1 == 4 and prizetype_2 == 4 and prizetype_3 == 4) then
            local index = math.random(1, 3)
            if (index == 1) then
                prizetype_1 = 2
            elseif (index == 2) then
                prizetype_2 = 2
            elseif (index == 3) then
                prizetype_3 = 2
            end
        end
        self:SetXingYunData(selfId, 1, JoinDragon, DragonPrize, prizetype_1,
                            prizetype_2, prizetype_3)
        self:LuaFnAuditLuckyTurnTable(selfId, prizetype_1, prizetype_2,
                                      prizetype_3)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                           self.g_BufferId, 0)
        self:TryRecieveItem(selfId, 30505255, 1)
        self:BeginUICommand()
        self:UICommand_AddInt(1)
        self:UICommand_AddInt(prizetype_1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, self.g_UICommand)
    elseif (IsJoin == 1) then
        prizetype_2 = self:GetXingYunData(selfId,
                                          self.g_GetXingYunDataParameter[5])
        self:BeginUICommand()
        self:UICommand_AddInt(2)
        self:UICommand_AddInt(prizetype_2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, self.g_UICommand)
        self:SetXingYunData(selfId, 2, -1, -1, -1, -1, -1)
    elseif (IsJoin == 2) then
        prizetype_3 = self:GetXingYunData(selfId,
                                          self.g_GetXingYunDataParameter[6])
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        self:UICommand_AddInt(prizetype_3)
        self:EndUICommand()
        self:DispatchUICommand(selfId, self.g_UICommand)
        self:SetXingYunData(selfId, 3, -1, -1, -1, -1, -1)
    end
end

function lucky_turntable:OnPrize()
    local odds = math.random(1, 100000)
    local prizetype = 0
    if (odds >= 1 and odds <= 1000) then
        prizetype = 1
    elseif (odds >= 1001 and odds <= 66540) then
        prizetype = 2
    elseif (odds >= 66541 and odds <= 66990) then
        prizetype = 3
    elseif (odds >= 66991 and odds <= 99990) then
        prizetype = 4
    elseif (odds >= 99991 and odds <= 100000) then
        prizetype = 5
    end
    return prizetype
end

function lucky_turntable:CheckTime(selfId)
    local td = self:GetDayTime()
    local LastXingYunTime = self:GetMissionData(selfId, define.MD_ENUM.MD_XINGYUN_TIME_INFO)
    if td > LastXingYunTime then
        self:SetXingYunData(selfId, 0, 0, 0, 0, 0, 0)
        self:SetMissionData(selfId, define.MD_ENUM.MD_XINGYUN_TIME_INFO, td)
    end
end

function lucky_turntable:GivePlayerPrize(selfId, targetId)
    self:LuaFnAddSalaryPoint(selfId, 5, 1)
    local PrizeType = {}

    PrizeType[1] =
        self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[4])
    PrizeType[2] =
        self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[5])
    PrizeType[3] =
        self:GetXingYunData(selfId, self.g_GetXingYunDataParameter[6])
    local needspace = 0
    for i = 1, 3 do
        if (PrizeType[i] == 3 or PrizeType[i] == 5) then
            needspace = needspace + 1
        end
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < needspace then
        self:BeginEvent(self.script_id)
        self:AddText("Túi của ngươi không đủ chỗ, không thể lĩnh phần thưởng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText("#{XYLP_20071222_03}")
    for i = 1, 3 do
        if (PrizeType[i] == 1) then
            self:AddText(self:GetExp(selfId, 1))
        elseif (PrizeType[i] == 2) then
            self:AddText(self:GetExp(selfId, 2))
        elseif (PrizeType[i] == 3) then
            self:AddText(self:GetItem(selfId, 3, targetId))
        elseif (PrizeType[i] == 5) then
            self:GetItem(selfId, 5, targetId)
            self:AddText("#GĐạo cụ: Tài Tử Giai Nhân")
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    self:SetXingYunData(selfId, -1, -1, -1, 0, 0, 0)
end

function lucky_turntable:GetExp(selfId, type, targetId)
    local str = ""
    local playerLevel = self:GetLevel(selfId)
    local exp = self.g_Exp[playerLevel]
    if (type == 1) then exp = exp * 5 end
    self:AddExp(selfId, exp * 10)
    str = string.format("#Gkinh nghiệm:%d", exp * 10)
    return str
end

function lucky_turntable:GetItem(selfId, type, targetId)
    local ItemId = 0
    local str = ""
    if (type == 3) then
        ItemId = self:RandomItem()
        str = string.format("#GVật phẩm:#{_ITEM%d}", ItemId)
    elseif (type == 5) then
        ItemId = 10124048
    elseif (type == 7) then
        ItemId = 10141084
        str = string.format(
                  "Chúc mừng! Tại hoạt động rút thăm trúng thưởng \"Tam Khoái Hoạt May Mắn\" của ngài đã nhận được các phần thưởng sau:#G#{_ITEM%d}",
                  ItemId)
    end
    local BagIndex = self:TryRecieveItem(selfId, ItemId)
    if (ItemId ~= self.g_DragonItem[1] and ItemId ~= self.g_DragonItem[2] and
        ItemId ~= self.g_DragonItem[3] and ItemId ~= 30509500) then
        local bindidx = self:LuaFnItemBind(selfId, BagIndex)
        if bindidx ~= 1 then
            local bindmsg = "Liên kết thất bại"
            self:BeginEvent(self.script_id)
            self:AddText(bindmsg)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
    local ItemInfo = self:GetBagItemTransfer(selfId, BagIndex)
    if BagIndex ~= -1 then
        if (type == 5) then
            local PlayerName = self:GetName(selfId)
            str = string.format(
                      "#{XYLP_20071222_11}#{_INFOUSR%s}#{XYLP_20071222_12}#{_INFOMSG%%s}#{XYLP_20071222_13}tọa kỵ phi long#{XYLP_20071222_14}",
                      PlayerName)
            str = gbk.fromutf8(str)
            str = string.format(str, ItemInfo)
            self:BroadMsgByChatPipe(selfId, str, 4)
            self:SetXingYunData(selfId, -1, 1, -1, -1, -1, -1)
        elseif (type == 3) then
            local PlayerName = self:GetName(selfId)
            local info = string.format(
                             "#{XYLP_20080104_01}#{_INFOUSR%s}#{XYLP_20080104_02}#{_INFOMSG%%s}#{XYLP_20080104_03}",
                             PlayerName)
            str = gbk.fromutf8(str)
            str = string.format(str, ItemInfo)
            self:BroadMsgByChatPipe(selfId, info, 4)
            return str
        elseif (type == 7) then
            self:BeginEvent(self.script_id)
            self:AddText(str)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            local PlayerName = self:GetName(selfId)
            str = string.format(
                      "#{XYLP_20071222_21}#{_INFOUSR%s}#{XYLP_20071222_22}#{_INFOMSG%%s}#{XYLP_20071222_23}",
                      PlayerName, ItemInfo)
            str = gbk.fromutf8(str)
            str = string.format(str, ItemInfo)
            self:BroadMsgByChatPipe(selfId, str, 4)
        end
    end
end

function lucky_turntable:RandomItem()
    local ItemId = 0
    local randomval = math.random(1, 50000)
    if (randomval >= 1 and randomval <= 900) then
        ItemId = 30008022
    elseif (randomval >= 901 and randomval <= 1800) then
        ItemId = 30008023
    elseif (randomval >= 1801 and randomval <= 2700) then
        ItemId = 30008024
    elseif (randomval >= 2701 and randomval <= 4685) then
        ItemId = 30008006
    elseif (randomval >= 4686 and randomval <= 6185) then
        ItemId = 30008018
    elseif (randomval >= 6186 and randomval <= 7185) then
        ItemId = 30008033
    elseif (randomval >= 7186 and randomval <= 8185) then
        ItemId = 30008016
    elseif (randomval >= 8186 and randomval <= 9685) then
        ItemId = 30900006
    elseif (randomval >= 9686 and randomval <= 9985) then
        ItemId = 30509500
    elseif (randomval >= 9986 and randomval <= 9990) then
        ItemId = self.g_DragonItem[1]
    elseif (randomval >= 9991 and randomval <= 9995) then
        ItemId = self.g_DragonItem[2]
    elseif (randomval >= 9996 and randomval <= 10000) then
        ItemId = self.g_DragonItem[3]
    elseif (randomval >= 10001 and randomval <= 50000) then
        ItemId = 30503019
    end
    return ItemId
end

function lucky_turntable:PlayerTip(selfId, tip)
    self:BeginEvent(self.script_id)
    if (tip == 1) then
        self:AddText("Liễu Nguyệt Hồng: Phần thưởng của ngài vẫn chưa rút hết đó!")
    else
        self:AddText(
            "Liễu Nguyệt Hồng: Chúc mừng ngài! Hoạt động rút thưởng \"Xúc Xắc May Mắn\" hôm nay của ngài đã hoàn thành, mời ngài tùy thời đến tìm ta để lĩnh phần thưởng!")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
end

function lucky_turntable:SwitchDragon(selfId, targetId)
    local ZhuaCount = self:LuaFnGetAvailableItemCount(selfId,
                                                      self.g_DragonItem[1])
    local YiCount =
        self:LuaFnGetAvailableItemCount(selfId, self.g_DragonItem[2])
    local YaCount =
        self:LuaFnGetAvailableItemCount(selfId, self.g_DragonItem[3])
    local result = 1
    if ZhuaCount < 2 then
        result = 0
    elseif YiCount < 2 then
        result = 0
    elseif YaCount < 2 then
        result = 0
    end
    if result == 0 then
        self:BeginEvent(self.script_id)
        self:AddText(
            "Nếu thu thập đủ 2 Đại Phong Nha, 2 Đại Phong Dực và 2 Đại Phong Trảo, ta có thể giúp ngươi triệu hồi ra phi long: Đại Phong. Rất tiếc, ngài hiện tại vẫn chưa thu thập đủ đạo cụ, ta cũng lực bất tòng tâm rồi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Túi của ngươi không đủ chỗ, không thể lĩnh phần thưởng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    for i, v in pairs(self.g_DragonItem) do
        if self:LuaFnDelAvailableItem(selfId, v, 2) == 0 then
            self:BeginEvent(self.script_id)
            self:AddText(
                "Nếu thu thập đủ 2 Đại Phong Nha, 2 Đại Phong Dực và 2 Đại Phong Trảo, ta có thể giúp ngươi triệu hồi ra phi long: Đại Phong. Rất tiếc, ngài hiện tại vẫn chưa thu thập đủ đạo cụ, ta cũng lực bất tòng tâm rồi.")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
    end
    local BagIndex = self:TryRecieveItem(selfId, 10141084)
    local bindidx = self:LuaFnItemBind(selfId, BagIndex)
    if bindidx ~= 1 then
        local bindmsg = "Liên kết thất bại"
        self:BeginEvent(self.script_id)
        self:AddText(bindmsg)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    local PlayerName = self:GetName(selfId)
    local ItemInfo = self:GetBagItemTransfer(selfId, BagIndex)
    if BagIndex ~= -1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYLP_20071222_16}")
        local msg = string.format(
                        "@*;SrvMsg;SCA:#{XYLP_20071222_17}#{_INFOUSR%s}#{XYLP_20071222_18}",
                        PlayerName)
        self:AddGlobalCountNews(msg)
        PlayerName = self:GetName(selfId)
        local str = string.format(
                  "#{XYLP_20071222_21}#{_INFOUSR%s}#{XYLP_20071222_22}#{_INFOMSG%%s}#{XYLP_20071222_23}",
                  PlayerName)
        str = gbk.fromutf8(str)
        str = string.format(str, ItemInfo)
        self:BroadMsgByChatPipe(selfId, str, 4)
        msg = string.format( "@*;SrvMsg;SCL:#{XYLP_20071222_21}#{_INFOUSR%s}#{XYLP_20071222_22}Phi Long:Đại Phong#{XYLP_20071222_23}", PlayerName)
        msg = gbk.fromutf8(msg)
        self:AddGlobalCountNews(msg)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function lucky_turntable:CheckAccept(selfId) end

function lucky_turntable:OnAccept(selfId) end

function lucky_turntable:OnAbandon(selfId) end

function lucky_turntable:OnContinue(selfId, targetId) end

function lucky_turntable:CheckSubmit(selfId) end

function lucky_turntable:OnSubmit(selfId, targetId, selectRadioId) end

function lucky_turntable:OnKillObject(selfId, objdataId, objId) end

function lucky_turntable:OnEnterArea(selfId, zoneId) end

function lucky_turntable:OnItemChanged(selfId, itemdataId) end

return lucky_turntable
