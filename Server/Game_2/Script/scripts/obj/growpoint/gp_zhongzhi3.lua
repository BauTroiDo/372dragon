local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_zhongzhi3 = class("gp_zhongzhi3", script_base)
gp_zhongzhi3.g_GPInfo = {}

gp_zhongzhi3.g_GPInfo[503] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 1}

gp_zhongzhi3.g_GPInfo[506] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 2}

gp_zhongzhi3.g_GPInfo[509] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 3}

gp_zhongzhi3.g_GPInfo[512] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 4}

gp_zhongzhi3.g_GPInfo[515] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 5}

gp_zhongzhi3.g_GPInfo[518] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 6}

gp_zhongzhi3.g_GPInfo[521] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 7}

gp_zhongzhi3.g_GPInfo[524] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 8}

gp_zhongzhi3.g_GPInfo[527] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 9}

gp_zhongzhi3.g_GPInfo[530] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 10}

gp_zhongzhi3.g_GPInfo[533] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 11}

gp_zhongzhi3.g_GPInfo[536] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 12}

gp_zhongzhi3.g_GPInfo[539] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 1}

gp_zhongzhi3.g_GPInfo[542] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 2}

gp_zhongzhi3.g_GPInfo[545] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 3}

gp_zhongzhi3.g_GPInfo[548] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 4}

gp_zhongzhi3.g_GPInfo[551] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 5}

gp_zhongzhi3.g_GPInfo[554] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 6}

gp_zhongzhi3.g_GPInfo[557] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 7}

gp_zhongzhi3.g_GPInfo[560] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 8}

gp_zhongzhi3.g_GPInfo[563] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 9}

gp_zhongzhi3.g_GPInfo[566] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 10}

gp_zhongzhi3.g_GPInfo[569] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 11}

gp_zhongzhi3.g_GPInfo[572] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 12}

gp_zhongzhi3.g_GPInfo[703] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 1}

gp_zhongzhi3.g_GPInfo[706] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 2}

gp_zhongzhi3.g_GPInfo[709] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 3}

gp_zhongzhi3.g_GPInfo[712] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 4}

gp_zhongzhi3.g_GPInfo[715] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 5}

gp_zhongzhi3.g_GPInfo[718] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 6}

gp_zhongzhi3.g_GPInfo[721] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 7}

gp_zhongzhi3.g_GPInfo[724] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 8}

gp_zhongzhi3.g_GPInfo[727] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 9}

gp_zhongzhi3.g_GPInfo[730] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 10}

gp_zhongzhi3.g_GPInfo[733] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 11}

gp_zhongzhi3.g_GPInfo[736] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 12}

gp_zhongzhi3.g_GPInfo[739] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 1}

gp_zhongzhi3.g_GPInfo[742] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 2}

gp_zhongzhi3.g_GPInfo[745] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 3}

gp_zhongzhi3.g_GPInfo[748] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 4}

gp_zhongzhi3.g_GPInfo[751] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 5}

gp_zhongzhi3.g_GPInfo[754] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 6}

gp_zhongzhi3.g_GPInfo[757] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 7}

gp_zhongzhi3.g_GPInfo[760] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 8}

gp_zhongzhi3.g_GPInfo[763] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 9}

gp_zhongzhi3.g_GPInfo[766] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 10}

gp_zhongzhi3.g_GPInfo[769] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 11}

gp_zhongzhi3.g_GPInfo[772] = {["abilityId"] = define.ABILITY_ZHONGZHI, ["needLevel"] = 12}

function gp_zhongzhi3:OnOpen(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return 1
    end
    local ItemBoxOwnerGUID = self:GetItemBoxOwner(targetId)
    local PlayerGuid = self:GetHumanGUID(selfId)
    if ItemBoxOwnerGUID ~= PlayerGuid then
        self:NotifyFailTips(selfId, "Tự tiện thu hoạch hoa màu của người khác trồng là không được đâu đó!")
        return define.OPERATE_RESULT.OR_INVALID_TARGET_POS
    end
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, GPInfo["abilityId"])
    if AbilityLevel >= GPInfo["needLevel"] then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
end

function gp_zhongzhi3:OnProcOver(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_zhongzhi3:OnRecycle(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return 1
    end
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
    ScriptGlobal.PLANTFLAG[num] = ScriptGlobal.PLANTFLAG[num] - 1
    return 1
end

function gp_zhongzhi3:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return gp_zhongzhi3
