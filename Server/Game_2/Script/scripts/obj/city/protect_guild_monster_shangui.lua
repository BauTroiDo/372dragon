local class = require "class"
local define = require "define"
local script_base = require "script_base"
local protect_guild_monster_shangui = class("protect_guild_monster_shangui", script_base)

protect_guild_monster_shangui.g_keySD = {}



protect_guild_monster_shangui.g_keySD["typ"]  = 0

protect_guild_monster_shangui.g_keySD["spt"]  = 1

protect_guild_monster_shangui.g_keySD["tim"]  = 2

protect_guild_monster_shangui.g_keySD["currStage"]  = 3

protect_guild_monster_shangui.g_keySD["scn"]  = 4

protect_guild_monster_shangui.g_keySD["cls"]  = 5

protect_guild_monster_shangui.g_keySD["dwn"]  = 6

protect_guild_monster_shangui.g_keySD["tem"]  = 7

protect_guild_monster_shangui.g_keySD["x"]  = 8

protect_guild_monster_shangui.g_keySD["z"]  = 9

protect_guild_monster_shangui.g_keySD["killMonsterNum"]  = 10

protect_guild_monster_shangui.g_keySD["genMonsterNum"]  = 11

protect_guild_monster_shangui.g_keySD["playerLevel"]  = 12

function protect_guild_monster_shangui:OnDie(selfId,killerId)

local killNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["killMonsterNum"] )

killNum = killNum + 1

self:LuaFnSetCopySceneData_Param(self.g_keySD["killMonsterNum"] ,killNum)

local genNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["genMonsterNum"] )

self:TipAllHuman("“—…±À¿…ΩπÌ  " .. killNum .. " / " .. genNum)

end



function protect_guild_monster_shangui:OnHeartBeat(selfId,nTick)



end



function protect_guild_monster_shangui:OnInit(selfId)

local genNum = self:LuaFnGetCopySceneData_Param(self.g_keySD["genMonsterNum"] )

genNum = genNum + 1

self:LuaFnSetCopySceneData_Param(self.g_keySD["genMonsterNum"] ,genNum)

end


function protect_guild_monster_shangui:OnKillCharacter(selfId,targetId)



end



function protect_guild_monster_shangui:OnEnterCombat(selfId,enmeyId)



end



function protect_guild_monster_shangui:OnLeaveCombat(selfId)



end



function protect_guild_monster_shangui:TipAllHuman(Str)

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



function protect_guild_monster_shangui:RandPlayer()

local nHumanNum = self:LuaFnGetCopyScene_HumanCount()

if nHumanNum < 1 then

return -1

end

local rPlayerIndex = self:random(nHumanNum)

local PlayerId = self:LuaFnGetCopyScene_HumanObjId(rPlayerIndex)

return PlayerId

end



return protect_guild_monster_shangui