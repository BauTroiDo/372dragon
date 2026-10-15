local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local eMission_lixiankuizeng = class("eMission_lixiankuizeng", script_base)
eMission_lixiankuizeng.script_id = 500619
eMission_lixiankuizeng.g_Position_X = 160.2399
eMission_lixiankuizeng.g_Position_Z = 134.1486
eMission_lixiankuizeng.g_SceneID = 0
eMission_lixiankuizeng.g_AccomplishNPC_Name = "周天师"
eMission_lixiankuizeng.g_givegift_diffday = 6
eMission_lixiankuizeng.g_givegift_levellimit = 30
eMission_lixiankuizeng.g_exppool_max = 80000000
eMission_lixiankuizeng.g_ExpTbl = { 
	[30] = 765, [31] = 787, [32] = 810, [33] = 832, [34] = 855, [35] = 877, [36] = 900,
    [37] = 922, [38] = 945, [39] = 967, [40] = 990, [41] = 1012, [42] = 1035, [43] = 1057, [44] = 1080, [45] = 1102,
    [46] = 1125, [47] = 1147, [48] = 1170, [49] = 1192, [50] = 1215, [51] = 1237, [52] = 1260, [53] = 1282, [54] = 1305,
    [55] = 1327, [56] = 1350, [57] = 1372, [58] = 1395, [59] = 1417, [60] = 1440, [61] = 1462, [62] = 1485, [63] = 1507,
    [64] = 1530, [65] = 1552, [66] = 1575, [67] = 1597, [68] = 1620, [69] = 1642, [70] = 1665, [71] = 1687, [72] = 1710,
    [73] = 1732, [74] = 1755, [75] = 1777, [76] = 1800, [77] = 1822, [78] = 1845, [79] = 1867, [80] = 1890, [81] = 1912,
    [82] = 1935, [83] = 1957, [84] = 1980, [85] = 2002, [86] = 2025, [87] = 2047, [88] = 2070, [89] = 2092, [90] = 3975,
    [91] = 4346, [92] = 4897, [93] = 5516, [94] = 6208, [95] = 6976, [96] = 7822, [97] = 8751, [98] = 9764, [99] = 10866,
    [100] = 10824, [101] = 10789, [102] = 10760, [103] = 10736, [104] = 10718, [105] = 10705, [106] = 10696,
    [107] = 10693, [108] = 10694, [109] = 10699, [110] = 10709, [111] = 10722, [112] = 10740, [113] = 10761,
    [114] = 10785, [115] = 10813, [116] = 10845, [117] = 10880, [118] = 10918, [119] = 10959, [120] = 11003,
    [121] = 11050, [122] = 11099, [123] = 11152, [124] = 11207, [125] = 11265, [126] = 11325, [127] = 11388,
    [128] = 11454, [129] = 11521, [130] = 11592, [131] = 11664, [132] = 11739, [133] = 11816, [134] = 11895,
    [135] = 11976, [136] = 12060, [137] = 12145, [138] = 12233, [139] = 12323, [140] = 12414, [141] = 12508,
    [142] = 12603, [143] = 12701, [144] = 12800, [145] = 13260, [146] = 13780, [147] = 14363, [148] = 15013,
    [149] = 15732, [150] = 0 }
eMission_lixiankuizeng.g_giftData = { ["nGiftId"] = 30505214, ["nGiftNum"] = 1 }
function eMission_lixiankuizeng:OnDefaultEvent(selfId, targetId,arg,index)
    if self:CheckActiveDay() == 0 then
        return
    end
    if index == 1 then
        local nCanGiftUnline = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_GIFT_OUTLINE)
        if nCanGiftUnline == 1 then
            self:BeginEvent(self.script_id)
            self:AddText("Tái chiến giang hồ")
            local szName = self:GetName(selfId)
            self:AddText("#{LXJY_80818_02}" .. szName .. "#{LXJY_80818_03}")
            self:AddItemBonus(self.g_giftData["nGiftId"], self.g_giftData["nGiftNum"])
            self:EndEvent()
            self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, -1)
        else
            self:GiveExpNum(selfId, targetId)
        end
    end
end
function eMission_lixiankuizeng:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:CheckActiveDay() == 0 then
        return
    end
    local nCanGiftUnline = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_GIFT_OUTLINE)
    local nPoolExp = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP)
    if (nPoolExp > 0 or nCanGiftUnline == 1) then
        caller:AddNumTextWithTarget(self.script_id,"#GTái Chiến Giang Hồ", 6, 1)
    end
end
function eMission_lixiankuizeng:OnSubmit(selfId, targetId, selectRadioId)
    local nCanGiftUnline = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_GIFT_OUTLINE)
    if nCanGiftUnline == 1 then
        self:BeginAddItem()
        self:AddItem(self.g_giftData["nGiftId"], self.g_giftData["nGiftNum"])
        local canAdd = self:EndAddItem(selfId)
        if canAdd then
            self:SetGiveFlag(selfId, 0)
            for count = 1, self.g_giftData["nGiftNum"] do
                local bagPos = self:TryRecieveItem(selfId, self.g_giftData["nGiftId"], ScriptGlobal.QUALITY_MUST_BE_CHANGE)
                self:LuaFnItemBind(selfId, bagPos)
            end
            self:AddOutlineGiftLog(selfId, 2, self.g_giftData["nGiftId"], self.g_giftData["nGiftNum"])
            self:GiveExpNum(selfId, targetId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("#{ LXJY_80818_04}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end
function eMission_lixiankuizeng:OnContinue(selfId, targetId)
end
function eMission_lixiankuizeng:CheckUnlineGift(selfId)
    if self:CheckActiveDay() == 0 then
        self:SetGiveFlag(selfId, 0)
        return
    end
    local nDiffDay = self:GetLoginDiffTime(selfId)
    local CurLevel = self:LuaFnGetLevel(selfId)
    if (nDiffDay > self.g_givegift_diffday and CurLevel >= self.g_givegift_levellimit) then
        self:CalcGiveExpNum(selfId)
        self:SetGiveFlag(selfId, 1)
        self:LuaFnSendSystemMail(self:GetName(selfId), "#{LXJY_80818_01}")
    else
        local nCurPoolExp = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP)
        if (nCurPoolExp > 0) then
            self:LuaFnSendSystemMail(self:GetName(selfId), "#{LXJY_90226_04}")
        end
        self:SetGiveFlag(selfId, 0)
    end
end
function eMission_lixiankuizeng:CalcGiveExpNum(selfId)
    local CurLevel = self:LuaFnGetLevel(selfId)
    if (CurLevel < 30 or CurLevel > 150) then
        return
    end
    local nDiffDay = self:GetLoginDiffTime(selfId)
    if nDiffDay <= self.g_givegift_diffday then
        return
    elseif nDiffDay > 366 then
        nDiffDay = 366
    end
    local ExpInHan = self.g_ExpTbl[CurLevel] * 60
    local nGiveReady = 0
    if CurLevel >= 90 then
        nGiveReady = ExpInHan * 2 * (nDiffDay - self.g_givegift_diffday)
    elseif CurLevel >= 30 then
        nGiveReady = ExpInHan * 2 * 1.5 * (nDiffDay - self.g_givegift_diffday)
    end
    local CurExp = self:GetExp(selfId)
    local nFullExp = self:GetFullExp(selfId)
    if nGiveReady > nFullExp then
        nGiveReady = nFullExp
    end
    local nCurPoolExp = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP)
    if (nGiveReady + nCurPoolExp > self.g_exppool_max) then
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP, self.g_exppool_max)
        self:AddOutlineGiftLog(selfId, 3, self.g_exppool_max, nDiffDay)
    else
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP, nCurPoolExp + nGiveReady)
        self:AddOutlineGiftLog(selfId, 3, nCurPoolExp + nGiveReady, nDiffDay)
    end
end
function eMission_lixiankuizeng:GiveExpNum(selfId, targetId)
    local nPoolExp = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP)
    if (nPoolExp) <= 0 then
        return
    end
    local nFullExp = self:GetFullExp(selfId)
    local nCurExp = self:GetExp(selfId)
    local nGiveExp = 0
    local nDiffDay = self:GetLoginDiffTime(selfId)
    if (nPoolExp + nCurExp > nFullExp) then
        nGiveExp = nFullExp - nCurExp
        if (nGiveExp > 0) then
            nPoolExp = nPoolExp - nGiveExp
            if (nPoolExp < 0) then
                nPoolExp = 0
            end
            self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP, nPoolExp)
            self:AddExpMore(selfId, nGiveExp)
            self:AddOutlineGiftLog(selfId, 1, 0, nGiveExp)
        end
        self:BeginEvent(self.script_id)
        self:AddText("Tái chiến giang hồ")
        local szName = self:GetName(selfId)
        self:AddText("#{LXJY_80818_02}" .. szName .. "#{LXJY_80818_03}")
        self:AddText("#{LXJY_90226_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        nGiveExp = nPoolExp
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_LIXIAN_POOLEXP, 0)
        self:AddExpMore(selfId, nGiveExp)
        self:AddOutlineGiftLog(selfId, 1, 1, nGiveExp)
        self:BeginEvent(self.script_id)
        self:AddText("Tái chiến giang hồ")
        local szName = self:GetName(selfId)
        self:AddText("#{LXJY_80818_02}" .. szName .. "#{LXJY_80818_03}")
        self:AddText("#{LXJY_90226_03}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end
function eMission_lixiankuizeng:SetGiveFlag(selfId, nFlag)
    if (nFlag == 1 or nFlag == 2) then
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_GIFT_OUTLINE, nFlag)
    else
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_GIFT_OUTLINE, 0)
    end
end
function eMission_lixiankuizeng:CheckActiveDay(selfId, nFlag)
    return 1
end
return eMission_lixiankuizeng