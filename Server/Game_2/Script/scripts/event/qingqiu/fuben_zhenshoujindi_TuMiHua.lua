local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_TuMiHua = class("fuben_zhenshoujindi_TuMiHua", script_base)
fuben_zhenshoujindi_TuMiHua.script_id = 893114
fuben_zhenshoujindi_TuMiHua.g_FuBenScriptId = 893020
fuben_zhenshoujindi_TuMiHua.IDX_CombatFlag = 1
fuben_zhenshoujindi_TuMiHua.IDX_StopWatch = 1	--秒表....
fuben_zhenshoujindi_TuMiHua.g_DamageImpact = {31818, 31819, 31820, 31821, 31822}

function fuben_zhenshoujindi_TuMiHua:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_TuMiHua:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_TuMiHua:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if not self:LuaFnIsObjValid(selfId) then
        return
    end
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            if self:IsInDist(nHumanId,selfId,3) then
                --self:DelayCallFunction(4000,"DelayBaoZhaXiaoGuo",nHumanId,selfId)
                self:DelayBaoZhaXiaoGuo(nHumanId,selfId)
            end
        end
    end
    self:TickStopWatch(selfId, nTick)
end
function fuben_zhenshoujindi_TuMiHua:DelayBaoZhaXiaoGuo(selfId,targetId)
    if self:IsInDist(selfId,targetId,3) then
        for i = 1,#self.g_DamageImpact do
            self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,self.g_DamageImpact[i],0)
        end
    end
    self:LuaFnDeleteMonster(targetId)
end
function fuben_zhenshoujindi_TuMiHua:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function fuben_zhenshoujindi_TuMiHua:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    --self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_TuMiHua:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_TuMiHua:OnDie(selfId, killerId)

end

function fuben_zhenshoujindi_TuMiHua:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId,self.IDX_CombatFlag,0)
end

function fuben_zhenshoujindi_TuMiHua:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function fuben_zhenshoujindi_TuMiHua:TickStopWatch(selfId, nTick)
    local time = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_StopWatch)
    if (time + nTick) > 1000 then
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick - 1000)
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_StopWatch, time + nTick)
        return
    end
end

return fuben_zhenshoujindi_TuMiHua
