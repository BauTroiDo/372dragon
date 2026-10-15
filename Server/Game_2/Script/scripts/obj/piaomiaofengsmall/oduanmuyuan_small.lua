--缥缈峰副本....
--端木元对话脚本....

local class = require "class"
local script_base = require "script_base"
local oduanmuyuan_small = class("oduanmuyuan_small", script_base)

--副本逻辑脚本号....
oduanmuyuan_small.g_FuBenScriptId = 402276

--**********************************
--死亡....
--**********************************
function oduanmuyuan_small:OnDie(selfId, killerId )
	--如果还没有挑战过李秋水则可以挑战李秋水....
	if 2 ~= self:CallScriptFunction( oduanmuyuan_small.g_FuBenScriptId, "GetBossBattleFlag", "LiQiuShui" )	then
		self:CallScriptFunction( oduanmuyuan_small.g_FuBenScriptId, "SetBossBattleFlag", "LiQiuShui", 1 )
	end
	-- zchw 全球公告
	local	playerName	= self:GetName(killerId )
	--杀死怪物的是宠物则获取其主人的名字....
	local playerID = killerId
	local objType = self:GetCharacterType(killerId )
	if objType == "pet" then
		playerID = self:GetPetCreator(killerId )
		playerName = self:GetName(playerID )
	end

	--如果玩家组队了则获取队长的名字....
	local leaderID = self:GetTeamLeader(playerID )
	if leaderID ~= -1 then
		playerName = self:GetName(leaderID )
	end

	if playerName ~= nil then
		local str = string.format("#{XPM_8724_5}#{_INFOUSR%s}#{XPM_8724_6}", playerName);  --任平生
		self:AddGlobalCountNews(str )
	end
end


return oduanmuyuan_small