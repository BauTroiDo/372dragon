local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_shisan = class("ai_shisan", script_base)
ai_shisan.script_id = 892330
ai_shisan.g_FuBenScriptId = 892328
ai_shisan.Buff_MianYi1 = 10472
ai_shisan.Buff_MianYi2 = 10471
ai_shisan.Skill_A = 1409
ai_shisan.Buff_A = 10230
ai_shisan.IDX_CombatFlag = 3
ai_shisan.IDX_SKILL_DELAY = 4
function ai_shisan:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function ai_shisan:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
    local delay = self:MonsterAI_GetIntParamByIndex(selfId, self.IDX_SKILL_DELAY)
    delay = delay - nTick
    if delay < 0 then
        local Per = math.floor(self:GetHp(selfId) / self:GetMaxHp(selfId))
        if Per <= 0.9 then
            if 1 == self:TickSkillA(selfId, nTick) then
                return
            end
        end
        if Per <= 0.8 then
            if 1 == self:TickSkillB(selfId, nTick) then
                return
            end
        end
        if Per <= 0.7 then
            if 1 == self:TickSkillC(selfId, nTick) then
                return
            end
        end
    else
        self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, delay)
    end
end

function ai_shisan:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 3)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 3, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 3, 45000 - (nTick - cd))
        return self:UseSkillC(selfId)
    end
end

function ai_shisan:UseSkillC(selfId)
    print("ai_shisan:UseSkillC selfId =", selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, 5000)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local mensi = {}
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Lũ tiểu nhân hèn nhát, hãy cùng mảnh đất này vỡ vụn ra đi!")
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnUnitUseSkill(selfId, 3229, selfId, x, z, 0, 1)
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId)and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(mensi, nHumanId)
        end
    end
    for i = 1, #(mensi) do
        local nHumanx, nHumanz = self:GetWorldPos(mensi[i])
        self:CreateSpecialObjByDataIndex(selfId, 1098, nHumanx, nHumanz, 2000)
    end
    return 1
end

function ai_shisan:DelaySpecialObjData(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local mensi = {}
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId)and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(mensi, nHumanId)
        end
    end
    for i = 1, #(mensi) do
        local nHumanx, nHumanz = self:GetWorldPos(mensi[i])
        self:CreateSpecialObjByDataIndex(selfId, 1098, nHumanx, nHumanz, 2000)
    end
end

function ai_shisan:TickSkillA(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 1)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 1, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 1, 125000 - (nTick - cd))
        return self:UseSkillA(selfId)
    end
end

function ai_shisan:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 2)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 2, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 2, 85000 - (nTick - cd))
        return self:UseSkillB(selfId)
    end
end

function ai_shisan:UseSkillB(selfId)
    print("ai_shisan:UseSkillB selfId =", selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, 5000)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Thập Tam sắp gây sát thương phạm vi, xin thiếu hiệp nhanh chóng rời khỏi Boss")
    local enmeyId = self:GetCurEnemy(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId)and self:LuaFnIsCharacterLiving(nHumanId) then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, nHumanId, 42656, 0)
        end
    end
    self:LuaFnUnitUseSkill(selfId, 3246, enmeyId, x, z, 0, 1)
    self:CreateSpecialObjByDataIndex(selfId, 1096, x, z, 4000)
    return 1
end

function ai_shisan:UseSkillA(selfId)
    print("ai_shisan:UseSkillA selfId =", selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, 5000)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local mensi = {}
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(mensi, nHumanId)
        end
    end
    local randomID = mensi[math.random(1, #(mensi))]
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", self:GetName(randomID) .. "Muốn chạy? Không dễ vậy đâu!")
    local x, z = self:GetWorldPos(randomID)
    self:SetCharacterDieTime(self:LuaFnCreateMonster(48505, x, z, 3, -1, -1), 2100)
    self:LuaFnUnitUseSkill(selfId, 3227, randomID, x, z, 0, 1)
    self:CreateSpecialObjByDataIndex(selfId, 1097, x, z, 2000)
    return 1
end

function ai_shisan:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, 0)
end

function ai_shisan:OnLeaveCombat(selfId)
	print("ai_shisan:OnLeaveCombat")
	--重置AI....
	self:ResetMyAI( selfId )
	--创建对话NPC....
    self:LuaFnDeleteMonster(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "DisableDynamicRegions", "ShiSan_BOSS")
	local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "ShiSan_NPC", -1, -1 )
	self:SetUnitReputationID( MstId, MstId, 0 )
end

function ai_shisan:OnKillCharacter(selfId, targetId)
end

function ai_shisan:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(892328, "OnDie", selfId, killerId)
end

function ai_shisan:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, self.IDX_SKILL_DELAY, 0)
end

return ai_shisan
