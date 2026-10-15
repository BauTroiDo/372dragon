--水月山庄副本
--阿莹对话脚本

local class = require "class"
local script_base = require "script_base"
local oaying = class("oaying", script_base)
--副本逻辑脚本号....
oaying.g_FuBenScriptId = 892328
oaying.script_id = 892337
--**********************************
--任务入口函数....
--**********************************
function oaying:OnDefaultEvent(selfId, targetId )
	self:BeginEvent(self.script_id)
	self:AddText("#{SYSZ_20210203_56}" )
	self:AddNumText("Khiêu chiến", 10, 1 )
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

--**********************************
--事件列表选中一项
--**********************************
function oaying:OnEventRequest(selfId, targetId, eventId )
	--是不是队长....
	if not self:IsCaptain(selfId) then
		self:BeginEvent(self.script_id)
		self:AddText("#{SYSZ_20210203_32}" )
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	if self:LuaFnGetCopySceneData_Param(10) == 1 then
		self:notify_tips(selfId, "Không thể khiêu chiến lặp")
		return
	end
	if 1 == self:CallScriptFunction(self.g_FuBenScriptId, "IsSYSZTimerRunning") then
		return
	end
	local ret, msg = self:CallScriptFunction(self.g_FuBenScriptId, "CheckHaveBOSS")
	if 1 == ret then
		self:BeginEvent(self.script_id)
		self:AddText(msg)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end
	--开启计时器来激活自己....
	self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "Aying_BOSS", -1, -1)
	self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS", "Aying_NPC")
	--取得当前场景里的人数
	local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
	local nHumanID;
	for i = 1,nHumanCount do
		nHumanID = self:LuaFnGetCopyScene_HumanObjId(i)
		if self:LuaFnIsObjValid(nHumanID)and self:LuaFnIsCanDoScriptLogic(nHumanID) then
			self:DoNpcTalk(nHumanID,111)
			self:BeginEvent(self.script_id)
			self:AddText("#{SYSZ_20210203_80}")
			self:EndEvent()
			self:DispatchMissionTips(nHumanID)
		end
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId, 1000)
end

--**********************************
--缥缈峰计时器的OnTimer....
--**********************************
function oaying:OnSYSZTimer(step)
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
		self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS", "Aying_NPC" )
		return
	end

	if 1 == step then
		--建立BOSS....
		self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS", "Aying_BOSS", -1, -1 )
		return
	end

end

return oaying