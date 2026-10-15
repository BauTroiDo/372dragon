local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_zhongzhi_zhima3 = class("gp_zhongzhi_zhima3", script_base)
gp_zhongzhi_zhima3.g_GpId = 509
gp_zhongzhi_zhima3.g_ItemBoxNeedLevel = 7
function gp_zhongzhi_zhima3:OnOpen(selfId, targetId)
    local ItemBoxOwnerGUID = self:GetItemBoxOwner(targetId)
    local PlayerGuid = self:GetHumanGUID(selfId)
    if ItemBoxOwnerGUID ~= PlayerGuid then
        self:BeginEvent(self.script_id)
        self:AddText("Tự tiện thu hoạch hoa màu của người khác trồng là không được đâu đó!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_INVALID_TARGET_POS
    end
    AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_ZHONGZHI)
    if AbilityLevel >= self.g_ItemBoxNeedLevel then
        return define.OPERATE_RESULT.OR_OK
    else
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
end

function gp_zhongzhi_zhima3:OnProcOver(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_zhongzhi_zhima3:OnRecycle(selfId, targetId)
    local num = 0
    local GP_X = self:GetItemBoxWorldPosX(targetId)
    local GP_Z = self:GetItemBoxWorldPosZ(targetId)
    GP_X = math.floor(GP_X)
    GP_Z = math.floor(GP_Z)
    local sceneId = self:get_scene():get_id()
    for i, findid in pairs(ScriptGlobal.PLANTNPC_ADDRESS) do
        if
            (GP_X >= findid["X_MIN"]) and (GP_Z >= findid["Z_MIN"]) and (GP_X <= findid["X_MAX"]) and
                (GP_Z <= findid["Z_MAX"]) and
                (sceneId == findid["Scene"])
         then
            num = i
            break
        end
    end
    if num == 0 then
        return
    end
    ScriptGlobal.PLANTFLAG[num] = ScriptGlobal.PLANTFLAG[num] - 1
    return 1
end

return gp_zhongzhi_zhima3
