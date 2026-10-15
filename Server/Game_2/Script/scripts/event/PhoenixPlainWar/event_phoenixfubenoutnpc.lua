local class = require "class"
local define = require "define"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_phoenixfubenoutnpc = class("event_phoenixfubenoutnpc", script_base)
-- local gbk = require "wire_charset"
event_phoenixfubenoutnpc.script_id = 900028

function event_phoenixfubenoutnpc:OnDefaultEvent( selfId,targetId )
	self:BeginEvent()
		self:AddText( "Bây giờ muốn ra ngoài?" );
		self:AddNumText( self.script_id, "Đúng, ta muốn ra ngoài", 6,1);
	self:EndEvent(sceneId)
	self:DispatchEventList(selfId,targetId)
end
function event_phoenixfubenoutnpc:OnEventRequest( selfId, targetId, arg, index )
	if index == 1 then
		if self:LuaFnGetCopySceneData_Param(191,21) == 0 then
			local Newscene = self:LuaFnGetCopySceneData_Param(24);
			local Int1 = self:LuaFnGetCopySceneData_Param(25);
			local Posx = math.floor(Int1 / 1000);
			local Posz = Int1 % 1000
			if selfId and self:LuaFnIsObjValid(selfId) then
				self:NewWorld(selfId, Newscene, nil, Posx, Posz);
			end
		else
			self:NewWorld(selfId,420,nil,152,147);
		end
	end
end
return event_phoenixfubenoutnpc

