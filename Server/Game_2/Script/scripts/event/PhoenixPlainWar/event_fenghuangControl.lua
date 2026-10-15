local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_fenghuangControl = class("event_fenghuangControl", script_base)
local gbk = require "wire_charset"
event_fenghuangControl.script_id = 403005

---------------------配置区------------------------
event_fenghuangControl.KillPlayerTime = 100				--击杀同一个玩家时间 间隙
--1-8个点的联盟  成员同盟盟会ID 任意数量为一个联盟   重点：一个联盟请少于四百人
event_fenghuangControl.UnionInfo = {
    [1] = {0},                  
    [2] = {1},                  
    [3] = {2},             
    [4] = {3},                        
    [5] = {4},                  
    [6] = {5},                     
    [7] = {6},             
    [8] = {7}           
}
---------------------配置区------------------------




---------------------活动数据定义区------------
event_fenghuangControl.SceneId = 191
event_fenghuangControl.g_SceneData =
{
    --下列数组含义1和2是本同盟复活点坐标
    --3是阵营数据 4和5是copysceneparam的占用 4是记录夺旗积分记录 5是抢夺水晶积分记录
	--6=联盟名称
    [1] = {66,35,109,0,22,				"Liên minh·Càn",},
    [2] = {252,28,110,1,23,				"Liên minh·Khôn",},
    [3] = {288,62,111,2,24,				"Liên minh·Chấn",},
    [4] = {292,250,112,3,25,			"Liên minh·Tốn",},
    [5] = {261,291,113,4,26,			"Liên minh·Khảm",},
    [6] = {68,291,114,5,27,				"Liên minh·Ly",},
    [7] = {28,239,115,6,28,				"Liên minh·Cấn",},
    [8] = {34,60,116,7,29,				"Liên minh·Đoài",},
}
event_fenghuangControl.g_CrystalCampID = 
{
    --下列数组含义1用于记录水晶归属 2用于记录水晶刷新时间
    --4用于记录击杀者的联盟名称
	--5=首次占领联盟
	--6=预留
	--7,8初始位置
    [14003] = {8,13,"Tây Nam",17,40,41,	91,229,	},
    [14005] = {9,14,"Đông Nam",18,42,43,	230,230,},
    [14007] = {10,15,"Tây Bắc",19,44,45,	92,90,	},
    [14009] = {11,16,"Đông Bắc",20,46,47,	229,90,	}

}
local flag_pos = 
{ 
    world_pos = { x = 0, y = 0}, --地图上旗子的位置
    hold_name = "", --手里拿着旗子的玩家
    hold_guild_name = "", --手里拿着旗子的玩家的同盟
}
local crystal_pos = 
    { 
        --第一个水晶
        [1] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = -1, --占领水晶同盟id
            guild_id = -1, --占领水晶帮会id
            league_name = "", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第二个水晶
        [2] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = -1, --占领水晶同盟id
            guild_id = -1, --占领水晶帮会id
            league_name = "", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第三个水晶
        [3] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = -1, --占领水晶同盟id
            guild_id = -1, --占领水晶帮会id
            league_name = "", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
        --第四个水晶
        [4] = 
        {
            world_pos = {x = -1, y = -1}, --水晶位置
            league_id = -1, --占领水晶同盟id
            guild_id = -1, --占领水晶帮会id
            league_name = "", --占领水晶同盟名称
            hp = 0, -- 写死传0
        },
    }
event_fenghuangControl.g_AllBossData = {14003,14005,14007,14009,14011,14012}
--第一个占领据点的同盟数据记录
event_fenghuangControl.g_First_Ascription = 12
--记录本次活动是否开启
event_fenghuangControl.g_NewFengHuangNoticeData = 21
--记录本次活动参与最低等级
event_fenghuangControl.PhoenixwarLevelneed = 48
--记录本次活动参与最低血量
event_fenghuangControl.PhoenixwarMaxhpneed = 49
--记录本次活动开启时间
event_fenghuangControl.PhoenixwarOpenTime = 50
--记录本次活动结束时间
event_fenghuangControl.PhoenixwarOverTime = 51
--记录本次活动场景
event_fenghuangControl.PhoenixwarSceneid = 52
--记录本次活动需求参与时间多久方可领取奖励  单位：秒
event_fenghuangControl.PhoenixwarParticipationTime = 53
--随机阵营位置记录
event_fenghuangControl.PhoenixwarParLmMin = 54
event_fenghuangControl.PhoenixwarParLmMax = 61
--GM开启后  存储多少秒后开启
event_fenghuangControl.PhoenixwarStartTime = 62
--63-72  杀人榜数
--73-82  杀人榜角色
--83-92  杀人榜联盟
--93-100	--联盟名称
--101-108  当前人数
--记录凤凰战旗刷新时间
event_fenghuangControl.FLAG_RefreshTime = 30
--记录凤凰战旗归属。
event_fenghuangControl.g_NewFengHuangFlag = 31
event_fenghuangControl.ScenePosData = {32,33,34,35,36,37,38,39}
event_fenghuangControl.PhoenixwarShort = 32767
--*********************************
-- 水晶归属交旗操作
--*********************************
function event_fenghuangControl:OnDefaultEvent(selfId,targetId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData)
	local opentime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarStartTime)
	local overtime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarOverTime)
	if isopen > 0 and isopen >= opentime and isopen < overtime then
		local nHave = self:LuaFnHaveImpactOfSpecificDataIndex(selfId,3019)
		if nHave then
			if self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangFlag) == selfId then
				self:LuaFnCancelSpecificImpact(selfId,3019) --清理战旗状态
				self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,0) --清理战旗归属数据
				self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45)--设置战旗45s刷新
				flag_pos.world_pos.x = 0
				flag_pos.world_pos.y = 0
				flag_pos.hold_name = ""
				self:DispatchPhoenixPlainWarFlagPos(flag_pos) -- 通知客户端，现在没旗子了。
				IsId = self:GetMissionData(selfId,ScriptGlobal.MD_FH_UNION)
				if IsId >= 1 and IsId <= 8 then
					local tinfo = self.g_SceneData[IsId]
					self:LuaFnSetCopySceneData_Param(tinfo[4],self:LuaFnGetCopySceneData_Param(tinfo[4]) + 120) --夺旗一次加分120分
					-- nRanking = TopListData[IsId].ranking
					-- TopListData[nRanking].crystal_hold_score = self:LuaFnGetCopySceneData_Param(tinfo[4])
					self:HumanTips("#{FHZD_090708_27}")
					self:NotifyFailBox(selfId,targetId,"#{FHZD_090708_83}")
					local Name = self:GetName(selfId)
					local fmt = string.format("#{_INFOUSR%s}#Wvượt năm ải, chém sáu tướng, phá vòng vây, cắm vững cờ chiến Phượng Hoàng lên cứ điểm phe mình, #{_INFOUSR%s}#Wlà anh hùng thật sự của Phượng Hoàng Cổ Thành!#c996666%s#Wnhận#G120 điểm#W.",Name,Name,tinfo[6])
					self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",fmt)
					sMessage = string.format("@*;SrvMsg;GLL:#YChiến sự Phượng Hoàng Cổ Thành:#{_INFOUSR%s}#Wlực vãn cuồng lan, đoạt cờ chiến Phượng Hoàng, mang về cho phe ta#G120 điểm#W.", Name)
					self:BroadMsgByChatPipe(selfId,gbk.fromutf8(sMessage),12)
				else
					self:NotifyFailBox(selfId,targetId,"Ngươi không thuộc người tham gia hoạt động")
				end
			else
				self:LuaFnCancelSpecificImpact(selfId,3019) --清理战旗状态
			end
		else
			self:NotifyFailBox(selfId,targetId,"Ngươi không có kỳ")
		end
	end
end
--*********************************
-- 场景内数据回调
--*********************************
function event_fenghuangControl:OnSceneTimer()
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData)
	if isopen < 1 then return end
	local opentime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarStartTime)
	if opentime < 2 then
		opentime = 6
		self:LuaFnSetCopySceneData_Param(self.PhoenixwarStartTime,opentime)
	end
	if isopen > opentime then
		self:OnSceneJianCe()
	elseif isopen == opentime then
		for i = 93,100 do
			if self:LuaFnGetCopySceneData_Param(i) == 0 then
				self:LuaFnSetCopySceneData_Param(i,self.g_SceneData[i - 92][6])
			end
		end
		self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangNoticeData,isopen + 1)
		local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
		for i = 1,nHumanCount do
			local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
			if self:LuaFnIsObjValid(nHumanId)
			and self:LuaFnIsCanDoScriptLogic(nHumanId)
			and self:LuaFnIsCharacterLiving(nHumanId) then
				self:NewWorld(nHumanId,420,nil,150,150)
			end
		 end
		local msg = "Phượng Hoàng Thành chính thức mở, chư vị đại hiệp vào được rồi"
		self:SceneBroadcastMsg(msg)
	elseif isopen >= 1 then
		self:ResetPhoenixwar()
	end
end
--*********************************
-- 凤凰古城争夺战检测
--*********************************
function event_fenghuangControl:OnSceneJianCe()
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData)
	-- local isopen = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData) + 1
	self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangNoticeData,isopen + 1)
	local overtick = self:LuaFnGetCopySceneData_Param(self.PhoenixwarOverTime)
	if isopen >= overtick then
		self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangNoticeData,0)
		local opentime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarOpenTime)
		local needtime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarParticipationTime)
		local secinfo_jifen = {
			{delflag = 1,index = 1,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 2,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 3,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 4,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			
			{delflag = 1,index = 5,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 6,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 7,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 1,index = 8,score = 0,name = " ",needtime = needtime,opentime = opentime,},
		}
		local secinfo_killplayer = {
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
			{delflag = 2,index = 0,score = 0,name = " ",needtime = needtime,opentime = opentime,},
		
		}
		local lmname
		local winname = ""
		for i,j in ipairs(self.g_SceneData) do
			secinfo_jifen[i].score = self:LuaFnGetCopySceneData_Param(j[4]) + self:LuaFnGetCopySceneData_Param(j[5])
			lmname = self:LuaFnGetCopySceneData_Param(i + 92)
			secinfo_jifen[i].name = lmname
			if secinfo_jifen[i].score >= 10000 then
				secinfo_jifen[i].score = 10000
				winname = lmname
				-- winname = j[6]
			end
		end
		for i,j in ipairs(secinfo_killplayer) do
			j.score = self:LuaFnGetCopySceneData_Param(i + 62)
			j.name = self:LuaFnGetCopySceneData_Param(i + 72)
		end
        table.sort(secinfo_killplayer,function(t1,t2) return t1.score > t2.score end)
		for i,j in ipairs(secinfo_killplayer) do
			j.index = i
		end
		for i = 384,388 do
			self:StopOneActivity(i)
		end
		-- for i = 0,100 do
			-- self:LuaFnSetCopySceneData_Param(i,0)
		-- end
		self:AddPhoenixPlainData(secinfo_jifen,secinfo_killplayer)
		local zqplayerid = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangFlag)
		if zqplayerid > 0 then
			if self:LuaFnIsObjValid(zqplayerid) then
				self:LuaFnCancelSpecificImpact(zqplayerid,3019) --清理战旗状态
			end
		end
		local nMonsterNum = self:GetMonsterCount()
		for r = 1,nMonsterNum do
			local MonsterId = self:GetMonsterObjID(r)
			local MosDataID = self:GetMonsterDataID(MonsterId)
			for i = 1,#self.g_AllBossData do
				if MosDataID == self.g_AllBossData[i]  then
					self:LuaFnDeleteMonster(MonsterId)
					break
				end
			end
		end
		flag_pos = 
		{ 
			world_pos = { x = 0, y = 0}, --地图上旗子的位置
			hold_name = "", --手里拿着旗子的玩家
			hold_guild_name = "", --手里拿着旗子的玩家的同盟
		}
		crystal_pos = 
			{ 
				--第一个水晶
				[1] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第二个水晶
				[2] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第三个水晶
				[3] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第四个水晶
				[4] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
			}
        self:DispatchPhoenixPlainWarFlagPos(flag_pos)
        self:DispatchPhoenixPlainWarCrystalPos(crystal_pos)
		local montername = ""
		if winname ~= "" then
			montername = winname
			local nMstId = self:LuaFnCreateMonster(14011,162,161,3,-1,-1)
			if nMstId > 0 then
				self:SetCharacterTitle("Bá chủ tranh đoạt Phượng Hoàng kỳ này")
				self:SetCharacterName(nMstId,montername)
			end
			self:SceneBroadcastMsg(string.format("#PPhượng Hoàng Cổ Thành, sau một trận đại chiến, %s#Pcuối cùng thắng quần hào, giành quán quân tranh đoạt Phượng Hoàng Cổ Thành. Cả võ lâm chấn động, họ là anh hùng thật sự hôm nay, những ngày tới sẽ hưởng đãi ngộ anh hùng tại Phượng Hoàng Cổ Thành.",winname))
		else
			montername = "Lưu Thủy Cục: không bá chủ"
			local nMstId = self:LuaFnCreateMonster(14011,162,161,3,-1,-1)
			if nMstId > 0 then
				self:SetCharacterTitle(nMstId,"Bá chủ tranh đoạt Phượng Hoàng kỳ này")
				self:SetCharacterName(nMstId,montername)
			end
			self:SceneBroadcastMsg("#PPhượng Hoàng Cổ Thành, sau một trận chèo nước, vòng này không ai thắng.")
		end
		self:LuaFnSetCopySceneData_Param(180,50,14011)
		self:LuaFnSetCopySceneData_Param(180,51,montername)
		return
	end
	local startick = self:LuaFnGetCopySceneData_Param(self.PhoenixwarStartTime)
	if isopen >= startick then
        --判断水晶归属并给归属盟加分
		local cursjscore
		for i = 8,11 do
			local sjforid = self:LuaFnGetCopySceneData_Param(i)
			if sjforid >= 1 and sjforid <= 8 then
				self:LuaFnSetCopySceneData_Param(self.g_SceneData[sjforid][5],
				self:LuaFnGetCopySceneData_Param(self.g_SceneData[sjforid][5]) + 1)
			end
		end
		local TopListData =
		{
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Càn",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Khôn",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Chấn",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Tốn",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Khảm",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Ly",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Cấn",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Đoài",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Đoài",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
			{league_id = -1,guild_id_1 = -1,guild_id_2 = -1,guild_id_3 = -1,crystal_hold_score = 0,flag_capture_score = 0,league_name = "Liên minh·Đoài",guild_name_1 = "",guild_name_2 = "",guild_name_3 = "",playercount = 0,},
		}
		local idx
		local tinfo,tmoster
		for i,j in ipairs(self.g_SceneData) do
			tinfo = TopListData[i]
			tinfo.league_id = i
			tinfo.crystal_hold_score = self:LuaFnGetCopySceneData_Param(j[4])
			tinfo.flag_capture_score = self:LuaFnGetCopySceneData_Param(j[5])
			-- tinfo.league_name = j[6]
			tinfo.league_name = self:LuaFnGetCopySceneData_Param(i + 92)
			if tinfo.crystal_hold_score + tinfo.flag_capture_score >= 10000 then
				self:LuaFnSetCopySceneData_Param(self.PhoenixwarOverTime,0)
			end
		end
		for i = 63,72 do
			idx = i - 62
			tinfo = TopListData[idx]
			tinfo.guild_id_3 = self:LuaFnGetCopySceneData_Param(i)
			tinfo.guild_name_1 = self:LuaFnGetCopySceneData_Param(i + 10)
			tinfo.guild_name_2 = self:LuaFnGetCopySceneData_Param(i + 20)
		end
        --小地图战旗显示
		local zqplayerid = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangFlag)
		if zqplayerid > 0 then
			if not self:LuaFnIsObjValid(zqplayerid) or self:GetMissionData(zqplayerid,ScriptGlobal.MD_FH_UNION) < 1 then
				zqplayerid = 0
				self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,zqplayerid)
				self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45)
				self:HumanTips("#{FHZD_090708_27}")
			end
		end
		nPosX,nPosY = 162,161
		if zqplayerid == 0 then
			flag_pos.world_pos.x = nPosX
			flag_pos.world_pos.y = nPosY
			flag_pos.hold_name = ""
			flag_pos.hold_guild_name = ""
		else
			nPosX,nPosY = self:GetWorldPos(zqplayerid)
			flag_pos.world_pos.x = nPosX
			flag_pos.world_pos.y = nPosY
			flag_pos.hold_name = self:GetName(zqplayerid)
			local islmid = self:GetMissionData(zqplayerid,ScriptGlobal.MD_FH_UNION)
			-- local lmname = self.g_SceneData[islmid][6] or "未知联盟"
			local lmname = self:LuaFnGetCopySceneData_Param(islmid + 92)
			-- local lmname = "未知联盟"
			flag_pos.hold_guild_name = lmname
		end
		local subtime = overtick - isopen
		if subtime > self.PhoenixwarShort then
			subtime = self.PhoenixwarShort
		elseif subtime < 0 then
			subtime = 0
		end
		--client
		--crystal_hold_score ==> flag_capture_score
		--flag_capture_score ==> crystal_hold_score
		local tinfox = TopListData[9]
		tinfox.league_id = 9
		-- tinfox.league_name = "未知联盟"
		tinfox.crystal_hold_score = subtime
		tinfox.flag_capture_score = self:LuaFnGetCopySceneData_Param(self.FLAG_RefreshTime)
		if tinfox.flag_capture_score > 0 then
			self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,tinfox.flag_capture_score - 1) 
		end
		tinfox.guild_id_1 = math.floor(nPosX)
		tinfox.guild_id_2 = math.floor(nPosY)
		
		
		for i = 13,16 do
			local sjtime = self:LuaFnGetCopySceneData_Param(i)
			if sjtime > 0 then
				sjtime = sjtime - 1
				self:LuaFnSetCopySceneData_Param(i,sjtime)
			end
		end
        --判断水晶归属并给归属盟加分
        --水晶刷新读秒
		tmoster = self.g_CrystalCampID[14003]
		tinfo = TopListData[10]
		tinfo.league_id = 10
		
		local sjforid = self:LuaFnGetCopySceneData_Param(tmoster[6])
		if sjforid >= 1 and sjforid <= 8 then
			self:LuaFnSetCopySceneData_Param(self.g_SceneData[sjforid][5],
			self:LuaFnGetCopySceneData_Param(self.g_SceneData[sjforid][5]) + 1)
		end
		tinfo.guild_id_1 = self:LuaFnGetCopySceneData_Param(tmoster[2])
		if tinfo.guild_id_1 > 0 then
			self:LuaFnSetCopySceneData_Param(tmoster[2],tinfo.guild_id_1 - 1)
		end
		local lmnames = self:LuaFnGetCopySceneData_Param(tmoster[4])
		if lmnames == 0 then
			lmnames = "Vô chủ"
		end
		-- tinfo.guild_name_1 = lmnames
		tinfox.league_name = lmnames
		
		tmoster = self.g_CrystalCampID[14005]
		sjforid = self:LuaFnGetCopySceneData_Param(tmoster[6])
		if sjforid >= 1 and sjforid <= 8 then
			self:LuaFnSetCopySceneData_Param(self.g_SceneData[sjforid][5],
			self:LuaFnGetCopySceneData_Param(self.g_SceneData[sjforid][5]) + 1)
		end
		
		tinfo.guild_id_2 = self:LuaFnGetCopySceneData_Param(tmoster[2])
		if tinfo.guild_id_2 > 0 then
			self:LuaFnSetCopySceneData_Param(tmoster[2],tinfo.guild_id_2 - 1)
		end
		lmnames = self:LuaFnGetCopySceneData_Param(tmoster[4])
		if lmnames == 0 then
			lmnames = "Vô chủ"
		end
		-- tinfo.guild_name_2 = lmnames
		tinfox.guild_name_3 = lmnames
		
		tmoster = self.g_CrystalCampID[14007]
		sjforid = self:LuaFnGetCopySceneData_Param(tmoster[6])
		if sjforid >= 1 and sjforid <= 8 then
			self:LuaFnSetCopySceneData_Param(self.g_SceneData[sjforid][5],
			self:LuaFnGetCopySceneData_Param(self.g_SceneData[sjforid][5]) + 1)
		end
		
		tinfo.flag_capture_score = self:LuaFnGetCopySceneData_Param(tmoster[2])
		if tinfo.flag_capture_score > 0 then
			self:LuaFnSetCopySceneData_Param(tmoster[2],tinfo.flag_capture_score - 1)
		end
		lmnames = self:LuaFnGetCopySceneData_Param(tmoster[4])
		if lmnames == 0 then
			lmnames = "Vô chủ"
		end
		tinfo.guild_name_3 = lmnames
		
		
		tmoster = self.g_CrystalCampID[14009]
		sjforid = self:LuaFnGetCopySceneData_Param(tmoster[6])
		if sjforid >= 1 and sjforid <= 8 then
			self:LuaFnSetCopySceneData_Param(self.g_SceneData[sjforid][5],
			self:LuaFnGetCopySceneData_Param(self.g_SceneData[sjforid][5]) + 1)
		end
		
		tinfo.crystal_hold_score = self:LuaFnGetCopySceneData_Param(tmoster[2])
		if tinfo.crystal_hold_score > 0 then
			self:LuaFnSetCopySceneData_Param(tmoster[2],tinfo.crystal_hold_score - 1)
		end
		lmnames = self:LuaFnGetCopySceneData_Param(tmoster[4])
		if lmnames == 0 then
			lmnames = "Vô chủ"
		end
		tinfo.league_name = lmnames
		
		local issj = 0
        --初始化数据
		local nMonsterNum = self:GetMonsterCount()
        for i = 1,nMonsterNum do
            local MonsterId = self:GetMonsterObjID(i)
            local MosDataID = self:GetMonsterDataID(MonsterId)
			tinfo = self.g_CrystalCampID[MosDataID]
            if tinfo then
				issj = issj + 1
                if self:LuaFnGetCopySceneData_Param(tinfo[5]) > 0 then
                    print("MosDataID = ",MosDataID)
                    crystal_pos[issj].world_pos.x = tinfo[7]
                    crystal_pos[issj].world_pos.y = tinfo[8]
                    crystal_pos[issj].guild_id = self:LuaFnGetCopySceneData_Param(tinfo[5])
                    crystal_pos[issj].league_id = self:LuaFnGetCopySceneData_Param(tinfo[6])
                    crystal_pos[issj].league_name = self:LuaFnGetCopySceneData_Param(tinfo[4])
                    crystal_pos[issj].hp = 0
                else
                    crystal_pos[issj].world_pos.x = tinfo[7]
                    crystal_pos[issj].world_pos.y = tinfo[8]
                    crystal_pos[issj].guild_id = -1
                    crystal_pos[issj].league_id = -1
                    crystal_pos[issj].league_name = ""
                    crystal_pos[issj].hp = 0
                end
            end
        end
		 self:AddHumanTime()
        print("crystal_pos = ",table.tostr(crystal_pos))
        self:DispatchPhoenixPlainWarFlagPos(flag_pos)
        self:LuaFnDispatchPhoenixPlainWarScore(TopListData)
        self:DispatchPhoenixPlainWarCrystalPos(crystal_pos)
        self:DispatchPhoenixPlainWarCampInfo()
	end
end
--*********************************
-- 玩家进入场景
--*********************************
function event_fenghuangControl:OnPlayerEnter(selfId)
	self:ResetPlayerData(selfId)
end
function event_fenghuangControl:GetGuildOnUnion(LeagueId,LeagueIdx)
	local IsId = 0
	if LeagueId ~= -1 then
		for i = 1,8 do
			if self.UnionInfo[i] then
				for j,k in ipairs(self.UnionInfo[i]) do
					if k == LeagueId then
						IsId = i
						break
					end
				end
			end
			if IsId > 0 then
				break
			end
		end
	end
	return IsId
end
--*********************************
-- 初始化个人数据
--*********************************
function event_fenghuangControl:ResetPlayerData(selfId)
	local needscene = self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid)
	if self:GetSceneID() ~= needscene then return end
	if self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData) > 2 then
		local selflv = self:GetLevel(selfId)
		local selfhp = self:GetMaxHp(selfId)
		if selflv < self:LuaFnGetCopySceneData_Param(self.PhoenixwarLevelneed)
		or selfhp < self:LuaFnGetCopySceneData_Param(self.PhoenixwarMaxhpneed) then
			-- self:LuaFnGmKillObj(selfId,selfId)
			self:NewWorld(selfId,420,nil,150,150)
			return
		end
		local opentime = self:LuaFnGetCopySceneData_Param(self.PhoenixwarOpenTime)
		if self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_TIME) ~= opentime then
			self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_KILLNUM,0)
			self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_PARTICIPATIONTIME,0)
			
			self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_FH_TIME,opentime)
		end
		local LeagueId = self:LuaFnGetHumanGuildLeagueID(selfId)
		local LeagueName = self:LuaFnGetHumanGuildLeagueName(selfId)
		local IsId = self:GetGuildOnUnion(LeagueId,LeagueId)
		-- local IsId = 0
		-- if LeagueId ~= -1 then
			-- for i = 1,8 do
				-- if self.UnionInfo[i] then
					-- for j,k in ipairs(self.UnionInfo[i]) do
						-- if k == LeagueId then
							-- IsId = i
							-- break
						-- end
					-- end
				-- end
				-- if IsId > 0 then
					-- break
				-- end
			-- end
		-- end
		if IsId > 0 then
			IsId = self:LuaFnGetCopySceneData_Param(IsId + self.PhoenixwarParLmMin - 1)
		end
		self:SetMissionData(selfId,ScriptGlobal.MD_FH_UNION,IsId)
		if IsId > 0 then
			self:LuaFnAddMissionHuoYueZhi(selfId, 29)
			if self:LuaFnGetCopySceneData_Param(IsId + 92) ~= LeagueName then
				self:LuaFnSetCopySceneData_Param(IsId + 92,LeagueName)
			end
		
			self:SetPlayerPvpRule(selfId,9) --设置玩家PVP规则
			self:SetUnitCampID(selfId,self.g_SceneData[IsId][3])
			local posx,posz = self.g_SceneData[IsId][1] ,self.g_SceneData[IsId][2]
			self:SetPlayerDefaultReliveInfo(selfId,1,1,1,needscene,posx,posz)
			self:SetPos(selfId, posx,posz)
			local curpnum = self:LuaFnGetCopySceneData_Param(IsId + 100) + 1
			self:LuaFnSetCopySceneData_Param(IsId + 100,curpnum)
			self:BeginUICommand()
			self:EndUICommand()
			self:DispatchUICommand(selfId,209042022)
			return
		end
		-- self:SetPlayerDefaultReliveInfo(selfId,1,1,1,needscene,139,66)
		-- self:SetPos(selfId, 139, 66)
		-- self:BeginEvent(self.script_id)
		-- self:AddText("当前凤凰战未开启或您不属于八个联盟中的成员")
		-- self:EndEvent()
		-- self:DispatchMissionTips(selfId)
		-- self:LuaFnGmKillObj(selfId,selfId)
		self:NewWorld(selfId,420,nil,150,150)
	end
end
--*********************************
-- 凤凰古城争夺战初始化数据
--*********************************
function event_fenghuangControl:ResetPhoenixwar()
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local isopen = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangNoticeData) + 1
	self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangNoticeData,isopen)
	local startick = self:LuaFnGetCopySceneData_Param(self.PhoenixwarStartTime)
	local subtime = startick - isopen
	local msg = "Chiến Phượng Hoàng sẽ"..tostring(subtime).."giây nữa bắt đầu, chư vị đại hiệp chuẩn bị!#H(ai chưa rời xin rời cảnh sớm, lúc mở chính thức sẽ dọn trận một lần)"
	if isopen == 2 then
		local idx = 0
		local lmtab = {1,2,3,4,5,6,7,8}
		while #lmtab > 0 do
			local curpos = math.random(#lmtab)
			self:LuaFnSetCopySceneData_Param(idx + self.PhoenixwarParLmMin,lmtab[curpos])
			idx = idx + 1
			table.remove(lmtab,curpos)
		end
		for j = 0,47 do
			if j ~= self.g_NewFengHuangNoticeData then
				self:LuaFnSetCopySceneData_Param(j,0) --清除所有记录
			end
		end
		local curtime = self:LuaFnGetCurrentTime()
		self:LuaFnSetCopySceneData_Param(self.PhoenixwarOpenTime,curtime)		--开启时间
		-- self:LuaFnSetCopySceneData_Param(self.PhoenixwarSceneid,self.SceneId)	--场景
		-- self:LuaFnSetCopySceneData_Param(self.PhoenixwarOverTime,2147483647)  --结束时间
		--清理榜单信息 TopListDataz
		for j = 63,92 do
			self:LuaFnSetCopySceneData_Param(j,0) --清除所有记录
		end
		-- for i = 93,100 do
			-- self:LuaFnSetCopySceneData_Param(i,self.g_SceneData[i - 92][6])
		-- end
        --活动重新开始清理一次数据
		local nMonsterNum = self:GetMonsterCount()
		for r = 1,nMonsterNum do
			local MonsterId = self:GetMonsterObjID(r)
			local MosDataID = self:GetMonsterDataID(MonsterId)
			for i = 1,#self.g_AllBossData do
				if MosDataID == self.g_AllBossData[i]  then
					self:LuaFnDeleteMonster(MonsterId)
					break
				end
			end
		end
        self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45) --设置战旗45s后刷新
        for i = 13,16 do
            self:LuaFnSetCopySceneData_Param(i,15) --设置水晶15s刷新
        end
        self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,0) --战旗归属清除
		for i = 384,388 do
			self:StartOneActivity(i,100*10)
		end
		flag_pos = 
		{ 
			world_pos = { x = 0, y = 0}, --地图上旗子的位置
			hold_name = "", --手里拿着旗子的玩家
			hold_guild_name = "", --手里拿着旗子的玩家的同盟
		}
		crystal_pos = 
			{ 
				--第一个水晶
				[1] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第二个水晶
				[2] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第三个水晶
				[3] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
				--第四个水晶
				[4] = 
				{
					world_pos = {x = -1, y = -1}, --水晶位置
					league_id = -1, --占领水晶同盟id
					guild_id = -1, --占领水晶帮会id
					league_name = "", --占领水晶同盟名称
					hp = 0, -- 写死传0
				},
			}
        self:DispatchPhoenixPlainWarFlagPos(flag_pos)
        self:DispatchPhoenixPlainWarCrystalPos(crystal_pos)
		self:HumanTips(msg)
		-- local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
		-- for i = 1,nHumanCount do
			-- local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
			-- if self:LuaFnIsObjValid(nHumanId)
			-- and self:LuaFnIsCanDoScriptLogic(nHumanId)
			-- and self:LuaFnIsCharacterLiving(nHumanId) then
				-- self:NewWorld(nHumanId,420,nil,150,150)
				-- self:ResetPlayerData(nHumanId)
			-- end
		 -- end
	-- elseif isopen == 5 then
		-- local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
		-- for i = 1,nHumanCount do
			-- local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
			-- if self:LuaFnIsObjValid(nHumanId)
			-- and self:LuaFnIsCanDoScriptLogic(nHumanId)
			-- and self:LuaFnIsCharacterLiving(nHumanId) then
				-- self:ResetPlayerData(nHumanId)
			-- end
		-- end
		-- self:SceneBroadcastMsgEx(msg)
	else
		self:SceneBroadcastMsgEx(msg)
	end
end
--*********************************
-- 玩家离开场景
--*********************************
function event_fenghuangControl:OnPlayerLeave(selfId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local IsId = self:GetMissionData(selfId,ScriptGlobal.MD_FH_UNION)
	--玩家离开场景，或者离线后清理一下场景内当前同盟参战人数
	if IsId >= 1 and IsId <= 8 then
		local curpnum = self:LuaFnGetCopySceneData_Param(IsId + 100) - 1
		if curpnum < 0 then
			curpnum = 0
		end
		self:LuaFnSetCopySceneData_Param(IsId + 100,curpnum)
	end
    self:LuaFnDispatchPhoenixPlainWarScore(TopListData)
    --离线或者离开场景检测是否是有战旗的玩家，是的话必须清理玩家战旗标记
	if self:LuaFnHaveImpactOfSpecificDataIndex(selfId,3019) then
		self:LuaFnCancelSpecificImpact(selfId,3019) --清理战旗状态
		if self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangFlag) > 0 then
			self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,0) --清理战旗归属数据
			self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45)--设置战旗45s刷新
			self:HumanTips("#{FHZD_090708_27}")
		end
    end
end
--*********************************
-- 发放奖励
--*********************************
function event_fenghuangControl:PhoneixReWard()
end
--*********************************
-- 水晶被打碎
--*********************************
function event_fenghuangControl:OnDie(objId,KillerId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
    local nMonsterId = self:GetMonsterDataID(objId)
	local targetId = KillerId
    if self:GetCharacterType(KillerId) == "pet" then
        targetId = self:GetPetCreator(KillerId)
    end
    local nKillName = self:GetName(targetId)
    local sMessage = ""
	local IsId = self:GetMissionData(targetId,ScriptGlobal.MD_FH_UNION)
	local lminfo = self.g_SceneData[IsId]
	if lminfo then
		local sjinfo = self.g_CrystalCampID[nMonsterId]
		local oldlmname = self:LuaFnGetCopySceneData_Param(sjinfo[4])
		if oldlmname == 0 then
			oldlmname = sjinfo[3]
		end
		-- local newlmname = lminfo[6]
		local newlmname = self:LuaFnGetCopySceneData_Param(IsId + 92)
		if targetId ~= -1 then
			self:LuaFnSetCopySceneData_Param(sjinfo[4],newlmname)
			-- self:LuaFnSetCopySceneData_Param(sjinfo[5] ,self:GetHumanGuildID(targetId))
			self:LuaFnSetCopySceneData_Param(sjinfo[6] ,IsId)
		end
		if self:LuaFnGetCopySceneData_Param(sjinfo[5]) == 0 then
			self:LuaFnSetCopySceneData_Param(lminfo[5],
			self:LuaFnGetCopySceneData_Param(lminfo[5] ) + 100)
			self:LuaFnSetCopySceneData_Param(sjinfo[5],IsId)
			sMessage = string.format("%s của %s dẫn bang chúng và đồng minh chớp nhoáng chiếm cứ điểm %s lần đầu.",newlmname,nKillName,sjinfo[3])
			self:HumanTips(sMessage)
			sMessage = string.format("@*;SrvMsg;GLL:#YChiến sự Phượng Hoàng Cổ Thành:#Wphe ta#{_INFOUSR%s}#Wphá thủy tinh sinh mệnh#Ycứ điểm %s#W, phe ta chiếm cứ điểm lần đầu, nhận thưởng#G100 điểm#W.",
			nKillName,sjinfo[3])
			self:BroadMsgByChatPipe(KillerId,gbk.fromutf8(sMessage),12)
			sMessage = string.format("#{_INFOUSR%s}#Wphá thủy tinh sinh mệnh#Ycứ điểm %s#W,#c996666%s#Wchiếm cứ điểm lần đầu, nhận thưởng#G100 điểm#W.#c996666%s#Gmỗi giây +1 điểm#W.",
			nKillName,sjinfo[3],newlmname,newlmname)
			self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",sMessage)
		else
			sMessage = string.format("@*;SrvMsg;GLL:#YChiến sự Phượng Hoàng Cổ Thành:#Wphe ta#{_INFOUSR%s}#Wphá hủy thủy tinh sinh mệnh#Ycứ điểm %s#W,#G15#Wgiây sau phe ta chiếm cứ điểm.",
			nKillName,sjinfo[3])
			self:BroadMsgByChatPipe(KillerId,gbk.fromutf8(sMessage),12)
			-- sMessage = string.format("#{_INFOUSR%s}#W成功击毁了#Y%s据点#W的生命水晶，#G15#W秒后，#c996666%s#W将占领%s据点。",nKillName,self.g_CrystalCampID[nMonsterId] [3] ,lminfo.league_name,self.g_CrystalCampID[nMonsterId] [3])
			sMessage = string.format("#{_INFOUSR%s}#Wphá hủy thành công thủy tinh sinh mệnh của#Ycứ điểm %s#W,#G15#Wgiây sau,#c996666%s#Wsẽ chiếm cứ điểm %s.",
			nKillName,oldlmname,newlmname,sjinfo[3])
			self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",sMessage)
		end
		self:LuaFnSetCopySceneData_Param(sjinfo[1],lminfo[3] )
		self:LuaFnSetCopySceneData_Param(sjinfo[2] ,15)
		sMessage = string.format("Chư vị anh hùng chú ý! 15 giây nữa thủy tinh cứ điểm %s làm mới lại.",sjinfo[3])
		self:HumanTips(sMessage)
		self:LuaFnDeleteMonster(objId)
	end
end
--*********************************
-- 玩家死亡状态
--*********************************
function event_fenghuangControl:OnSceneHumanDie(selfId,KillerId)
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local targetId = KillerId
    if self:GetCharacterType(KillerId) == "pet" then
        targetId = self:GetPetCreator(KillerId)
    end
    --防止自杀情况
    if selfId == targetId then
        self:LuaFnCancelSpecificImpact(selfId,3019)
        self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,0)
        self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45)
        return
    end
	local nPosX,nPosY = self:GetWorldPos(selfId)
    local nHave = self:LuaFnHaveImpactOfSpecificDataIndex(selfId,3019)
    local nFlag = self:LuaFnGetCopySceneData_Param(self.g_NewFengHuangFlag)
    if nHave and nFlag > 0 then
		local MstId = self:LuaFnCreateMonster(14012,nPosX,nPosY, 3, 0,403006)
		if MstId > 0 then
			-- self:MonsterTalk(-1,"凤凰平原", "#{FHZD_090708_67}")
			-- self:HumanTips("#{FHZD_090708_67}")
			self:SetCharacterName(MstId,"凤凰战旗")
			flag_pos.world_pos.x = nPosX
			flag_pos.world_pos.y = nPosY
			flag_pos.hold_name = ""
			flag_pos.hold_guild_name = ""
			self:DispatchPhoenixPlainWarFlagPos(flag_pos)
		end
        self:LuaFnCancelSpecificImpact(selfId,3019)
        self:LuaFnSetCopySceneData_Param(self.g_NewFengHuangFlag,0)
        -- self:LuaFnSetCopySceneData_Param(self.FLAG_RefreshTime,45)
        -- local Msg = string.format("#{_INFOUSR%s}丢掉了凤凰战旗。",self:GetName(selfId))
        -- self:HumanTips(Msg)
        self:HumanTips("#{FHZD_090708_27}")
        local Msg = string.format("#{_INFOUSR%s} đã đánh rơi cờ chiến Phượng Hoàng.",self:GetName(selfId))
        self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",Msg)
    end
	local selfunion = self:GetMissionData(selfId,ScriptGlobal.MD_FH_UNION)
	local tarunion = self:GetMissionData(targetId,ScriptGlobal.MD_FH_UNION)
	if selfunion > 0 and tarunion > 0 and selfunion ~= tarunion then
		local tarname,iseffective = self:GetKillEffective(selfId,targetId,event_fenghuangControl.KillPlayerTime)
		if iseffective then
			local maxkillnum = self.PhoenixwarShort
			local tarkillnum = self:GetMissionDataEx(targetId,ScriptGlobal.MDEX_FH_KILLNUM) + 1
			if tarkillnum > maxkillnum then
				tarkillnum = maxkillnum
			end
			self:SetMissionDataEx(targetId,ScriptGlobal.MDEX_FH_KILLNUM,tarkillnum)
			-- local targuid = self:LuaFnGetGUID(targetId)
			local toppos = 0
			-- local tarlmname = self.g_SceneData[tarunion][6] or "未知联盟"
			local tarlmname = self:LuaFnGetCopySceneData_Param(tarunion + 92)
			for i = 73,82 do
				if self:LuaFnGetCopySceneData_Param(i) == tarname then
					toppos = i
					self:LuaFnSetCopySceneData_Param(i - 10,tarkillnum)
					self:LuaFnSetCopySceneData_Param(i + 10,tarlmname)
					break
				end
			end
			if toppos == 0 then
				for i = 63,72 do
					local topkillnum = self:LuaFnGetCopySceneData_Param(i)
					if topkillnum < maxkillnum then
						maxkillnum = topkillnum
						toppos = i
					end
				end
				if tarkillnum > maxkillnum and toppos > 0 then
					self:LuaFnSetCopySceneData_Param(toppos,tarkillnum)
					self:LuaFnSetCopySceneData_Param(toppos + 10,tarname)
					self:LuaFnSetCopySceneData_Param(toppos + 20,tarlmname)
				end
			end
			if tarkillnum >= 10 and tarkillnum % 10 == 0 then
				local Msg = string.format("#{_INFOUSR%s} với khí thế không ai cản nổi, chém %d địch.",tarname,tarkillnum)
				self:MonsterTalk(-1,"Phượng Hoàng Bình Nguyên",Msg)
			end
		else
			self:BeginEvent(self.script_id)
			self:AddText("Giết không hợp lệ ("..tostring(event_fenghuangControl.KillPlayerTime).."giây)")
			self:EndEvent()
			self:DispatchMissionTips(nHumanId)
		end
	else
		self:BeginEvent(self.script_id)
		self:AddText("Giết không hợp lệ (bản thân hoặc mục tiêu không thuộc chiến Phượng Hoàng)")
		self:EndEvent()
		self:DispatchMissionTips(nHumanId)
	end
end

function event_fenghuangControl:HumanTips(str)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId)
        and self:LuaFnIsCanDoScriptLogic(nHumanId)
        and self:LuaFnIsCharacterLiving(nHumanId) then
            self:BeginEvent(self.script_id)
            self:AddText(str)
            self:EndEvent()
            self:DispatchMissionTips(nHumanId)
        end
     end
end
function event_fenghuangControl:AddHumanTime()
	if self:GetSceneID() ~= self:LuaFnGetCopySceneData_Param(self.PhoenixwarSceneid) then return end
	local lmid
	local addtime
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1,nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(nHumanId) then
			lmid = self:GetMissionData(nHumanId,ScriptGlobal.MD_FH_UNION)
			if lmid >= 1 and lmid <= 8 then
				addtime = self:GetMissionDataEx(nHumanId,ScriptGlobal.MDEX_FH_PARTICIPATIONTIME) + 1
				self:SetMissionDataEx(nHumanId,ScriptGlobal.MDEX_FH_PARTICIPATIONTIME,addtime)
			end
        end
     end
end
function event_fenghuangControl:MsgBox(selfId,str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function event_fenghuangControl:NotifyFailBox(selfId,targetId,msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end
return event_fenghuangControl
