--缥缈峰副本....
--乌老大对话脚本....

local class = require "class"
local script_base = require "script_base"
local owulaoda = class("owulaoda", script_base)
owulaoda.script_id = 402272
-- 402272

--副本逻辑脚本号....
owulaoda.g_FuBenScriptId = 402263

--战败乌老大对话脚本号....
owulaoda.g_LossScriptId = 402288

--**********************************
--任务入口函数....
--**********************************
function owulaoda:OnDefaultEvent(selfId, targetId )
	self:BeginEvent(self.script_id)
	self:AddText("#{PMF_20080521_10}" )
	self:AddNumText("Khiêu chiến", 10, 1 )
	--判断当前是否可以挑战李秋水....
	if 1 == self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "LiQiuShui" ) then
		self:AddNumText("Quyết chiến Lý Thu Thủy?", 10, 2 )
	end
	if 2 == self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "LiQiuShui" ) then
		self:AddNumText("Rời đi", 9, 100 )
	end
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

--**********************************
--事件列表选中一项
--**********************************
function owulaoda:OnEventRequest(selfId, targetId, arg, eventId )
	--如果正在激活BOSS则返回....
	if 1 == self:CallScriptFunction(self.g_FuBenScriptId, "IsPMFTimerRunning") then
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

	if eventId == 1 then
		--判断当前是否可以挑战乌老大...
		--[[if 1 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "WuLaoDa" ) then
			self:notify_tips(selfId, "#{PMF_20080521_11}")
			return
		end]]
		--开启缥缈峰计时器来激活自己....
		self:CallScriptFunction(self.g_FuBenScriptId, "OpenPMFTimer", 7, self.script_id, -1 ,-1 )
	elseif eventId == 2 then
		--判断当前是否可以挑战李秋水....
		if 1 ~= self:CallScriptFunction(self.g_FuBenScriptId, "GetBossBattleFlag", "LiQiuShui" ) then
			return
		end
		--开启缥缈峰计时器来激活李秋水....
		self:CallScriptFunction(self.g_FuBenScriptId, "OpenPMFTimer", 7, self.script_id, -1 ,-1 )
	elseif eventId == 100 then
		self:CallScriptFunction((400900), "TransferFunc", selfId,186, 193,220)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end

--**********************************
--缥缈峰计时器的OnTimer....
--**********************************
function owulaoda:OnPMFTimer(step)
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
		self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS", "WuLaoDa_NPC" )
		return
	end

	if 1 == step then
		--建立BOSS....
		self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "WuLaoDa_BOSS", -1, -1 )
		return
	end
end

return owulaoda