local class = require "class"
local define = require "define"
local script_base = require "script_base"
local protect_guild_npc_shangui = class("protect_guild_npc_shangui", script_base)

protect_guild_npc_shangui.script_id = 805043

protect_guild_npc_shangui.g_EventList = {805042}



protect_guild_npc_shangui.g_minLevel = 20

function protect_guild_npc_shangui:UpdateEventList(selfId,targetId)

self:CallScriptFunction(self.g_EventList[1] ,"OnEnumerate",selfId,targetId)

end



function protect_guild_npc_shangui:OnDefaultEvent(selfId,targetId)

self:UpdateEventList(selfId,targetId)

end



function protect_guild_npc_shangui:OnEventRequest(selfId,targetId,arg,index)

for i,findId in pairs(self.g_EventList) do

if arg == findId then

self:CallScriptFunction(arg,"OnDefaultEvent",selfId,targetId)

return

end

end

end



function protect_guild_npc_shangui:OnMissionAccept(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnAccept",selfId)

return

end

end

end



function protect_guild_npc_shangui:OnMissionRefuse(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:UpdateEventList(selfId,targetId)

return

end

end

end



function protect_guild_npc_shangui:OnMissionContinue(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnContinue",selfId,targetId)

return

end

end

end



function protect_guild_npc_shangui:OnMissionSubmit(selfId,targetId,missionScriptId,selectRadioId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnSubmit",selfId,targetId,selectRadioId)

return

end

end

end



function protect_guild_npc_shangui:OnDie(selfId,killerId)



end



return protect_guild_npc_shangui