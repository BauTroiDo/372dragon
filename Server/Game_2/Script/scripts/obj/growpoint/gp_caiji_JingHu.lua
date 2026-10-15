local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_caiji_JingHu = class("gp_caiji_JingHu", script_base)
gp_caiji_JingHu.script_id = 710531
gp_caiji_JingHu.g_GPInfo = {}

gp_caiji_JingHu.g_RandNum = 10000
gp_caiji_JingHu.g_GPInfo[776] = {["abilityId"] = define.ABILITY_CAIYAO, ["name"] = "Cỏ Ngàn Năm Kính Hồ", ["mainId"] = 40004414}

function gp_caiji_JingHu:OnCreate(growPointType, x, y)
    local actId = 36
    local bActStatus = self:GetActivityParam(actId, 0)
    if bActStatus <= 0 then
        return -1
    end
    local bQianNianCaoGen = self:GetActivityParam(actId, 1)
    if bQianNianCaoGen > 0 then
        return -1
    end
    local ItemBoxId = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, 40004414)
    self:SetItemBoxMaxGrowTime(ItemBoxId, 30 * 60 * 1000)
    self:SetActivityParam(actId, 1, 1)
end

function gp_caiji_JingHu:OnOpen(selfId, targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_caiji_JingHu:OnProcOver(selfId, targetId)
    self:LuaFnGetItemBoxGrowPointType(targetId)
    return define.OPERATE_RESULT.OR_OK
end

function gp_caiji_JingHu:OnRecycle(selfId, targetId)
    self:LuaFnGetItemBoxGrowPointType(targetId)
    self:LuaFnAuditHDXianCaoZhengDuo(selfId, "Thu thập Tiên Thảo")
    return 1
end

function gp_caiji_JingHu:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function gp_caiji_JingHu:OnTickCreateFinish(growPointType, tickCount)
end

return gp_caiji_JingHu
