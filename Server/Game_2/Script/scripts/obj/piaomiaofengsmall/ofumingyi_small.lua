--缥缈峰副本....
--符敏仪对话脚本....


local class = require "class"
local script_base = require "script_base"
local ofumingyi_small = class("owulaoda_small", script_base)
ofumingyi_small.script_id = 402286
-- 402286

--副本逻辑脚本号....
ofumingyi_small.g_FuBenScriptId = 402276

--震慑buff表....
ofumingyi_small.g_ZhenSheBuffTbl = { 10264, 10265, 10266 }
--有趣buff表....
ofumingyi_small.g_YouQuBuffTbl = { 10261, 10262, 10263 }


--**********************************
--任务入口函数....
--**********************************
function ofumingyi_small:OnDefaultEvent(selfId, targetId )
	self:BeginEvent(self.script_id)
	self:AddText("#{PMF_20080521_12}" )
	--判断当前是否可以挑战李秋水....
	if 1 == self:CallScriptFunction( self.g_FuBenScriptId, "GetBossBattleFlag", "ShuangZi" ) then
		self:AddNumText("Thử thách Bất Bình Đạo Nhân Hòa Trác Bất Phàm", 10, 2 )
	end
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

--**********************************
--事件列表选中一项
--**********************************
function ofumingyi_small:OnEventRequest(selfId, targetId, eventId )
	--如果正在激活BOSS则返回....
	if 1 == self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "IsPMFTimerRunning" ) then
		return
	end

	--是不是队长....
	if self:GetTeamLeader(selfId) ~= selfId then
		self:notify_tips(selfId, "#{PMF_20080521_07}")
		return
	end

	--判断当前是否可以挑战双子...
	--[[if 1 ~= self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "GetBossBattleFlag", "ShuangZi" ) then
		return
	end]]

	--如果正在和别的BOSS战斗则返回....
	local ret, msg = self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "CheckHaveBOSS")
	if 1 == ret then
		self:notify_tips(selfId, msg)
		return
	end

	--开启缥缈峰计时器来激活自己....
	self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "OpenPMFTimer", 16, self.script_id, -1 ,-1 )
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end

--**********************************
--缥缈峰计时器的OnTimer....
--**********************************
function ofumingyi_small:OnPMFTimer(step, data1, data2 )
	if 16 == step then
		self:MonsterTalk(-1, "", "#{PMF_20080521_13}" )
		return
	end

	if 13 == step then
		self:MonsterTalk(-1, "", "#{PMF_20080521_14}" )
		return
	end

	if 10 == step then
		self:MonsterTalk(-1, "", "#{PMF_20080521_15}" )
		return
	end

	if 7 == step then
		self:MonsterTalk(-1, "", "#{PMF_20080521_16}" )
		self:UseZhenShe( )
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 5 giây" )
		return
	end

	if 6 == step then
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 4 giây" )
		return
	end

	if 5 == step then
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 3 giây" )
		return
	end

	if 4 == step then
		self:MonsterTalk(-1, "", "#{PMF_20080521_17}" )
		self:UseYouQu()
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 2 giây" )
		return
	end

	if 3 == step then
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 1 giây" )
		return
	end

	if 2 == step then
		--提示战斗开始....
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "TipAllHuman", "Chiến đấu bắt đầu" )
		return
	end

	if 1 == step then
		--建立BOSS....
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "CreateBOSS", "ZhuoBuFan_BOSS", -1, -1 )
		self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "CreateBOSS", "BuPingDaoRen_BOSS", -1, -1 )
		return
	end
end

--**********************************
--发动震慑....
--**********************************
function ofumingyi_small:UseZhenShe( )
	local bossId = self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "FindBOSS", "FuMinYi_NPC" )
	if bossId == -1 then
		return
	end

	local idx = math.random( #(ofumingyi_small.g_ZhenSheBuffTbl) )
	local buffId = ofumingyi_small.g_ZhenSheBuffTbl[idx]

	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			self:LuaFnSendSpecificImpactToUnit( bossId, bossId, nHumanId, buffId, 0 )
		end
	end
end

--**********************************
--发动有趣....
--**********************************
function ofumingyi_small:UseYouQu()
	local bossId = self:CallScriptFunction( ofumingyi_small.g_FuBenScriptId, "FindBOSS", "FuMinYi_NPC" )
	if bossId == -1 then
		return
	end
	local idx = math.random( #(ofumingyi_small.g_YouQuBuffTbl) )
	local buffId = ofumingyi_small.g_YouQuBuffTbl[idx]

	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	for i=1, nHumanCount do
		local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) and self:LuaFnIsCharacterLiving(nHumanId) then
			self:LuaFnSendSpecificImpactToUnit(bossId, bossId, nHumanId, buffId, 0 )
		end
	end
end

return ofumingyi_small