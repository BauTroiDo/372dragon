local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_langhun = class("ai_langhun", script_base)
ai_langhun.script_id = 892333
ai_langhun.g_FuBenScriptId = 892333
ai_langhun.Buff_MianYi1 = 10472
ai_langhun.Buff_MianYi2 = 10471
ai_langhun.Skill_A = 1409
ai_langhun.Buff_A = 10230
ai_langhun.IDX_CombatFlag = 1
function ai_langhun:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function ai_langhun:OnCharacterTimer(objId, dataId, uTime)
    local targetId = self:LuaFnGetNpcIntParameter(objId, 0)
    if self:GetName(objId) == "飞鹰" then
        self:AddPrimaryEnemy(objId, targetId)
        if self:IsInDist(targetId, objId, 3) and self:LuaFnIsObjValid(objId) then
            local x, z = self:GetWorldPos(targetId)
            self:CreateSpecialObjByDataIndex(targetId, 487, x, z, 0)
            self:LuaFnDeleteMonster(objId)
            return
        end
        return
    end
    if not self:LuaFnIsObjValid(targetId) or not self:LuaFnIsCanDoScriptLogic(targetId) or not self:LuaFnIsCharacterLiving(targetId) then
        return
    end
    local cd = self:LuaFnGetNpcIntParameter(objId, 1)
    if cd >= 60 then
        local x, z = self:GetWorldPos(objId)
        self:CreateSpecialObjByDataIndex(objId, 478, x, z, 0)
        self:LuaFnSetNpcIntParameter(objId, 1, 0)
        self:LuaFnGmKillObj(objId, objId)
        self:LuaFnDeleteMonster(objId)
    else
        self:LuaFnSetNpcIntParameter(objId, 1, cd + 1)
    end
    if self:IsInDist(targetId, objId, 2) then
        return
    end
    self:AddPrimaryEnemy(objId, targetId)
end

function ai_langhun:OnHeartBeat(selfId, nTick)
end

function ai_langhun:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
end

function ai_langhun:OnLeaveCombat(selfId)
    self:ResetMyAI(selfId)
    self:LuaFnDeleteMonster(selfId)
end

function ai_langhun:OnKillCharacter(selfId, targetId)
end

function ai_langhun:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(892328, "OnDie", selfId, killerId)
end

function ai_langhun:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
end

return ai_langhun
