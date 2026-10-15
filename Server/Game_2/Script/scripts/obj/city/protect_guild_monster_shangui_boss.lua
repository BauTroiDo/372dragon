local class = require "class"
local define = require "define"
local script_base = require "script_base"
local protect_guild_monster_shangui_boss = class("protect_guild_monster_shangui_boss", script_base)

protect_guild_monster_shangui_boss.SKILL_TBL = {[1] = {["IDX_TimerAlarm"] = 1,["IDX_TimerInterval"] = 2,["IDX_Count"] = 3,["IDX_State"] = 4,["BossSkill"] = 1100,["AlarmTime"] = 0,["SkillCondition"] = 1,["SkilCoolDown"] = 0,["SkillBlood"] = 10,["TargetType"] = 0,["TargetCord"] = 1,["MsgAlarmType"] = 0,["MsgAlarm"] = "山鬼愤怒的看着周围众人",["MsgFire"] = ""}

}



protect_guild_monster_shangui_boss.g_keySD = {}



protect_guild_monster_shangui_boss.g_keySD["typ"]  = 0

protect_guild_monster_shangui_boss.g_keySD["spt"]  = 1

protect_guild_monster_shangui_boss.g_keySD["tim"]  = 2

protect_guild_monster_shangui_boss.g_keySD["currStage"]  = 3

protect_guild_monster_shangui_boss.g_keySD["scn"]  = 4

protect_guild_monster_shangui_boss.g_keySD["cls"]  = 5

protect_guild_monster_shangui_boss.g_keySD["dwn"]  = 6

protect_guild_monster_shangui_boss.g_keySD["tem"]  = 7

protect_guild_monster_shangui_boss.g_keySD["x"]  = 8

protect_guild_monster_shangui_boss.g_keySD["z"]  = 9

protect_guild_monster_shangui_boss.g_keySD["killMonsterNum"]  = 10

protect_guild_monster_shangui_boss.g_keySD["genMonsterNum"]  = 11

protect_guild_monster_shangui_boss.g_keySD["playerLevel"]  = 12

function protect_guild_monster_shangui_boss:OnDie(selfId,killerId)

local killNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["killMonsterNum"] )

killNum = killNum + 1

self:LuaFnSetCopySceneData_Param(self.g_keySD["killMonsterNum"] ,killNum)

local currStage = self:LuaFnGetCopySceneData_Param(self.g_keySD["currStage"] )

if currStage == 1 then

local genNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["genMonsterNum"] )

self:TipAllHuman("已杀死山鬼  " .. killNum .. " / " .. genNum)

end

end



function protect_guild_monster_shangui_boss:OnHeartBeat(selfId,nTick)

if (1 == self:LuaFnIsCharacterLiving(selfId)) then

local i = 0

for i = 1,self:getn(self.SKILL_TBL) do

local TimeInterval = self:MonsterAI_GetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerInterval"] )

local nCount = self:MonsterAI_GetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_Count"] )

local nState = self:MonsterAI_GetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_State"] )

if nState == 0 then

if self.SKILL_TBL[i] ["SkillCondition"]  == 0 then

if 0 < TimeInterval then

TimeInterval = TimeInterval - nTick

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerInterval"] ,TimeInterval)

else

nState = 1

end

end

if self.SKILL_TBL[i] ["SkillCondition"]  == 1 then

if nCount == 0 then

if self:GetHp(selfId) < (self:GetMaxHp(selfId)*self.SKILL_TBL[i] ["SkillBlood"] )/100 then

nState = 1

end

end

end

end

if nState == 1 then

if (TimeInterval <= 0 and self.SKILL_TBL[i] ["MsgAlarm"]  ~= "") then

if self.SKILL_TBL[i] ["MsgAlarmType"]  == 0 then

self:LuaFnNpcChat(selfId,1,self.SKILL_TBL[i] ["MsgAlarm"] )

elseif self.SKILL_TBL[i] ["MsgAlarmType"]  == 1 then

self:TipAllHuman(self.SKILL_TBL[i] ["MsgAlarm"] )

end

end

nState = 2

end

if nState == 2 then

local TimeAlarm = self:MonsterAI_GetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerAlarm"] )

if (0 < TimeAlarm) then

TimeAlarm = TimeAlarm - nTick

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerAlarm"] ,TimeAlarm)

else

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerAlarm"] ,self.SKILL_TBL[i] ["AlarmTime"] )

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerInterval"] ,self.SKILL_TBL[i] ["SkilCoolDown"] )

local nTarget = self:LuaFnGetTargetObjID(selfId)
if self.SKILL_TBL[i] ["TargetType"]  == 1 then

nTarget = self:RandPlayer()

else

nTarget = self:LuaFnGetTargetObjID(selfId)

end

if (-1 ~= nTarget) then

if (self.SKILL_TBL[i] ["MsgFire"]  ~= "") then

local msgFire = self:format(self.SKILL_TBL[i] ["MsgFire"] ,self:LuaFnGetName(nTarget))

self:LuaFnNpcChat(selfId,1,msgFire)

end

local posX,posZ = self:GetWorldPos(nTarget)

local fDir = 0.0

if (self.SKILL_TBL[i] ["TargetCord"]  == 1) then

posX = self:GetWorldPos(selfId)

end

self:LuaFnUnitUseSkill(selfId,self.SKILL_TBL[i] ["BossSkill"] ,nTarget,posX,posZ,fDir)

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_Count"] ,nCount + 1)

end

nState = 0

end

end

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_State"] ,nState)

end

end

end



function protect_guild_monster_shangui_boss:OnInit(selfId)

local i = 0

for i = 1,self:getn(self.SKILL_TBL) do

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerAlarm"] ,self.SKILL_TBL[i] ["AlarmTime"] )

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerInterval"] ,self.SKILL_TBL[i] ["SkilCoolDown"] )

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_Count"] ,0)

self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_State"] ,0)

end

local genNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["genMonsterNum"] )

genNum = genNum + 1

self:LuaFnSetCopySceneData_Param(self.g_keySD["genMonsterNum"] ,genNum)

end



function protect_guild_monster_shangui_boss:OnKillCharacter(selfId,targetId)



end



function protect_guild_monster_shangui_boss:OnEnterCombat(selfId,enmeyId)



end



function protect_guild_monster_shangui_boss:OnLeaveCombat(selfId)



end



function protect_guild_monster_shangui_boss:TipAllHuman(Str)

local nHumanNum = self:LuaFnGetCopyScene_HumanCount()

if nHumanNum < 1 then

return

end

for i = 0,nHumanNum - 1 do

local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)

if self:LuaFnIsObjValid(PlayerId) == 1 and self:LuaFnIsCanDoScriptLogic(PlayerId) == 1 then

self:BeginEvent(self.script_id)

self:AddText(Str)

self:EndEvent()

self:DispatchMissionTips(PlayerId)

end

end

end



function protect_guild_monster_shangui_boss:RandPlayer()

local nHumanNum = self:LuaFnGetCopyScene_HumanCount()

if nHumanNum < 1 then

return -1

end

local rPlayerIndex = self:random(nHumanNum)

local PlayerId = self:LuaFnGetCopyScene_HumanObjId(rPlayerIndex)

return PlayerId

end



return protect_guild_monster_shangui_boss