local class = require "class"
local define = require "define"
local script_base = require "script_base"
local s_baobutong = class("s_baobutong", script_base)
s_baobutong.TBL = {
    ["IDX_TimerPrepare"] = 1,
    ["IDX_TimerInterval"] = 2,
    ["IDX_FlagCombat"] = 1,
    ["BossSkill"] = 1002,
    ["PrepareTime"] = 60000,
    ["SkillInterval"] = 60000,
    ["BossBuff"] = 9999
}

s_baobutong.g_BuffId = 10175
function s_baobutong:OnDie(selfId, killerId)
    local nNpcNum = self:GetMonsterCount()
    for i = 1, nNpcNum do
        local nNpcId = self:GetMonsterObjID(i)
        if self:GetName(nNpcId) == "公冶乾" or self:GetName(nNpcId) ==
            "邓百川" or self:GetName(nNpcId) == "包不同" or
            self:GetName(nNpcId) == "风波恶" then
            if selfId ~= nNpcId then
                if self:GetHp(nNpcId) > 100 then
                    self:LuaFnSendSpecificImpactToUnit(nNpcId, nNpcId, nNpcId, self.g_BuffId, 0)
                    self:CallScriptFunction((200060), "Paopao",self:GetName(nNpcId), "燕子坞", "Không cầu sinh cùng năm cùng tháng cùng ngày, chỉ cầu chết cùng năm cùng tháng cùng ngày!")
                end
            end
        end
    end
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function s_baobutong:OnHeartBeat(selfId, nTick) end

function s_baobutong:OnInit(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
end

function s_baobutong:OnKillCharacter(selfId, targetId) end

function s_baobutong:OnEnterCombat(selfId, enmeyId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], self.TBL["PrepareTime"])
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 1)
end

function s_baobutong:OnLeaveCombat(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerPrepare"], 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.TBL["IDX_TimerInterval"], 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.TBL["IDX_FlagCombat"], 0)
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_BuffId) then
        self:LuaFnCancelSpecificImpact(selfId, self.g_BuffId)
    end
end

return s_baobutong
