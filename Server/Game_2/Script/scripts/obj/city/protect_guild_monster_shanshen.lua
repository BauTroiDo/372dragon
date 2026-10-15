local class = require "class"
local define = require "define"
local script_base = require "script_base"
local protect_guild_monster_shanshen = class("protect_guild_monster_shanshen", script_base)
protect_guild_monster_shanshen.IDX_BossFightingState = 20
protect_guild_monster_shanshen.SKILL_TBL = {[1] = {["IDX_TimerPrepare"] = 1,["IDX_TimerInterval"] = 2,["IDX_Count"] = 3,["IDX_State"] = 4,["BossSkill"] = 1101,["AlarmTime"] = 0,["SkillCondition"] = 0,["SkilCoolDown"] = 20000,["SkillBlood"] = 0,["TargetType"] = 1,["TargetCord"] = 0,["MsgAlarmType"] = 0,["MsgAlarm"] = "",["MsgFire"] = "%s, hãy lắng nghe lời triệu hồi của Sơn Thần đi!",["BuffList"] = {154,5945,5946}
}
,[2] = {["IDX_TimerPrepare"] = 5,["IDX_TimerInterval"] = 6,["IDX_Count"] = 7,["IDX_State"] = 8,["BossSkill"] = 1102,["AlarmTime"] = 1000,["SkillCondition"] = 0,["SkilCoolDown"] = 25000,["SkillBlood"] = 0,["TargetType"] = 0,["TargetCord"] = 1,["MsgAlarmType"] = 0,["MsgAlarm"] = "Cảm nhận sự phẫn nộ của Sơn Thần đi!",["MsgFire"] = ""}
,[3] = {["IDX_TimerPrepare"] = 9,["IDX_TimerInterval"] = 10,["IDX_Count"] = 11,["IDX_State"] = 12,["BossSkill"] = 1103,["AlarmTime"] = 1000,["SkillCondition"] = 1,["SkilCoolDown"] = 0,["SkillBlood"] = 50,["TargetType"] = 0,["TargetCord"] = 2,["MsgAlarmType"] = 0,["MsgAlarm"] = "Ta không phải một Cá nhân đang Chiến đấu, phàm nhân!",["MsgFire"] = ""}
}

protect_guild_monster_shanshen.g_monster_list = {[1] = {["StageId"] = 1,["MonsterList"] = {{["mType"] = 9626,["x"] = 128,["z"] = 98,["aiType"] = 25,["aiScript"] = -1,["scriptId"] = 805044}
}
}
}

protect_guild_monster_shanshen.g_keySD = {}

protect_guild_monster_shanshen.g_keySD["typ"]  = 0
protect_guild_monster_shanshen.g_keySD["spt"]  = 1
protect_guild_monster_shanshen.g_keySD["tim"]  = 2
protect_guild_monster_shanshen.g_keySD["currStage"]  = 3
protect_guild_monster_shanshen.g_keySD["scn"]  = 4
protect_guild_monster_shanshen.g_keySD["cls"]  = 5
protect_guild_monster_shanshen.g_keySD["dwn"]  = 6
protect_guild_monster_shanshen.g_keySD["tem"]  = 7
protect_guild_monster_shanshen.g_keySD["x"]  = 8
protect_guild_monster_shanshen.g_keySD["z"]  = 9
protect_guild_monster_shanshen.g_keySD["killMonsterNum"]  = 10
protect_guild_monster_shanshen.g_keySD["genMonsterNum"]  = 11
protect_guild_monster_shanshen.g_keySD["playerLevel"]  = 12
function protect_guild_monster_shanshen:OnDie(selfId,killerId)
local killNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["killMonsterNum"] )
killNum = killNum + 1
self:LuaFnSetCopySceneData_Param(self.g_keySD["killMonsterNum"] ,killNum)
local nam_ply = self:GetName(killerId)
local playerID = killerId
local objType = self:GetCharacterType(killerId)
if objType == 3 then
playerID = self:GetPetCreator(killerId)
nam_ply = self:GetName(playerID)
end
local leaderID = self:GetTeamLeader(playerID)
if leaderID ~= -1 then
nam_ply = self:GetName(leaderID)
end
local cityName = self:LuaFnCityGetNameBySceneId()
local message
message = self:format("#cff99cc#{_INFOUSR%s}Đối mặt cường địch, suất lĩnh đội ngũ triển khai cuộc bảo vệ chiến gian khổ tuyệt luân của %s, Sơn Thần tổn binh triệt tướng, không thể công hạ, cuối cùng rốt cuộc từ bỏ kế hoạch hủy diệt thành thị.",nam_ply,cityName)
self:BroadMsgByChatPipe(selfId,message,4)
end

function protect_guild_monster_shanshen:OnHeartBeat(selfId,nTick)
if (1 == self:LuaFnIsCharacterLiving(selfId) and self:MonsterAI_GetIntParamByIndex(selfId,self.IDX_BossFightingState) == 1) then
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
local TimePrepare = self:MonsterAI_GetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerPrepare"] )
if (0 < TimePrepare) then
TimePrepare = TimePrepare - nTick
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerPrepare"] ,TimePrepare)
else
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerPrepare"] ,self.SKILL_TBL[i] ["AlarmTime"] )
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
if (self.SKILL_TBL[i] ["TargetCord"]  == 2) then
posX = self:GetWorldPos(selfId)
self:GenObj(1,posX,posZ - 1)
end
self:LuaFnUnitUseSkill(selfId,self.SKILL_TBL[i] ["BossSkill"] ,nTarget,posX,posZ,fDir)
if self.SKILL_TBL[i] ["BuffList"]  ~= nil then
local bidx = 0
for bidx = 1,self:getn(self.SKILL_TBL[i] ["BuffList"] ) do
self:LuaFnSendSpecificImpactToUnit(selfId,selfId,nTarget,self.SKILL_TBL[i] ["BuffList"] [bidx] ,0)
end
end
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_Count"] ,nCount + 1)
end
nState = 0
end
end
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_State"] ,nState)
end
end
end

function protect_guild_monster_shanshen:OnInit(selfId)
local i = 0
for i = 1,self:getn(self.SKILL_TBL) do
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerPrepare"] ,self.SKILL_TBL[i] ["AlarmTime"] )
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_TimerInterval"] ,self.SKILL_TBL[i] ["SkilCoolDown"] )
self:MonsterAI_SetIntParamByIndex(selfId,self.SKILL_TBL[i] ["IDX_Count"] ,0)
self:MonsterAI_SetIntParamByIndex(selfId,self.IDX_BossFightingState,0)
end
local genNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["genMonsterNum"] )
genNum = genNum + 1
self:LuaFnSetCopySceneData_Param(self.g_keySD["genMonsterNum"] ,genNum)
self:LuaFnNpcChat(selfId,1,"Uy nghiêm của Sơn Thần! Sao có thể mạo phạm!")
end

function protect_guild_monster_shanshen:OnKillCharacter(selfId,targetId)

end

function protect_guild_monster_shanshen:OnEnterCombat(selfId,enmeyId)
self:MonsterAI_SetIntParamByIndex(selfId,self.IDX_BossFightingState,1)
end

function protect_guild_monster_shanshen:OnLeaveCombat(selfId)
self:MonsterAI_SetIntParamByIndex(selfId,self.IDX_BossFightingState,0)
end

function protect_guild_monster_shanshen:TipAllHuman(Str)
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

function protect_guild_monster_shanshen:GenObj(listid,x,z)
if self.g_monster_list[listid]  == nil then
return
end
local IndexList = self.g_monster_list[listid] ["MonsterList"] 
local IndexListSize = self:getn(IndexList)
local i = 1
local str
for i = 1,IndexListSize do
local MonsterId = self:CreateNpc(IndexList[i] ["mType"] ,x,z,IndexList[i] ["aiType"] ,IndexList[i] ["aiScript"] ,IndexList[i] ["scriptId"] )
end
end

function protect_guild_monster_shanshen:RandPlayer()
local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
if nHumanNum < 1 then
return -1
end
local nHumanAliveNum = 0
for i = 0,nHumanNum - 1 do
local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
if self:LuaFnIsCharacterLiving(PlayerId) == 1 then
nHumanAliveNum = nHumanAliveNum + 1
end
end
if nHumanAliveNum < 1 then
return -1
end
local rPlayerIndex = self:random(nHumanAliveNum)
local ind = 0
local round = 2*nHumanNum
while round > 0 do
local PlayerId = self:LuaFnGetCopyScene_HumanObjId(ind)
if self:LuaFnIsCharacterLiving(PlayerId) == 1 and self:LuaFnIsObjValid(PlayerId) == 1 and self:LuaFnIsCanDoScriptLogic(PlayerId) == 1 then
if rPlayerIndex > 0 then
rPlayerIndex = rPlayerIndex - 1
else
return PlayerId
end
end
ind = ind + 1
if ind >= nHumanNum then
ind = 0
end
round = round - 1
end
return -1
end

function protect_guild_monster_shanshen:CreateNpc(NpcId,x,y,Ai,AiFile,Script)
local PlayerLevel = self:LuaFnGetCopySceneData_Param(self.g_keySD["playerLevel"] )
local ModifyLevel = 0
if PlayerLevel > 80 then
ModifyLevel = 1
end
if PlayerLevel > 90 then
ModifyLevel = 2
end
if PlayerLevel > 100 then
ModifyLevel = 3
end
if PlayerLevel > 110 then
ModifyLevel = 4
end
if PlayerLevel > 120 then
ModifyLevel = 5
end
if PlayerLevel > 130 then
ModifyLevel = 6
end
if PlayerLevel > 140 then
ModifyLevel = 7
end
local nNpcId = NpcId + ModifyLevel - 1
local nMonsterId = self:LuaFnCreateMonster(nNpcId,x,y,Ai,AiFile,Script)
self:SetLevel(nMonsterId,PlayerLevel)
local strNpcName = self:GetName(nNpcId)
if (strNpcName == "大山鬼") or (strNpcName == "山神") then
self:SetCharacterTitle(nNpcId,"\"Thạch Đầu Quái Nhân\"")
end
return nMonsterId
end

return protect_guild_monster_shanshen