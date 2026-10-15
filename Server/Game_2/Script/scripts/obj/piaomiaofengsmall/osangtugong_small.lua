--缥缈峰副本....
--桑土公对话脚本....

local class = require "class"
local script_base = require "script_base"
local osangtugong_small = class("osangtugong_small", script_base)
osangtugong_small.script_id = 402284
-- 402284

--副本逻辑脚本号....
osangtugong_small.g_FuBenScriptId = 402276

--**********************************
--任务入口函数....
--**********************************
function osangtugong_small:OnDefaultEvent(selfId, targetId )
	self:BeginEvent(self.script_id)
	self:AddText("#{PMF_20080521_08}" )
	self:AddNumText("Khiêu chiến", 10, 1 )
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

--**********************************
--事件列表选中一项
--**********************************
function osangtugong_small:OnEventRequest( selfId, targetId, eventId )
	--如果正在激活BOSS则返回....
	if 1 == self:CallScriptFunction( self.g_FuBenScriptId, "IsPMFTimerRunning") then
		return
	end
	--是不是队长....
	if not self:IsCaptain(selfId) then
		self:BeginEvent(self.script_id)
		self:AddText("#{PMF_20080521_07}" )
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

	--如果正在和别的BOSS战斗则返回....
	local ret, msg = self:CallScriptFunction(self.g_FuBenScriptId, "CheckHaveBOSS")
	if 1 == ret then
		self:BeginEvent(self.script_id)
		self:AddText(msg)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

	--判断当前是否可以挑战桑土公....
	if 1 ~= self:CallScriptFunction( self.g_FuBenScriptId, "GetBossBattleFlag", "SangTuGong" ) then
		self:BeginEvent(self.script_id)
		self:AddText("#{PMF_20080521_09}")
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

	--开启缥缈峰计时器来激活自己....
	self:CallScriptFunction(self.g_FuBenScriptId, "OpenPMFTimer", 7, self.script_id, -1 ,-1 )
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end

--**********************************
--缥缈峰计时器的OnTimer....
--**********************************
function osangtugong_small:OnPMFTimer( step )
	if 7 == step then
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 5 giây" )
		return
	end

	if 6 == step then
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 4 giây" )
		return
	end

	if 5 == step then
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 3 giây" )
		return
	end

	if 4 == step then
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 2 giây" )
		return
	end

	if 3 == step then
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu sẽ bắt đầu sau 1 giây" )
		return
	end

	if 2 == step then
		--提示战斗开始....
		self:CallScriptFunction(self.g_FuBenScriptId, "TipAllHuman", "Chiến đấu bắt đầu" )
		--删除NPC....
		self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS", "SangTuGong_NPC" )
		return
	end

	if 1 == step then
		--建立BOSS....
		self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "SangTuGong_BOSS", -1, -1 )
		return
	end
end

return osangtugong_small