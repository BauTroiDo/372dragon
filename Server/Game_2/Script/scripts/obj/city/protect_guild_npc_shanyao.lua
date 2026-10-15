local class = require "class"
local define = require "define"
local script_base = require "script_base"
local protect_guild_npc_shanyao = class("protect_guild_npc_shanyao", script_base)

protect_guild_npc_shanyao.script_id = 805040

protect_guild_npc_shanyao.g_EventList = {805042}



protect_guild_npc_shanyao.g_minLevel = 20

function protect_guild_npc_shanyao:UpdateEventList(selfId,targetId)

local Humanguildid = self:GetHumanGuildID(selfId)

local cityguildid = self:GetCityGuildID(selfId)

if Humanguildid ~= cityguildid then

self:BeginEvent(self.script_id)

self:AddText("#{SYDH_81016_01}")

self:AddNumText("Về việc bảo vệ bang hội",11,2)

self:EndEvent()

self:DispatchEventList(selfId,targetId)

return

end

self:CallScriptFunction(self.g_EventList[1] ,"OnEnumerate",selfId,targetId)

end



function protect_guild_npc_shanyao:OnDefaultEvent(selfId,targetId)

self:UpdateEventList(selfId,targetId)

end



function protect_guild_npc_shanyao:OnEventRequest(selfId,targetId,arg,index)

for i,findId in pairs(self.g_EventList) do

if arg == findId then

self:CallScriptFunction(arg,"OnDefaultEvent",selfId,targetId)

return

end

end

end



function protect_guild_npc_shanyao:OnMissionAccept(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnAccept",selfId)

return

end

end

end



function protect_guild_npc_shanyao:OnMissionRefuse(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:UpdateEventList(selfId,targetId)

return

end

end

end



function protect_guild_npc_shanyao:OnMissionContinue(selfId,targetId,missionScriptId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnContinue",selfId,targetId)

return

end

end

end



function protect_guild_npc_shanyao:OnMissionSubmit(selfId,targetId,missionScriptId,selectRadioId)

for i,findId in pairs(self.g_EventList) do

if missionScriptId == findId then

self:CallScriptFunction(missionScriptId,"OnSubmit",selfId,targetId,selectRadioId)

return

end

end

end



function protect_guild_npc_shanyao:OnDie(selfId,killerId)



end



return protect_guild_npc_shanyao