local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_phoenixfubenload = class("event_phoenixfubenload", script_base)
-- local gbk = require "gbk"
event_phoenixfubenload.script_id = 403015

event_phoenixfubenload.g_FjqhFuben_X = 13;
event_phoenixfubenload.g_FjqhFuben_Z = 110;
event_phoenixfubenload.g_FjqhFubenName = "Phượng Hoàng Lăng Mộ";
function event_phoenixfubenload:OnCopySceneReady(destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
	local Leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId);
	local Leaderobjid = self:LuaFnGuid2ObjId(Leaderguid);
	if Leaderobjid and self:LuaFnIsObjValid(Leaderobjid ) then
		local Nearcount = self:GetNearTeamCount(Leaderobjid);
		local teaminfo = {}
		local playerid
		local idx = 0
		if Nearcount and Nearcount > 0 then
			for i = 1,Nearcount do
				playerid = self:GetNearTeamMember(Leaderobjid, i);
				if playerid ~= Leaderobjid then
					if self:LuaFnIsObjValid( playerid ) then
						idx = idx + 1;
						teaminfo[idx] = playerid;
					end
				end
			end
		end
		self:NewWorld(Leaderobjid, destsceneId,sn, self.g_FjqhFuben_X, self.g_FjqhFuben_Z,281);
		for i,j in ipairs(teaminfo) do
			self:NewWorld(j, destsceneId,sn, self.g_FjqhFuben_X, self.g_FjqhFuben_Z,281);
		end
	end
end
function event_phoenixfubenload:OnPlayerEnter(selfId)
	local sceneId = self:GetSceneID()
	local Leaderguid = self:LuaFnGetCopySceneData_TeamLeader(sceneId);
	local Guid = self:LuaFnGetGUID(selfId);
	if Guid == Leaderguid then
		self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, self.g_FjqhFuben_X, self.g_FjqhFuben_Z)
	else
		local Istrue = 0;
		for i = 26,30 do
			if Guid == self:LuaFnGetCopySceneData_Param( i) then
				Istrue = 1;
				break
			end
		end
		if Istrue == 1 then
			self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, self.g_FjqhFuben_X, self.g_FjqhFuben_Z)
		else
			local oldscene = self:LuaFnGetCopySceneData_Param(24)
			local pos = self:LuaFnGetCopySceneData_Param(25)
			local posx = math.floor(pos / 1000)
			local posz = pos % 1000
			self:NewWorld(selfId, oldscene, nil,posx,posz)
		end
	end
end
function event_phoenixfubenload:OnHumanDie(selfId, killerId)
	if selfId == killerId then
		local msg = string.format("Ối! [%s] lách vào phụ bản [%s] đang định cười thầm thì não giật, lăn ra chết, tự giết chính mình cũng tài, lêu lêu!!",LuaFnGetName(sceneId,selfId),event_phoenixfubenload.g_FjqhFubenName)
		self:AddGlobalCountNews( msg);
	end
end
function event_phoenixfubenload:OnCopySceneTimer(nowTime)
	local Closefag = self:LuaFnGetCopySceneData_Param(4);
	if Closefag > 0 then
		local Quit = self:LuaFnGetCopySceneData_Param(5);
		if Quit < 0 then
			return
		elseif Quit == 0 then
			local Playercount = self:LuaFnGetCopyScene_HumanCount()
			local oldscene = self:LuaFnGetCopySceneData_Param(24);
			local pos = self:LuaFnGetCopySceneData_Param(25);
			local posx = math.floor(pos / 1000)
			local posz = pos % 1000
			for i = 1,Playercount do
				pos = self:LuaFnGetCopyScene_HumanObjId(i);
				if self:LuaFnIsObjValid(pos) then
					self:NewWorld(pos, oldscene, nil,posx,posz)
				end
			end
		else
			Quit = Quit - 1;
			self:LuaFnSetCopySceneData_Param( 5, Quit);
			local msg = string.format("Phụ bản kết thúc, sau [%d] giây tự truyền ra, cũng có thể tìm NPC truyền tống hoặc cách khác.",Quit)
			self:MonsterTalk( -1, self.g_FjqhFubenName, msg);
		end
	else
		local Timer = self:LuaFnGetCopySceneData_Param(2);
		if Timer >= self:LuaFnGetCopySceneData_Param(3) then
			self:LuaFnSetCopySceneData_Param(4, 1);
			local msg = string.format("Hết giờ phụ bản, sẽ đóng sau [%d] giây.",self:LuaFnGetCopySceneData_Param(5));
			self:MonsterTalk( -1, self.g_FjqhFubenName, msg);
		else
			Timer = Timer + 1;
			self:LuaFnSetCopySceneData_Param(2, Timer);
			local Killmoster = self:LuaFnGetCopySceneData_Param(6);
			if Killmoster >= self:LuaFnGetCopySceneData_Param(7) then
				local Dataid = self:LuaFnGetCopySceneData_Param(8)
				local Moster = self:LuaFnCreateMonster(Dataid, 67, 74, 4, -1, 900029 );
				if Moster and Moster >= 0 then
					self:LuaFnSetCopySceneData_Param(6,0)
					local Moslv = self:LuaFnGetCopySceneData_Param(9);
					if Moslv > 0 then
						self:SetLevel(Moster,Moslv);
					end
					self:SetCharacterTitle(Moster, "Đạo Mộ Thủ lĩnh")
					self:MonsterTalk( -1, self.g_FjqhFubenName, msg);
				end
			end
		end
	end
end
return event_phoenixfubenload

