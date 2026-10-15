local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_phoenixfubennpc = class("event_phoenixfubennpc", script_base)
-- local gbk = require "gbk"
event_phoenixfubennpc.script_id = 403014
event_phoenixfubennpc.NeedSceneId = 191

event_phoenixfubennpc.NddePlayerCount = 3				--进副本需求人数

function event_phoenixfubennpc:OnDefaultEvent( selfId,targetId )
	if not self:LuaFnIsActivityMonster(selfId,targetId,1) then
		return
	end
	self:BeginEvent()
		self:AddText( "Từng dự thành chiến và thuộc minh bá chủ mới dẫn đội vào lăng Phượng Hoàng" );
		self:AddNumText(self.g_ScriptId, "Vào lăng mộ Phượng Hoàng", 6,1);
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end
function event_phoenixfubennpc:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		if not self:LuaFnIsActivityMonster(selfId,targetId,1) then
			return
		end
		if self:LuaFnHasTeam(selfId) == 0 then
			self:Box( selfId, targetId, "Bạn chưa có đội, xin lập đội từ 3 người trở lên tới" )
			return
		elseif self:LuaFnIsTeamLeader(selfId) == 0 then
			self:Box( selfId, targetId, "Bạn không phải đội trưởng, xin đội trưởng chọn tham gia hay không" )
			return
		elseif not self:IsPhoenixPlainBaZhu(selfId) then
			self:Box( selfId, targetId, "Cần bá chủ dẫn đội vào phụ bản" )
			return
		end
		local Teamcount = self:GetTeamMemberCount(selfId)
		if Teamcount < self.NddePlayerCount then
			self:Box( selfId, targetId, "Muốn vào phụ bản này cần đội ít nhất"..tostring(self.NddePlayerCount).."người" )
			return
		end
		local NearTeamSize = self:GetNearTeamCount(selfId)
		if Teamcount ~= NearTeamSize then
			self:Box( selfId, targetId, "Xin gọi hết đồng đội tới bên cạnh trước" )
			return
		end
		local nPosX,nPosY = self:GetWorldPos(selfId)
		nPosX = math.floor(nPosX)
		nPosY = math.floor(nPosY)
		local Pos = nPosX * 1000 + nPosY
		local teamguid = {}
		local teamlv = self:GetLevel(selfId)
		teamguid[1] = self:LuaFnGetGUID(selfId)
		local playerid
		local idx = 1
		for i = 1,Teamcount do
			playerid = self:GetNearTeamMember(selfId, i)
			if playerid ~= selfId then
				idx = idx + 1
				teamguid[idx] = self:LuaFnGetGUID(playerid)
				teamlv = teamlv + self:GetLevel(playerid)
			end
		end
		teamlv = math.ceil(teamlv / Teamcount)
		local lvini = math.floor(teamlv / 10)
		if teamlv % 10 >= 5 then
			lvini = lvini + 1
		end
		if lvini < 4 then
			lvini = 4
		elseif lvini > 12 then
			lvini = 12
		end
		local bossinfo = {0,0,0, 13759,13760,13761,13762,13763,13764,13765,13766,13767};
		local Bossid = bossinfo[lvini];
		local config = {}
		config.navmapname = "PhoenixMaze.nav"
		config.client_res = 281
		config.teamleader = leaderguid
		config.NoUserCloseTime = 10000
		config.Timer = 1000
		config.params = {}
		config.params[0] = ScriptGlobal.FUBEN_FENGHUANGLINGMU        	--设置副本数据，这里将0号索引的数据设置为999，用于表示副本号999(数字自定义)
		config.params[1] = 403015                            	--将1号数据设置为副本场景事件脚本号
		config.params[2] = 0                                         	--设置定时器调用次数
		config.params[3] = 3600                                      	--超时则副本关闭  定时器次数 >= 3600
		config.params[4] = 0                                         	--设置副本关闭标志, 0开放，1关闭
		config.params[5] = 10                                        	--副本标志关闭时倒计时 == 0 时 把副本里的人传出去
		config.params[6] = 0                                         	--击杀盗墓贼数量
		config.params[7] = 43                                        	--击杀盗墓贼数量 >= 43 时 刷boss
		config.params[8] = Bossid                                    	--刷BOSSID
		config.params[9] = teamlv                                    	--BOSSLV
		for i = 10,31 do
			config.params[i] = 0
		end
		config.params[24] = self.NeedSceneId                                         --进入场景
		config.params[25] = Pos                                         --进入位置
		for i,j in ipairs(teamguid) do
			config.params[25 + i] = j
		end
		-- config.event_area                              = "PhoenixMaze_area.ini"
		config.monsterfile                             = "PhoenixMaze_monster"..tostring(lvini)..".ini"
		config.sn                                      = self:LuaFnGenCopySceneSN()
		local bRetSceneID                              = self:LuaFnCreateCopyScene(config)
		if bRetSceneID > 0 then
			self:LuaFnDeleteMonster(targetId)
			self:notify_tips(selfId, "Tạo phó bản thành công!")
		else
			self:notify_tips(selfId, "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
		end
	end
end
function event_phoenixfubennpc:Box( selfId, targetId, Box )
	self:BeginEvent()
	self:AddText( Box )
	self:EndEvent( )
	self:DispatchEventList( selfId, targetId )
end
return event_phoenixfubennpc
