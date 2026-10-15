local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejinghu_Boss_3 = class("ejinghu_Boss_3", script_base)
ejinghu_Boss_3.script_id = 005119
ejinghu_Boss_3.TBL = {
    ["IDX_TimerPrepare"] = 1,
    ["IDX_TimerInterval"] = 2,
    ["IDX_FlagCombat"] = 1,
    ["BossSkill"] = 1006,
    ["PrepareTime"] = 45000,
    ["SkillInterval"] = 60000,
    ["BossBuff"] = 9999
}

function ejinghu_Boss_3:OnDie(selfId, killerId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function ejinghu_Boss_3:OnHeartBeat(selfId, nTick)
    if (self:LuaFnIsCharacterLiving(selfId)) then
        if (1 == self:MonsterAI_GetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"])) then
            local TimePrepare = self:MonsterAI_GetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"])
            if (0 < TimePrepare) then
                TimePrepare = TimePrepare - nTick
                self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], TimePrepare)
            else
                local TimeInterval = self:MonsterAI_GetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"])
                if (0 < TimeInterval) then
                    TimeInterval = TimeInterval - nTick
                    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], TimeInterval)
                else
                    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], self.TBL["SkillInterval"])
                    local nTarget = self:LuaFnGetTargetObjID(selfId)
                    if (-1 ~= nTarget) then
                        local posX, posZ = self:GetWorldPos(nTarget)
                        local fDir = 0.0
                        self:LuaFnUnitUseSkill(selfId, self.TBL["BossSkill"], nTarget, posX, posZ, fDir)
                    end
                end
            end
        end
    end
end

function ejinghu_Boss_3:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function ejinghu_Boss_3:OnKillCharacter(selfId, targetId)
end

function ejinghu_Boss_3:OnEnterCombat(selfId, enmeyId)
    if (0 < self.TBL["BossBuff"]) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.TBL["BossBuff"], 0)
    end
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], self.TBL["PrepareTime"])
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 1)
end

function ejinghu_Boss_3:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

return ejinghu_Boss_3
