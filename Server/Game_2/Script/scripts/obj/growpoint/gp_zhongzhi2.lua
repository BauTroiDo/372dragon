local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_zhongzhi2 = class("gp_zhongzhi2", script_base)
gp_zhongzhi2.g_RandNum = 10000
gp_zhongzhi2.g_GPInfo = {}

gp_zhongzhi2.g_rareRules = {}

gp_zhongzhi2.g_rareRules[1] = {
    {["rate"] = 77, ["num"] = 1},
    {["rate"] = 14, ["num"] = 2},
    {["rate"] = 9, ["num"] = 3}
}

gp_zhongzhi2.g_rareRules[2] = {
    {["rate"] = 50, ["num"] = 3},
    {["rate"] = 30, ["num"] = 4},
    {["rate"] = 20, ["num"] = 5}
}

gp_zhongzhi2.g_GPInfo[502] = {
    ["NextGeneration"] = 503,
    ["MainProduct"] = 20104001,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105013,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[505] = {
    ["NextGeneration"] = 506,
    ["MainProduct"] = 20104002,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105014,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[508] = {
    ["NextGeneration"] = 509,
    ["MainProduct"] = 20104003,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105015,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[511] = {
    ["NextGeneration"] = 512,
    ["MainProduct"] = 20104004,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105016,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[514] = {
    ["NextGeneration"] = 515,
    ["MainProduct"] = 20104005,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105017,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[517] = {
    ["NextGeneration"] = 518,
    ["MainProduct"] = 20104006,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105018,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[520] = {
    ["NextGeneration"] = 521,
    ["MainProduct"] = 20104007,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105019,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[523] = {
    ["NextGeneration"] = 524,
    ["MainProduct"] = 20104008,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105020,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[526] = {
    ["NextGeneration"] = 527,
    ["MainProduct"] = 20104009,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105021,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[529] = {
    ["NextGeneration"] = 530,
    ["MainProduct"] = 20104010,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105022,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[532] = {
    ["NextGeneration"] = 533,
    ["MainProduct"] = 20104011,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105023,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[535] = {
    ["NextGeneration"] = 536,
    ["MainProduct"] = 20104012,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = 20105024,
    ["rOdds"] = 2000
}

gp_zhongzhi2.g_GPInfo[538] = {
    ["NextGeneration"] = 539,
    ["MainProduct"] = 20105001,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[541] = {
    ["NextGeneration"] = 542,
    ["MainProduct"] = 20105002,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[544] = {
    ["NextGeneration"] = 545,
    ["MainProduct"] = 20105003,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[547] = {
    ["NextGeneration"] = 548,
    ["MainProduct"] = 20105004,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[550] = {
    ["NextGeneration"] = 551,
    ["MainProduct"] = 20105005,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[553] = {
    ["NextGeneration"] = 554,
    ["MainProduct"] = 20105006,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[556] = {
    ["NextGeneration"] = 557,
    ["MainProduct"] = 20105007,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[559] = {
    ["NextGeneration"] = 560,
    ["MainProduct"] = 20105008,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[562] = {
    ["NextGeneration"] = 563,
    ["MainProduct"] = 20105009,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[565] = {
    ["NextGeneration"] = 566,
    ["MainProduct"] = 20105010,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[568] = {
    ["NextGeneration"] = 569,
    ["MainProduct"] = 20105011,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[571] = {
    ["NextGeneration"] = 572,
    ["MainProduct"] = 20105012,
    ["ProtectDuration"] = 300000,
    ["ProductCount"] = 1,
    ["RecycleDuration"] = 300000,
    ["rareJunior"] = -1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[702] = {
    ["NextGeneration"] = 703,
    ["MainProduct"] = 20104001,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105013,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[705] = {
    ["NextGeneration"] = 706,
    ["MainProduct"] = 20104002,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105014,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[708] = {
    ["NextGeneration"] = 709,
    ["MainProduct"] = 20104003,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105015,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[711] = {
    ["NextGeneration"] = 712,
    ["MainProduct"] = 20104004,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105016,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[714] = {
    ["NextGeneration"] = 715,
    ["MainProduct"] = 20104005,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105017,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[717] = {
    ["NextGeneration"] = 718,
    ["MainProduct"] = 20104006,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105018,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[720] = {
    ["NextGeneration"] = 721,
    ["MainProduct"] = 20104007,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105019,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[723] = {
    ["NextGeneration"] = 724,
    ["MainProduct"] = 20104008,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105020,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[726] = {
    ["NextGeneration"] = 727,
    ["MainProduct"] = 20104009,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105021,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[729] = {
    ["NextGeneration"] = 730,
    ["MainProduct"] = 20104010,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105022,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[732] = {
    ["NextGeneration"] = 733,
    ["MainProduct"] = 20104011,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105023,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[735] = {
    ["NextGeneration"] = 736,
    ["MainProduct"] = 20104012,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = 20105024,
    ["rOdds"] = 10000
}

gp_zhongzhi2.g_GPInfo[738] = {
    ["NextGeneration"] = 739,
    ["MainProduct"] = 20105001,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[741] = {
    ["NextGeneration"] = 742,
    ["MainProduct"] = 20105002,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[744] = {
    ["NextGeneration"] = 745,
    ["MainProduct"] = 20105003,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[747] = {
    ["NextGeneration"] = 748,
    ["MainProduct"] = 20105004,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[750] = {
    ["NextGeneration"] = 751,
    ["MainProduct"] = 20105005,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[753] = {
    ["NextGeneration"] = 754,
    ["MainProduct"] = 20105006,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[756] = {
    ["NextGeneration"] = 757,
    ["MainProduct"] = 20105007,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[759] = {
    ["NextGeneration"] = 760,
    ["MainProduct"] = 20105008,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[762] = {
    ["NextGeneration"] = 763,
    ["MainProduct"] = 20105009,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[765] = {
    ["NextGeneration"] = 766,
    ["MainProduct"] = 20105010,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[768] = {
    ["NextGeneration"] = 769,
    ["MainProduct"] = 20105011,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

gp_zhongzhi2.g_GPInfo[771] = {
    ["NextGeneration"] = 772,
    ["MainProduct"] = 20105012,
    ["ProtectDuration"] = 900000,
    ["ProductCount"] = 10,
    ["RecycleDuration"] = 900000,
    ["rareJunior"] = 1,
    ["rareId"] = -1,
    ["rOdds"] = 0
}

function gp_zhongzhi2:OnRecycle(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return 1
    end
    local itemBoxX = self:GetItemBoxWorldPosX(targetId)
    local itemBoxZ = self:GetItemBoxWorldPosZ(targetId)
    local ItemBoxId = self:ItemBoxEnterScene(itemBoxX, itemBoxZ, GPInfo["NextGeneration"], 0, 0)
    for i = 1, GPInfo["ProductCount"] do
        self:AddItemToBox(ItemBoxId, define.QUALITY_MUST_BE_CHANGE, 1, GPInfo["MainProduct"])
    end
    local randomOdds = math.random(self.g_RandNum)
    if GPInfo["rareId"] ~= -1 and randomOdds <= GPInfo["rOdds"] then
        local selectrareRule
        if GPInfo["rareJunior"] == 1 then
            selectrareRule = self.g_rareRules[2]
        else
            selectrareRule = self.g_rareRules[1]
        end
        local totalRate = 0
        local rareRuleItem
        for _, rareRuleItem in pairs(selectrareRule) do
            totalRate = totalRate + rareRuleItem["rate"]
        end
        local randomValue = math.random(totalRate)
        local itemNum = 0
        for _, rareRuleItem in pairs(selectrareRule) do
            if randomValue < rareRuleItem["rate"] then
                itemNum = rareRuleItem["num"]
                break
            end
            randomValue = randomValue - rareRuleItem["rate"]
        end
        local itemp
        for itemp = 0, itemNum - 1 do
            self:AddItemToBox(ItemBoxId, define.QUALITY_MUST_BE_CHANGE, 1, GPInfo["rareId"])
        end
    end
    local ItemBoxOwnerGUID = self:GetItemBoxOwner(targetId)
    self:SetItemBoxOwner(ItemBoxId, ItemBoxOwnerGUID)
    self:SetItemBoxPickOwnerTime(ItemBoxId, GPInfo["ProtectDuration"])
    self:EnableItemBoxPickOwnerTime(ItemBoxId)
    self:SetItemBoxMaxGrowTime(ItemBoxId, GPInfo["RecycleDuration"])
    local GP_X = self:GetItemBoxWorldPosX(targetId)
    local GP_Z = self:GetItemBoxWorldPosZ(targetId)
    GP_X = math.floor(GP_X)
    GP_Z = math.floor(GP_Z)
    local num = 0
    local i = 0
    local sceneId = self:get_scene():get_id()
    for i, findid in pairs(ScriptGlobal.PLANTNPC_ADDRESS) do
        if
            GP_X >= findid["X_MIN"] and GP_Z >= findid["Z_MIN"] and GP_X <= findid["X_MAX"] and GP_Z <= findid["Z_MAX"] and
                sceneId == findid["Scene"]
         then
            num = i
            break
        end
    end
    if num == 0 then
        return 1
    end
    if ScriptGlobal.PLANTFLAG[num] == 8 then
        local strMail =
            string.format(
            "Cây trồng của ngươi đã chín, mời trong vòng %dphút đến #G%s(%d,%d)#W thu hoạch.",
            (GPInfo["ProtectDuration"] / 60000),
            self:GetSceneName(),
            GP_X,
            GP_Z
        )
        self:LuaFnSendMailToGUID(ItemBoxOwnerGUID, strMail)
    end
    ScriptGlobal.PLANTFLAG[num] = ScriptGlobal.PLANTFLAG[num] - 1
    return 1
end

return gp_zhongzhi2
