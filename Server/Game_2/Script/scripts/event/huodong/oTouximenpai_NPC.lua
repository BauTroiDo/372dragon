--偷袭门派
--普通
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oTouximenpai_NPC = class("oTouximenpai_NPC", script_base)

--所拥有的事件ID列表
oTouximenpai_NPC.g_EventList	= { 808016,808027,808028,808029,808030,808031,808032,808033,808034 ,893253,893254,893256}

--场景id到事件脚本号的映射表
oTouximenpai_NPC.g_Scene2EventList = {{9,808027}, {16,808028}, {13,808029}, {17,808030},{11,808031},{10,808032},{12,808033},{15,808034},{14,808016},{184,893253},{987,893254},{1358,893256}}

--接取任务的最低等级
oTouximenpai_NPC.g_minLevel			= 20

--**********************************
--事件列表
--**********************************
function oTouximenpai_NPC:UpdateEventList(selfId, targetId )
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    for _,FindsceneId in ipairs(self.g_Scene2EventList) do
        if FindsceneId[1] == self:get_scene_id() then
			self:CallScriptFunction( FindsceneId[2], "OnEnumerate", self, selfId, targetId )
		end
	end
end

--**********************************
--事件交互入口
--**********************************
function oTouximenpai_NPC:OnDefaultEvent(selfId, targetId )
	self:UpdateEventList(selfId, targetId )
end

--**********************************
--事件列表选中一项
--**********************************
function oTouximenpai_NPC:OnEventRequest(selfId, targetId, eventId )
	for i, findId in ipairs(self.g_EventList) do
		if eventId == findId then
			self:CallScriptFunction( eventId, "OnDefaultEvent", selfId, targetId )
			return
		end
	end
end

--**********************************
--接受此NPC的任务
--**********************************
function oTouximenpai_NPC:OnMissionAccept(selfId, targetId, missionScriptId )
	for i, findId in ipairs(self.g_EventList) do
		if missionScriptId == findId then
			self:CallScriptFunction( missionScriptId, "OnAccept", selfId )
			return
		end
	end
end

--**********************************
--拒绝此NPC的任务
--**********************************
function oTouximenpai_NPC:OnMissionRefuse(selfId, targetId, missionScriptId )
	--拒绝之后，要返回NPC的事件列表
	for i, findId in ipairs(self.g_EventList) do
		if missionScriptId == findId then
			self:UpdateEventList(selfId, targetId )
			return
		end
	end
end

--**********************************
--继续（已经接了任务）
--**********************************
function oTouximenpai_NPC:OnMissionContinue(selfId, targetId, missionScriptId )
	for i, findId in ipairs(self.g_EventList) do
		if missionScriptId == findId then
			self:CallScriptFunction( missionScriptId, "OnContinue", selfId, targetId )
			return
		end
	end
end

--**********************************
--提交已做完的任务
--**********************************
function oTouximenpai_NPC:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId )
	for i, findId in ipairs(self.g_EventList) do
		if missionScriptId == findId then
			self:CallScriptFunction( missionScriptId, "OnSubmit", selfId, targetId, selectRadioId )
			return
		end
	end
end

--**********************************
--死亡事件
--**********************************
function oTouximenpai_NPC:OnDie(selfId, killerId )
end

return oTouximenpai_NPC