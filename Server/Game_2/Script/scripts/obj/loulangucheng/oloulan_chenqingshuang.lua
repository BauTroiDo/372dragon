--楼兰NPC....
--缥缈峰接引使....
local class = require "class"
local script_base = require "script_base"
local oloulan_chenqingshuang = class("oloulan_chenqingshuang", script_base)

--所拥有的事件ID列表
oloulan_chenqingshuang.g_eventList={402276,402263}

--**********************************
--事件列表
--**********************************
function oloulan_chenqingshuang:UpdateEventList(selfId,targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{PMF_20080521_01}")
	for _, eventId in ipairs(self.g_eventList) do
		self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId )
	end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

--**********************************
--事件交互入口
--**********************************
function oloulan_chenqingshuang:OnDefaultEvent(selfId,targetId )
	self:UpdateEventList(selfId, targetId )
end

--**********************************
--事件列表选中一项
--**********************************
function oloulan_chenqingshuang:OnEventRequest(selfId, targetId, eventId )
	for _, findId in ipairs(self.g_eventList) do
		if eventId == findId then
			self:CallScriptFunction(eventId, "OnDefaultEvent", selfId, targetId, eventId, self.script_id)
		    return
		end
	end
end

return oloulan_chenqingshuang