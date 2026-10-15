local class = require "class"
local define = require "define"
local script_base = require "script_base"
local wangyuyan = class("wangyuyan", script_base)
wangyuyan.TBL = {
    ["IDX_TimerPrepare"] = 1,
    ["IDX_TimerInterval"] = 2,
    ["IDX_FlagCombat"] = 1,
    ["BossSkill"] = 1002,
    ["PrepareTime"] = 60000,
    ["SkillInterval"] = 60000,
    ["BossBuff"] = 9999
}
wangyuyan.g_DuanAndWangFlag = 29
function wangyuyan:OnDie(selfId, killerId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function wangyuyan:OnDefaultEvent(selfId, targetId)

end

function wangyuyan:OnHeartBeat(selfId, nTick)
    if (self:LuaFnIsCharacterLiving(selfId)) then
        if (1 == self:MonsterAI_GetBoolParamByIndex(selfId, 1)) then
            if self:GetHp(selfId) <= self:GetMaxHp(selfId) - 100 then
                if self:LuaFnGetCopySceneData_Param(self.g_DuanAndWangFlag) == 0 then
                    self:LuaFnSetCopySceneData_Param(self.g_DuanAndWangFlag, 1)
                    local nMonsterNum = self:GetMonsterCount()
                    for i = 1, nMonsterNum do
                        local nMonsterId = self:GetMonsterObjID(i)
                        if self:GetName(nMonsterId) == "段誉" then
                            self:SetAIScriptID(nMonsterId, 246)
                        end
                    end
                end
            end
        else
            if self:GetHp(selfId) <= self:GetMaxHp(selfId) - 100 then
                if self:LuaFnGetCopySceneData_Param(self.g_DuanAndWangFlag) == 0 then
                    self:LuaFnSetCopySceneData_Param(self.g_DuanAndWangFlag, 1)
                    local nMonsterNum = self:GetMonsterCount()
                    for i = 1, nMonsterNum do
                        local nMonsterId = self:GetMonsterObjID(i)
                        if self:GetName(nMonsterId) == "段誉" then
                            self:SetAIScriptID(nMonsterId, 246)
                        end
                    end
                end
            end
        end
    end
end

function wangyuyan:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function wangyuyan:OnKillCharacter(selfId, targetId)

end

function wangyuyan:OnEnterCombat(selfId, enmeyId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], self.TBL["PrepareTime"])
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 1)
end

function wangyuyan:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

return wangyuyan
