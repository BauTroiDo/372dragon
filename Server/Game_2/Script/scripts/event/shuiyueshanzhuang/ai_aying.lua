local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ai_aying = class("ai_aying", script_base)
ai_aying.script_id = 892332
ai_aying.g_FuBenScriptId = 892328
ai_aying.Buff_MianYi1 = 10472
ai_aying.Buff_MianYi2 = 10471
ai_aying.Skill_A = 1409
ai_aying.Buff_A = 10230
ai_aying.IDX_CombatFlag = 1
function ai_aying:OnInit(selfId)
    self:ResetMyAI(selfId)
end

function ai_aying:OnHeartBeat(selfId, nTick)
    if not self:LuaFnIsCharacterLiving(selfId) then
        return
    end
    if 0 == self:MonsterAI_GetBoolParamByIndex(selfId, self.IDX_CombatFlag) then
        return
    end
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
end

function ai_aying:TickSkillC(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 3)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 3, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 3, 145000 - (nTick - cd))
        return self:UseSkillC(selfId)
    end
end

function ai_aying:UseSkillC(selfId)
    self:SetPos(selfId, 143, 66)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Ưng về! Cùng ta chống địch.")
    self:LuaFnUnitUseSkill(selfId, 1419, selfId, x, z, 0, 0)
    local Pos = {
        {143, 76},
        {143, 56},
        {153, 66},
        {133, 66}
    }

    for i = 1, 4 do
        local nNpcId = self:LuaFnCreateMonster(48519, Pos[i][1], Pos[i][2], 32, -1, 892333)
        self:LuaFnSendSpecificImpactToUnit(nNpcId, nNpcId, nNpcId, 50004, 0)
        self:LuaFnSetNpcIntParameter(nNpcId, 0, selfId)
        --self:SetCharacterTimer(nNpcId, 1000)
    end
    return 1
end

function ai_aying:TickSkillA(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 1)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 1, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 1, 125000 - (nTick - cd))
        return self:UseSkillA(selfId)
    end
end

function ai_aying:TickSkillB(selfId, nTick)
    local cd = self:MonsterAI_GetIntParamByIndex(selfId, 2)
    if cd >= nTick then
        self:MonsterAI_SetIntParamByIndex(selfId, 2, cd - nTick)
        return 0
    else
        self:MonsterAI_SetIntParamByIndex(selfId, 2, 35000 - (nTick - cd))
        return self:UseSkillB(selfId)
    end
end

function ai_aying:UseSkillB(selfId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local nHumanInfo = {}
    local nCount = 1
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Con mồi đã rơi vào bẫy, hay là nên ngoan ngoãn chịu trói đi.")
    self:LuaFnUnitUseSkill(selfId,3236,selfId,x,z,0,0)
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
            table.insert(nHumanInfo,nHumanId)
        end
    end
    if #nHumanInfo then
        if nHumanCount > 2 then
            nCount = 2
        end
        for i = 1,nCount do
            local nRandomPlayerID = nHumanInfo[math.random(1,#nHumanInfo)]
            local nHumanx,nHumanz = self:GetWorldPos(nRandomPlayerID)
            self:CreateSpecialObjByDataIndex(selfId,1100,nHumanx,nHumanz,12000)
        end
    end
    return 1
end

function ai_aying:UseSkillA(selfId)
    local x, z = self:GetWorldPos(selfId)
    self:MonsterTalk(selfId, "Thủy Nguyệt Động Thiên", "Để tiểu nữ tử này lĩnh giáo chiêu cao minh của các vị vậy~")
    self:LuaFnUnitUseSkill(selfId, 1417, selfId, x, z, 0, 0)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        for j = 1, 2 do
            local nNpcId = self:LuaFnCreateMonster(48518, x, z, 32, -1, 892333)
            self:LuaFnSetNpcIntParameter(nNpcId, 0, nHumanId)
            self:SetUnitReputationID(nNpcId, nNpcId, 0)
            --self:SetCharacterTimer(nNpcId, 500)
        end
    end
    return 1
end

function ai_aying:OnEnterCombat(selfId, enmeyId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi1, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.Buff_MianYi2, 0)
    self:ResetMyAI(selfId)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 1)
end

function ai_aying:OnKillCharacter(selfId, targetId)
end
function ai_aying:OnLeaveCombat(selfId)
	--重置AI....
	self:ResetMyAI( selfId )
	--创建对话NPC....
    self:LuaFnDeleteMonster(selfId)
    self:CallScriptFunction(self.g_FuBenScriptId, "DisableDynamicRegions", "Aying_BOSS")
	local MstId = self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "Aying_NPC", -1, -1 )
	self:SetUnitReputationID( MstId, MstId, 0 )
end

function ai_aying:OnDie(selfId, killerId)
    self:ResetMyAI(selfId)
    self:CallScriptFunction(892328, "OnDie", selfId, killerId)
end

function ai_aying:ResetMyAI(selfId)
    self:MonsterAI_SetIntParamByIndex(selfId, 1, 0)
    self:MonsterAI_SetIntParamByIndex(selfId, 2, 0)
    self:MonsterAI_SetBoolParamByIndex(selfId, self.IDX_CombatFlag, 0)
end

return ai_aying
