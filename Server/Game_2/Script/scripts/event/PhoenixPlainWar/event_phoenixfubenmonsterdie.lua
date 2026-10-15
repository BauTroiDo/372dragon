local class = require "class"
local define = require "define"
-- local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_phoenixfubenmonsterdie = class("event_phoenixfubenmonsterdie", script_base)
-- local gbk = require "wire_charset"
event_phoenixfubenmonsterdie.script_id = 900029
event_phoenixfubenmonsterdie.NeedSceneId = 191

function event_phoenixfubenmonsterdie:OnDie( objId, killerId )
	if sceneId ~= self.NeedSceneId then return end
	local MosDataID = self:GetMonsterDataID(objId)
	if MosDataID and MosDataID >= 13759 and MosDataID <= 13767 then
		self:LuaFnSetCopySceneData_Param(4, 1);
		local msg = string.format("Đã giết Ban Sơn Đạo Nhân, phụ bản đóng sau [%d] giây.",self:LuaFnGetCopySceneData_Param(5));
		self:MonsterTalk(-1, "Phượng Hoàng Lăng Mộ", msg);
	else
		local Killcount = self:LuaFnGetCopySceneData_Param( 6) + 1;
		self:LuaFnSetCopySceneData_Param( 6, Killcount);
		local msg = string.format("Đã giết Mạc Kim Hiệu Úy [%d/%d]",Killcount,self:LuaFnGetCopySceneData_Param(7))
		self:MonsterTalk(-1, "Phượng Hoàng Lăng Mộ", msg);
	end
end
return event_phoenixfubenmonsterdie

