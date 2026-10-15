local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ebaibianlianpu = class("ebaibianlianpu", script_base)
ebaibianlianpu.script_id = 808125
ebaibianlianpu.g_CampaignName = "BaiBianLianPu"
ebaibianlianpu.g_Exp = { [10] = 1516, [11] = 1596, [12] = 1672, [13] = 1749, [14] = 1829, [15] = 1906, [16] = 1983,
    [17] = 2063, [18] = 2140, [19] = 2220, [20] = 3002, [21] = 3124, [22] = 3250, [23] = 3376, [24] = 3502, [25] = 3625,
    [26] = 3751, [27] = 3877, [28] = 4003, [29] = 4125, [30] = 5137, [31] = 5289, [32] = 5441, [33] = 5589, [34] = 5742,
    [35] = 5894, [36] = 6046, [37] = 6194, [38] = 6346, [39] = 6498, [40] = 9700, [41] = 9922, [42] = 10139,
    [43] = 10361, [44] = 10583, [45] = 10801, [46] = 11022, [47] = 11244, [48] = 11462, [49] = 11684, [50] = 11905,
    [51] = 12123, [52] = 12345, [53] = 12567, [54] = 12789, [55] = 13006, [56] = 13228, [57] = 13450, [58] = 13667,
    [59] = 13889, [60] = 14111, [61] = 14328, [62] = 14550, [63] = 14772, [64] = 14990, [65] = 15211, [66] = 15433,
    [67] = 15651, [68] = 15873, [69] = 16095, [70] = 16316, [71] = 16534, [72] = 16756, [73] = 16978, [74] = 17195,
    [75] = 17417, [76] = 17639, [77] = 17856, [78] = 18078, [79] = 18300, [80] = 18517, [81] = 18739, [82] = 18961,
    [83] = 19183, [84] = 19401, [85] = 19622, [86] = 19844, [87] = 20062, [88] = 20284, [89] = 20505, [90] = 20723,
    [91] = 20945, [92] = 21167, [93] = 21384, [94] = 21606, [95] = 21828, [96] = 22045, [97] = 22267, [98] = 22489,
    [99] = 22711, [100] = 22928, [101] = 23146, [102] = 23368, [103] = 23590, [104] = 23807, [105] = 24029,
    [106] = 24251, [107] = 24468, [108] = 24690, [109] = 24912, [110] = 25129, [111] = 25351, [112] = 25573,
    [113] = 25791, [114] = 26013, [115] = 26234, [116] = 26452, [117] = 26674, [118] = 26896, [119] = 27113,
    [120] = 27335, [121] = 27557, [122] = 27774, [123] = 27996, [124] = 28218, [125] = 28435, [126] = 28657,
    [127] = 28879, [128] = 29101, [129] = 29319, [130] = 29540, [131] = 29762, [132] = 29980, [133] = 30202,
    [134] = 30423, [135] = 30641, [136] = 30863, [137] = 31085, [138] = 31302, [139] = 31524, [140] = 31746,
    [141] = 31963, [142] = 32185, [143] = 32407, [144] = 32625, [145] = 32846, [146] = 33068, [147] = 33286,
    [148] = 33508, [149] = 33729, [150] = 33947 }
ebaibianlianpu.g_Buff = { 4838, 4839, 4840, 4843, 4852, 4853, 4854, 4857, 4858, 4879 }
ebaibianlianpu.g_Tip = { ["lev"] = "#{BBLP_90209_4}", ["ride"] = "#{BBLP_90209_5}", ["model"] = "#{BBLP_90209_6}",
    ["joint"] = "#{BBLP_90209_8}" }
ebaibianlianpu.g_Msg = { ["joint"] = "#{BBLP_90209_7}", ["ok"] = "#{BBLP_90209_9}" }
function ebaibianlianpu:OnDefaultEvent(selfId, targetId,arg,index)
    local NumText = index
    if NumText == 1 then
        self:JoinCampaign(selfId, targetId)
    elseif NumText == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BBLP_90209_10}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function ebaibianlianpu:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id,"#{BBLP_90209_2}", 6, 1)
    caller:AddNumTextWithTarget(self.script_id,"#{BBLP_90209_3}", 11, 2)
end

function ebaibianlianpu:JoinCampaign(selfId, targetId)
    if self:GetLevel(selfId) < 10 then
        self:NotifyTip(selfId, self.g_Tip["lev"])
        return
    end
    local td = self:GetTime2Day()
    local lt = self:GetMissionDataEx(selfId, 122)
    if td == lt then
        self:MsgBox(selfId, targetId, self.g_Msg["joint"])
        self:NotifyTip(selfId, self.g_Tip["joint"])
        return
    end
    if self:LuaFnIsRiding(selfId) then
        self:NotifyTip(selfId, self.g_Tip["ride"])
        return
    elseif self:LuaFnIsModelOrMount(selfId) then
        self:NotifyTip(selfId, self.g_Tip["model"])
        return
    end
    local BuffId = self:RandomBuffId()
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, BuffId, 0)
    self:SetMissionDataEx(selfId, 122, td)
    local nLevel = self:GetLevel(selfId)
    local nExp = self.g_Exp[nLevel]
    self:AddExp(selfId, nExp * 10)
    self:MsgBox(selfId, targetId, self.g_Msg["ok"])
    self:LuaFnAddMissionHuoYueZhi(selfId, 24)
end

function ebaibianlianpu:RandomBuffId()
    local BuffId = 0
    local i = 0
    local randomval = math.random(1, 10000)
    if (randomval >= 1 and randomval <= 1250) then
        i = 1
    elseif (randomval <= 2500) then
        i = 2
    elseif (randomval <= 3750) then
        i = 3
    elseif (randomval <= 5000) then
        i = 4
    elseif (randomval <= 6000) then
        i = 5
    elseif (randomval <= 7000) then
        i = 6
    elseif (randomval <= 8000) then
        i = 7
    elseif (randomval <= 8800) then
        i = 8
    elseif (randomval <= 9600) then
        i = 9
    elseif (randomval <= 10000) then
        i = 10
    end
    BuffId = self.g_Buff[i]
    return BuffId
end

function ebaibianlianpu:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ebaibianlianpu:NotifyTip(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return ebaibianlianpu
