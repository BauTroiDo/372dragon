local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_SaoDiHu = class("fuben_zhenshoujindi_SaoDiHu", script_base)
fuben_zhenshoujindi_SaoDiHu.script_id = 893115
fuben_zhenshoujindi_SaoDiHu.g_FuBenScriptId = 893020
fuben_zhenshoujindi_SaoDiHu.IDX_CombatFlag = 1
function fuben_zhenshoujindi_SaoDiHu:OnDefaultEvent(selfId, targetId)
end

function fuben_zhenshoujindi_SaoDiHu:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_SaoDiHu:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
end

function fuben_zhenshoujindi_SaoDiHu:OnEnterCombat(selfId, enmeyId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction((893020), "TipAllHumanPaoPao", selfId, 516)
    self:CallScriptFunction(self.g_FuBenScriptId, "UpdateCurMainStep", 2)
end

function fuben_zhenshoujindi_SaoDiHu:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:SetHp(selfId, self:GetMaxHp(selfId))
end

function fuben_zhenshoujindi_SaoDiHu:OnKillCharacter(selfId, targetId)
end

function fuben_zhenshoujindi_SaoDiHu:OnDie(selfId, killerId)
    self:CallScriptFunction(self.g_FuBenScriptId, "OnSaoDiDie")
end

function fuben_zhenshoujindi_SaoDiHu:ResetMyAI(selfId)
end

function fuben_zhenshoujindi_SaoDiHu:NotifyTip(selfId, Msg)
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return fuben_zhenshoujindi_SaoDiHu
