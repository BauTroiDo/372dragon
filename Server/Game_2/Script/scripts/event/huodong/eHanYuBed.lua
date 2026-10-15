local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eHanYuBed = class("eHanYuBed", script_base)
eHanYuBed.script_id = 808072
eHanYuBed.g_NoRMBBuffID = 5901
eHanYuBed.g_RMBBuffID = 5902
eHanYuBed.g_SpouseBuffID = 5704
eHanYuBed.g_NormalExpBuffID = 5905
eHanYuBed.g_MoreExpBuffID = 5904
eHanYuBed.g_MaxAddExpCount = 60
eHanYuBed.g_ExpTbl = {
    [30] = 5137,
    [31] = 5289,
    [32] = 5441,
    [33] = 5589,
    [34] = 5742,
    [35] = 5894,
    [36] = 6046,
    [37] = 6194,
    [38] = 6346,
    [39] = 6498,
    [40] = 9700,
    [41] = 9922,
    [42] = 10139,
    [43] = 10361,
    [44] = 10583,
    [45] = 10801,
    [46] = 11022,
    [47] = 11244,
    [48] = 11462,
    [49] = 11684,
    [50] = 11905,
    [51] = 12123,
    [52] = 12345,
    [53] = 12567,
    [54] = 12789,
    [55] = 13006,
    [56] = 13228,
    [57] = 13450,
    [58] = 13667,
    [59] = 13889,
    [60] = 14111,
    [61] = 14328,
    [62] = 14550,
    [63] = 14772,
    [64] = 14990,
    [65] = 15211,
    [66] = 15433,
    [67] = 15651,
    [68] = 15873,
    [69] = 16095,
    [70] = 16316,
    [71] = 16534,
    [72] = 16756,
    [73] = 16978,
    [74] = 17195,
    [75] = 17417,
    [76] = 17639,
    [77] = 17856,
    [78] = 18078,
    [79] = 18300,
    [80] = 18517,
    [81] = 18739,
    [82] = 18961,
    [83] = 19183,
    [84] = 19401,
    [85] = 19622,
    [86] = 19844,
    [87] = 20062,
    [88] = 20284,
    [89] = 20505,
    [90] = 20723,
    [91] = 20945,
    [92] = 21167,
    [93] = 21384,
    [94] = 21606,
    [95] = 21828,
    [96] = 22045,
    [97] = 22267,
    [98] = 22489,
    [99] = 22711,
    [100] = 22928,
    [101] = 23146,
    [102] = 23368,
    [103] = 23590,
    [104] = 23807,
    [105] = 24029,
    [106] = 24251,
    [107] = 24468,
    [108] = 24690,
    [109] = 24912,
    [110] = 25129,
    [111] = 25351,
    [112] = 25573,
    [113] = 25791,
    [114] = 26013,
    [115] = 26234,
    [116] = 26452,
    [117] = 26674,
    [118] = 26896,
    [119] = 27113,
    [120] = 27335,
    [121] = 27557,
    [122] = 27774,
    [123] = 27996,
    [124] = 28218,
    [125] = 28435,
    [126] = 28657,
    [127] = 28879,
    [128] = 29101,
    [129] = 29319,
    [130] = 29540,
    [131] = 29762,
    [132] = 29980,
    [133] = 30202,
    [134] = 30423,
    [135] = 30641,
    [136] = 30863,
    [137] = 31085,
    [138] = 31302,
    [139] = 31524,
    [140] = 31746,
    [141] = 31963,
    [142] = 32185,
    [143] = 32407,
    [144] = 32625,
    [145] = 32846,
    [146] = 33068,
    [147] = 33286,
    [148] = 33508,
    [149] = 33729,
    [150] = 0
}

function eHanYuBed:OnSceneTimer()
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:DoHanYuLogic(nHumanId)
    end
end

function eHanYuBed:DoHanYuLogic(selfId)
    if self:GetLevel(selfId) < 70 then
        self:NotifyTip(selfId, "Chưa đủ cấp 70, không nhận kinh nghiệm được")
        return
    end
    if not self:LuaFnIsObjValid(selfId) then return end
    if not self:LuaFnIsCanDoScriptLogic(selfId) then return end
    local GuaJiType = 0
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_NoRMBBuffID) then
        GuaJiType = 1
    elseif self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_RMBBuffID)then
        GuaJiType = 2
    elseif self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SpouseBuffID) then
        GuaJiType = 3
    end
    if 0 == GuaJiType then return end
    local IsMoreExp = 0
    local CurLevel = self:LuaFnGetLevel(selfId)
    local CurExp = self.g_ExpTbl[CurLevel]
    if CurExp and CurExp > 0 then
        self:LuaFnAddExp(selfId, CurExp)
    end
    if 1 == IsMoreExp then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_MoreExpBuffID, 0)
    else
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_NormalExpBuffID, 0)
    end
end

function eHanYuBed:OnPlayerUseHanYuBook(selfId) end

function eHanYuBed:OnImpactFadeOut(selfId, impactId) end

function eHanYuBed:OnPlayerPickUpItemInHanYuBed(selfId, itemId, bagidx)
    if itemId == 30501148 or itemId == 30501149 or itemId == 30501150 or itemId ==
        30700200 or itemId == 30505178 then
        local playerName = self:GetName(selfId)
        playerName = gbk.fromutf8(playerName)
        local transfer = self:GetBagItemTransfer(selfId, bagidx)
        local fmt = gbk.fromutf8("#{_INFOUSR%s}#P tại #GTô Châu (178, 129) Lâm Triều Hùng#P chỉ dẫn đến #GHàn Ngọc Cốc#P Tu luyện, võ công đại tiến đồng thời còn vô tình nhặt được một #{_INFOMSG%s}#P.")
        local message = string.format(fmt, playerName, transfer)
        self:BroadMsgByChatPipe(selfId, message, 4)
    end
end

function eHanYuBed:GetPreExpOfThisLevel(level)
    local Exp = self.g_ExpTbl[level]
    if Exp then
        return Exp
    else
        return 0
    end
end

function eHanYuBed:NotifyTip(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return eHanYuBed
