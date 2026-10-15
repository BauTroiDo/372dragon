local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gp_yinghuochong = class("gp_yinghuochong", script_base)
gp_yinghuochong.g_MainItemId = 30501104
gp_yinghuochong.g_SubItemId = 30501105
gp_yinghuochong.g_Byproduct = {20103019, 20103031, 20103043, 20103055}

gp_yinghuochong.g_AbilityId = 7
gp_yinghuochong.g_AbilityLevel = 0
function gp_yinghuochong:OnCreate(growPointType, x, y)
    local targetId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    local ItemCount = math.random(1, 4)
    for n = 1, ItemCount do
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_MainItemId)
    end
    if math.random(1, 9) == 1 then
        self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, self.g_SubItemId)
    end
end

function gp_yinghuochong:OnOpen(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, ABilityID)
    local res = self:OpenCheck(selfId, ABilityID, AbilityLevel)
    return res
end

function gp_yinghuochong:OnRecycle(selfId, targetId)
    local ABilityID = self:GetItemBoxRequireAbilityID(targetId)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, ABilityID, self.g_AbilityLevel)
    return 1
end

function gp_yinghuochong:OnProcOver(selfId, targetId)
    return 0
end

function gp_yinghuochong:OpenCheck(selfId, AbilityId, AbilityLevel)
    if AbilityLevel < self.g_AbilityLevel then
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_yinghuochong:OnTickCreateFinish(growPointType, tickCount)
end

return gp_yinghuochong
